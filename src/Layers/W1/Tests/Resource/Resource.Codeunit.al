codeunit 136907 Resource
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [Resource]
    end;

    var
        DummyJobsSetup: Record "Jobs Setup";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LocationWhite: Record Location;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJob: Codeunit "Library - Job";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized: Boolean;
        WantToCreateContactQst: Label 'Do you want to create a contact as a customer using a customer template?', Comment = '%1 = Contact No., %2 = Contact Name';
        WantToCreateContractQst: Label 'Do you want to create the contract using a contract template?';
        CannotModifyBaseUnitOfMeasureErr: Label 'You cannot modify %1 %2 for resource %3 because it is the resource''s %4.', Comment = '%1 Table name (Item Unit of measure), %2 Value of Measure (KG, PCS...), %3 Item ID, %4 Base unit of Measure';
        BaseUnitOfMeasureQtyMustBeOneErr: Label 'The quantity per base unit of measure must be 1. %1 is set up with %2 per unit of measure.', Comment = '%1 Name of Unit of measure (e.g. BOX, PCS, KG...), %2 Qty. of %1 per base unit of measure ';
        JobLedgerEntryUpdatedMsg: Label 'The project ledger entry item costs have now been updated to equal the related item ledger entry actual costs.';
        NoJobLedgEntriesToUpdateMsg: Label 'There were no project ledger entries that needed to be updated';
        WantToPostJournalLinesQst: Label 'Do you want to post the journal lines?';
        JournalLinesPostedMsg: Label 'The journal lines were successfully posted.';
        NoJobLedgerEntriesUpdatedMsg: Label 'There were no project ledger entries that needed to be updated.';
        JobPlanningLineMustBeEmptyMsg: Label 'Project Planning Line must be empty.';
        PurchaseLineTypeErr: Label 'Project No. must not be specified when Type = Charge (Item) in Purchase Line';
        JobNoErr: Label 'Project No. must not be specified when Type = Fixed Asset in Purchase Line Document Type=''%1'',Document No.=''%2'',Line No.=''%3''', Comment = '%1 = Document Type Value, %2 = Document No. Value, %3 = Line No. Value';
        QuantityMustBeSameMsg: Label 'Quantity must be same.';
        AdjustedJobLedgerEntryExistMsg: Label 'Adjusted Project ledger entry exist.';
        ItemAnalysisViewEntryMustNotExistMsg: Label 'Item Analysis View entry must not exist.';
        WantToUndoConsumptionQst: Label 'Do you want to undo consumption of the selected shipment line(s)?';
        TemplateCodeErr: Label 'Unexpected Template Code';
        JobPlanningLineCountErr: Label '%1 count should be greater than %2';
        JobPlanningLineFilterErr: Label 'Entry count of %1 with filter %2 is invalid';
        DaysTok: Label 'day(s)';
        JobLedgEntryExistsErr: Label 'Incorrect Project Ledger Entry exists.';
        DocumentExistsErr: Label 'You cannot delete resource %1 because there are one or more outstanding %2 that include this resource.';
        UnitPriceErr: Label 'Unit Price must not change.';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnDoingCreateAsCustomerOnContact()
    var
        Contact: Record Contact;
        TemplateCode: Code[10];
    begin
        // Setup. Create Contact.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryVariableStorage.Enqueue(WantToCreateContactQst);  // Enqueue for Confirm Handler.
        LibraryVariableStorage.Enqueue(false);  // Enqueue for Confirm Handler.

        // Exercise.
        TemplateCode := Contact.ChooseNewCustomerTemplate();

        // Verify.
        Assert.AreEqual('', TemplateCode, TemplateCodeErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceContractTemplateListPageHandler,ContractLineSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure SelectContractLinesOnServiceContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceItem: Record "Service Item";
    begin
        // Setup: Create Customer and Service Item. Create Service Contract.
        Initialize();
        CreateServiceContractHeader(ServiceContractHeader, ServiceItem);

        // Exercise.
        OpenSelectContractLinesFromServiceContractPage(ServiceContractHeader."Contract No.");

        // Verify.
        VerifyServiceContractLine(ServiceContractHeader, ServiceItem."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnDeletingResourceBaseUnitOfMeasure()
    var
        Resource: Record Resource;
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
    begin
        // Setup: Create Resource.
        Initialize();
        LibraryResource.CreateResourceNew(Resource);
        ResourceUnitOfMeasure.Get(Resource."No.", Resource."Base Unit of Measure");

        // Exercise.
        asserterror ResourceUnitOfMeasure.Delete(true);

        // Verify.
        Assert.ExpectedError(
          StrSubstNo(
            CannotModifyBaseUnitOfMeasureErr, ResourceUnitOfMeasure.TableCaption(), ResourceUnitOfMeasure.Code, Resource."No.",
            Resource.FieldCaption("Base Unit of Measure")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnRenamingResourceBaseUnitOfMeasure()
    var
        Resource: Record Resource;
        SalesLine: Record "Sales Line";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // Setup: Create Resource. Create and post Sales Order. Create Unit of Measure code.
        Initialize();
        LibraryResource.CreateResourceNew(Resource);
        CreateAndPostSalesOrder(
          '', SalesLine.Type::Resource, Resource."No.", LibraryRandom.RandDec(10, 2));
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        ResourceUnitOfMeasure.Get(Resource."No.", Resource."Base Unit of Measure");

        // Exercise.
        asserterror ResourceUnitOfMeasure.Rename(Resource."No.", UnitOfMeasure.Code);

        // Verify.
        Assert.ExpectedError(
          StrSubstNo(
            CannotModifyBaseUnitOfMeasureErr, ResourceUnitOfMeasure.TableCaption(), Resource."Base Unit of Measure", Resource."No.",
            Resource.FieldCaption("Base Unit of Measure")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaskForContactWithSalesPerson()
    begin
        // Setup.
        Initialize();
        TaskForContact(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaskForContactWithSalesPersonAndTeamCode()
    begin
        // Setup.
        Initialize();
        TaskForContact(true);  // UpdateTeamCode as TRUE.
    end;

    local procedure TaskForContact(UpdateTeamCode: Boolean)
    var
        Contact: Record Contact;
        TeamSalesperson: Record "Team Salesperson";
        Team: Record Team;
        Task: Record "To-do";
        TaskList: TestPage "Task List";
    begin
        // Create Contact. Create Team and Team Salesperson.
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateTeam(Team);
        LibraryMarketing.CreateTeamSalesperson(TeamSalesperson, Team.Code, Contact."Salesperson Code");

        // Exercise.
        CreateTask(Task, Contact);

        // Verify.
        VerifyTask(Contact, Task."No.");

        if UpdateTeamCode then begin
            // Exercise.
            OpenTaskCardFromContactCardAndUpdateTeamCode(TaskList, Contact."No.", Team.Code);

            // Verify.
            TaskList."Team Code".AssertEquals(Team.Code);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingJobTaskNoOnPurchaseOrderLine()
    var
        JobTask: Record "Job Task";
    begin
        // Setup.
        Initialize();
        ErrorOnUpdatingJobTaskTypeOnPurchaseLine(JobTask."Job Task Type"::Total);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateJobItemCostReportAfterPostPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
        Quantity: Decimal;
        DirectUnitCost: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // [FEATURE] [Update Job Item Cost]
        // [SCENARIO] Job ledger entries contain correct values after running Update Job Item Cost batch report and posting Purchase Orders.

        // Setup: Create Item with Average Costing method. Create Job and Job Task. Post Purchase Orders with different Direct Unit cost. Run Adjust Cost Item entries batch job.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        DirectUnitCost := Quantity + LibraryRandom.RandInt(10);  // Greater value required for Direct Unit Cost.
        CreateItemWithCostingMethod(Item, Item."Costing Method"::Average);
        CreateJobWithJobTask(JobTask);
        DocumentNo :=
          CreateAndPostPurchaseOrderWithJob(
            PurchaseHeader, PurchaseLine, JobTask, Item."No.", Quantity, Quantity, Quantity, PurchaseLine."Job Line Type"::Budget, true);
        // Validating Direct Unit Cost as Quantity and post as invoice.
        DocumentNo2 :=
          CreateAndPostPurchaseOrderWithJob(
            PurchaseHeader, PurchaseLine, JobTask, Item."No.", Quantity, Quantity, DirectUnitCost,
            PurchaseLine."Job Line Type"::Budget, true);  // post as invoice.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Exercise.
        LibraryVariableStorage.Enqueue(NoJobLedgEntriesToUpdateMsg);  // Enqueue for MessageHandler.
        LibraryJob.RunUpdateJobItemCost(JobTask."Job No.");

        // Verify.
        VerifyJobLedgerEntry(
          JobTask."Job No.", DocumentNo, JobLedgerEntry."Line Type"::Budget, Item."Base Unit of Measure", Quantity,
          Quantity, Quantity, 0);  // Calculated value required for Unit Cost.
        VerifyJobLedgerEntry(
          JobTask."Job No.", DocumentNo2, JobLedgerEntry."Line Type"::Budget, Item."Base Unit of Measure", DirectUnitCost,
          DirectUnitCost, Quantity, 0);  // Calculated value required for Unit Cost.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetReceiptLinesOnPurchaseInvoiceWithJob()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create Item. Create Job and Job Task. Create and post Purchase Order with two lines with different Job Line Type.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateJobWithJobTask(JobTask);
        CreateAndPostPurchaseOrderWithMultipleLines(PurchaseHeader, PurchaseLine, PurchaseLine2, JobTask, Item."No.");

        // Exercise.
        DocumentNo := CreateAndPostPurchaseInvoiceWithGetReceiptLines(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."No.");

        // Verify.
        VerifyJobPlanningLine(PurchaseLine, JobPlanningLine."Line Type"::Budget, false, PurchaseLine.Quantity);
        VerifyJobPlanningLine(PurchaseLine2, JobPlanningLine."Line Type"::Budget, true, PurchaseLine2.Quantity);  // MoveNext as TRUE.
        VerifyJobPlanningLine(PurchaseLine2, JobPlanningLine."Line Type"::Billable, false, PurchaseLine2.Quantity);
        VerifyJobLedgerEntry(
          JobTask."Job No.", DocumentNo, PurchaseLine."Job Line Type", Item."Base Unit of Measure", PurchaseLine."Direct Unit Cost",
          PurchaseLine."Direct Unit Cost", PurchaseLine.Quantity, 0);
        VerifyJobLedgerEntry(
          JobTask."Job No.", DocumentNo, PurchaseLine2."Job Line Type", Item."Base Unit of Measure", PurchaseLine2."Direct Unit Cost",
          PurchaseLine2."Direct Unit Cost", PurchaseLine2.Quantity, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateJobItemCostWithPOAndStandardCosting()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        JobTask: Record "Job Task";
        Quantity: Decimal;
    begin
        // [FEATURE] [Update Job Item Cost]
        // [SCENARIO] Adjustment Job ledger entry does not gets created after Update Job Item Cost batch job with Standard Costing.

        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        AdjustCostItemEntriesWithJobAndStandardCosting(Item, ItemUnitOfMeasure, JobTask, Quantity);

        // Exercise.
        LibraryVariableStorage.Enqueue(NoJobLedgerEntriesUpdatedMsg);  // Enqueue for Message Handler.
        LibraryJob.RunUpdateJobItemCost(JobTask."Job No.");

        // Verify: Adjustment Job ledger entry does not exist.
        VerifyAdjustedJobLedgerEntryExist(JobTask."Job No.", Item."No.", Item."Base Unit of Measure", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesWithDiffUOMAndStandardCosting()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        JobTask: Record "Job Task";
        Quantity: Decimal;
        OldAutomaticUpdateJobItemCost: Boolean;
    begin
        // [FEATURE] [Update Job Item Cost]
        // [SCENARIO] Adjustment Job ledger entry does not gets created after Adjust Cost Item Entries with different UOM and Standard Costing.

        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        AdjustCostItemEntriesWithJobAndStandardCosting(Item, ItemUnitOfMeasure, JobTask, Quantity);
        LibraryVariableStorage.Enqueue(NoJobLedgerEntriesUpdatedMsg);  // Enqueue for Message Handler.
        LibraryJob.RunUpdateJobItemCost(JobTask."Job No.");

        // Exercise: Update Automatic Update Job Item cost on Jobs Setup. Create and post Job Journal. Run Adjust Cost Item entries batch job.
        OldAutomaticUpdateJobItemCost := UpdateAutomaticUpdateJobItemCostOnJobsSetup(true);
        CreateAndPostJobJournalLine(JobTask, Item."No.", ItemUnitOfMeasure.Code, Quantity, 0, false);  // Value 0 required for Unit Cost.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify: Adjustment Job ledger entry does not exist.
        VerifyAdjustedJobLedgerEntryExist(JobTask."Job No.", Item."No.", ItemUnitOfMeasure.Code, false);

        // Tear Down.
        UpdateAutomaticUpdateJobItemCostOnJobsSetup(OldAutomaticUpdateJobItemCost);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateJobItemCostWithPOAndSpecificCosting()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        JobTask: Record "Job Task";
        Quantity: Decimal;
    begin
        // [FEATURE] [Update Job Item Cost]
        // [SCENARIO] Adjustment Job ledger entry gets created after Update Job Item Cost batch job with Specific Costing and Serial Tracking.

        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        AdjustCostItemEntriesWithJobAndSpecificCosting(Item, ItemUnitOfMeasure, JobTask, Quantity);

        // Exercise.
        LibraryVariableStorage.Enqueue(JobLedgerEntryUpdatedMsg);  // Enqueue for Message Handler.
        LibraryJob.RunUpdateJobItemCost(JobTask."Job No.");

        // Verify: Adjustment Job ledger entry exist.
        VerifyAdjustedJobLedgerEntryExist(JobTask."Job No.", Item."No.", Item."Base Unit of Measure", true);  // TRUE for Entry Exist.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesWithDiffUOMAndSpecificCosting()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        JobTask: Record "Job Task";
        Quantity: Decimal;
        OldAutomaticUpdateJobItemCost: Boolean;
    begin
        // [FEATURE] [Update Job Item Cost]
        // [SCENARIO] Adjustment Job ledger entry gets created after Adjust Cost Item Entries with different UOM, Specific Costing and Serial Tracking.

        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        AdjustCostItemEntriesWithJobAndSpecificCosting(Item, ItemUnitOfMeasure, JobTask, Quantity);
        LibraryVariableStorage.Enqueue(JobLedgerEntryUpdatedMsg);  // Enqueue for Message Handler.
        LibraryJob.RunUpdateJobItemCost(JobTask."Job No.");

        // Exercise: Update Automatic Update Job Item cost on Jobs Setup. Create and post Job Journal. Run Adjust Cost Item entries batch job.
        OldAutomaticUpdateJobItemCost := UpdateAutomaticUpdateJobItemCostOnJobsSetup(true);
        CreateAndPostJobJournalLine(
          JobTask, Item."No.", ItemUnitOfMeasure.Code, Quantity / ItemUnitOfMeasure."Qty. per Unit of Measure",
          Item."Unit Cost" + 50, true);  // Calculated values required for Quantity and Direct Unit Cost. TRUE for Tracking.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify: Adjustment Job ledger entry exist.
        VerifyAdjustedJobLedgerEntryExist(JobTask."Job No.", Item."No.", ItemUnitOfMeasure.Code, true);  // TRUE for Entry Exist.

        // Tear Down.
        UpdateAutomaticUpdateJobItemCostOnJobsSetup(OldAutomaticUpdateJobItemCost);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateJobItemCostWithPOAndAverageCosting()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Update Job Item Cost]
        // [SCENARIO] Adjustment Job ledger entry gets created after Update Job Item Cost batch job with Average Costing.

        // Setup.
        Initialize();
        UpdateJobItemCostWithPOAndCostingMethod(Item."Costing Method"::Average);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesWithDiffUOMAndAverageCosting()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Update Job Item Cost]
        // [SCENARIO] Adjustment Job ledger entry gets created after Adjust Cost Item Entries with different UOM and Average Costing.

        // Setup.
        Initialize();
        AdjustCostItemWithMultipleUOMAndCostingMethod(Item."Costing Method"::Average);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateJobItemCostWithPOAndFIFOCosting()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Update Job Item Cost]
        // [SCENARIO] Adjustment Job ledger entry gets created after Update Job Item Cost batch job with FIFO Costing.

        // Setup.
        Initialize();
        UpdateJobItemCostWithPOAndCostingMethod(Item."Costing Method"::FIFO);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesWithDiffUOMAndFIFOCosting()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Update Job Item Cost]
        // [SCENARIO] Adjustment Job ledger entry gets created after Adjust Cost Item Entries with different UOM and FIFO Costing.

        // Setup.
        Initialize();
        AdjustCostItemWithMultipleUOMAndCostingMethod(Item."Costing Method"::FIFO);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateJobItemCostWithPOAndLIFOCosting()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Update Job Item Cost]
        // [SCENARIO] Adjustment Job ledger entry gets created after Update Job Item Cost batch job with LIFO Costing.

        // Setup.
        Initialize();
        UpdateJobItemCostWithPOAndCostingMethod(Item."Costing Method"::LIFO);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesWithDiffUOMAndLIFOCosting()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Update Job Item Cost]
        // [SCENARIO] Adjustment Job ledger entry gets created after Adjust Cost Item Entries with different UOM and LIFO Costing.

        // Setup.
        Initialize();
        AdjustCostItemWithMultipleUOMAndCostingMethod(Item."Costing Method"::LIFO);
    end;

    local procedure AdjustCostItemWithMultipleUOMAndCostingMethod(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        JobTask: Record "Job Task";
        Quantity: Decimal;
        OldAutomaticUpdateJobItemCost: Boolean;
    begin
        // Adjust Cost Item Entries with Job and Costing Method.
        Quantity := LibraryRandom.RandDec(10, 2);
        AdjustCostItemEntriesWithJobAndCostingMethod(Item, ItemUnitOfMeasure, JobTask, CostingMethod, Quantity);
        LibraryVariableStorage.Enqueue(JobLedgerEntryUpdatedMsg);  // Enqueue for Message Handler.
        LibraryJob.RunUpdateJobItemCost(JobTask."Job No.");

        // Exercise: Update Automatic Update Job Item cost on Jobs Setup. Create and post Job Journal. Run Adjust Cost Item entries batch job.
        OldAutomaticUpdateJobItemCost := UpdateAutomaticUpdateJobItemCostOnJobsSetup(true);
        CreateAndPostJobJournalLine(JobTask, Item."No.", ItemUnitOfMeasure.Code, Quantity, Item."Unit Cost" + 50, false);  // Greater value required for Unit Cost.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify: Adjusted Job ledger entry exist.
        VerifyAdjustedJobLedgerEntryExist(JobTask."Job No.", Item."No.", ItemUnitOfMeasure.Code, true);  // TRUE for Entry Exist.

        // Tear Down.
        UpdateAutomaticUpdateJobItemCostOnJobsSetup(OldAutomaticUpdateJobItemCost);
    end;

    local procedure UpdateJobItemCostWithPOAndCostingMethod(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        JobTask: Record "Job Task";
        Quantity: Decimal;
    begin
        // Adjust Cost Item Entries with Job and Costing Method.
        Quantity := LibraryRandom.RandDec(10, 2);
        AdjustCostItemEntriesWithJobAndCostingMethod(Item, ItemUnitOfMeasure, JobTask, CostingMethod, Quantity);

        // Exercise.
        LibraryVariableStorage.Enqueue(JobLedgerEntryUpdatedMsg);  // Enqueue for Message Handler.
        LibraryJob.RunUpdateJobItemCost(JobTask."Job No.");

        // Verify: Adjusted Job ledger entry exist.
        VerifyAdjustedJobLedgerEntryExist(JobTask."Job No.", Item."No.", Item."Base Unit of Measure", true);  // TRUE for Entry Exist.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlngLinesAfterShippingPurchOrdWithPartialQty()
    var
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup.
        Initialize();

        // Exercise.
        CreateAndReceivePurchaseOrderWithJob(PurchaseHeader, PurchaseLine);

        // Verify.
        VerifyEmptyJobPlanningLines(PurchaseLine, JobPlanningLine."Line Type"::Budget);
        VerifyEmptyJobPlanningLines(PurchaseLine, JobPlanningLine."Line Type"::Billable);
        VerifyEmptyJobPlanningLines(PurchaseLine, JobPlanningLine."Line Type"::"Both Budget and Billable");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlngLinesAfterInvoicingPurchOrdWithPartialQty()
    var
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create and receive Purchase Order with Job.
        Initialize();
        CreateAndReceivePurchaseOrderWithJob(PurchaseHeader, PurchaseLine);

        // Exercise.
        PostPurchaseOrder(PurchaseHeader, false);

        // Verify.
        VerifyJobPlanningLine(PurchaseLine, JobPlanningLine."Line Type"::Budget, false, PurchaseLine.Quantity / 2);
        VerifyJobPlanningLine(PurchaseLine, JobPlanningLine."Line Type"::Billable, false, PurchaseLine.Quantity / 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlngLinesAfterInvoicingPurchaseOrder()
    var
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create and receive Purchase Order with Job. Post Purchase Order as Invoice.
        Initialize();
        CreateAndReceivePurchaseOrderWithJob(PurchaseHeader, PurchaseLine);
        PostPurchaseOrder(PurchaseHeader, false);

        // Exercise.
        PostPurchaseOrder(PurchaseHeader, true);  // Post as Ship and Invoice.

        // Verify.
        VerifyJobPlanningLine(PurchaseLine, JobPlanningLine."Line Type"::Budget, true, PurchaseLine.Quantity / 2);  // MoveNext as True.
        VerifyJobPlanningLine(PurchaseLine, JobPlanningLine."Line Type"::Billable, true, PurchaseLine.Quantity / 2);  // MoveNext as True.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderUsingCopyDocumentWithJob()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Create Job with Job Task.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateJobWithJobTask(JobTask);

        // Exercise.
        CopyDocumentUsingPurchaseOrderWithJob(JobTask, Item."No.", Quantity);

        // Verify.
        VerifyPurchaseReturnOrder(JobTask, Item."No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderUsingCopyDocumentWithJob()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        JobTask: Record "Job Task";
        Quantity: Decimal;
    begin
        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateJobWithJobTask(JobTask);
        CopyDocumentUsingPurchaseOrderWithJob(JobTask, Item."No.", Quantity);

        // Exercise.
        UpdateQuantityAndPostPurchaseReturnOrder(Item."No.", Quantity / 2);  // Partial posting required.

        // Verify.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, ItemLedgerEntry."Document Type"::"Purchase Receipt", false, Item."No.",
          Quantity, 0, 0);  // Value 0 for Remaining Quantity.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, ItemLedgerEntry."Document Type"::"Purchase Return Shipment", false, Item."No.",
          -Quantity / 2, 0, 0);  // Value 0 for Remaining Quantity.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingEndTotalJobTaskTypeOnPurchaseLine()
    var
        JobTask: Record "Job Task";
    begin
        // Setup.
        Initialize();
        ErrorOnUpdatingJobTaskTypeOnPurchaseLine(JobTask."Job Task Type"::"End-Total");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingBeginTotalJobTaskTypeOnPurchaseLine()
    var
        JobTask: Record "Job Task";
    begin
        // Setup.
        Initialize();
        ErrorOnUpdatingJobTaskTypeOnPurchaseLine(JobTask."Job Task Type"::"Begin-Total");
    end;

    local procedure ErrorOnUpdatingJobTaskTypeOnPurchaseLine(JobTaskType: Enum "Job Task Type")
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Job and Job Task. Update Job Task Type on Job Task. Create Item.
        CreateJobWithJobTask(JobTask);
        UpdateJobTaskTypeOnJobTask(JobTask, JobTaskType);
        LibraryInventory.CreateItem(Item);

        // Exercise.
        asserterror CreatePurchaseOrderWithJob(
            PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2), PurchaseLine.Quantity,
            JobTask."Job No.", JobTask."Job Task No.", LibraryRandom.RandDec(10, 2), PurchaseLine."Job Line Type"::Budget);

        // Verify.
        Assert.ExpectedTestFieldError(JobTask.FieldCaption("Job Task Type"), Format(JobTask."Job Task Type"::Posting));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingJobNoOnPurchaseLineForChargeItem()
    var
        Vendor: Record Vendor;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemCharge: Record "Item Charge";
    begin
        // Setup: Create Vendor. Create Job and Job Task line. Create Item Charge.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateJobWithJobTask(JobTask);
        LibraryInventory.CreateItemCharge(ItemCharge);

        // Exercise.
        asserterror CreatePurchaseOrderWithJob(
            PurchaseHeader, PurchaseLine, PurchaseLine.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandDec(10, 2),
            PurchaseLine.Quantity, JobTask."Job No.", JobTask."Job Task No.", LibraryRandom.RandDec(10, 2),
            PurchaseLine."Job Line Type"::Budget);

        // Verify.
        Assert.ExpectedError(PurchaseLineTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingJobNoOnPurchaseLineForFixedAsset()
    var
        JobTask: Record "Job Task";
        FixedAsset: Record "Fixed Asset";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create Job with Job Task. Create Fixed Asset.
        Initialize();
        CreateJobWithJobTask(JobTask);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);

        // Exercise.
        asserterror CreatePurchaseOrderWithJob(
            PurchaseHeader, PurchaseLine, PurchaseLine.Type::"Fixed Asset", FixedAsset."No.", LibraryRandom.RandDec(10, 2),
            PurchaseLine.Quantity, JobTask."Job No.", JobTask."Job Task No.", LibraryRandom.RandDec(10, 2),
            PurchaseLine."Job Line Type"::Budget);

        // Verify.
        Assert.ExpectedError(StrSubstNo(JobNoErr, PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,EnterQuantityToCreatePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateJobItemCostWithPartialPOAndSpecificCosting()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OldAutomaticUpdateJobItemCost: Boolean;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Update Job Item Cost]
        // [SCENARIO] Job Ledger Entry contains correct values after Update Job Item Cost and Adjust Cost Item Entries with Specific Costing Method.

        // Setup: Create Item with Serial Item Tracking. Update Unit Price and Costing Method on Item. Create Job with Job Task. Update Automatic Update Job Item Cost on Jobs Setup. Create and Post Partial Purchase Order with job.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateItemWithSerialItemTracking(Item);
        UpdateUnitPriceAndCostingMethodOnItem(Item, Item."Costing Method"::Specific);
        CreateJobWithJobTask(JobTask);
        OldAutomaticUpdateJobItemCost := UpdateAutomaticUpdateJobItemCostOnJobsSetup(true);
        CreatePurchaseOrderWithJob(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, Item."No.", Quantity * 2,
          Quantity, JobTask."Job No.", JobTask."Job Task No.", 0,
          PurchaseLine."Job Line Type"::Budget);  // Large Quantity Value Required. Use 0 for DirectUnitCost.
        UpdateUnitPriceAndAssignTrackingOnPurchaseLine(PurchaseLine, Item."Unit Price" * 2);  // Calculated Value Required for Unit Price.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Receive and Invoice as TRUE.
        DocumentNo2 :=
          UpdateUnitPriceAndPostPurchaseOrder(
            PurchaseHeader, PurchaseLine, Item."Unit Price" / 2);  // Calculated Value Required for Unit Price.

        // Exercise.
        UpdateJobItemCostAfterAdjustCostItemEntries(Item."No.", JobTask."Job No.");

        // Verify.
        VerifyJobLedgerEntryForSerial(Item, JobTask, DocumentNo, Quantity);
        VerifyJobLedgerEntryForSerial(Item, JobTask, DocumentNo2, Quantity);

        // Tear Down.
        UpdateAutomaticUpdateJobItemCostOnJobsSetup(OldAutomaticUpdateJobItemCost);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateJobItemCostWithMultiplePOAndLIFOCosting()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        PurchaseLine: Record "Purchase Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        OldAutomaticUpdateJobItemCost: Boolean;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Update Job Item Cost]
        // [SCENARIO] Job Ledger Entry contains correct values after Update Job Item Cost and Adjust Cost Item Entries with Different UOM and LIFO Costing Method.

        // Setup: Create Item with Multiple Unit of Measure. Update Unit Price and Costing Method on Item. Create Job with Job Task. Update Automatic Update Job Item Cost on Jobs Setup. Create and Post Multiple Purchase Orders.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithMultipleUnitOfMeasure(Item, ItemUnitOfMeasure);
        UpdateUnitPriceAndCostingMethodOnItem(Item, Item."Costing Method"::LIFO);
        CreateJobWithJobTask(JobTask);
        OldAutomaticUpdateJobItemCost := UpdateAutomaticUpdateJobItemCostOnJobsSetup(true);
        DocumentNo :=
          CreateAndPostPurchaseOrderWithDifferentUOM(
            PurchaseLine, Item."No.", Quantity, Quantity, JobTask."Job No.", JobTask."Job Task No.", ItemUnitOfMeasure.Code);
        DocumentNo2 :=
          CreateAndPostPurchaseOrderWithDifferentUnitPrice(
            Item."No.", Quantity / 2, JobTask."Job No.", JobTask."Job Task No.",
            Item."Unit Price" / 2);  // Calculated Value Required for Quantity and Unit Price.

        // Exercise.
        UpdateJobItemCostAfterAdjustCostItemEntries(Item."No.", JobTask."Job No.");
        // Verify.
        VerifyJobLedgerEntry(
          JobTask."Job No.", DocumentNo, PurchaseLine."Job Line Type", Item."Base Unit of Measure", 0, 0, 0,
          Item."Unit Price");  // Use 0 for DirectUnitCost, Unit Cost and Total Cost (LCY).
        VerifyJobLedgerEntryDoesNotExist(
          JobTask."Job No.", DocumentNo, PurchaseLine."Job Line Type", ItemUnitOfMeasure.Code);
        // Use 0 for DirectUnitCost, Unit Cost and Total Cost (LCY). Calculated Value Required for Unit Price.
        VerifyJobLedgerEntry(
          JobTask."Job No.", DocumentNo2, PurchaseLine."Job Line Type", Item."Base Unit of Measure", 0, 0, 0,
          Item."Unit Price");  // Use 0 for DirectUnitCost, Unit Cost and Total Cost (LCY).

        // Tear Down.
        UpdateAutomaticUpdateJobItemCostOnJobsSetup(OldAutomaticUpdateJobItemCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSourceDocumentsOnWhseShipmentWithMultipleItems()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        Quantity: Decimal;
    begin
        // Setup: Create Multiple Items. Create and Release Sales Order with Multiple Items. Create Warehouse Shipment Header with Location.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        CreateSalesOrder(SalesHeader, '', SalesLine.Type::Item, Item."No.", Quantity, LocationWhite.Code);
        CreateSalesLineWithLocationCode(SalesHeader, SalesLine, SalesLine.Type::Item, Item2."No.", Quantity, LocationWhite.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWarehouseShipmentHeaderWithLocation(WarehouseShipmentHeader, LocationWhite.Code);

        // Exercise.
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, LocationWhite.Code);

        // Verify.
        VerifyWarehouseShipmentLine(SalesHeader."No.", Item."No.", Quantity);
        VerifyWarehouseShipmentLine(SalesHeader."No.", Item2."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateItemAnalysisViewAfterPostJobJournal()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        JobTask: Record "Job Task";
        ItemAnalysisViewCode: Code[10];
    begin
        // Setup: Create Item, Customer with Default Dimension. Create Job with Job Task. Create and Post Job Journal Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        ItemAnalysisViewCode := CreateCustomerWithDefaultDimension(Customer);
        CreateJobWithJobTask(JobTask);
        CreateAndPostJobJournalLine(JobTask, Item."No.", Item."Base Unit of Measure", LibraryRandom.RandDec(100, 2), 0, false);  // Use 0 for UnitCost.

        // Exercise.
        UpdateItemAnalysisView(ItemAnalysisViewCode);

        // Verify.
        FilterItemAnalysisViewEntry(ItemAnalysisViewEntry, Item."No.");
        Assert.IsTrue(ItemAnalysisViewEntry.IsEmpty, ItemAnalysisViewEntryMustNotExistMsg);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateItemAnalysisViewAfterPostSalesOrder()
    var
        Customer: Record Customer;
        Item: Record Item;
        JobTask: Record "Job Task";
        SalesLine: Record "Sales Line";
        ItemAnalysisViewCode: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Create Item, Customer with Default Dimension. Create Job with Job Task. Create and Post Job Journal Line. Create and post Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        ItemAnalysisViewCode := CreateCustomerWithDefaultDimension(Customer);
        CreateJobWithJobTask(JobTask);
        CreateAndPostJobJournalLine(JobTask, Item."No.", Item."Base Unit of Measure", Quantity, 0, false);  // Use 0 for UnitCost.
        CreateAndPostSalesOrder(Customer."No.", SalesLine.Type::Item, Item."No.", Quantity);

        // Exercise.
        UpdateItemAnalysisView(ItemAnalysisViewCode);

        // Verify.
        VerifyItemAnalysisViewEntry(Item."No.", -Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionAfterPostServiceOrder()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ServiceHeaderNo: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Undo Service Consumption]
        // [SCENARIO] Post Service Order with Quantity = Q, "Qty. to Ship" = Q/2, undo consumption, ILEs contain positive and negative adjustments of Service Shipment with Quantity = Q/2.

        // Setup: Create Item with Unit Cost. Create and Post Item Journal Line. Create and Post Service Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithUnitCost(Item);
        CreateAndPostItemJournalLine(Item."No.", Quantity);
        ServiceHeaderNo := CreateAndPostServiceOrder(Item."No.", Quantity);

        // Exercise: Undo Consumption.
        UndoServiceConsumption(ServiceHeaderNo);

        // Verify: Verify Item Ledger Entry.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::"Negative Adjmt.", ItemLedgerEntry."Document Type"::"Service Shipment", false, Item."No.",
          -Quantity / 2, 0, -Item."Unit Price" * (Quantity / 2));  // Open as FALSE. Use 0 for Remaining Quantity.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ItemLedgerEntry."Document Type"::"Service Shipment", true, Item."No.",
          Quantity / 2, Quantity / 2, Item."Unit Price" * (Quantity / 2));  // Open as TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceGetUOMFilter()
    var
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        Resource: Record Resource;
        "Filter": Text;
        "Count": Integer;
        JobTaskNo: Code[20];
    begin
        // UT for Resource.GetUnitOfMeasureFilter function

        // Initialize
        // Char '(' will be used as part filter and should be correctly interpreted
        Count := CreateJobPlanningLinesWithDifferentUOMCode(DaysTok, ResourceUnitOfMeasure, JobTaskNo);

        // Excercise
        Filter := Resource.GetUnitOfMeasureFilter(ResourceUnitOfMeasure."Resource No.", ResourceUnitOfMeasure.Code);

        // Verify
        VerifyResourceGetUnitOfMeasureFilter(JobTaskNo, Count, Filter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBaseUnitOfMeasure_ExistingBUoM()
    var
        Res: Record Resource;
        ResUnitOfMeasure: Record "Resource Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // Verify that existing item unit of measure can be used as item's base unit of measure

        // Setup: create item, unit of measure, item unit of measure
        Initialize();

        LibraryResource.CreateResourceNew(Res);

        CreateUoM_and_ResUoM(UnitOfMeasure, ResUnitOfMeasure, Res);

        // Exercise: validate Base Unit of Measure
        Res.Validate("Base Unit of Measure", UnitOfMeasure.Code);

        // Verify: Base Unit of Measure is updated
        VerifyBaseUnitOfMeasure(Res, UnitOfMeasure.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBaseUnitOfMeasure_NonExistingBUoM()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        NewUnitOfMeasureCode: Code[10];
    begin
        // Verify that non existing item unit of measure can be used as item's base unit of measure
        // and this unit of measure is created during the validation

        // Setup: create item, unit of measure, item unit of measure
        Initialize();

        Item.Init();
        Item.Insert(true);

        NewUnitOfMeasureCode := CreateNewUnitOfMeasureCode();
        UnitOfMeasure.Init();
        UnitOfMeasure.Code := NewUnitOfMeasureCode;
        UnitOfMeasure.Insert();

        // Exercise: validate Base Unit of Measure with non-existent item unit of measure
        Item.Validate("Base Unit of Measure", NewUnitOfMeasureCode);

        // Verify: new Item Unit of Measure is created
        ItemUnitOfMeasure.Get(Item."No.", NewUnitOfMeasureCode);
        ItemUnitOfMeasure.TestField("Qty. per Unit of Measure", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectExistingUnitOfMeasureAsBaseUnitOfMeasure()
    var
        Res: Record Resource;
        FirstUnitOfMeasure: Record "Unit of Measure";
        SecondUnitOfMeasure: Record "Unit of Measure";
        ResUnitOfMeasure: Record "Resource Unit of Measure";
    begin
        Initialize();

        Res.Init();
        Res.Insert(true);

        CreateUoM_and_ResUoM(FirstUnitOfMeasure, ResUnitOfMeasure, Res);
        CreateUoM_and_ResUoM(SecondUnitOfMeasure, ResUnitOfMeasure, Res);

        Res.Validate("Base Unit of Measure", FirstUnitOfMeasure.Code);
        Res.Modify(true);
        VerifyBaseUnitOfMeasureSetAndResUnitOfMeasureInserted(Res, FirstUnitOfMeasure, 2);

        // Test setting with existing to other
        Res.Validate("Base Unit of Measure", SecondUnitOfMeasure.Code);
        Res.Modify(true);
        VerifyBaseUnitOfMeasureSetAndResUnitOfMeasureInserted(Res, SecondUnitOfMeasure, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectingBaseUnitOfMeasureInsertsResUnitOfMeasure()
    var
        Res: Record Resource;
        FirstUnitOfMeasure: Record "Unit of Measure";
        SecondUnitOfMeasure: Record "Unit of Measure";
    begin
        Initialize();

        Res.Init();
        Res.Insert(true);

        LibraryInventory.CreateUnitOfMeasureCode(FirstUnitOfMeasure);
        LibraryInventory.CreateUnitOfMeasureCode(SecondUnitOfMeasure);

        Res.Validate("Base Unit of Measure", FirstUnitOfMeasure.Code);
        Res.Modify(true);
        VerifyBaseUnitOfMeasureSetAndResUnitOfMeasureInserted(Res, FirstUnitOfMeasure, 1);

        Res.Validate("Base Unit of Measure", SecondUnitOfMeasure.Code);
        Res.Modify(true);
        VerifyBaseUnitOfMeasureSetAndResUnitOfMeasureInserted(Res, SecondUnitOfMeasure, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveBaseUnitOfMeasureFromRes()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Initialize();

        Item.Init();
        Item.Insert(true);

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        Item.Modify(true);

        Item.Validate("Base Unit of Measure", '');
        Item.Modify(true);

        Assert.AreEqual('', Item."Base Unit of Measure", 'Base unit of measure was not removed from item');
        Assert.IsTrue(ItemUnitOfMeasure.Get(Item."No.", UnitOfMeasure.Code), 'Item unit of measure is should be present');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectingUoMForBaseUoMThatHasQtyGreaterThanOneWillTriggerError()
    var
        Res: Record Resource;
        UnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasureQtyGreaterThanOne: Record "Unit of Measure";
        ResUnitOfMeasure: Record "Resource Unit of Measure";
    begin
        Initialize();

        Res.Init();
        Res.Insert(true);

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        CreateUoM_and_ResUoM(UnitOfMeasureQtyGreaterThanOne, ResUnitOfMeasure, Res);
        ResUnitOfMeasure.Get(Res."No.", UnitOfMeasureQtyGreaterThanOne.Code);
        ResUnitOfMeasure."Qty. per Unit of Measure" := LibraryRandom.RandIntInRange(2, 1000);
        ResUnitOfMeasure.Modify(true);

        Res.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        Res.Modify(true);

        asserterror Res.Validate("Base Unit of Measure", UnitOfMeasureQtyGreaterThanOne.Code);
        Assert.ExpectedError(
          StrSubstNo(BaseUnitOfMeasureQtyMustBeOneErr, UnitOfMeasureQtyGreaterThanOne.Code, ResUnitOfMeasure."Qty. per Unit of Measure"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotRenameBaseUnitOfMeasureFromResUnitOfMeasuresRecord()
    var
        Item: Record Item;
        FirstUnitOfMeasure: Record "Unit of Measure";
        SecondUnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Initialize();

        Item.Init();
        Item.Insert(true);

        LibraryInventory.CreateUnitOfMeasureCode(FirstUnitOfMeasure);
        LibraryInventory.CreateUnitOfMeasureCode(SecondUnitOfMeasure);

        Item.Validate("Base Unit of Measure", FirstUnitOfMeasure.Code);
        Item.Modify(true);

        ItemUnitOfMeasure.Get(Item."No.", FirstUnitOfMeasure.Code);
        asserterror ItemUnitOfMeasure.Rename(Item."No.", SecondUnitOfMeasure.Code);
        Assert.ExpectedError('cannot modify');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotDeleteBaseUnitOfMeasureFromResUnitOfMeasuresRecord()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Initialize();

        Item.Init();
        Item.Insert(true);

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        Item.Modify(true);

        ItemUnitOfMeasure.Get(Item."No.", UnitOfMeasure.Code);
        asserterror ItemUnitOfMeasure.Delete(true);
        Assert.ExpectedError('modify');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameResUnitOfMeasure()
    var
        Res: Record Resource;
        ResUnitOfMeasure: Record "Resource Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        NewUnitOfMeasureCode: Code[10];
    begin
        // Verify that rename of item unit of measure caused update of Item."Base Unit of Measure"
        // because it has ValidateTableRelation=No

        // Setup: create item, unit of measure, item unit of measure
        Initialize();

        Res.Init();
        Res.Insert(true);

        CreateUoM_and_ResUoM(UnitOfMeasure, ResUnitOfMeasure, Res);

        Res.Validate("Base Unit of Measure", ResUnitOfMeasure.Code);
        Res.Modify();

        NewUnitOfMeasureCode := CreateNewUnitOfMeasureCode();
        Commit();

        // Exercise: rename unit of measure assigned to Item (and Item Unit of Measure)
        UnitOfMeasure.Rename(NewUnitOfMeasureCode);

        // Verify: Base Unit of Measure is updated
        Res.Get(Res."No.");
        VerifyBaseUnitOfMeasure(Res, NewUnitOfMeasureCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanInsertTwoResourcesOnSameLocation()
    var
        Resource: array[2] of Record Resource;
        ResourceLocation: Record "Resource Location";
        Location: Record Location;
        I: Integer;
    begin
        // [FEATURE] [Location]
        // [SCENARIO 380436] It should be possible to allocate two resources on the same location, the same date
        Initialize();

        // [GIVEN] Location "L"
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create resource "R1" and resource location for resource "R1" on location "L"
        // [WHEN] Create resource "R2" and resource location for resource "R2" on location "L"
        for I := 1 to ArrayLen(Resource) do begin
            LibraryResource.CreateResourceNew(Resource[I]);
            CreateResourceLocation(ResourceLocation, Resource[I]."No.", Location.Code, WorkDate());
        end;

        // [THEN] Two resource locations are created
        ResourceLocation.SetRange("Location Code", Location.Code);
        Assert.RecordCount(ResourceLocation, ArrayLen(Resource));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanInsertResourceInDifferentLocationsDifferentDates()
    var
        Location: array[2] of Record Location;
        Resource: Record Resource;
        ResourceLocation: Record "Resource Location";
        I: Integer;
    begin
        // [FEATURE] [Location]
        // [SCENARIO 380436] It should be possible to allocate one resource on different locations on different dates
        Initialize();

        // [GIVEN] Resource "R"
        LibraryResource.CreateResourceNew(Resource);

        // [GIVEN] Create location "L1" and resource location for resource "R" on location "L1"
        // [WHEN] Create location "L2" and resource location for resource "R" on location "L2"
        for I := 1 to ArrayLen(Location) do begin
            LibraryWarehouse.CreateLocation(Location[I]);
            CreateResourceLocation(ResourceLocation, Resource."No.", Location[I].Code, WorkDate() + I);
        end;

        // [THEN] Two resource locations are created
        ResourceLocation.SetRange("Resource No.", Resource."No.");
        Assert.RecordCount(ResourceLocation, ArrayLen(Location));
    end;

    [Test]
    [HandlerFunctions('ResourceUnitofMeasurePageHandler')]
    [Scope('OnPrem')]
    procedure OpenResourceUnitOfMeasurePage()
    var
        Resource: Record Resource;
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
    begin
        // [FEATURE] [Resource Unit of Measure]
        // [SCENARIO 161627] "Resource Unit of Measure" Page should take "Base Unit of Measure" from Resource.
        Initialize();

        // [GIVEN] Resource with "Base Unit Of Measure" = "X".
        LibraryResource.CreateResource(Resource, '');

        // [WHEN] Open "Resource Unit of Measure" Page.
        // [THEN] Page is opened with "Unit Of Measure" = "X".
        // Assert is done in ResourceUnitofMeasurePageHandler.
        LibraryVariableStorage.Enqueue(Resource."Base Unit of Measure");
        ResourceUnitOfMeasure.SetRange("Resource No.", Resource."No.");
        PAGE.RunModal(0, ResourceUnitOfMeasure);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceResLedgerEntryAfterPostSalesInvoiceSalesLineQuantityPositive()
    var
        SalesHeader: Record "Sales Header";
        DocNo: Code[20];
        ResNo: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 210924] Value of "Unit Price" of Resource Ledger Entry must be positive when Quantity of Sales Line of Sales Credit Memo is positive
        Initialize();

        // [GIVEN] Sales Credit Memo with Resource Sales Ivoice line with Quanity > 0
        CreateSalesHeaderWithTwoSalesLine(
          SalesHeader, ResNo, UnitPrice, LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandIntInRange(5, 10));

        // [WHEN] Post Sales Credit Memo
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] "Res. Ledger Entry"."Unit Price" > 0
        VerifyUnitPriceResLedgerEntry(DocNo, ResNo, UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceResLedgerEntryAfterPostSalesInvoiceSalesLineQuantityNegative()
    var
        SalesHeader: Record "Sales Header";
        DocNo: Code[20];
        ResNo: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 210924] Value of "Unit Price" of Resource Ledger Entry must be positive when Quantity of Sales Line of Sales Credit Memo is Negative
        Initialize();

        // [GIVEN] Sales Credit Memo with Resource Sales Ivoice line with Quanity > 0 and Resource Sales Invoice line with Quantity < 0
        CreateSalesHeaderWithTwoSalesLine(
          SalesHeader, ResNo, UnitPrice, LibraryRandom.RandIntInRange(50, 100), -LibraryRandom.RandIntInRange(5, 10));

        // [WHEN] Post Sales Credit Memo
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] "Res. Ledger Entry"."Unit Price" > 0
        VerifyUnitPriceResLedgerEntry(DocNo, ResNo, UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceResLedgerEntryAfterPostSalesInvoiceSalesLineUnitPriceNegative()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocNo: Code[20];
        ResNo: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 217415] Value of "Unit Price" of Resource Ledger Entry must be negative when Unit Price of Sales Line of Sales Invoice is negative
        Initialize();

        // [GIVEN] Sales Invoice with two Resource Sales Invoice line
        ResNo := LibraryResource.CreateResourceNo();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        // [GIVEN] First sales line has positive "Unit Price" = 100
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, ResNo, LibraryRandom.RandIntInRange(5, 10));
        UnitPrice[1] := SalesLine."Unit Price";

        // [GIVEN] Second sales line has negative "Unit Price" = -100
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, ResNo, SalesLine.Quantity);
        SalesLine.Validate("Unit Price", -SalesLine."Unit Price");
        SalesLine.Modify(true);
        UnitPrice[2] := SalesLine."Unit Price";

        // [WHEN] Post Sales Invoice
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] "Res. Ledger Entry" for second sales line has "Unit Price" = -100
        VerifyUnitPriceResLedgerEntry(DocNo, ResNo, UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnRenamingResourceBaseUnitOfMeasureAfterPurchase()
    var
        Resource: Record Resource;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Purchase] [Resource]
        // [SCENARIO 289386] Resource base unit of measure cannot be renamed if it was purchased
        Initialize();

        // [GIVEN] Posted purchase order with resource line
        LibraryResource.CreateResourceNew(Resource);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, Resource."No.", LibraryRandom.RandInt(10));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] New unit of measure
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        ResourceUnitOfMeasure.Get(Resource."No.", Resource."Base Unit of Measure");

        // [WHEN] Rename resource unit of measure
        asserterror ResourceUnitOfMeasure.Rename(Resource."No.", UnitOfMeasure.Code);

        // [THEN] Error message that resource unit of measure cannot be renamed because it is bease unit of measure is shown
        Assert.ExpectedError(
          StrSubstNo(
            CannotModifyBaseUnitOfMeasureErr, ResourceUnitOfMeasure.TableCaption(), Resource."Base Unit of Measure", Resource."No.",
            Resource.FieldCaption("Base Unit of Measure")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteResourceExistedInPurchaseOrder()
    var
        Resource: Record Resource;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Resource cannot be deleted if it exists in the purchase document
        Initialize();

        // [GIVEN] Resource
        LibraryResource.CreateResourceNew(Resource);

        // [GIVEN] Purchase order with resource
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, Resource."No.", LibraryRandom.RandInt(10));

        // [WHEN] Delete resource
        asserterror Resource.Delete(true);

        // [THEN] Error message that resource cannot be deleted is shown
        Assert.ExpectedError(StrSubstNo(DocumentExistsErr, Resource."No.", PurchaseLine."Document Type"::Order));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ResLedgEntryHaveSourceInformationAfterPostingUsageEntryFromJobJournalLine()
    var
        JobTask: Record "Job Task";
        Resource: Record Resource;
        JobJournalLine: Record "Job Journal Line";
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        // [SCENARIO 377641] Resource Ledger Entry has "Source Type" and "Source No." after posting Job Journal Line with "Entry Type" equals "Usage"

        Initialize();

        // [GIVEN] Job with job task "X"
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Resource "Y"
        LibraryResource.CreateResourceNew(Resource);

        // [GIVEN] Job Journal Line with type "Both Budget and Billable", "Job Task" = "X", Type = "Resource", "No." = "Y"
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::"Both Budget and Billable", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
        JobJournalLine.Validate("No.", Resource."No.");
        JobJournalLine.Validate(Quantity, LibraryRandom.RandInt(10));
        JobJournalLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        JobJournalLine.Validate("Unit Cost (LCY)", LibraryRandom.RandDec(100, 2));
        JobJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(WantToPostJournalLinesQst);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(JournalLinesPostedMsg);

        // [WHEN] Post Job Journal Line
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Single resource ledger entry with "Entry Type" = Usage is created
        ResLedgerEntry.SetRange("Resource No.", Resource."No.");
        Assert.RecordCount(ResLedgerEntry, 1);

        // [THEN] Resource Ledger Entry has "Source Type" and "Source No." fields specified
        ResLedgerEntry.FindFirst();
        ResLedgerEntry.TestField("Entry Type", ResLedgerEntry."Entry Type"::Usage);
        ResLedgerEntry.TestField("Source Type");
        ResLedgerEntry.TestField("Source No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyManualSalesPriceNotResetWhenQuantityChanged()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DefaultUnitPrice: Decimal;
        ManualUnitPrice: Decimal;
    begin
        // [SCENARIO 491841] Resources in Sales Document: Manual Sales Price Resets When Quantity Changes
        Initialize();

        // [GIVEN] Create Sales Order
        LibrarySales.CreateSalesHeader(
            SalesHeader,
            SalesHeader."Document Type"::Order,
            LibrarySales.CreateCustomerNo());

        // [GIVEN] Create sales line with Resource has positive "Unit Price" = 100
        LibrarySales.CreateSalesLine(
            SalesLine,
            SalesHeader,
            SalesLine.Type::Resource,
            LibraryResource.CreateResourceNo(),
            LibraryRandom.RandIntInRange(5, 10));
        DefaultUnitPrice := SalesLine."Unit Price";

        // [WHEN] Update Sales Line Unit Price manually, and Quantity on Sales Line
        ManualUnitPrice := LibraryRandom.RandDec(100, 2);
        SalesLine.Validate("Unit Price", ManualUnitPrice);
        SalesLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);

        // [VERIFY] Verify: Unit Price not changed on Sales Line when updating Quantity
        Assert.AreNotEqual(DefaultUnitPrice, SalesLine."Unit Price", UnitPriceErr);
        Assert.AreEqual(ManualUnitPrice, SalesLine."Unit Price", UnitPriceErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::Resource);
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::Resource);

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        NoSeriesSetup();
        CreateItemJournalTemplateAndBatch();
        LocationSetup();

        DummyJobsSetup."Allow Sched/Contract Lines Def" := false;
        DummyJobsSetup."Apply Usage Link by Default" := false;
        DummyJobsSetup.Modify();
        LibraryJob.SetJobNoSeriesCode();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::Resource);
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure LocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);  // Location: White.
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        JobsSetup: Record "Jobs Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        JobsSetup.Get();
        JobsSetup.Validate("Job Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        JobsSetup.Modify(true);
    end;

    local procedure AdjustCostItemEntriesWithJobAndCostingMethod(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure"; var JobTask: Record "Job Task"; CostingMethod: Enum "Costing Method"; Quantity: Decimal)
    begin
        // Create Item with Costing Method and Item Unit of Measure. Create Job and Job Task. Create and post Job Journal and Purchase Order. Run Adjust Cost Item entries batch job.
        CreateItemWithCostingMethodAndUOM(Item, ItemUnitOfMeasure, CostingMethod);
        CreateJobWithJobTask(JobTask);
        CreateAndPostJobJournalLine(JobTask, Item."No.", Item."Base Unit of Measure", Quantity, Item."Unit Cost", false);
        CreateAndPostPurchaseOrder(
          Item."No.", Quantity * 2, Item."Unit Cost" + LibraryRandom.RandDec(10, 2),
          Item."Base Unit of Measure", false);  // Calculated values required for Quantity and Direct Unit Cost.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
    end;

    local procedure AdjustCostItemEntriesWithJobAndSpecificCosting(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure"; var JobTask: Record "Job Task"; Quantity: Decimal)
    begin
        // Create Item with Serial Tracking, Specific Costing Method and Item Unit of Measure. Create Job and Job Task. Create and post Job Journal and Purchase Order. Run Adjust Cost Item entries batch job.
        CreateItemWithCostingMethodAndUOM(Item, ItemUnitOfMeasure, Item."Costing Method"::Specific);
        CreateJobWithJobTask(JobTask);
        CreateAndPostItemJournalLineWithSerialTracking(JobTask, Item."No.", Quantity);
        CreateAndPostJobJournalLine(
          JobTask, Item."No.", Item."Base Unit of Measure", Quantity, Item."Unit Cost", true);  // TRUE for Tracking.
        CreateAndPostPurchaseOrder(
          Item."No.", Quantity, Item."Unit Cost" + LibraryRandom.RandDec(10, 2),
          Item."Base Unit of Measure", true);  // Greater value required for Direct Unit Cost. TRUE for Tracking.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
    end;

    local procedure AdjustCostItemEntriesWithJobAndStandardCosting(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure"; var JobTask: Record "Job Task"; Quantity: Decimal)
    begin
        // Create Item with Standard Costing Method and Item Unit of Measure. Create Job and Job Task. Create and post Job Journal and Purchase Order. Run Adjust Cost Item entries batch job.
        CreateItemWithCostingMethodAndUOM(Item, ItemUnitOfMeasure, Item."Costing Method"::Standard);
        CreateJobWithJobTask(JobTask);
        CreateAndPostJobJournalLine(JobTask, Item."No.", Item."Base Unit of Measure", Quantity, 0, false);  // Value 0 required for Unit Cost.
        CreateAndPostPurchaseOrder(Item."No.", Quantity, 0, Item."Base Unit of Measure", false);  // Value 0 required for Direct Unit Cost.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
    end;

    local procedure CreateCustomerWithDefaultDimension(var Customer: Record Customer): Code[10]
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisLine: Record "Analysis Line";
        DefaultDimension: Record "Default Dimension";
        ItemAnalysisView: Record "Item Analysis View";
    begin
        LibrarySales.CreateCustomer(Customer);
        ItemAnalysisView.SetRange("Include Budgets", true);
        ItemAnalysisView.FindFirst();
        AnalysisLineTemplate.SetRange("Item Analysis View Code", ItemAnalysisView.Code);
        AnalysisLineTemplate.FindFirst();
        AnalysisLine.SetRange("Analysis Line Template Name", AnalysisLineTemplate.Name);
        AnalysisLine.FindFirst();
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", ItemAnalysisView."Dimension 1 Code", AnalysisLine.Range);
        exit(ItemAnalysisView.Code);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLineWithSerialTracking(JobTask: Record "Job Task"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingMode: Option SelectEntries,AssignSerialNo;
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo, Quantity);
        ItemJournalLine.Validate("Job No.", JobTask."Job No.");
        ItemJournalLine.Validate("Job Task No.", JobTask."Job Task No.");
        ItemJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);  // Enqueue for ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);  // Enqueue for EnterQtyToCreatePageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostJobJournalLine(JobTask: Record "Job Task"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; Quantity: Decimal; UnitCost: Decimal; Tracking: Boolean)
    var
        JobJournalLine: Record "Job Journal Line";
        ItemTrackingMode: Option SelectEntries,AssignSerialNo;
    begin
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::"Both Budget and Billable", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", ItemNo);
        JobJournalLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        JobJournalLine.Validate(Quantity, Quantity);
        if UnitCost <> 0 then
            JobJournalLine.Validate("Unit Cost (LCY)", UnitCost);
        JobJournalLine.Modify(true);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingPageHandler.
            JobJournalLine.OpenItemTrackingLines(false);
        end;
        LibraryVariableStorage.Enqueue(WantToPostJournalLinesQst);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(true);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(JournalLinesPostedMsg);  // Enqueue for MessageHandler.
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateAndPostPurchaseOrder(ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal; UnitOfMeasureCode: Code[10]; Tracking: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemTrackingMode: Option SelectEntries,AssignSerialNo;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Modify(true);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);  // Enqueue for ItemTrackingPageHandler.
            LibraryVariableStorage.Enqueue(Quantity);  // Enqueue for EnterQtyToCreatePageHandler.
            PurchaseLine.OpenItemTrackingLines();
        end;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
    end;

    local procedure CreateAndPostPurchaseInvoiceWithGetReceiptLines(VendorNo: Code[20]; OrderNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        GetReceiptLines(PurchaseHeader, OrderNo);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Post as Receive and Invoice.
    end;

    local procedure CreateAndPostPurchaseOrderWithJob(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; JobTask: Record "Job Task"; ItemNo: Code[20]; Quantity: Decimal; QuantityToReceive: Decimal; DirectUnitCost: Decimal; JobLineType: Enum "Job Line Type"; PostAsInvoice: Boolean): Code[20]
    begin
        CreatePurchaseOrderWithJob(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, ItemNo, Quantity, QuantityToReceive, JobTask."Job No.",
          JobTask."Job Task No.", DirectUnitCost, JobLineType);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, PostAsInvoice));  // Receive as True.
    end;

    local procedure CreateAndPostPurchaseOrderWithMultipleLines(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var PurchaseLine2: Record "Purchase Line"; JobTask: Record "Job Task"; ItemNo: Code[20])
    var
        Vendor: Record Vendor;
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLineWithJob(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity, Quantity, JobTask."Job No.", JobTask."Job Task No.",
          PurchaseLine."Job Line Type"::Budget, LibraryRandom.RandInt(10));
        CreatePurchaseLineWithJob(
          PurchaseLine2, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, PurchaseLine.Quantity + Quantity,
          PurchaseLine.Quantity + Quantity, JobTask."Job No.", JobTask."Job Task No.",
          PurchaseLine2."Job Line Type"::"Both Budget and Billable",
          PurchaseLine."Direct Unit Cost" + LibraryRandom.RandInt(10));  // Greater values required for Quantity and Direct Unit Cost.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive.
    end;

    local procedure CreateAndPostPurchaseOrderWithDifferentUnitPrice(ItemNo: Code[20]; Quantity: Decimal; JobNo: Code[20]; JobTaskNo: Code[20]; UnitPrice: Decimal) DocumentNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrderWithJob(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, ItemNo, Quantity, Quantity, JobNo, JobTaskNo, 0,
          PurchaseLine."Job Line Type"::Budget);  // Use 0 for DirectUnitCost.
        PurchaseLine.Validate("Unit Price (LCY)", UnitPrice);
        PurchaseLine.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
    end;

    local procedure CreateAndPostSalesOrder(CustomerNo: Code[20]; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesHeader, CustomerNo, Type, No, Quantity, '');
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as SHIP and INVOICE.
    end;

    local procedure CreateAndPostServiceOrder(ItemNo: Code[20]; Quantity: Decimal): Code[20]
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLine(ServiceHeader, ItemNo, ServiceItemLine."Line No.", Quantity);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);  // Ship and Consume as TRUE.
        exit(ServiceHeader."No.");
    end;

    local procedure CreateAndReceivePurchaseOrderWithJob(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        Quantity: Decimal;
    begin
        LibraryInventory.CreateItem(Item);
        CreateJobWithJobTask(JobTask);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostPurchaseOrderWithJob(
          PurchaseHeader, PurchaseLine, JobTask, Item."No.", Quantity, Quantity / 2, LibraryRandom.RandDec(10, 2),
          PurchaseLine."Job Line Type"::"Both Budget and Billable", false);
    end;

    local procedure CreateItemJournalTemplateAndBatch()
    begin
        ItemJournalTemplate.SetRange(Recurring, false);
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", '');
        ItemJournalTemplate.Modify(true);

        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", '');
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, LibraryRandom.RandInt(5) + 1);
    end;

    local procedure CreateItemWithCostingMethod(var Item: Record Item; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        UpdateCostingMethodOnItem(Item, CostingMethod);
    end;

    local procedure CreateItemWithCostingMethodAndUOM(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure"; CostingMethod: Enum "Costing Method")
    begin
        CreateItemWithCostingMethod(Item, CostingMethod);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        if CostingMethod = Item."Costing Method"::Standard then
            Item.Validate("Standard Cost", LibraryRandom.RandDec(10, 2))
        else
            Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
    end;

    local procedure CreateItemWithMultipleUnitOfMeasure(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
    end;

    local procedure CreateItemWithSerialItemTracking(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);
    end;

    local procedure CreateItemWithUnitCost(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobPlanningLines(JobTask: Record "Job Task"; ResourceNo: Code[20]; UOMCode: Code[10]) "Count": Integer
    var
        JobPlanningLine: Record "Job Planning Line";
        Index: Integer;
    begin
        Count := LibraryRandom.RandIntInRange(5, 10);
        for Index := 1 to Count do
            CreateJobPlanningLine(JobTask, ResourceNo, UOMCode, JobPlanningLine);

        exit(Count);
    end;

    local procedure CreateJobPlanningLine(JobTask: Record "Job Task"; ResourceNo: Code[20]; UOMCode: Code[10]; var JobPlanningLine: Record "Job Planning Line")
    begin
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        JobPlanningLine."Unit of Measure Code" := UOMCode;
        JobPlanningLine.Validate("No.", ResourceNo);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobPlanningLinesWithDifferentUOMCode(UOMCode: Code[10]; var ResourceUnitOfMeasure: Record "Resource Unit of Measure"; var JobTaskNo: Code[20]) "Count": Integer
    var
        JobTask: Record "Job Task";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        CreateJobWithJobTask(JobTask);

        CreateResourceUnitOfMeasure(
          ResourceUnitOfMeasure,
          LibraryUtility.GenerateRandomCode(UnitOfMeasure.FieldNo(Code), DATABASE::"Unit of Measure"),
          true);
        CreateJobPlanningLines(JobTask, ResourceUnitOfMeasure."Resource No.", ResourceUnitOfMeasure.Code);

        CreateResourceUnitOfMeasure(ResourceUnitOfMeasure, UOMCode, true);
        Count := CreateJobPlanningLines(JobTask, ResourceUnitOfMeasure."Resource No.", ResourceUnitOfMeasure.Code);
        JobTaskNo := JobTask."Job Task No.";
        exit(Count);
    end;

    local procedure CreatePurchaseOrderWithJob(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; ItemNo: Code[20]; Quantity: Decimal; QuantityToReceive: Decimal; JobNo: Code[20]; JobTaskNo: Code[20]; DirectUnitCost: Decimal; JobLineType: Enum "Job Line Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithJob(
          PurchaseLine, PurchaseHeader, Type, ItemNo, Quantity, QuantityToReceive, JobNo, JobTaskNo, JobLineType, DirectUnitCost);
    end;

    local procedure CreatePurchaseLineWithJob(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; ItemNo: Code[20]; Quantity: Decimal; QuantityToReceive: Decimal; JobNo: Code[20]; JobTaskNo: Code[20]; JobLineType: Enum "Job Line Type"; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, ItemNo, Quantity);
        PurchaseLine.Validate("Qty. to Receive", QuantityToReceive);
        PurchaseLine.Validate("Job No.", JobNo);
        PurchaseLine.Validate("Job Task No.", JobTaskNo);
        PurchaseLine.Validate("Job Line Type", JobLineType);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrderWithDifferentUOM(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; QuantityToReceive: Decimal; JobNo: Code[20]; JobTaskNo: Code[20]; ItemUnitOfMeasureCode: Code[10]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
    begin
        CreatePurchaseOrderWithJob(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, ItemNo, Quantity, QuantityToReceive, JobNo, JobTaskNo, 0,
          PurchaseLine."Job Line Type"::Budget);// Use 0 for DirectUnitCost.
        CreatePurchaseLineWithJob(
          PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, ItemNo, Quantity, QuantityToReceive, JobNo, JobTaskNo,
          PurchaseLine2."Job Line Type"::Budget, 0);  // Use 0 for DirectUnitCost.
        PurchaseLine2.Validate("Unit of Measure Code", ItemUnitOfMeasureCode);
        PurchaseLine2.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Receive and Invoice as TRUE.
    end;

    local procedure CreateResourceLocation(var ResourceLocation: Record "Resource Location"; ResourceNo: Code[20]; LocationCode: Code[10]; StartingDate: Date)
    begin
        ResourceLocation.Validate("Location Code", LocationCode);
        ResourceLocation.Validate("Starting Date", StartingDate);
        ResourceLocation.Validate("Resource No.", ResourceNo);
        ResourceLocation.Insert(true);
    end;

    local procedure CreateResourceUnitOfMeasure(var ResourceUnitOfMeasure: Record "Resource Unit of Measure"; UOMCode: Code[10]; RelatedToBaseUnitOfMeas: Boolean)
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        Resource: Record Resource;
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Init();
        UnitOfMeasure.Code := UOMCode;
        UnitOfMeasure.Insert(true);

        Resource.Init();
        Resource.Validate("No.", LibraryUtility.GenerateRandomCode(Resource.FieldNo("No."), DATABASE::Resource));
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        Resource.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        Resource.Insert(true);

        ResourceUnitOfMeasure.Init();
        ResourceUnitOfMeasure.Validate("Resource No.", Resource."No.");
        ResourceUnitOfMeasure.Validate(Code, UOMCode);
        ResourceUnitOfMeasure.Validate("Related to Base Unit of Meas.", RelatedToBaseUnitOfMeas);
        ResourceUnitOfMeasure.Insert(true);

        Resource.Validate("Base Unit of Measure", UOMCode);
        Resource.Modify(true);
    end;

    local procedure CreateSalesLineWithLocationCode(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesHeaderWithTwoSalesLine(var SalesHeader: Record "Sales Header"; var ResNo: Code[20]; var UnitPrice: array[2] of Decimal; FirstLineQnt: Decimal; SecondLineQnt: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        ResNo := LibraryResource.CreateResourceNo();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        UnitPrice[1] := CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, ResNo, FirstLineQnt);
        UnitPrice[2] := CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, ResNo, SecondLineQnt);
    end;

    local procedure CreateSalesLine(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; SalesLineType: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal): Decimal
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType, No, Quantity);
        exit(SalesLine."Unit Price");
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLineWithLocationCode(SalesHeader, SalesLine, Type, No, Quantity, LocationCode);
    end;

    local procedure CreateServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header"; var ServiceItem: Record "Service Item")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryVariableStorage.Enqueue(WantToCreateContractQst);  // Enqueue for Confirm Handler.
        LibraryVariableStorage.Enqueue(true);  // Enqueue for Confirm Handler.
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
    end;

    local procedure CreateServiceLine(var ServiceHeader: Record "Service Header"; ItemNo: Code[20]; ServiceItemLineNo: Integer; Quantity: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Qty. to Ship", Quantity / 2);  // Enter Partial Quantity to Ship.
        ServiceLine.Validate("Qty. to Consume", ServiceLine."Qty. to Ship");
        ServiceLine.Modify(true);
    end;

    local procedure CreateTask(var Task: Record "To-do"; Contact: Record Contact)
    begin
        LibraryMarketing.CreateTask(Task);
        Task.Validate(Date, WorkDate());
        Task.Validate("Contact No.", Contact."No.");
        Task.Validate("Salesperson Code", Contact."Salesperson Code");
        Task.Modify(true);
    end;

    local procedure CreateWarehouseShipmentHeaderWithLocation(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", LocationCode);
        WarehouseShipmentHeader.Modify(true);
    end;

    local procedure CreateUoM_and_ResUoM(var UnitOfMeasure: Record "Unit of Measure"; var ResUnitOfMeasure: Record "Resource Unit of Measure"; Res: Record Resource)
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryResource.CreateResourceUnitOfMeasure(ResUnitOfMeasure, Res."No.", UnitOfMeasure.Code, 1);
    end;

    local procedure CreateNewUnitOfMeasureCode(): Code[10]
    var
        RefUnitOfMeasure: Record "Unit of Measure";
    begin
        exit(LibraryUtility.GenerateRandomCode(RefUnitOfMeasure.FieldNo(Code), DATABASE::"Unit of Measure"));
    end;

    local procedure CopyDocumentUsingPurchaseOrderWithJob(JobTask: Record "Job Task"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        DocumentNo :=
          CreateAndPostPurchaseOrderWithJob(
            PurchaseHeader, PurchaseLine, JobTask, ItemNo, Quantity, Quantity, Quantity,
            PurchaseLine."Job Line Type"::Budget, true);  // Invoice as True.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.");
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, "Purchase Document Type From"::"Posted Invoice", DocumentNo, false, true);  // TRUE for RecalculateLines.
    end;

    local procedure GetReceiptLines(PurchaseHeader: Record "Purchase Header"; OrderNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.FindFirst();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure FilterItemAnalysisViewEntry(var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; ItemNo: Code[20])
    begin
        ItemAnalysisViewEntry.SetRange("Item Ledger Entry Type", ItemAnalysisViewEntry."Item Ledger Entry Type"::Sale);
        ItemAnalysisViewEntry.SetRange("Entry Type", ItemAnalysisViewEntry."Entry Type"::"Direct Cost");
        ItemAnalysisViewEntry.SetRange("Item No.", ItemNo);
    end;

    local procedure FilterJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; PurchaseLine: Record "Purchase Line"; LineType: Enum "Job Planning Line Line Type")
    begin
        JobPlanningLine.SetRange("Job No.", PurchaseLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", PurchaseLine."Job Task No.");
        JobPlanningLine.SetRange("No.", PurchaseLine."No.");
        JobPlanningLine.SetRange("Line Type", LineType);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobNo: Code[20]; DocumentNo: Code[20])
    begin
        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.FindSet();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
    end;

    local procedure OpenSelectContractLinesFromServiceContractPage(ContractNo: Code[20])
    var
        ServiceContract: TestPage "Service Contract";
    begin
        ServiceContract.OpenEdit();
        ServiceContract.FILTER.SetFilter("Contract No.", ContractNo);
        ServiceContract.SelectContractLines.Invoke();
    end;

    local procedure OpenTaskCardFromContactCardAndUpdateTeamCode(var TaskList: TestPage "Task List"; ContactNo: Code[20]; TeamCode: Code[10])
    var
        ContactCard: TestPage "Contact Card";
        TaskCard: TestPage "Task Card";
    begin
        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", ContactNo);
        TaskList.Trap();
        ContactCard."T&asks".Invoke();
        TaskCard.Trap();
        TaskList."Edit Organizer Task".Invoke();
        TaskCard."Team Code".SetValue(TeamCode);
        TaskCard.OK().Invoke();
    end;

    local procedure PostPurchaseOrder(PurchaseHeader: Record "Purchase Header"; IsShipAndInvoice: Boolean)
    begin
        PurchaseHeader.Find();
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, IsShipAndInvoice, true);  // Post as Invoice.
    end;

    local procedure UndoServiceConsumption(OrderNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        LibraryVariableStorage.Enqueue(WantToUndoConsumptionQst);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(true);  // Enqueue for ConfirmHandler.
        ServiceShipmentLine.SetRange("Order No.", OrderNo);
        CODEUNIT.Run(CODEUNIT::"Undo Service Consumption Line", ServiceShipmentLine);
    end;

    local procedure UpdateAutomaticUpdateJobItemCostOnJobsSetup(NewAutomaticUpdateJobItemCost: Boolean) OldAutomaticUpdateJobItemCost: Boolean
    var
        JobsSetup: Record "Jobs Setup";
    begin
        JobsSetup.Get();
        OldAutomaticUpdateJobItemCost := JobsSetup."Automatic Update Job Item Cost";
        JobsSetup.Validate("Automatic Update Job Item Cost", NewAutomaticUpdateJobItemCost);
        JobsSetup.Modify(true);
    end;

    local procedure UpdateCostingMethodOnItem(var Item: Record Item; CostingMethod: Enum "Costing Method")
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if CostingMethod = Item."Costing Method"::Specific then begin
            LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
            Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
            Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        end;
        Item.Validate("Costing Method", CostingMethod);
        Item.Modify(true);
    end;

    local procedure UpdateItemAnalysisView(ItemAnalysisViewCode: Code[10])
    var
        ItemAnalysisViewList: TestPage "Item Analysis View List";
    begin
        ItemAnalysisViewList.OpenEdit();
        ItemAnalysisViewList.FILTER.SetFilter(Code, ItemAnalysisViewCode);
        ItemAnalysisViewList."&Update".Invoke();
    end;

    local procedure UpdateJobItemCostAfterAdjustCostItemEntries(ItemNo: Code[20]; JobNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(NoJobLedgerEntriesUpdatedMsg);  // Enqueue for MessageHandler.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        LibraryJob.RunUpdateJobItemCost(JobNo);
    end;

    local procedure UpdateJobTaskTypeOnJobTask(var JobTask: Record "Job Task"; JobTaskType: Enum "Job Task Type")
    begin
        JobTask.Validate("Job Task Type", JobTaskType);
        JobTask.Modify(true);
    end;

    local procedure UpdateQuantityAndPostPurchaseReturnOrder(ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        FindPurchaseLine(PurchaseLine, ItemNo);
        UpdateQuantityOnPurchaseLine(PurchaseLine, Quantity);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Receive and Invoice as TRUE.
    end;

    local procedure UpdateQuantityOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; Quantity: Decimal)
    begin
        PurchaseLine.Validate(Quantity, Quantity);
        PurchaseLine.Validate("Return Qty. to Ship", Quantity);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateUnitPriceAndCostingMethodOnItem(var Item: Record Item; CostingMethod: Enum "Costing Method")
    begin
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        UpdateCostingMethodOnItem(Item, CostingMethod);
    end;

    local procedure UpdateUnitPriceAndAssignTrackingOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; UnitPrice: Decimal)
    var
        ItemTrackingMode: Option SelectEntries,AssignSerialNo;
    begin
        PurchaseLine.Validate("Unit Price (LCY)", UnitPrice);
        PurchaseLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);  // Enqueue for ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(PurchaseLine."Qty. to Receive");  // Enqueue for EnterQtyToCreatePageHandler.
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure UpdateUnitPriceAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; UnitPrice: Decimal): Code[20]
    var
        ItemTrackingMode: Option SelectEntries,AssignSerialNo;
    begin
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        PurchaseLine.Find();
        PurchaseLine.Validate("Unit Price (LCY)", UnitPrice);
        PurchaseLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);  // Enqueue for ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(PurchaseLine."Qty. to Receive");  // Enqueue for EnterQtyToCreatePageHandler.
        PurchaseLine.OpenItemTrackingLines();
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Receive and Invoice as TRUE.
    end;

    local procedure VerifyAdjustedJobLedgerEntryExist(JobNo: Code[20]; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; EntryExist: Boolean)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.SetRange("No.", ItemNo);
        JobLedgerEntry.SetRange("Unit of Measure Code", UnitOfMeasureCode);
        JobLedgerEntry.SetRange(Adjusted, true);
        Assert.AreEqual(JobLedgerEntry.FindFirst(), EntryExist, AdjustedJobLedgerEntryExistMsg);
    end;

    local procedure VerifyEmptyJobPlanningLines(PurchaseLine: Record "Purchase Line"; LineType: Enum "Job Planning Line Line Type")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        FilterJobPlanningLine(JobPlanningLine, PurchaseLine, LineType);
        Assert.IsTrue(JobPlanningLine.IsEmpty, JobPlanningLineMustBeEmptyMsg);
    end;

    local procedure VerifyItemAnalysisViewEntry(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
    begin
        FilterItemAnalysisViewEntry(ItemAnalysisViewEntry, ItemNo);
        ItemAnalysisViewEntry.FindFirst();
        ItemAnalysisViewEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPurchaseReturnOrder(JobTask: Record "Job Task"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, ItemNo);
        PurchaseLine.TestField("Job No.", JobTask."Job No.");
        PurchaseLine.TestField("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Enum "Item Ledger Entry Type"; DocumentType: Enum "Item Ledger Document Type"; Open: Boolean; ItemNo: Code[20]; Quantity: Decimal; RemainingQuantity: Decimal; CostAmountActual: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document Type", DocumentType);
        ItemLedgerEntry.SetRange(Open, Open);
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Remaining Quantity", RemainingQuantity);
        ItemLedgerEntry.TestField("Invoiced Quantity", Quantity);
        ItemLedgerEntry.TestField("Cost Amount (Actual)", CostAmountActual);
    end;

    local procedure VerifyJobLedgerEntry(JobNo: Code[20]; DocumentNo: Code[20]; LineType: Enum "Job Line Type"; UnitOfMeasureCode: Code[10]; DirectUnitCost: Decimal; UnitCost: Decimal; Quantity: Decimal; UnitPrice: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Line Type", LineType);
        JobLedgerEntry.SetRange("Unit of Measure Code", UnitOfMeasureCode);
        FindJobLedgerEntry(JobLedgerEntry, JobNo, DocumentNo);
        JobLedgerEntry.TestField("Direct Unit Cost (LCY)", DirectUnitCost);
        JobLedgerEntry.TestField("Unit Cost (LCY)", UnitCost);
        JobLedgerEntry.TestField("Total Cost (LCY)", UnitCost * Quantity);  // Calculated value required for Total Cost.
        JobLedgerEntry.TestField("Unit Price", UnitPrice);
    end;

    local procedure VerifyJobLedgerEntryDoesNotExist(JobNo: Code[20]; DocumentNo: Code[20]; LineType: Enum "Job Line Type"; UnitOfMeasureCode: Code[10])
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Line Type", LineType);
        JobLedgerEntry.SetRange("Unit of Measure Code", UnitOfMeasureCode);
        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        Assert.IsTrue(JobLedgerEntry.IsEmpty, JobLedgEntryExistsErr);
    end;

    local procedure VerifyJobLedgerEntryForSerial(Item: Record Item; JobTask: Record "Job Task"; DocumentNo: Code[20]; TotalQuantity: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        Quantity: Decimal;
    begin
        JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        JobLedgerEntry.SetRange(Type, JobLedgerEntry.Type::Item);
        JobLedgerEntry.SetRange("No.", Item."No.");
        JobLedgerEntry.SetRange("Job Task No.", JobTask."Job Task No.");
        FindJobLedgerEntry(JobLedgerEntry, JobTask."Job No.", DocumentNo);
        repeat
            JobLedgerEntry.TestField("Serial No.");
            JobLedgerEntry.TestField("Unit Price", Item."Unit Price");
            JobLedgerEntry.TestField(Quantity, 1);  // Value Required for Serial.
            Quantity += JobLedgerEntry.Quantity;
        until JobLedgerEntry.Next() = 0;
        Assert.AreEqual(TotalQuantity, Quantity, QuantityMustBeSameMsg);
    end;

    local procedure VerifyJobPlanningLine(PurchaseLine: Record "Purchase Line"; LineType: Enum "Job Planning Line Line Type"; MoveNext: Boolean; Quantity: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        FilterJobPlanningLine(JobPlanningLine, PurchaseLine, LineType);
        JobPlanningLine.FindSet();
        if MoveNext then
            JobPlanningLine.Next();
        JobPlanningLine.TestField(Quantity, Quantity);
        JobPlanningLine.TestField("Unit Cost (LCY)", PurchaseLine."Unit Cost (LCY)");
    end;

    local procedure VerifyServiceContractLine(ServiceContractHeader: Record "Service Contract Header"; ServiceItemNo: Code[20])
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        ServiceContractLine.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.FindFirst();
        ServiceContractLine.TestField("Service Item No.", ServiceItemNo);
    end;

    local procedure VerifyTask(Contact: Record Contact; No: Code[20])
    var
        Task: Record "To-do";
    begin
        Task.Get(No);
        Task.TestField("Contact No.", Contact."No.");
        Task.TestField("Salesperson Code", Contact."Salesperson Code");
    end;

    local procedure VerifyWarehouseShipmentLine(SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyResourceGetUnitOfMeasureFilter(JobTaskNo: Code[20]; UOMCodeLineCount: Integer; "Filter": Text)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job Task No.", JobTaskNo);
        Assert.IsTrue(UOMCodeLineCount < JobPlanningLine.Count, StrSubstNo(JobPlanningLineCountErr, JobPlanningLine.TableCaption(), UOMCodeLineCount));
        JobPlanningLine.SetFilter("Unit of Measure Code", Filter);
        Assert.AreEqual(UOMCodeLineCount, JobPlanningLine.Count, StrSubstNo(JobPlanningLineFilterErr, JobPlanningLine.TableCaption(), JobPlanningLine.GetFilters));
    end;

    local procedure VerifyBaseUnitOfMeasure(Res: Record Resource; BaseUnitOfMeasureCode: Code[10])
    begin
        Res.TestField("Base Unit of Measure", BaseUnitOfMeasureCode);
    end;

    local procedure VerifyBaseUnitOfMeasureSetAndResUnitOfMeasureInserted(Res: Record Resource; ExpectedBaseUnitOfMeasure: Record "Unit of Measure"; ExpectedUnitsOfMeasureCount: Integer)
    var
        ResUnitOfMeasure: Record "Resource Unit of Measure";
    begin
        ResUnitOfMeasure.SetFilter("Resource No.", Res."No.");
        Assert.AreEqual(ExpectedUnitsOfMeasureCount, ResUnitOfMeasure.Count, 'Wrong number of Units of measure was found on the item');
        ResUnitOfMeasure.SetFilter(Code, ExpectedBaseUnitOfMeasure.Code);

        Assert.IsTrue(ResUnitOfMeasure.FindFirst(), 'Cannot get Item unit of measure for specified code');
        Assert.AreEqual(1, ResUnitOfMeasure."Qty. per Unit of Measure", 'Qty. per Unit of Measure should be set to 1');
        Assert.AreEqual(Res."Base Unit of Measure", ResUnitOfMeasure.Code, 'Base unit of measure was not set by validate');
    end;

    local procedure VerifyUnitPriceResLedgerEntry(DocNo: Code[20]; ResNo: Code[20]; UnitPrice: array[2] of Decimal)
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        ResLedgerEntry.SetRange("Document No.", DocNo);
        ResLedgerEntry.SetRange("Resource No.", ResNo);
        Assert.RecordCount(ResLedgerEntry, 2);
        ResLedgerEntry.FindSet();
        ResLedgerEntry.TestField("Unit Price", UnitPrice[1]);
        ResLedgerEntry.Next();
        ResLedgerEntry.TestField("Unit Price", UnitPrice[2]);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(ConfirmMessage, LocalMessage) > 0, ConfirmMessage);
        LibraryVariableStorage.Dequeue(DequeueVariable);
        Reply := DequeueVariable;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContractLineSelectionPageHandler(var ContractLineSelection: TestPage "Contract Line Selection")
    begin
        ContractLineSelection.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    var
        DequeueVariable: Variant;
        QtyToCreate: Decimal;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        QtyToCreate := DequeueVariable;
        EnterQuantityToCreate.QtyToCreate.SetValue(QtyToCreate);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
        ItemTrackingMode: Option SelectEntries,AssignSerialNo;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;
        case ItemTrackingMode of
            ItemTrackingMode::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingMode::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
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
    procedure ResourceUnitofMeasurePageHandler(var ResourceUnitsofMeasure: TestPage "Resource Units of Measure")
    begin
        ResourceUnitsofMeasure.Code.AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(Message, LocalMessage) > 0, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractTemplateListPageHandler(var ServiceContractTemplateList: TestPage "Service Contract Template List")
    begin
        ServiceContractTemplateList.OK().Invoke();
    end;
}
