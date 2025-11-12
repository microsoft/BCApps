codeunit 136309 "Job Posting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job]
        IsInitialized := false;
    end;

    var
        DummyJobsSetup: Record "Jobs Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJob: Codeunit "Library - Job";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        LibraryNoSeries: Codeunit "Library - No. Series";
        Any: Codeunit Any;
        TargetJobNo: Code[20];
        JournalTemplateName: Code[10];
        SerialNo: array[15] of Code[50];
        IsInitialized: Boolean;
        VerifyTrackingLine: Boolean;
        FromSource: Option "Job Planning Lines","Job Ledger Entries","None";
        Amount: Decimal;
        Cost: Decimal;
        AmountFCY: Decimal;
        CostFCY: Decimal;
        InvoicedCostFCY: Decimal;
        ValueMatchError: Label '%1 must not be same in %2 and %3.', Comment = '%1=Field name, %2=Table name,%3=Table name';
        SalesDocumentMsg: Label 'Sales Document should not be created.';
        JobNotExistErr: Label '%1 %2 does not exist.', Comment = '%1 - Table Caption;%2 - Field Value.';
        DimensionMustMatchMsg: Label 'Global Dimension must match';
        BinContentNotDeletedErr: Label 'Bin content must be deleted after reverting the receipt.';
        WrongJobCurrencyCodeErr: Label 'Wrong Project Currency Code';
        JobWithManualNoCreatedErr: Label 'Project with manual number is created.';
        ApplToItemEntryErr: Label 'Field "Appl.-to Item Entry" on Reservation Entry must be equal to correspondent Reservation Entry No.';
        OverBudgetSetIncorrectlyErr: Label 'Field "Over Budget" on table Project is set incorrectly.';
        JobCueIncorrectErr: Label 'Projects Over Budget cue has incorrect value.';
        TrackingOption: Option SelectSerialNo,AssignManualSN;
        PostJournaLinesQst: Label 'Do you want to post the journal lines?';
        UsageWillNotBeLinkedQst: Label 'Usage will not be linked to the project planning line because the Line Type field is empty.';
        WrongPostPreviewErr: Label 'Expected empty error from Preview. Actual error: ';

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostJobJournalLine()
    var
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        RandomInput: Decimal;
    begin
        // Check value of Job Ledger Entries and Job Planning Line exist or not after posting Job Journal Line.

        // 1. Setup: Create Job with Job Task, Resource and Job Journal Line.
        Initialize();
        RandomInput := LibraryRandom.RandDec(10, 2);  // Using Random Value for Quantity,Unit Cost and Unit Price.
        CreateJobWithJobTask(JobTask);
        CreateJobJournalLine(
          LibraryJob.UsageLineTypeBoth(), JobJournalLine.Type::Resource, JobJournalLine, JobTask, LibraryResource.CreateResourceNo(),
          RandomInput, RandomInput, RandomInput);  // Using Random because value is not important.

        // 2. Exercise: Post Job Journal Line.
        LibraryJob.PostJobJournal(JobJournalLine);

        // 3. Verify: Verify posted values in Job Ledger Entry and Job Planning Line.
        VerifyJobLedgerEntry(JobJournalLine);
        VerifyJobPlanningLine(JobJournalLine, LibraryJob.PlanningLineTypeSchedule());
        VerifyJobPlanningLine(JobJournalLine, LibraryJob.PlanningLineTypeContract());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobOnOrderByPage()
    var
        Job: Record Job;
    begin
        // Verify creation of Job by page with Status type Order.

        Initialize();
        CreateJobCardAndVerifyData(Job.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobOnPlanningByPage()
    var
        Job: Record Job;
    begin
        // Verify creation of Job by page with Status type Planning.

        Initialize();
        CreateJobCardAndVerifyData(Job.Status::Planning);
    end;

    local procedure CreateJobCardAndVerifyData(Status: Enum "Job Status")
    var
        Job: Record Job;
        JobNo: Code[20];
    begin
        // Setup: Create Job using record.
        CreateJob(Job, Status);

        // Exercise: Create Job using page.
        JobNo := CreateJobCard(Job);

        // Verify: Compare Job created using page with Job created using record.
        VerifyJob(Job, JobNo);
    end;

    [Test]
    [HandlerFunctions('CopyJobHandler,JobTaskListHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyJobPlanningLines()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        RandomInput: Decimal;
    begin
        // Test functionality of Copy Job with From Source as Job Planning Lines.

        // 1. Setup: Create Job, Job Task and Job Planning Lines.
        Initialize();
        RandomInput := LibraryRandom.RandDec(10, 2);  // Using Random Value for Quantity,Unit Cost and Unit Price.
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLine(
          JobPlanningLine, LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ResourceType(), JobTask, LibraryResource.CreateResourceNo(),
          RandomInput, RandomInput, RandomInput);  // Using Random because value is not important.
        CreateJobPlanningLine(
          JobPlanningLine2, LibraryJob.PlanningLineTypeContract(), LibraryJob.ResourceType(), JobTask, LibraryResource.CreateResourceNo(),
          RandomInput, RandomInput, RandomInput);    // Using Random because value is not important.
        TargetJobNo := GenerateJobNo();  // Use TargetJobNo as global for CopyJobHandler.

        // 2. Exercise: Run Copy Job with From Source as Job Planning Lines.
        FromSource := FromSource::"Job Planning Lines";  // Use FromSource as global for CopyJobHandler.
        RunCopyJob(JobTask."Job No.");

        // 3. Verify: Verify Job Planning Lines are copied successfully.
        VerifyValuesOnJobPlanningLine(
          TargetJobNo, JobPlanningLine."Job Task No.", JobPlanningLine."Line No.", JobPlanningLine."Line Type", JobPlanningLine."No.",
          JobPlanningLine.Quantity, JobPlanningLine."Unit Price");
        VerifyValuesOnJobPlanningLine(
          TargetJobNo, JobPlanningLine2."Job Task No.", JobPlanningLine2."Line No.", JobPlanningLine2."Line Type", JobPlanningLine2."No.",
          JobPlanningLine2.Quantity, JobPlanningLine2."Unit Price");
    end;

    [Test]
    [HandlerFunctions('CopyJobHandler,JobTaskListHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CopyJobLedgerLines()
    var
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        RandomInput: Decimal;
    begin
        // Test functionality of Copy Job with From Source as Job Ledger Entries.

        // 1. Setup: Create Job, Job Task and Job Planning Lines. Create and post Job journal Line.
        Initialize();
        RandomInput := LibraryRandom.RandDec(10, 2);  // Using Random Value for Quantity,Unit Cost and Unit Price.
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLine(
          JobPlanningLine, LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ResourceType(), JobTask, LibraryResource.CreateResourceNo(),
          RandomInput, RandomInput, RandomInput);  // Using Random because value is not important.
        CreateJobJournalLine(
          LibraryJob.UsageLineTypeBoth(), JobJournalLine.Type::Resource, JobJournalLine, JobTask, LibraryResource.CreateResourceNo(),
          RandomInput, RandomInput, RandomInput);  // Using Random because value is not important.
        LibraryJob.PostJobJournal(JobJournalLine);
        TargetJobNo := GenerateJobNo();  // Use TargetJobNo as global for CopyJobHandler.

        // 2. Exercise:  Run Copy Job with From Source as Job Ledger Entries.
        FromSource := FromSource::"Job Ledger Entries";  // Use FromSource as global for CopyJobHandler.
        RunCopyJob(JobTask."Job No.");

        // 3. Verify: Verify values of Job Planning Line are replaced by Job Ledger Entry.
        VerifyValuesOnJobPlanningLine(
          TargetJobNo, JobPlanningLine."Job Task No.", JobPlanningLine."Line No.", JobPlanningLine."Line Type", JobJournalLine."No.",
          JobJournalLine.Quantity, JobJournalLine."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostJobGLJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JobTask: Record "Job Task";
    begin
        // Check value of Job Ledger Entries and Job Planning Line exist or not after posting Job G/L Journal Line.

        // 1. Setup: Create Job with Job Task and a Job G/L Journal line.
        Initialize();
        CreateJobWithJobTask(JobTask);
        CreateJobGLJournalLine(GenJournalLine, JobTask);

        // 2. Exercise: Post Job G/L Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify posted values in Job Ledger Entry and Job Planning Lines.
        VerifyJobLedgerEntryUsingGeneralJournalLine(GenJournalLine);
        VerifyJobPlanningLineUsingGeneralJournalLine(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostingPurchaseOrderWithItemTracking()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify Remaining Quantity on Item Ledger Entry after posting Purchase Order with Item Tracking Lines.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Create and Receive Purchase Order.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        DocumentNo := PostPurchaseOrderWithItemTracking(PurchaseLine, false);

        // 3. Verify: Verify Cost,Invoiced and Remaining Quantity on Item Ledger Entry.
        VerifyItemLedgerEntry(DocumentNo, ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine.Quantity, 0, 0);  // Invoiced Quantity and Cost must be zero.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSelectEntriesPageHandler,JobJournalTemplateListPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostingJobJournalWithItemTracking()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify Remaining Quantity on Item Ledger Entry after posting Job Journal Line with Item Tracking Lines.

        // 1. Setup: Create Purchase Order With Item Tracking Lines, Post Purchase Order, Create a Job and Job Task, Create Job Journal Line.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        DocumentNo := PostPurchaseOrderWithItemTracking(PurchaseLine, false);

        // Update General Posting Setup.
        GeneralPostingSetup.Get('', PurchaseLine."Gen. Prod. Posting Group");  // Gen. Bus. Posting Group is blank for Job.
        UpdateGeneralPostingSetup(GeneralPostingSetup, GLAccount."No.");
        CreateJobWithJobTask(JobTask);
        LibraryVariableStorage.Enqueue(true);
        CreateJobJournalLineWithItemTracking(JobJournalLine, JobTask, PurchaseLine."No.", PurchaseLine.Quantity);
        AssignItemTrackingLinesOnJobJournal(JobJournalLine);

        // 2. Exercise: Post Job Journal Line.
        LibraryJob.PostJobJournal(JobJournalLine);

        // 3. Verify: Verify Cost,Invoiced and Remaining Quantity on Item Ledger Entry.
        VerifyItemLedgerEntry(DocumentNo, ItemLedgerEntry."Entry Type"::Purchase, 0, 0, 0);  // Cost, Remaining and Invoiced Quantity must be zero.
        VerifyItemLedgerEntry(
          JobJournalLine."Document No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.", 0, -PurchaseLine.Quantity,
          -JobJournalLine."Total Cost");  // Remaining Quantity must be zero.

        // 4. Tear Down.
        UpdateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup."Inventory Adjmt. Account");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,JobJournalTemplateListPageHandler,ConfirmHandlerTrue,ItemTrackingSelectEntriesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostingJobJournalWithItemTrackingAndNegativeQuantity()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        PurchaseLine: Record "Purchase Line";
        LotNo: Code[50];
    begin
        // Verify Remaining Quantity on Item Ledger Entry after posting Job Journal Line with Item Tracking Lines and Negative Quantity.

        // 1. Setup: Create and post Purchase Order With Item Tracking Lines.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryVariableStorage.Enqueue(false);
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo);
        PostPurchaseOrderWithItemTracking(PurchaseLine, true);

        // Update General Posting Setup, Create a Job and Job Task, Create and post Job Journal Line with Item Tracking Lines.
        GeneralPostingSetup.Get('', PurchaseLine."Gen. Prod. Posting Group");  // Gen. Bus. Posting Group is blank for Job.
        UpdateGeneralPostingSetup(GeneralPostingSetup, GLAccount."No.");
        CreateJobWithJobTask(JobTask);
        LibraryVariableStorage.Enqueue(true);
        CreateJobJournalLineWithItemTracking(JobJournalLine, JobTask, PurchaseLine."No.", PurchaseLine.Quantity);
        AssignItemTrackingLinesOnJobJournal(JobJournalLine);
        LibraryJob.PostJobJournal(JobJournalLine);

        // Create Job Journal line with negative Quantity and Item Tracking Lines.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(LotNo);
        CreateJobJournalLineWithItemTracking(JobJournalLine, JobTask, PurchaseLine."No.", -PurchaseLine.Quantity);
        LibraryVariableStorage.Enqueue(JobJournalLine.Quantity);
        AssignItemTrackingLinesOnJobJournal(JobJournalLine);

        // 2. Exercise: Post Job Journal Line.
        LibraryJob.PostJobJournal(JobJournalLine);

        // 3. Verify: Verify Cost,Invoiced and Remaining Quantity on Item Ledger Entry.
        VerifyItemLedgerEntry(
          JobJournalLine."Document No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.", PurchaseLine.Quantity, PurchaseLine.Quantity,
          -JobJournalLine."Total Cost");

        // 4. Tear Down.
        UpdateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup."Inventory Adjmt. Account");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReceivePurchaseOrderWithJob()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify Invoiced and Remaining Quantity on Item Ledger Entry after Receiving Purchase Order with Item Tracking Lines.

        // 1. Setup: Create Purchase Order With Item Tracking Lines, Update General Posting Setup, Post Purchase Order, Create a Job and Job Task, Create Job Journal Line.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        CreatePurchaseDocumentWithJobAndItemTracking(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine."Job Line Type"::"Both Budget and Billable", true, false);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        AssignItemTrackingLinesOnPurchaseOrder(PurchaseHeader);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        UpdateGeneralPostingSetup(GeneralPostingSetup, GLAccount."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // 2. Exercise: Receive the Purchase Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // 3. Verify: Verify Cost,Invoiced and Remaining Quantity on Item Ledger Entry.
        VerifyItemLedgerEntry(DocumentNo, ItemLedgerEntry."Entry Type"::Purchase, 0, 0, 0);  // Cost, Remaining and Invoiced Quantity must be zero.
        VerifyItemLedgerEntry(DocumentNo, ItemLedgerEntry."Entry Type"::"Negative Adjmt.", 0, 0, 0);  // Cost, Remaining and Invoiced Quantity must be zero.

        // 4. Tear Down.
        UpdateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup."Inventory Adjmt. Account");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure InvoicePurchaseOrderWithJob()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify Invoiced and Remaining Quantity on Item Ledger Entry after Invoicing Purchase Order with Item Tracking Lines.

        // 1. Setup. Create and receive Purchase Order with Job and Item Tracking.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        CreatePurchaseDocumentWithJobAndItemTracking(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine."Job Line Type"::"Both Budget and Billable", true, false);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        AssignItemTrackingLinesOnPurchaseOrder(PurchaseHeader);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        UpdateGeneralPostingSetup(GeneralPostingSetup, GLAccount."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // 2. Exercise: Invoice the Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // 3. Verify: Verify Cost,Invoiced and Remaining Quantity on Item Ledger Entry.
        VerifyItemLedgerEntry(
          DocumentNo, ItemLedgerEntry."Entry Type"::Purchase, 0, PurchaseLine.Quantity,
          PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost");  // Remaining Quantity must be zero.
        VerifyItemLedgerEntry(
          DocumentNo, ItemLedgerEntry."Entry Type"::"Negative Adjmt.", 0, -PurchaseLine.Quantity,
          -PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost");  // Remaining Quantity must be zero.

        // 4. Tear Down.
        UpdateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup."Inventory Adjmt. Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateJobUsingCopyJobFunctionality()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        CopyJob: Codeunit "Copy Job";
        LibraryUtility: Codeunit "Library - Utility";
        BillToCustomerNo: Code[20];
        TargetJobNo: Code[20];
    begin
        // Create a new job with Copy Job functionality.

        // 1. Setup: Create a Job and Job Task for it.
        Initialize();
        CreateJobWithJobTask(JobTask);
        Job.Get(JobTask."Job No.");
        BillToCustomerNo := Job."Bill-to Customer No.";
        TargetJobNo := LibraryUtility.GenerateGUID();

        // 2. Exercise: Create new Job using Copy Job functionality.
        CopyJob.CopyJob(Job, TargetJobNo, TargetJobNo, Job."Bill-to Customer No.", '');

        // 3. Verify: Verify Bill-to Customer No. and Job Task No. for new Job.
        Job.TestField("Bill-to Customer No.");  // To make sure that Bill-to Customer No. is not blank.
        Job.Get(TargetJobNo);
        Job.TestField("Bill-to Customer No.", BillToCustomerNo);
        JobTask.Get(TargetJobNo, JobTask."Job Task No.");  // To verify that Job Task exists for new Job created using Copy Job function.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesCreateSerialNoPageHandler,EnterCustomizedSNPageHandler,PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoWithTrackingAndJob()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Item Tracking Lines on Purchase Credit Memo which is created after executing "Get Posted Document Lines to Reverse" where Serial No and Job are involved.

        // 1. Setup: Create and post Purchase Invoice With Item Tracking Lines and Job. Create Purchase Credit Memo.
        Initialize();
        PostPurchaseInvoice(PurchaseHeader);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");

        // 2. Exercise: Create Purchase Credit Memo Lines using Get Posted Document Lines to Reverse function.
        PurchaseHeader.GetPstdDocLinesToReverse();

        // 3. Verify: Verification done in 'ItemTrackingLinesCreateSerialNoPageHandler'.
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        VerifyTrackingLine := true;  // Assign in Global variable.
        PurchaseLine.OpenItemTrackingLines();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesCreateSerialNoPageHandler,EnterCustomizedSNPageHandler,PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostingPurchaseCreditMemoWithJobAndTracking()
    var
        PurchaseHeader: Record "Purchase Header";
        JobLedgerEntry: Record "Job Ledger Entry";
        DocumentNo: Code[20];
        "Count": Integer;
    begin
        // Verify Gl Entry and Job Ledger Entry after posting the Purchase Credit Memo with more than one quantity after executing "Get Posted Document Lines to Reverse" where Serial No and Job are involved.

        // 1. Setup: Create and post Purchase Invoice With Item Tracking Lines and Job. Create Purchase Credit Memo Lines using Get Posted Document Lines to Reverse function.
        Initialize();
        PostPurchaseInvoice(PurchaseHeader);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.GetPstdDocLinesToReverse();

        // 2. Exercise: Post Purchase Credit Memo.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // 3. Verify: Verify Serial No. in Job Ledger Enrty.
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.FindSet();
        Count := 1;
        repeat
            JobLedgerEntry.TestField("Serial No.", SerialNo[Count]);
            Count := Count + 1;
        until JobLedgerEntry.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesCreateSerialNoPageHandler,EnterCustomizedSNPageHandler,PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingLineOnPurchaseCreditMemoHasCorrectApplToItemEntry()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 361355] Item Tracking Line on Purchase Credit Memo has correct "Appl.-to Item Entry" after using "Get Posted Document Lines to Reverse"
        Initialize();

        // [GIVEN] Create and post Purchase Invoice With Item Tracking Lines with Reservations.
        // [GIVEN] Purchase Credit Memo.
        PostPurchaseInvoiceWithItemTrackingLines(PurchaseHeader);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Get Posted Document Lines to Reverse on Purchase Credit Memo
        PurchaseHeader.GetPstdDocLinesToReverse();

        // [THEN] Reservation Entry on the Credit Memo Line is applied to Item Ledger Entry posted by Invoice
        VerifyApplToItemEntry(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchPageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithJobAndChargeItem()
    var
        ItemCharge: Record "Item Charge";
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify Job Ledger Entry after posting the Purchase Order with Job and Charge (Item).

        // 1. Setup: Create Purchase Order With Job and ChargeItem.
        Initialize();
        CreateJobWithJobTask(JobTask);
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreatePurchaseOrderWithJob(
          PurchaseLine, PurchaseLine."Document Type"::Order, JobTask, CreateItem(),
          PurchaseLine."Job Line Type"::"Both Budget and Billable");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemCharge."No.");
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);
        PurchaseLine.ShowItemChargeAssgnt();
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // 2. Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 3. Verify.
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, PurchaseLine."No.");
        JobLedgerEntry.TestField(Quantity, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('JobTaskStatisticsScheduleUsagePageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobTaskStatisticsScheduleUsageLCY()
    var
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
    begin
        // Verify Job Task Statistics Price, Cost and Profit for Schedule and Usage.

        // 1. Setup: Create a Job and Job Task for it. Create and Post Job Journal Lines for Type Item, Resource and GLAccount.
        Initialize();
        LibraryJob.CreateJob(Job);
        CreateJobJournalLinesForDifferentType(Job, JobJournalLine);
        LibraryJob.PostJobJournal(JobJournalLine);

        // 2. Exercise: Open Job Task Statistics Page from Job Task Lines.
        OpenJobTaskLines(Job."No.");

        // 3. Verify: Verify Schedule and Usage Price, Cost and Profit on JobTaskStatisticsScheduleUsagePageHandler.
    end;

    [Test]
    [HandlerFunctions('JobTaskStatisticsScheduleUsagePageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobTaskStatisticsScheduleUsageFCY()
    var
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
    begin
        // Verify Job Task Statistics Price, Cost and Profit for Schedule and Usage with Different Currency.

        // 1. Setup: Create a Job with different Currency and Job Task for it. Create and Post Job Journal Lines for Type Item, Resource and GLAccount.
        Initialize();
        CreateJobWithCurrency(Job);
        CreateJobJournalLinesForDifferentType(Job, JobJournalLine);
        LibraryJob.PostJobJournal(JobJournalLine);

        // 2. Exercise: Open Job Task Statistics Page from Job Task Lines.
        OpenJobTaskLines(Job."No.");

        // 3. Verify: Verify Schedule and Usage Price, Cost and Profit on JobTaskStatisticsScheduleUsagePageHandler.
    end;

    [Test]
    [HandlerFunctions('JobStatisticsScheduleUsagePageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobStatisticsScheduleUsageLCY()
    var
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
        Counter: Integer;
    begin
        // Verify Job Statistics Price, Cost and Profit for Schedule and Usage.

        // 1. Setup: Create a Job and multiple Job Tasks for it. Create and Post Job Journal Lines for Type Item, Resource and GLAccount.
        Initialize();
        LibraryJob.CreateJob(Job);
        for Counter := 1 to 1 + LibraryRandom.RandInt(3) do begin
            CreateJobJournalLinesForDifferentType(Job, JobJournalLine);
            LibraryJob.PostJobJournal(JobJournalLine);
        end;

        // 2. Exercise: Open Job Statistics Page from Job Card.
        OpenJobCard(Job."No.");

        // 3. Verify: Verify Schedule and Usage Price, Cost and Profit on JobStatisticsScheduleUsagePageHandler.
    end;

    [Test]
    [HandlerFunctions('JobStatisticsScheduleUsagePageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobStatisticsScheduleUsageFCY()
    var
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
        Counter: Integer;
    begin
        // Verify Job Statistics Price, Cost and Profit for Schedule and Usage with Different Currency.

        // 1. Setup: Create a Job with different Currency and multiple Job Tasks for it. Create and Post Job Journal Lines for Type Item, Resource and GLAccount.
        Initialize();
        CreateJobWithCurrency(Job);
        for Counter := 1 to 1 + LibraryRandom.RandInt(3) do begin
            CreateJobJournalLinesForDifferentType(Job, JobJournalLine);
            LibraryJob.PostJobJournal(JobJournalLine);
        end;

        // 2. Exercise: Open Job Statistics Page from Job Card.
        OpenJobCard(Job."No.");

        // 3. Verify: Verify Schedule and Usage Price, Cost and Profit on JobStatisticsScheduleUsagePageHandler.
    end;

    [Test]
    [HandlerFunctions('JobTaskStatisticsContractInvoicedPageHandler,JobTransferToSalesInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobTaskStatisticsContractInvoicedLCY()
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Verify Job Task Statistics Price, Cost and Profit for Contract and Invoiced.

        // 1. Setup: Create a Job and Job Task for it. Create Job Planning Lines for Type Item, Resource and GLAccount and then Create Sales Invoice from Job Planning Line. Post the Sales Invoice.
        Initialize();
        LibraryJob.CreateJob(Job, CreateCustomer(''));  // Passing Blank for Currency Code.
        CreateJobPlanningLinesForDifferentType(Job, JobPlanningLine);
        CreateAndPostSalesInvoice(JobPlanningLine, Job."Bill-to Customer No.");

        // 2. Exercise: Open Job Task Statistics Page from Job Task Lines.
        OpenJobTaskLines(Job."No.");

        // 3. Verify: Verify Contract and Invoiced Price, Cost and Profit on JobTaskStatisticsContractInvoicedPageHandler.
    end;

    [Test]
    [HandlerFunctions('JobTaskStatisticsContractInvoicedPageHandler,JobTransferToSalesInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobTaskStatisticsContractInvoicedFCY()
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Verify Job Task Statistics Price, Cost and Profit for Contract and Invoiced with Different Currency.

        // 1. Setup: Create a Job with different Currency and Job Task for it. Create Job Planning Lines for Type Item, Resource and GLAccount and then Create Sales Invoice from Job Planning Line. Post the Sales Invoice.
        Initialize();
        CreateJobWithCurrency(Job);
        CreateJobPlanningLinesForDifferentType(Job, JobPlanningLine);
        CreateAndPostSalesInvoice(JobPlanningLine, Job."Bill-to Customer No.");

        // 2. Exercise: Open Job Task Statistics Page from Job Task Lines.
        OpenJobTaskLines(Job."No.");

        // 3. Verify: Verify Contract and Invoiced Price, Cost and Profit on JobTaskStatisticsContractInvoicedPageHandler.
    end;

    [Test]
    [HandlerFunctions('JobStatisticsContractInvoicedPageHandler,JobTransferToSalesInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobStatisticsContractInvoicedLCY()
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        Counter: Integer;
    begin
        // Verify Job Statistics Price, Cost and Profit for Contract and Invoiced.

        // 1. Setup: Create a Job and multiple Job Tasks for it. Create Job Planning Lines for Type Item, Resource and GLAccount and then Create Sales Invoice from Job Planning Line. Post the Sales Invoice.
        Initialize();
        LibraryJob.CreateJob(Job, CreateCustomer(''));  // Passing Blank for Currency Code.
        for Counter := 1 to 1 + LibraryRandom.RandInt(3) do begin
            CreateJobPlanningLinesForDifferentType(Job, JobPlanningLine);
            CreateAndPostSalesInvoice(JobPlanningLine, Job."Bill-to Customer No.");
        end;

        // 2. Exercise: Open Job Statistics Page from Job Card.
        OpenJobCard(Job."No.");

        // 3. Verify: Verify Contract and Invoiced Price, Cost and Profit on JobStatisticsContractInvoicedPageHandler.
    end;

    [Test]
    [HandlerFunctions('JobStatisticsContractInvoicedPageHandler,JobTransferToSalesInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobStatisticsContractInvoicedFCY()
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        Counter: Integer;
    begin
        // Verify Job Statistics Price, Cost and Profit for Contract and Invoiced with Different Currency.

        // 1. Setup: Create a Job with different Currency and multiple Job Tasks for it. Create Job Planning Lines for Type Item, Resource and GLAccount and then Create Sales Invoice from Job Planning Line. Post the Sales Invoice.
        Initialize();
        CreateJobWithCurrency(Job);
        for Counter := 1 to 1 + LibraryRandom.RandInt(3) do begin
            CreateJobPlanningLinesForDifferentType(Job, JobPlanningLine);
            CreateAndPostSalesInvoice(JobPlanningLine, Job."Bill-to Customer No.");
        end;

        // 2. Exercise: Open Job Statistics Page from Job Card.
        OpenJobCard(Job."No.");

        // 3. Verify: Verify Contract and Invoiced Price, Cost and Profit on JobStatisticsContractInvoicedPageHandler.
    end;

    [Test]
    [HandlerFunctions('JobTaskStatisticsPageHander,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobTaskStatisticsFilters()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        RandomInput: Decimal;
    begin
        // Verify Job Task Statistics Price, Cost and Profit for Schedule and Usage with Planning and Posting Date Filters.

        // 1. Setup: Create a Job and Job Task for it. Create and Post Job Journal Lines for Type Resource.
        Initialize();
        RandomInput := LibraryRandom.RandDec(10, 2);  // Using Random Value for Quantity,Unit Cost and Unit Price.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobJournalLine(
          LibraryJob.UsageLineTypeSchedule(), JobJournalLine.Type::Resource, JobJournalLine, JobTask, LibraryResource.CreateResourceNo(),
          RandomInput, RandomInput, RandomInput);  // Using Random because value is not important.
        LibraryJob.PostJobJournal(JobJournalLine);

        // 2. Exercise: Open Job Task Statistics Page from Job Task Lines.
        OpenJobTaskLines(JobTask."Job No.");

        // 3. Verify: Verify Schedule and Usage Price, Cost and Profit on JobTaskStatisticsPageHandler.
    end;

    [Test]
    [HandlerFunctions('JobStatisticsPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobStatisticsFilters()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        RandomInput: Decimal;
        Counter: Integer;
    begin
        // Verify Job Statistics Price, Cost and Profit for Schedule and Usage with Planning and Posting Date Filters.

        // 1. Setup: Create a Job and multiple Job Tasks for it. Create Job Planning Lines for Type Resource and then Create Sales Invoice from Job Planning Line. Post the Sales Invoice.
        Initialize();
        RandomInput := LibraryRandom.RandDec(10, 2);  // Using Random Value for Quantity,Unit Cost and Unit Price.
        LibraryJob.CreateJob(Job);
        for Counter := 1 to 1 + LibraryRandom.RandInt(3) do begin
            LibraryJob.CreateJobTask(Job, JobTask);
            CreateJobJournalLine(
              LibraryJob.UsageLineTypeSchedule(), JobJournalLine.Type::Resource, JobJournalLine, JobTask, LibraryResource.CreateResourceNo(),
              RandomInput, RandomInput, RandomInput);  // Using Random because value is not important.
            LibraryJob.PostJobJournal(JobJournalLine);
        end;

        // 2. Exercise: Open Job Task Statistics Page from Job Task Lines.
        OpenJobCard(JobTask."Job No.");

        // 3. Verify: Verify Schedule and Usage Price, Cost and Profit on JobStatisticsPageHandler.
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinePageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseRetunOrderWithJob()
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        DocumentNo: Code[20];
    begin
        // Verify Program allows to post the Purchase Return Order should be posted with Job after executing the Get Posted Document Lines to Reverse function.

        // 1. Setup: Update Exact Cost Reversing checkbox on Purchase & Payable Setup.
        PurchasesPayablesSetup.Get();
        UpdatePurchasesAndPayablesSetup(true);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateJobWithJobTask(JobTask);
        CreatePurchaseOrderWithJob(
          PurchaseLine, PurchaseLine."Document Type"::Order, JobTask, CreateItem(), PurchaseLine."Job Line Type"::Billable);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreatePurchaseHeader(PurchaseHeader, PurchaseLine."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.");
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        UpdateGeneralPostingSetup(GeneralPostingSetup, GLAccount."No.");

        GetPostedDocumentLinesToReverse(PurchaseHeader."No.");
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // 2. Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 3. Verify.
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, PurchaseLine."No.");
        JobLedgerEntry.TestField(Quantity, -PurchaseLine.Quantity);
        JobLedgerEntry.TestField(Type, JobLedgerEntry.Type);
        JobLedgerEntry.TestField("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        JobLedgerEntry.TestField("Job Task No.", JobTask."Job Task No.");

        // 4. Tear Down.
        UpdateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup."Inventory Adjmt. Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyPerUnitOfMeasureOnPurchaseLineWithJob()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QtyPerUnitOfMeasure: Decimal;
    begin
        // Verify Qty. per Unit of Measure on Purchase Line is not updated when changed it on Base Unit of Measure after receiving the Purchase Order.

        Initialize();
        QtyPerUnitOfMeasure := ReceivePurchaseOrderWithNewUOM(PurchaseHeader);
        FindPurchaseLine(PurchaseLine, PurchaseHeader);

        // 2. Exercise: Modify Qty. per Unit of Measure for new Unit of Measure.
        ItemUnitOfMeasure.Get(PurchaseLine."No.", PurchaseLine."Unit of Measure");
        ModifyQtyPerUnitOfMeasure(ItemUnitOfMeasure, QtyPerUnitOfMeasure);

        // 3. Verify: Verify Qty. per Unit of Measure value is not updated on the Purchase Line.
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        Assert.AreNotEqual(
          QtyPerUnitOfMeasure, PurchaseLine."Qty. per Unit of Measure",
          StrSubstNo(
            ValueMatchError, ItemUnitOfMeasure.FieldCaption("Qty. per Unit of Measure"), ItemUnitOfMeasure.TableCaption(),
            PurchaseLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyPerUnitOfMeasureOnJobLedgerEntry()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        JobLedgerEntry: Record "Job Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        QtyPerUnitOfMeasure: Decimal;
    begin
        // Verify Job Ledger Entry after posting a Purchase Order where "Qty. per Unit of Measure" is different on Base Unit of Measure while posting Purchase Order as receive and then Invoice.

        Initialize();
        QtyPerUnitOfMeasure := ReceivePurchaseOrderWithNewUOM(PurchaseHeader);
        FindPurchaseLine(PurchaseLine, PurchaseHeader);

        // 2. Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // 3. Verify: Verify Qty. per Unit of Measure value is not updated on the Job Ledger Entry.
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, PurchaseLine."No.");
        Assert.AreNotEqual(
          QtyPerUnitOfMeasure, JobLedgerEntry."Qty. per Unit of Measure",
          StrSubstNo(
            ValueMatchError, ItemUnitOfMeasure.FieldCaption("Qty. per Unit of Measure"), ItemUnitOfMeasure.TableCaption(),
            JobLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineUnitPriceWithItemSalesPrice()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesPrice: Record "Sales Price";
        PriceListLine: Record "Price List Line";
    begin
        // Verify correct Unit Price for an Item is updated on Job Planning Line when Sales Price are defined on the Item.

        // 1. Setup: Create Job and Job Task, create Item with Unit Price, create Sales Price for Item with Minimum Quantity with Random values.
        Initialize();
        CreateJobWithJobTask(JobTask);
        Job.Get(JobTask."Job No.");
        Item.Get(CreateItem());
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::Customer, Job."Bill-to Customer No.", WorkDate(), '', '',
          Item."Base Unit of Measure", 1 + LibraryRandom.RandInt(10), Item."Unit Price" - LibraryRandom.RandInt(10));
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // 2. Exercise: Create Job Planning Line.
        CreateAndUpdateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget,
          Item."No.", SalesPrice."Minimum Quantity");

        // 3. Verify: Verify Unit Price on Job Planning Line.
        JobPlanningLine.TestField("Unit Price", SalesPrice."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobForCustomerWithoutCurrency()
    begin
        // Check Currency Code and Invoice Currency Code field values on Job Card when Bill to Customer No. on Job is having no Currency attached.

        // 1. Setup: Supply Blank value for Currency Code to update it on Customer.
        Initialize();
        InvoiceCurrencyForJob('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobForCustomerWithCurrency()
    begin
        // Check Currency Code and Invoice Currency Code field values on Job Card when Bill to Customer No. on Job has Currency attached.

        // 1. Setup: Create Currency and update it on Customer.
        Initialize();
        InvoiceCurrencyForJob(CreateCurrency());
    end;

    local procedure InvoiceCurrencyForJob(InvoiceCurrencyCode: Code[10])
    var
        Job: Record Job;
    begin
        // 2. Exercise: Create Job for Customer.
        LibraryJob.CreateJob(Job, CreateCustomer(InvoiceCurrencyCode));

        // 3. Verify: Verify Currency Code and Invoice Currency Code field on Job according to the Customer.
        Job.TestField("Currency Code", '');
        Job.TestField("Invoice Currency Code", InvoiceCurrencyCode);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AutomaticCostPostingAdjustmentAlways()
    var
        InventorySetup: Record "Inventory Setup";
        ItemJournalLine: Record "Item Journal Line";
        TempItemJournalLine: Record "Item Journal Line" temporary;
        ItemNo: Code[20];
        NoOfLines: Integer;
        TotalAmount: Decimal;
    begin
        // Verify Program updates the Unit Cost with Automatic Cost Posting set to YES and Automatic Cost Adjustment set to Always on Inventory Setup.

        // 1. Setup: Set Automatic Cost Posting as TRUE and Automatic Cost Adjustment to Always, Create Item, Create multiple Item Journal Lines.
        Initialize();
        ItemNo := CreateItemWithInventoryAdjustmentAccount();
        UpdateInventorySetup(true, InventorySetup."Automatic Cost Adjustment"::Always);
        NoOfLines := 1 + LibraryRandom.RandInt(3);  // To create 2 to 4 Item Journal Lines Boundary 2 is important.
        TotalAmount := CreateMultipleItemJournalLines(ItemJournalLine, ItemNo, NoOfLines);
        SaveItemJnlLineInTempTable(TempItemJournalLine, ItemJournalLine);
        LibraryUtility.GenerateGUID();  // Hack to fix problem with GenerateGUID.

        // 2. Exercise: Post Item Journal Lines.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // 3. Verify: Verify Unit Cost on Item and Item Ledger Entries.
        VerifyUnitCostOnItem(ItemNo, Round(TotalAmount / NoOfLines, LibraryJob.GetUnitAmountRoundingPrecision('')));
        VerifyItemLedgerEntries(TempItemJournalLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostJobWithAutomaticCostPostingAdjustmentAlways()
    var
        Item: Record Item;
        GeneralLedgerSetup: Record "General Ledger Setup";
        InventorySetup: Record "Inventory Setup";
        JobTask: Record "Job Task";
        ItemJournalLine: Record "Item Journal Line";
        TempItemJournalLine: Record "Item Journal Line" temporary;
        JobJournalLine: Record "Job Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        NoOfLines: Integer;
        TotalAmount: Decimal;
    begin
        // Veriy Program updates the Unit Cost when posting of Job Journal with Automatic Cost Posting set to YES and Automatic Cost Adjustment set to Always on Inventory Setup.

        // 1. Setup: Set Automatic Cost Posting as TRUE and Automatic Cost Adjustment to Always, Create Item, Create and Post Item Journal Lines, Create Job with Job Task, Create Job Journal line.
        Initialize();
        InventorySetup.Get();
        GeneralLedgerSetup.Get();
        Item.Get(CreateItemWithInventoryAdjustmentAccount());
        UpdateInventorySetup(true, InventorySetup."Automatic Cost Adjustment"::Always);
        NoOfLines := 1 + LibraryRandom.RandInt(3);  // To create 2 to 4 Item Journal Lines Boundary 2 is important.
        TotalAmount := CreateMultipleItemJournalLines(ItemJournalLine, Item."No.", NoOfLines);
        SaveItemJnlLineInTempTable(TempItemJournalLine, ItemJournalLine);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateJobWithJobTask(JobTask);
        CreateJobJournalLine(
          LibraryJob.UsageLineTypeBoth(), JobJournalLine.Type::Item, JobJournalLine, JobTask, Item."No.", 1, Item."Unit Cost", Item."Unit Price");  // Taking Quantity as 1 is important for test.
        TempItemJournalLine.FindFirst();  // Required for the verification of Item "Unit Cost" and Item Ledger Entry.

        // 2. Exercise: Post Job Journal Line.
        LibraryJob.PostJobJournal(JobJournalLine);

        // 3. Verify: Verify Cost,Invoiced and Remaining Quantity on Item Ledger Entry and Unit Cost on Item.
        VerifyUnitCostOnItem(
          Item."No.",
          Round((TotalAmount - TempItemJournalLine."Unit Amount") / (NoOfLines - 1), LibraryJob.GetUnitAmountRoundingPrecision('')));
        VerifyItemLedgerEntry(
          JobJournalLine."Document No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.", 0, -1, -TempItemJournalLine."Unit Amount");  // Remaining Quantity must be 0 and Invoiced Quantity must be -1.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure GLEntriesOnPostedPurchaseOrderWithJob()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Test G/L Entries on Posted Purchase Order with job with Automatic and Expected Cost Posting to True.
        PostedPurchaseOrderWithJob(PurchaseLine."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure GLEntriesOnPostedPurchaseReturnOrderWithJob()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Test G/L Entries Posted Purchase Return Order with job with Automatic and Expected Cost Posting to True.
        PostedPurchaseOrderWithJob(PurchaseLine."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptOnPostedPostedOrder()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedOrderNo: Code[20];
    begin
        // Test G/L Entries and Value Entries With Undo Reciept on Posted Purchase Order with job with Automatic and Expected Cost Posting to True.
        // Setup: Create And Post Purchase Order With Job No.
        Initialize();
        UpdateInventorySetupWithExpectedCost(true, true);

        // Excercise : Undo Purchase Reciept on Posted Purchase Invoice.
        CreateJobWithJobTask(JobTask);
        CreatePurchaseOrderWithJob(
          PurchaseLine, PurchaseLine."Document Type"::Order, JobTask, CreateItem(), PurchaseLine."Job Line Type"::Billable);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PostedOrderNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        UndoPurchaseReceiptLine(PostedOrderNo, PurchaseLine."No.");

        // Verify: Verify G/L Entries.
        VerifyGLEntry(PostedOrderNo, PurchaseLine."Line Amount");
        VerifyValueEntry(PostedOrderNo, PurchaseLine."No.", PurchaseLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure UndoPostedReturnShipmentOnPostedReturnOrder()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedRetunOrderNo: Code[20];
    begin
        // Test G/L Entries and Value Entries With Undo Retun Shipment on Posted Purchase Return Order with job with Automatic and Expected Cost Posting to True.
        // Setup: Create And Post Purchase Return Order With Job No.
        Initialize();
        UpdateInventorySetupWithExpectedCost(true, true);
        CreateJobWithJobTask(JobTask);
        CreatePurchaseOrderWithJob(
          PurchaseLine, PurchaseLine."Document Type"::"Return Order", JobTask, CreateItem(), PurchaseLine."Job Line Type"::Billable);

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PostedRetunOrderNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Excercise : Undo Retun Shipment on Posted Purchase Order.
        UndoReturnShipmentLine(PostedRetunOrderNo, PurchaseLine."No.");

        // Verify: Verify G/L and Value Entries.
        VerifyGLEntry(PostedRetunOrderNo, PurchaseLine."Line Amount");
        VerifyValueEntry(PostedRetunOrderNo, PurchaseLine."No.", PurchaseLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceFromJobWhenItemBlocked()
    begin
        // Verify Sales Invoice not created when Item Blocked.
        SalesDocumentDoesNotExistWhenItemBlocked(false);  // Parameter False is used to distinguish Sales Document created with Invoice/Creditmemo.
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesCreditMemoFromJobWhenItemBlocked()
    begin
        // Verify Sales Credit Memo not created when Item Blocked.
        SalesDocumentDoesNotExistWhenItemBlocked(true);  // Parameter True is used to distinguish Sales Document created with Invoice/Creditmemo.
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceFromJobWhenItemNotBlocked()
    begin
        // Verify Extended Text on Sales Invoice when Item was not Blocked.
        SalesDocumentExistWithExtendedText(false);  // Parameter False is used to distinguish Sales Document created with Invoice / Creditmemo.
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesCreditMemoHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesCreditMemoFromJobWhenItemNotBlocked()
    begin
        // Verify Extended Text on Sales Credit Memo when Item was not Blocked.
        SalesDocumentExistWithExtendedText(true);  // Parameter True is used to distinguish Sales Document created with Invoice / Creditmemo.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTargetJobTaskNoOnCopyJobPlanningLinesPage()
    var
        JobTask: Record "Job Task";
        CopyJobPlanningLinesPage: TestPage "Copy Job Planning Lines";
    begin
        // Verify that TargetJobTaskNo is working as per the selection of TargetJobNo on Copy Job Planning Lines page.

        // Setup: Create Job and Job Task.
        Initialize();
        CreateJobWithJobTask(JobTask);

        // Exercise: Open Copy Job Planning Lines page and set the value on the controls TargetJobNo and TargetJobTaskNo.
        CopyJobPlanningLinesPage.OpenEdit();
        CopyJobPlanningLinesPage.TargetJobNo.SetValue(JobTask."Job No.");
        CopyJobPlanningLinesPage.TargetJobTaskNo.SetValue(JobTask."Job Task No.");

        // Verify: Verify that the TargetJobTaskNo contains the correct Job task no. of the TargetJobNo.
        CopyJobPlanningLinesPage.TargetJobTaskNo.AssertEquals(JobTask."Job Task No.");
    end;

    [Test]
    [HandlerFunctions('JobTaskListHandler')]
    [Scope('OnPrem')]
    procedure LookUpTargetJobTaskNoOnCopyJobPlanningLinesPage()
    var
        JobTask: Record "Job Task";
        CopyJobPlanningLinesPage: TestPage "Copy Job Planning Lines";
    begin
        // Verify that TargetJobTaskNo lookup is working as per the selection of TargetJobNo on Copy Job Planning Lines page.

        // Setup: Create Job and Job Task.
        Initialize();
        CreateJobWithJobTask(JobTask);

        // Exercise: Open Copy Job Planning Lines page and set the value on the control TargetJobNo and then lookup TargetJobTaskNo.
        CopyJobPlanningLinesPage.OpenEdit();
        CopyJobPlanningLinesPage.TargetJobNo.SetValue(JobTask."Job No.");
        CopyJobPlanningLinesPage.TargetJobTaskNo.Lookup();

        // Verify: Verify that the TargetJobTaskNo contains the correct Job task no. of the TargetJobNo.
        CopyJobPlanningLinesPage.TargetJobTaskNo.AssertEquals(JobTask."Job Task No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TargetJobTaskNoErrorOnCopyJobPlanningLinesPage()
    var
        JobTask: Record "Job Task";
        CopyJobPlanningLinesPage: TestPage "Copy Job Planning Lines";
    begin
        // Verify that system throws error while setting the value in TargetJobTaskNo if TargetJobNo is not filled.

        // Setup: Create Job and Job Task.
        Initialize();
        CreateJobWithJobTask(JobTask);

        // Exercise: Open Copy Job Planning Lines page and set the value on the controls SourceJobNo and TargetJobTaskNo.
        CopyJobPlanningLinesPage.OpenEdit();
        CopyJobPlanningLinesPage.SourceJobNo.SetValue(JobTask."Job No.");
        asserterror CopyJobPlanningLinesPage.TargetJobTaskNo.SetValue(JobTask."Job Task No.");

        // Verify: Verify that system throws error while setting the value in TargetJobTaskNo if TargetJobNo is not filled.
        Assert.ExpectedError(StrSubstNo(JobNotExistErr, JobTask.TableCaption(), JobTask."Job Task No."));
    end;

    [Test]
    [HandlerFunctions('CopyJobHandler,JobTaskListHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CopyDimensionsOnJobUsingCopyJobFunctionality()
    var
        SourceJob: Record Job;
        TargetJob: Record Job;
        JobTask: Record "Job Task";
    begin
        // Verify Global Dimensions of new Job from Source Job using Copy Job functionality.

        // Setup: Create a Job and Job Task for it and update Global Dimension.
        Initialize();
        CreateJobWithJobTask(JobTask);
        SourceJob.Get(JobTask."Job No.");
        UpdateGlobalDimensionOnJob(SourceJob);
        TargetJobNo := GenerateJobNo();

        // Exercise: Create new Job using Copy Job functionality.
        RunCopyJob(JobTask."Job No.");
        TargetJob.Get(TargetJobNo);

        // Verify: Verify Global Dimensions of new Job from Source Job using Copy Job functionality.
        Assert.AreEqual(SourceJob."Global Dimension 1 Code", TargetJob."Global Dimension 1 Code", DimensionMustMatchMsg);
        Assert.AreEqual(SourceJob."Global Dimension 2 Code", TargetJob."Global Dimension 2 Code", DimensionMustMatchMsg);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TFS358363_UndoReiceptDeletesBinContent()
    var
        JobPlanningLine: Record "Job Planning Line";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        PurchRcptNo: Code[20];
    begin
        CreateJobWithPlanningUsageLink(JobPlanningLine);
        CreateLocationWithBin(Bin);

        CreatePurchaseLineForPlan(PurchaseLine, JobPlanningLine, Bin);
        PurchRcptNo := PostPurchaseReceipt(PurchaseLine."Document No.");
        UndoPurchaseReceiptLine(PurchRcptNo, JobPlanningLine."No.");

        VerifyBinIsEmpty(JobPlanningLine."Location Code", JobPlanningLine."Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineCurrencyCodeFromJobTask()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Verify Currency Code populated from Job after item changed on purchase line
        // [GIVEN] Job Task with some Currency Code
        CreateJobWithCurrency(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Purchase invoice with a line and pointed to the job
        CreatePurchaseOrderWithJob(
          PurchaseLine, PurchaseLine."Document Type"::Order, JobTask, CreateItem(),
          PurchaseLine."Job Line Type"::" ");
        // [WHEN] Another Item set to the line
        PurchaseLine.Validate("No.", CreateItem());
        PurchaseLine.Modify(true);
        // [THEN] Job Currency Code must be kept and equal to Job's Currency Code
        Assert.AreEqual(Job."Currency Code", PurchaseLine."Job Currency Code", WrongJobCurrencyCodeErr);
    end;

    [Test]
    [HandlerFunctions('CopyJobHandler,JobTaskListHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NotAllowedToCopyJobWithManualNoAndDisabledManualNos()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        // [SCENARIO 108995] Verify that job cannot be copied with manual "No." and disabled "Manual Nos." in "Job No. Series"
        Initialize();

        // [GIVEN] Job with job task
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Disabled "Manual Nos." in "Job No. Series"
        SetupManualNosInJobNoSeries(false);

        // [WHEN] Copy the job to new TargetJobNo
        TargetJobNo := GenerateJobNo();
        FromSource := FromSource::"Job Planning Lines";
        RunCopyJob(Job."No.");

        // [THEN] TargetJobNo is not created
        Assert.IsFalse(Job.Get(TargetJobNo), JobWithManualNoCreatedErr);

        // TearDown
        SetupManualNosInJobNoSeries(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure BlankCurrencyCodeAfterValidateCustWithCurrency()
    var
        Job: Record Job;
        CustNo: Code[20];
        CurCode: Code[10];
    begin
        // [FEATURE] [Currency Code]
        // [SCENARIO 218732] "Currency Code" clears out when update "Bill-To Customer No." by Customer with any currency
        Initialize();

        // [GIVEN] Job with "Currency Code" = "USD" and Customer "X"
        CreateJobWithCurrency(Job);

        // [GIVEN] Customer "Y" with currency "RUB"
        CreateCustomerWithCurrency(CustNo, CurCode);

        // [WHEN] Set "Bill-to Customer No." = customer "Y"
        Job.Validate("Bill-to Customer No.", CustNo);

        // [THEN] "Currency Code" in Job is blank
        Job.TestField("Currency Code", '');

        // [THEN] Job has "Invoice Currency Code" = "RUB"
        Job.TestField("Invoice Currency Code", CurCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CurrencyCodeNotChangedAfterValidateCustWithoutCurrency()
    var
        Job: Record Job;
        CustNo: Code[20];
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Currency Code]
        // [SCENARIO 288249] "Currency Code" doesn't change when update "Bill-To Customer No." by Customer without currency
        Initialize();

        // [GIVEN] Job with "Currency Code" = EUR
        LibraryJob.CreateJob(Job);
        CurrencyCode := CreateCurrency();
        Job.Validate("Currency Code", CurrencyCode);

        // [GIVEN] Customer "X" without Currency Code
        CustNo := CreateCustomer('');

        // [WHEN] Set "Bill-to Customer No." = Customer "X"
        Job.Validate("Bill-to Customer No.", CustNo);

        // [THEN] "Currency Code" in Job is not changed = EUR
        Job.TestField("Currency Code", CurrencyCode);

        // [THEN] Job "Invoice Currency Code" is blank
        Job.TestField("Invoice Currency Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankCurCodeOnValidateInvoiceCurCode()
    var
        Job: Record Job;
    begin
        // [FEATURE] [Currency Code]
        // [SCENARIO 288249] "Currency Code" is blank, when you change "Invoice Currency Code"
        Initialize();

        // [GIVEN] Job with "Currency Code" = RUB
        CreateJobWithCurrency(Job);

        // [WHEN] Update "Invoice Currency Code" in job with EUR
        Job.Validate("Invoice Currency Code", CreateCurrency());

        // [THEN] "Currency Code" is blank
        Job.TestField("Currency Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankInvCurCodeOnValidateCurCode()
    var
        Job: Record Job;
    begin
        // [FEATURE] [Currency Code]
        // [SCENARIO 288249] "Invoice Currency Code" is blank, when you change "Currency Code"
        Initialize();

        // [GIVEN] Job with "Invoice Currency Code" = RUB
        LibraryJob.CreateJob(Job);
        Job.Validate("Invoice Currency Code", CreateCurrency());

        // [WHEN] Update "Currency Code" in job with EUR
        Job.Validate("Currency Code", CreateCurrency());

        // [THEN] "Invoice Currency Code" is blank
        Job.TestField("Invoice Currency Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobCardInvoiceCurrencyCodeEditabled()
    var
        Job: Record Job;
        JobCard: TestPage "Job Card";
    begin
        // [FEATURE] [Currency Code] [UI]
        // [SCENARIO 218732] "Invoice Currency Code" on Job Card page is editable when "Currency Code" has value
        Initialize();

        // [GIVEN] Job with "Currency Code" = RUB
        CreateJobWithCurrency(Job);

        // [WHEN] Open "Job Card" page
        JobCard.OpenEdit();
        JobCard.GotoRecord(Job);

        // [THEN] "Invoice Currency Code" is editable
        Assert.IsTrue(JobCard."Invoice Currency Code".Editable(), StrSubstNo('%1 must be editable', Job.FieldName("Invoice Currency Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobCardCurrencyCodeEditabled()
    var
        Job: Record Job;
        JobCard: TestPage "Job Card";
    begin
        // [FEATURE] [Currency Code] [UI]
        // [SCENARIO 218732] "Currency Code" on Job Card page is editable when "Invoice Currency Code" has value
        Initialize();

        // [GIVEN] Job with "Invoice Currency Code" = RUB
        LibraryJob.CreateJob(Job);
        Job.Validate("Invoice Currency Code", CreateCurrency());
        Job.Modify(true);

        // [WHEN] Open "Job Card" page
        JobCard.OpenEdit();
        JobCard.GotoRecord(Job);

        // [THEN] "Currency Code" is editable
        Assert.IsTrue(JobCard."Currency Code".Editable(), StrSubstNo('%1 must be editable', Job.FieldName("Currency Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithJobAndDiffUnitOfMeasureCode()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        JobLedgEntry: Record "Job Ledger Entry";
        UOMMgt: Codeunit "Unit of Measure Management";
        ItemNo: Code[20];
        DocNo: Code[20];
        ExpectedQty: Decimal;
    begin
        // [FEATURE] [Purch. Unit of Measure]
        // [SCENARIO 375427] The Quantity in Job Ledger Entry should be calculated in Base Unit Of Measure Code when posting Purchase Invoice with Job and different Unit Of Measure Code

        Initialize();
        // [GIVEN] Unit Of Measure "BOX" With "Qty. Per Unit Of Measure" = 10
        ItemNo := LibraryInventory.CreateItemNo();
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, ItemNo);
        // [GIVEN] Purchase Invoice with Job, "Unit Of Measure" = "BOX" and Quantity = 3
        CreatePurchaseDocument(PurchLine, PurchHeader."Document Type"::Invoice, ItemNo);
        PurchLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchLine.Modify(true);
        AttachJobTaskToPurchLine(PurchLine);
        ExpectedQty := UOMMgt.CalcBaseQty(PurchLine.Quantity, ItemUnitOfMeasure."Qty. per Unit of Measure");
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");

        // [WHEN] Post Purchase Invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Quantity in Job Ledger Entry = 30
        FindJobLedgerEntry(JobLedgEntry, DocNo, PurchLine."No.");
        JobLedgEntry.TestField(Quantity, ExpectedQty);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure JobCurrencyCodeUpdateByBilltoCustomer()
    var
        Job: Record Job;
        JobCard: TestPage "Job Card";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 379760] Clear Currency Code on Job Card when update Bill-To Customer with filled Currency Code
        Initialize();

        // [GIVEN] Job with Customer without Currency Code
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Currency Code updated
        Job."Currency Code" := CreateCurrency();
        Job.Modify(true);

        // [WHEN] Update Bill-to Customer field on Job Card by another Customer with Currency Code
        JobCard.OpenEdit();
        JobCard.FILTER.SetFilter("No.", Job."No.");
        JobCard."Bill-to Name".SetValue(CreateCustomer(CreateCurrency()));
        JobCard.OK().Invoke();

        // [THEN] Job."Currency Code" is empty
        Job.Find();
        Job.TestField("Currency Code", '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesCreateSerialNoPageHandler,EnterCustomizedSNPageHandler')]
    [Scope('OnPrem')]
    procedure SerialNoAssignedToJobPlanningLineFromJobLedgEntryAfterPurchOrderWithTrackingAndStrictLinkToJob()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgEntry: Record "Job Ledger Entry";
        InvNo: Code[20];
    begin
        // [FEATURE] [Item Tracking] [Serial No.]
        // [SCENARIO 382364] "Serial No." in Job Planning Line is equal the same field from Job Ledger Entry after posting Purchase Order with Item Tracking and "Job Planning Line No." defined

        Initialize();

        // [GIVEN] Job with Planning Line - "Usage Link" and Item "X" with Tracking by "Serial Nos."
        CreateJobWithPlanningUsageLinkAndSpecificItem(JobPlanningLine, CreateItemWithTrackingCode(false, true));

        // [GIVEN] Purchase Order with Item "X", Job ("Job Planning Line No." is defined to make strict link to Job) and Quantity = 1 (to have one "Serial No.")
        CreatePurchaseHeader(PurchHeader, PurchHeader."Document Type"::Order, '');
        CreatePurchLineWithExactQuantityAndJobLink(PurchLine, PurchHeader, PurchLine.Type::Item, JobPlanningLine."No.", JobPlanningLine, 1);
        LibraryVariableStorage.Enqueue(PurchLine.Quantity);
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        AssignItemTrackingLinesOnPurchaseOrder(PurchHeader);

        // [WHEN] Post Purchase Order
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] The value of "Serial No." in Job Ledger Entry is assigned
        FindJobLedgerEntry(JobLedgEntry, InvNo, JobPlanningLine."No.");
        JobLedgEntry.TestField("Serial No.");

        // [THEN] The value of "Serial No." in Job Planning Line is equal value in Job Ledger Entry
        JobPlanningLine.Find();
        JobPlanningLine.TestField("Serial No.", JobLedgEntry."Serial No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure LotNoAssignedToJobPlanningLineFromJobLedgEntryAfterPurchOrderWithTrackingAndStrictLinkToJob()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgEntry: Record "Job Ledger Entry";
        InvNo: Code[20];
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Lot No.]
        // [SCENARIO 382364] "Lot No." in Job Planning Line is equal the same field from Job Ledger Entry after posting Purchase Order with Item Tracking and "Job Planning Line No." defined

        Initialize();

        // [GIVEN] Job with Planning Line - "Usage Link" and Item "X" with Tracking by "Lot Nos."
        CreateJobWithPlanningUsageLinkAndSpecificItem(JobPlanningLine, CreateItemWithTrackingCode(true, false));

        // [GIVEN] Purchase Order with Item "X", Job ("Job Planning Line No." is defined to make strict link to Job)
        LibraryVariableStorage.Enqueue(false);
        LotNo := LibraryUtility.GenerateGUID();  // Assign in Global variable.
        LibraryVariableStorage.Enqueue(LotNo);
        CreatePurchaseDocument(PurchLine, PurchHeader."Document Type"::Order, JobPlanningLine."No.");
        UpdatePurchaseLine(PurchLine, JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", PurchLine."Job Line Type"::Budget);
        PurchLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        PurchLine.Modify(true);
        LibraryVariableStorage.Enqueue(PurchLine.Quantity);
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        AssignItemTrackingLinesOnPurchaseOrder(PurchHeader);

        // [WHEN] Post Purchase Order
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] The value of "Lot No." in Job Ledger Entry is assigned
        FindJobLedgerEntry(JobLedgEntry, InvNo, JobPlanningLine."No.");
        JobLedgEntry.TestField("Lot No.");

        // [THEN] The value of "Lot No." in Job Planning Line is equal value in Job Ledger Entry
        JobPlanningLine.Find();
        JobPlanningLine.TestField("Lot No.", JobLedgEntry."Lot No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostJobGLJournalVerifyOverBudget()
    var
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        GenJournalLine: Record "Gen. Journal Line";
        JobCue: Record "Job Cue";
        JobTask: Record "Job Task";
        JobCost: Decimal;
        InitialOverBudget: Integer;
        FinalOverBudget: Integer;
    begin
        // Check value of Job Ledger Entries and Job Planning Line exist or not after posting Job Journal Line.

        // [WHEN] Job with Job Task, Resource and Job Journal Line is created.
        Initialize();
        CreateJobWithJobTask(JobTask);
        JobCue.CalcFields("Jobs Over Budget");
        InitialOverBudget := JobCue."Jobs Over Budget";

        // [THEN] Verify job is not over budget as nothing has been consumed against it yet.
        Job.Get(JobTask."Job No.");
        Assert.AreEqual(false, Job."Over Budget", OverBudgetSetIncorrectlyErr);

        CreateJobJournalLine(
          LibraryJob.UsageLineTypeBoth(), JobJournalLine.Type::Resource, JobJournalLine, JobTask, LibraryResource.CreateResourceNo(),
          10, 10, 10);  // Using Random because value is not important.
        // [THEN] Verify job is not over budget as nothing has been consumed against it yet.
        Job.Get(JobTask."Job No.");
        Assert.IsFalse(Job."Over Budget", OverBudgetSetIncorrectlyErr);

        // [WHEN] Job Journal is Posted and additional Job Journal line is created and posted to push job over budget.
        LibraryJob.PostJobJournal(JobJournalLine);

        JobTask.CalcFields("Schedule (Total Cost)");
        JobCost := JobTask."Schedule (Total Cost)";

        CreateJobGLJournalLineFixedCost(GenJournalLine, JobTask, JobCost);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify "Over Budget" value in job table is now true.
        if Job.Get(JobTask."Job No.") then
            Assert.IsTrue(Job."Over Budget", OverBudgetSetIncorrectlyErr);

        // [THEN] Verify "Jobs Over Budget" value has increased by 1.
        JobCue.CalcFields("Jobs Over Budget");
        FinalOverBudget := JobCue."Jobs Over Budget";
        Assert.AreEqual(FinalOverBudget, InitialOverBudget + 1, JobCueIncorrectErr);

        // [WHEN] Job planning line is increased to make the job under budget.
        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.SetRange("Schedule Line", true);
        if JobPlanningLine.FindFirst() then begin
            JobPlanningLine.Validate(Quantity, JobPlanningLine.Quantity + 1000);
            JobPlanningLine.Modify(true);
        end;

        // [THEN] Verify "Over Budget" Value in job table is now true.
        if Job.Get(JobTask."Job No.") then
            Assert.IsFalse(Job."Over Budget", OverBudgetSetIncorrectlyErr);

        // [THEN] Verify "Jobs Over Budget" value has decreased by 1.
        JobCue.CalcFields("Jobs Over Budget");
        FinalOverBudget := JobCue."Jobs Over Budget";
        Assert.AreEqual(FinalOverBudget, InitialOverBudget, JobCueIncorrectErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure S492799_PostJobGLJournalVerifyApplyUsageLinkEnabled()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        JobCost: Decimal;
    begin
        // [SCENARIO 492799] Verify "Apply Usage Link" can be changed with "Over Budget" updated on validation.
        Initialize();

        // [GIVEN] Change Jobs Setup.
        DummyJobsSetup."Apply Usage Link by Default" := true;
        DummyJobsSetup.Modify();

        // [GIVEN] Job with Job Task, Resource and Job Journal Line is created.
        CreateJobWithJobTask(JobTask);

        // [THEN] Verify job is not over budget as nothing has been consumed against it yet.
        Job.Get(JobTask."Job No.");
        Assert.AreEqual(false, Job."Over Budget", OverBudgetSetIncorrectlyErr);

        CreateJobJournalLine(
          LibraryJob.UsageLineTypeBoth(), JobJournalLine.Type::Resource, JobJournalLine, JobTask, LibraryResource.CreateResourceNo(),
          10, 10, 10);  // Using Random because value is not important.
        // [THEN] Verify job is not over budget as nothing has been consumed against it yet.
        Job.Get(JobTask."Job No.");
        Assert.IsFalse(Job."Over Budget", OverBudgetSetIncorrectlyErr);

        // [WHEN] Job Journal is Posted and additional Job Journal line is created and posted to push job over budget.
        LibraryJob.PostJobJournal(JobJournalLine);

        JobTask.CalcFields("Schedule (Total Cost)");
        JobCost := JobTask."Schedule (Total Cost)";

        CreateJobGLJournalLineFixedCost(GenJournalLine, JobTask, JobCost);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify "Over Budget" value in job table is still false.
        if Job.Get(JobTask."Job No.") then
            Job.TestField("Over Budget", false);

        // [GIVEN] Mock that "Over Budget" is true.
        Job."Over Budget" := true;
        Job.Modify();

        // [GIVEN] "Apply Usage Link" is disabled.
        Job.Validate("Apply Usage Link", false);
        Job.Modify(true);

        // [WHEN] "Apply Usage Link" is enabled.
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [THEN] Verify "Over Budget" is updated to false.
        Job.Get(JobTask."Job No.");
        Job.TestField("Apply Usage Link", true);
        Job.TestField("Over Budget", false);

        // Restore Jobs Setup.
        DummyJobsSetup."Apply Usage Link by Default" := false;
        DummyJobsSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobRoleCenterTests()
    var
        JobTask: Record "Job Task";
        MyJob: Record "My Job";
        BusinessChartBuffer: Record "Business Chart Buffer";
        TempJob: Record Job temporary;
        JobChartMgt: Codeunit "Job Chart Mgt";
        ChartType: Option Point,,Bubble,Line,,StepLine,,,,,Column,StackedColumn,StackedColumn100,"Area",,StackedArea,StackedArea100,Pie,Doughnut,,,Range,,,,Radar,,,,,,,,Funnel;
        JobChartType: Option Profitability,"Actual to Budget Cost","Actual to Budget Price";
    begin
        // Check value of Job Ledger Entries and Job Planning Line exist or not after posting Job Journal Line.

        // [WHEN] Job with Job Task, Resource and Job Journal Line is created.
        Initialize();
        CreateJobWithJobTask(JobTask);
        Commit();

        MyJob.Init();
        MyJob."User ID" := UserId;
        MyJob."Job No." := JobTask."Job No.";
        MyJob.Insert();
        Commit();

        // [THEN] Job charts are can be created without errors.
        JobChartMgt.CreateJobChart(BusinessChartBuffer, TempJob, ChartType::Column, JobChartType::"Actual to Budget Cost");
        JobChartMgt.CreateJobChart(BusinessChartBuffer, TempJob, ChartType::Column, JobChartType::"Actual to Budget Price");
        JobChartMgt.CreateJobChart(BusinessChartBuffer, TempJob, ChartType::Column, JobChartType::Profitability);
    end;

    [Test]
    [HandlerFunctions('SerialNoItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandlerWithValidation,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostJobJournalLineWithoutJobPlanningLineNo()
    var
        Item: Record Item;
        Location: Record Location;
        Job: Record Job;
        JobTask: array[2] of Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
    begin
        // [FEATURE] [Job] [Reservation] [Item Tracking]
        // [SCENARIO 230236] when job has reserve for item and job journal line hasn't "Job Planning Line No." the journal line can be posted
        Initialize();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Item "I" with Serial No. tracking and Reserve = Always
        CreateSNTrackingReserveAlwaysItem(Item);

        // [GIVEN] Inventory of 2 units of "I" at location "L"
        CreateAndPostTwoItemJournalLinesWithTracking(Item."No.", Location.Code);

        // [GIVEN] Job with "Apply Usage Link" on and two tasks "T1" and "T2"
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask[1]);

        // [GIVEN] "Job Planning Line" for "T1" and 1 unit of "I" at "L" with "Line Type" = "Both Budget and Billable", reserved
        CreateJobPlanningLineWithItemAndLocation(
          JobPlanningLine, JobTask[1], JobPlanningLine."Line Type"::"Both Budget and Billable", Location.Code, Item."No.", 1);
        JobPlanningLine.AutoReserve();

        // [GIVEN] "Job Journal Line" for "T2" and 1 unit of "I" at "L" with "Line Type" is void, tracking assigned
        LibraryJob.CreateJobTask(Job, JobTask[2]);
        CreateJournalLineWithItemAndLocation(
          JobJournalLine, JobTask[2], JobJournalLine."Line Type"::" ", Location.Code, Item."No.", 1);

        LibraryVariableStorage.Enqueue(TrackingOption::SelectSerialNo); // for SerialNoItemTrackingLinesPageHandler
        JobJournalLine.OpenItemTrackingLines(false);

        // [WHEN] Post job journal
        // [THEN] Confirm dialogue with text "Usage will not be linked to the job planning line because the Line Type field is empty." occurs.
        LibraryVariableStorage.Enqueue(PostJournaLinesQst);
        LibraryVariableStorage.Enqueue(UsageWillNotBeLinkedQst);
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostInvtCostToGLPerPostingGroupLeavesJobNoBlank()
    var
        Item: Record Item;
        JobJournalLine: Record "Job Journal Line";
        GLEntry: Record "G/L Entry";
        GLRegister: Record "G/L Register";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Post Inventory Cost to G/L]
        // [SCENARIO 252104] Post Inventory Cost to G/L batch job run with "Per Posting Group" option leaves Job No. field blank on G/L entries.
        Initialize();

        // [GIVEN] Item with inventory.
        // [GIVEN] Cost is adjusted in order not to include the positive adjustment entry to the next run of Post Cost to G/L job.
        LibraryInventory.CreateItem(Item);
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LibraryRandom.RandIntInRange(20, 40), LibraryRandom.RandDec(10, 2));
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [GIVEN] Job "J" and a job planning line with the item.
        // [GIVEN] Posted job journal line with the item.
        CreateAndPostJobJournalWithItem(JobJournalLine, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Cost of the posted job journal line is adjusted.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [WHEN] Run "Post Inventory Cost to G/L" batch job with "Per Posting Group" option.
        DocumentNo := LibraryUtility.GenerateGUID();
        LibraryPostInventoryToGL.PostInvtCostToGL(true, WorkDate(), DocumentNo);

        // [THEN] Two G/L entries are created.
        GLRegister.FindLast();
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.RecordCount(GLEntry, 2);

        // [THEN] "Job No." on the G/L entries is blank.
        GLEntry.SetRange("Job No.", '');
        Assert.RecordCount(GLEntry, 2);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostInvtCostToGLPerEntryPopulatesJobNo()
    var
        Item: Record Item;
        JobJournalLine: Record "Job Journal Line";
        GLEntry: Record "G/L Entry";
    begin
        // [FEATURE] [Post Inventory Cost to G/L]
        // [SCENARIO 252104] Post Inventory Cost to G/L batch job run with "Per Entry" option populates Job No. field on G/L entries from value entries.
        Initialize();

        // [GIVEN] Item with inventory.
        LibraryInventory.CreateItem(Item);
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LibraryRandom.RandIntInRange(20, 40), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Job "J" and a job planning line with the item.
        // [GIVEN] Posted job journal line with the item.
        CreateAndPostJobJournalWithItem(JobJournalLine, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Cost of the posted job journal line is adjusted.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [WHEN] Run "Post Inventory Cost to G/L" batch job with "Per Entry" option.
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Two G/L entries are created.
        GLEntry.SetRange("Document No.", JobJournalLine."Document No.");
        Assert.RecordCount(GLEntry, 2);

        // [THEN] "Job No." on the G/L entries is equal to "J".
        GLEntry.SetRange("Job No.", JobJournalLine."Job No.");
        Assert.RecordCount(GLEntry, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderFCYWithJob()
    var
        Item: Record Item;
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgEntry: Record "Job Ledger Entry";
        DocNo: Code[20];
        ExchangeRate: array[2] of Decimal;
        PlanningDate: Date;
        PostingDate: Date;
        RemainingQty: Integer;
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 299333] "Posted Total Cost (LCY)" in job planning line relies on "Posting Date" of posting job ledger entry
        Initialize();

        // [GIVEN] Currency "C" with exchange rates: 100 at date Jan 1st, and 200 and Jan 2nd.
        RemainingQty := LibraryRandom.RandIntInRange(5, 10);

        PlanningDate := WorkDate() - 1;
        PostingDate := WorkDate();

        LibraryInventory.CreateItem(Item);
        ExchangeRate[1] := 1 / LibraryRandom.RandDecInRange(10, 20, 2);
        ExchangeRate[2] := ExchangeRate[1] / 5;

        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, PlanningDate, ExchangeRate[1], ExchangeRate[1]);
        LibraryERM.CreateExchangeRate(Currency.Code, PostingDate, ExchangeRate[2], ExchangeRate[2]);

        // [GIVEN] Given Job "J" with "Currency Code" = "C", "Planning Date" = Jan 1st and "Usage Link" = TRUE
        LibraryJob.CreateJob(Job);
        Job.Validate("Currency Code", Currency.Code);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("Planning Date", PlanningDate);
        JobPlanningLine.Validate("Currency Code", Currency.Code);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate(Quantity, RemainingQty * 3);
        JobPlanningLine.Validate("Unit Cost", LibraryRandom.RandDecInRange(10, 20, 2));
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);

        // [GIVEN] Purchase order with "Currency Code" = "C", "Posting Date" = Jan 2nd, "Total Cost" = 300 and linked to job "J"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Currency Code", Currency.Code);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, JobPlanningLine."No.", RemainingQty);

        PurchaseLine.Validate("Direct Unit Cost", JobPlanningLine."Unit Cost");
        PurchaseLine.Validate("Job No.", JobPlanningLine."Job No.");
        PurchaseLine.Validate("Job Task No.", JobPlanningLine."Job Task No.");
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        PurchaseLine.Modify(true);

        // [WHEN] Post purchase order
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] "Total Cost (LCY)" = 300 * 200 = 60000 in posted job ledger entry
        FindJobLedgerEntry(JobLedgEntry, DocNo, PurchaseLine."No.");
        JobLedgEntry.TestField("Total Cost (LCY)", Round(PurchaseLine."Direct Unit Cost" / ExchangeRate[2] * PurchaseLine.Quantity));

        // [THEN] "Posted Total Cost (LCY)" = 300 * 200 = 60000 in job planning line of job "J"
        JobPlanningLine.Find();
        JobPlanningLine.TestField("Posted Total Cost (LCY)", JobLedgEntry."Total Cost (LCY)");
        // Bug 307929: Posted Total CostL CY of Job Planning Line is wrong
        JobPlanningLine.TestField("Remaining Total Cost (LCY)", JobLedgEntry."Total Cost (LCY)" * 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShouldSetDefaultBinCodeIfAvailableWhenLocationChanges()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        LocationA: Record Location;
        LocationB: Record Location;
        BinA: Record Bin;
        BinB: Record Bin;
    begin
        // [SCENARIO] Should set the job planning line bin code when the item is set and the location changes to a location with a default bin code.
        InitSetupForDefaultBinCodeTests(ItemA, ItemB, JobPlanningLine, LocationA, LocationB, BinA, BinB);

        // [WHEN] Setting item A on the job journal line.
        JobPlanningLine.Validate("No.", ItemA."No.");

        // [THEN] The bin code is not set.
        Assert.AreEqual(JobPlanningLine."Bin Code", '', 'Expected default bin to not be set. ');

        // [WHEN] Setting item A on the job journal line.
        JobPlanningLine.Validate("Location Code", LocationB.Code);

        // [THEN] The bin code is not set.
        Assert.AreEqual(JobPlanningLine."Bin Code", '', 'Expected default bin to not be set. ');

        // [WHEN] Setting location A on the job journal line.
        JobPlanningLine.Validate("Location Code", LocationA.Code);

        // [THEN] The bin code is populated with the default bin code for item A.
        Assert.AreEqual(JobPlanningLine."Bin Code", BinA.Code, 'Expected default bin to be set. ');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShouldSetDefaultBinCodeIfAvailableWhenItemChanges()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        LocationA: Record Location;
        LocationB: Record Location;
        BinA: Record Bin;
        BinB: Record Bin;
    begin
        // [SCENARIO] Should set the job planning line bin code when the location is set and the item changes to an item with a default bin code.
        InitSetupForDefaultBinCodeTests(ItemA, ItemB, JobPlanningLine, LocationA, LocationB, BinA, BinB);

        // [WHEN] Setting item B on the job planning line.
        JobPlanningLine.Validate("No.", ItemB."No.");

        // [THEN] The bin code is not set.
        Assert.AreEqual(JobPlanningLine."Bin Code", '', 'Expected default bin to not be set. ');

        // [WHEN] Setting location A on the job journal line.
        JobPlanningLine.Validate("Location Code", LocationA.Code);

        // [THEN] The bin code is not set.
        Assert.AreEqual(JobPlanningLine."Bin Code", '', 'Expected default bin to not be set. ');

        // [WHEN] Setting item A on the job journal line.
        JobPlanningLine.Validate("No.", ItemA."No.");

        // [THEN] The bin code is populated with the default bin code for item A.
        Assert.AreEqual(JobPlanningLine."Bin Code", BinA.Code, 'Expected default bin to be set. ');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShouldClearBinCodeWhenLocationChanges()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        LocationA: Record Location;
        LocationB: Record Location;
        BinA: Record Bin;
        BinB: Record Bin;
    begin
        // [SCENARIO] Should clear the job planning line bin code when the location changes to a location with no default bin code.
        InitSetupForDefaultBinCodeTests(ItemA, ItemB, JobPlanningLine, LocationA, LocationB, BinA, BinB);

        // [WHEN] Setting item A and location A on the job planning line.
        JobPlanningLine.Validate("No.", ItemA."No.");
        JobPlanningLine.Validate("Location Code", LocationA.Code);

        // [THEN] The bin code is populated with the default bin code for item A.
        Assert.AreEqual(JobPlanningLine."Bin Code", BinA.Code, 'Expected default bin to be set. ');

        // [WHEN] Setting location B on the job journal line.
        JobPlanningLine.Validate("Location Code", LocationB.Code);

        // [THEN] The bin code is cleared.
        Assert.AreEqual(JobPlanningLine."Bin Code", '', 'Expected default bin to be cleared. ');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShouldClearBinCodeWhenItemChanges()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        LocationA: Record Location;
        LocationB: Record Location;
        BinA: Record Bin;
        BinB: Record Bin;
    begin
        // [SCENARIO] Should clear the job planning line bin code when the item changes to an item with no default bin code.
        InitSetupForDefaultBinCodeTests(ItemA, ItemB, JobPlanningLine, LocationA, LocationB, BinA, BinB);

        // [WHEN] Setting item A and location A on the job planning line.
        JobPlanningLine.Validate("No.", ItemA."No.");
        JobPlanningLine.Validate("Location Code", LocationA.Code);

        // [THEN] The bin code is populated with the default bin code for item A.
        Assert.AreEqual(JobPlanningLine."Bin Code", BinA.Code, 'Expected default bin to be set. ');

        // [WHEN] When setting item B.
        JobPlanningLine.Validate("No.", ItemB."No.");

        // [THEN] The bin code is cleared.
        Assert.AreEqual(JobPlanningLine."Bin Code", '', 'Expected default bin to be cleared. ');
    end;

    [Test]
    procedure PostingPurchaseOrderWithAlternateUoMAndJob()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Invoice] [Item Unit of Measure] [Unit Price]
        // [SCENARIO 395884] Unit Price on job planning line created by posting purchase invoice respects item unit of measure.
        Initialize();

        // [GIVEN] Item with unit price = 8.0, base unit of measure = "PCS".
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);

        // [GIVEN] Alternate Unit of Measure "BOX". 1 "BOX" = 10 "PCS".
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Create job, job task and job planning line.
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLine(
          JobPlanningLine, JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, Item."No.",
          LibraryRandom.RandInt(10), Item."Unit Cost", Item."Unit Price");

        // [GIVEN] Create purchase invoice for 1 "BOX", link it to the job.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Job Line Type", PurchaseLine."Job Line Type"::Billable);
        PurchaseLine.Modify(true);

        // [WHEN] Post the purchase invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] A new job planning line is created in base unit of measure "PCS".
        // [THEN] The job planning line has Unit Price = Unit Price (LCY) = Item."Unit Price".
        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.SetRange("Line Type", JobPlanningLine."Line Type"::Billable);
        JobPlanningLine.FindFirst();
        JobPlanningLine.TestField("Unit of Measure Code", Item."Base Unit of Measure");
        JobPlanningLine.TestField("Unit Price", Item."Unit Price");
        JobPlanningLine.TestField("Unit Price (LCY)", Item."Unit Price");
    end;

    [Test]
    procedure PurchOrderPostLinkedJobPlanningLineDiffUOM1()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        JobTask: Record "Job Task";
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 422599] Posting of Purchase Document line in Base UOM linked withn Job Planning line with other UOM
        Initialize();

        // [GIVEN] Item "I" with "Base Unit of Measure" Code = PCS, other unit of measure Box = 50 PCS.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 50);

        // [GIVEN] Create job, job task and job planning line with Item "I" 2 Box.
        CreateJobWithJobTask(JobTask);
        Job.Get(JobTask."Job No.");
        Job.Validate("Apply Usage Link", true);
        Job.Modify();
        CreateJobPlanningLine(
          JobPlanningLine, JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, Item."No.",
          2, Item."Unit Cost", Item."Unit Price");
        JobPlanningLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        JobPlanningLine.Modify();

        // [WHEN] Create purchase invoice for 1 "PCS", link it to the job planning line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        PurchaseLine.Modify(true);

        // [THEN] Purchase Line "Job Remaining Qty." = 1.98 (2 Box - 1 PCS) ,"Job Remaining Qty. (Base)" = 99 (2 Box(50) - 1 Pcs)
        PurchaseLine.TestField("Job Remaining Qty.", 1.98);
        PurchaseLine.TestField("Job Remaining Qty. (Base)", 99);

        // [WHEN] Post the purchase invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The job planning line Quantity - 2, "Unit of Measure" = Box
        JobPlanningLine.FIND();
        JobPlanningLine.TestField(Quantity, 2);
        JobPlanningLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);
    end;

    [Test]
    procedure PurchOrderPostLinkedJobPlanningLineDiffUOM2()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        JobTask: Record "Job Task";
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 422599] Posting of Purchase Document line in UOM linked withn Job Planning line with Base UOM
        Initialize();

        // [GIVEN] Item "I" with "Base Unit of Measure" Code = PCS, other unit of measure Box = 50 PCS.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 50);

        // [GIVEN] Create job, job task and job planning line with Item "I" 60 PCS.
        CreateJobWithJobTask(JobTask);
        Job.Get(JobTask."Job No.");
        Job.Validate("Apply Usage Link", true);
        Job.Modify();
        CreateJobPlanningLine(
          JobPlanningLine, JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, Item."No.",
          60, Item."Unit Cost", Item."Unit Price");

        // [WHEN] Create purchase invoice for 1 "BOX", link it to the job planning line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        PurchaseLine.Modify(true);

        // [THEN] Purchase Line Purchase Line "Job Remaining Qty." = 10 ,"Job Remaining Qty. (Base)" = 10 (60 - 1 Box(50 PCS))
        PurchaseLine.TestField("Job Remaining Qty.", 10);
        PurchaseLine.TestField("Job Remaining Qty. (Base)", 10);

        // [WHEN] Post the purchase invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The job planning line Quantity - 60, "Unit of Measure" = PCS
        JobPlanningLine.FIND();
        JobPlanningLine.TestField(Quantity, 60);
        JobPlanningLine.TestField("Unit of Measure Code", Item."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPreviewJobJournal()
    var
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
        ResLegerEntry: Record "Res. Ledger Entry";
        JobJournalPost: Codeunit "Job Jnl.-Post";
        GLPostingPreview: TestPage "G/L Posting Preview";
        RandomInput: Decimal;
    begin
        // Check value of Job Ledger Entries and Job Planning Line exist or not after posting Job Journal Line.

        // 1. Setup: Create Job with Job Task, Resource and Job Journal Line.
        Initialize();
        RandomInput := LibraryRandom.RandDec(10, 2);  // Using Random Value for Quantity,Unit Cost and Unit Price.
        CreateJobWithJobTask(JobTask);
        CreateJobJournalLine(
          LibraryJob.UsageLineTypeBoth(), JobJournalLine.Type::Resource, JobJournalLine, JobTask, LibraryResource.CreateResourceNo(),
          RandomInput, RandomInput, RandomInput);  // Using Random because value is not important.
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror JobJournalPost.Preview(JobJournalLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the journal is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, JobLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ResLegerEntry.TableCaption(), 1);

        Assert.IsFalse(GLPostingPreview.Next(), 'No more entries should exist.');
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    procedure PostJobJournalAndCheckRegister()
    var
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobRegister: Record "Job Register";
        JobsSetup: Record "Jobs Setup";
        ResLedgerEntry: Record "Res. Ledger Entry";
        ResourceRegister: Record "Resource Register";
        ResourcesSetup: Record "Resources Setup";
        JobJournalPost: Codeunit "Job Jnl.-Post";
        RandomInput: Decimal;
    begin
        // Check value of Job Ledger Entries and Job Planning Line exist or not after posting Job Journal Line.

        // 1. Setup: Create Job with Job Task, Resource and Job Journal Line with 3 lines.
        Initialize();
        RandomInput := LibraryRandom.RandDec(10, 2);  // Using Random Value for Quantity,Unit Cost and Unit Price.
        CreateJobWithJobTask(JobTask);
        CreateJobJournalLine(
          LibraryJob.UsageLineTypeBoth(), JobJournalLine.Type::Resource, JobJournalLine, JobTask, LibraryResource.CreateResourceNo(),
          RandomInput, RandomInput, RandomInput);  // Using Random because value is not important.
        CreateJobJournalLine(
          LibraryJob.UsageLineTypeBoth(), JobJournalLine.Type::Resource, JobJournalLine, JobTask, LibraryResource.CreateResourceNo(),
          RandomInput, RandomInput, RandomInput);  // Using Random because value is not important.
        CreateJobJournalLine(
          LibraryJob.UsageLineTypeBoth(), JobJournalLine.Type::Resource, JobJournalLine, JobTask, LibraryResource.CreateResourceNo(),
          RandomInput, RandomInput, RandomInput);  // Using Random because value is not important.
        Commit();

        // [WHEN] Post job journal
        JobJournalPost.Run(JobJournalLine);

        // [THEN] Check the entries that will be created when the journal is posted
        JobRegister.FindLast();
        JobLedgerEntry.SetRange("Entry No.", JobRegister."From Entry No.", JobRegister."To Entry No.");
        if JobsSetup.UseLegacyPosting() then
            Assert.AreEqual(
                JobLedgerEntry.Count(), JobRegister."To Entry No." - JobRegister."From Entry No." + 1, 'incorrect number of job entries');
        JobLedgerEntry.FindFirst();
        Assert.AreEqual(JobLedgerEntry."Entry No.", JobRegister."From Entry No.", 'incorrect job register From Entry No.');
        JobLedgerEntry.FindLast();
        Assert.AreEqual(JobLedgerEntry."Entry No.", JobRegister."To Entry No.", 'incorrect job register To Entry No.');

        ResourceRegister.FindLast();
        ResLedgerEntry.SetRange("Entry No.", ResourceRegister."From Entry No.", ResourceRegister."To Entry No.");
        if ResourcesSetup.UseLegacyPosting() then
            Assert.AreEqual(
                JobLedgerEntry.Count(), ResourceRegister."To Entry No." - ResourceRegister."From Entry No." + 1, 'incorrect number of resource entries');
        ResLedgerEntry.FindFirst();
        Assert.AreEqual(ResLedgerEntry."Entry No.", ResourceRegister."From Entry No.", 'incorrect resource register From Entry No.');
        ResLedgerEntry.FindLast();
        Assert.AreEqual(ResLedgerEntry."Entry No.", ResourceRegister."To Entry No.", 'incorrect resource register To Entry No.');
    end;

    local procedure Initialize()
    var
        NoSeries: Record "No. Series";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Posting");
        // Clear the needed global variables.
        ClearGlobals();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Posting");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        NoSeries.Get(LibraryJob.GetJobTestNoSeries());
        NoSeries."Manual Nos." := true;
        NoSeries.Modify();

        DummyJobsSetup."Allow Sched/Contract Lines Def" := false;
        DummyJobsSetup."Apply Usage Link by Default" := false;
        DummyJobsSetup."Job Nos." := LibraryJob.GetJobTestNoSeries();
        DummyJobsSetup.Modify();
        LibraryJob.SetJobNoSeriesCode();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Posting");
    end;

    local procedure VerifyGLPostingPreviewLine(GLPostingPreview: TestPage "G/L Posting Preview"; TableName: Text; ExpectedEntryCount: Integer)
    begin
        Assert.AreEqual(TableName, GLPostingPreview."Table Name".Value, StrSubstNo('A record for Table Name %1 was not found.', TableName));
        Assert.AreEqual(ExpectedEntryCount, GLPostingPreview."No. of Records".AsInteger(),
          StrSubstNo('Table Name %1 Unexpected number of records.', TableName));
    end;

    local procedure AssignGlobalVariables(LineAmountLCY: Decimal; TotalCostLCY: Decimal; LineAmount: Decimal; TotalCost: Decimal)
    begin
        // Assigning global variables as required in Page Handler.
        Amount := Amount + LineAmountLCY;
        Cost := Cost + TotalCostLCY;
        AmountFCY := AmountFCY + LineAmount;
        CostFCY := CostFCY + TotalCost;
    end;

    local procedure AssignItemTrackingLinesOnPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines."Item Tracking Lines".Invoke();
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
    end;

    local procedure AssignItemTrackingLinesOnJobJournal(var JobJournalLine: Record "Job Journal Line")
    var
        JobJournal: TestPage "Job Journal";
    begin
        Commit();
        JobJournal.OpenEdit();
        JobJournal.CurrentJnlBatchName.SetValue(JobJournalLine."Journal Batch Name");
        JobJournal.ItemTrackingLines.Invoke();
        JobJournalLine.Get(JobJournalLine."Journal Template Name", JobJournalLine."Journal Batch Name", JobJournalLine."Line No.");
    end;

    local procedure ClearGlobals()
    begin
        JournalTemplateName := '';
        Amount := 0;
        Cost := 0;
        AmountFCY := 0;
        CostFCY := 0;
        InvoicedCostFCY := 0;
        VerifyTrackingLine := false;
        Clear(SerialNo);
    end;

    local procedure CreateAndPostSalesInvoice(var JobPlanningLine: Record "Job Planning Line"; CustomerNo: Code[20])
    var
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        PostSalesInvoice(CustomerNo);
    end;

    local procedure CreateAndReceivePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        JobTask: Record "Job Task";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateJobWithJobTask(JobTask);
        CreatePurchaseOrderWithJob(
          PurchaseLine, PurchaseLine."Document Type"::Order, JobTask, ItemNo, PurchaseLine."Job Line Type"::Billable);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateAndUpdateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; JobLineType: Enum "Job Planning Line Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibraryJob.CreateJobPlanningLine(JobLineType, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", No);
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Modify(true);
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

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(50, 2));  // Use Random value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithAutomaticExtText(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        Commit();
    end;

    local procedure CreateItemWithNewUOM(var ItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
        // Create Item with one more Unit of Measure Code where Qty. per Unit of Measure is 1.
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, CreateItem(), 1);
    end;

    local procedure CreateItemWithInventoryAdjustmentAccount(): Code[20]
    begin
        exit(CreateItem());
    end;

    local procedure CreateItemWithTrackingCode(LotSpecificTracking: Boolean; SNSpecificTracking: Boolean): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(CreateItem());
        Item."Serial Nos." := CreateNoSeries();
        Item.Validate("Item Tracking Code", CreateTrackingCodeWithLotSpecific(LotSpecificTracking, SNSpecificTracking));
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));  // Take Random value for Last Direct Cost.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeriesCode: Code[20];
    begin
        Any.SetDefaultSeed();
        NoSeriesCode := CopyStr(Any.AlphabeticText(10), 1, 10);
        LibraryNoSeries.CreateNoSeries(NoSeriesCode, true, true, false);
        exit(NoSeriesCode)
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20])
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, ItemNo, UnitOfMeasure.Code, LibraryRandom.RandIntInRange(3, 10));
    end;

    local procedure CreateLocationWithBin(var Bin: Record Bin)
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);

        LibraryWarehouse.CreateBin(
          Bin, Location.Code, LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), '', '');
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, '');
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
    end;

    local procedure CreatePurchLineWithExactQuantityAndJobLink(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; JobPlanningLine: Record "Job Planning Line"; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        UpdatePurchaseLine(PurchaseLine, JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", PurchaseLine."Job Line Type"::Budget);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInDecimalRange(100, 200, 2));
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        // Create Purchase Line with Random Quantity and Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithJob(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; JobTask: Record "Job Task"; ItemNo: Code[20]; JobLineType: Enum "Job Line Type")
    begin
        CreatePurchaseDocument(PurchaseLine, DocumentType, ItemNo);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));  // Use Random value for Direct Unit Cost.
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Job Line Type", JobLineType);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseDocumentWithJobAndItemTracking(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; JobLineType: Enum "Job Line Type"; LotSpecificTracking: Boolean; SNSpecificTracking: Boolean)
    var
        JobTask: Record "Job Task";
    begin
        // Create a Job and Job Task, Create Purchase Order With Job, Update General Posting Setup and assign Item Tracking Lines on Purchase Order.
        CreateJobWithJobTask(JobTask);
        CreatePurchaseDocument(PurchaseLine, DocumentType, CreateItemWithTrackingCode(LotSpecificTracking, SNSpecificTracking));
        UpdatePurchaseLine(PurchaseLine, JobTask."Job No.", JobTask."Job Task No.", JobLineType);
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);
    end;

    local procedure CreateJobCard(Job: Record Job) JobNo: Code[20]
    var
        JobCard: TestPage "Job Card";
    begin
        JobCard.OpenNew();
        JobCard.Description.Activate(); // Need to change focus to get Job No. assigned.
        JobNo := JobCard."No.".Value();
        JobCard.OK().Invoke();

        JobCard.OpenEdit(); // Need to reopen page to refresh fields.
        JobCard.FILTER.SetFilter("No.", JobNo);
        JobCard."Sell-to Customer No.".SetValue(Job."Sell-to Customer No.");
        JobCard."Person Responsible".SetValue(Job."Person Responsible");
        JobCard."Job Posting Group".SetValue(Job."Job Posting Group");
        JobCard."WIP Method".SetValue(Job."WIP Method");
        JobCard.Status.SetValue(Job.Status);
        JobCard.OK().Invoke();
    end;

    local procedure CreateJobJournalLine(LineType: Enum "Job Line Type"; ConsumableType: Enum "Job Planning Line Type"; var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task"; No: Code[20]; Quantity: Decimal; UnitCost: Decimal; UnitPrice: Decimal)
    begin
        LibraryJob.CreateJobJournalLineForType(LineType, ConsumableType, JobTask, JobJournalLine);
        JobJournalLine.Validate("No.", No);
        JobJournalLine.Validate(Quantity, Quantity);
        JobJournalLine.Validate("Unit Cost", UnitCost);
        JobJournalLine.Validate("Unit Price", UnitPrice);
        JobJournalLine.Modify(true);
    end;

    local procedure CreateJobJournalLinesForDifferentType(Job: Record Job; var JobJournalLine: Record "Job Journal Line")
    var
        JobTask: Record "Job Task";
        Quantity: Decimal;
        UnitCost: Decimal;
        UnitPrice: Decimal;
    begin
        LibraryJob.CreateJobTask(Job, JobTask);

        // Assigning Random Values to variables because the values of Unit Price and Unit Cost should be different and to have same values for all types of Job Planning Lines.
        Quantity := LibraryRandom.RandInt(10);
        UnitCost := LibraryRandom.RandDec(50, 2);
        UnitPrice := LibraryRandom.RandDec(100, 2);
        CreateJobJournalLine(
          LibraryJob.UsageLineTypeSchedule(), JobJournalLine.Type::Resource, JobJournalLine, JobTask,
          LibraryResource.CreateResourceNo(), Quantity, UnitCost, UnitPrice);
        CreateJobJournalLine(
          LibraryJob.UsageLineTypeSchedule(), JobJournalLine.Type::Item, JobJournalLine, JobTask,
          CreateItemWithInventoryAdjustmentAccount(), Quantity, UnitCost, UnitPrice);
        CreateJobJournalLine(
          LibraryJob.UsageLineTypeSchedule(), JobJournalLine.Type::"G/L Account", JobJournalLine, JobTask,
          LibraryERM.CreateGLAccountWithSalesSetup(), Quantity, UnitCost, UnitPrice);
        AssignGlobalVariables(
          JobJournalLine."Line Amount (LCY)", JobJournalLine."Total Cost (LCY)", JobJournalLine."Line Amount", JobJournalLine."Total Cost");  // Assigning global variables as required in Page Handler.
    end;

    local procedure CreateJobJournalLineForItem(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task"; LineType: Enum "Job Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibraryJob.CreateJobJournalLine(LineType, JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", No);
        JobJournalLine.Validate(Quantity, Quantity);
        JobJournalLine.Modify(true);
    end;

    local procedure CreateJobJournalLineWithItemTracking(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task"; No: Code[20]; Quantity: Decimal)
    begin
        CreateJobJournalLineForItem(JobJournalLine, JobTask, JobJournalLine."Line Type"::"Both Budget and Billable", No, Quantity);
        JournalTemplateName := JobJournalLine."Journal Template Name";  // Assign in Global variable.
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

    local procedure CreateJobPlanningLinesForDifferentType(Job: Record Job; var JobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
        Quantity: Decimal;
        UnitCost: Decimal;
        UnitPrice: Decimal;
    begin
        LibraryJob.CreateJobTask(Job, JobTask);

        // Assigning Random Values to variables because the values of Unit Price and Unit Cost should be different and to have same values for all types of Job Planning Lines.
        Quantity := LibraryRandom.RandInt(10);
        UnitCost := LibraryRandom.RandDec(50, 2);
        UnitPrice := LibraryRandom.RandDec(100, 2);
        CreateJobPlanningLine(
          JobPlanningLine, LibraryJob.PlanningLineTypeContract(), LibraryJob.ResourceType(), JobTask, LibraryResource.CreateResourceNo(),
          Quantity, UnitCost, UnitPrice);
        CreateJobPlanningLine(
          JobPlanningLine, LibraryJob.PlanningLineTypeContract(), LibraryJob.ItemType(), JobTask, CreateItemWithInventoryAdjustmentAccount(),
          Quantity, UnitCost, UnitPrice);
        CreateJobPlanningLine(
          JobPlanningLine, LibraryJob.PlanningLineTypeContract(), LibraryJob.GLAccountType(), JobTask,
          LibraryERM.CreateGLAccountWithSalesSetup(), Quantity, UnitCost, UnitPrice);
        AssignGlobalVariables(
          JobPlanningLine."Line Amount (LCY)", JobPlanningLine."Total Cost (LCY)", JobPlanningLine."Line Amount",
          JobPlanningLine."Total Cost");  // Assigning global variables as required in Page Handler.
    end;

    local procedure CreateJobWithCurrency(var Job: Record Job)
    begin
        LibraryJob.CreateJob(Job, CreateCustomer(''));  // Blank value for Currency Code.
        Job.Validate("Currency Code", CreateCurrency());
        Job.Modify(true);
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job, CreateCustomer(''));  // Blank value for Currency Code.
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobWithPlanningUsageLink(var JobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);

        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobWithPlanningUsageLinkAndSpecificItem(var JobPlanningLine: Record "Job Planning Line"; ItemNo: Code[20])
    var
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);

        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(100));
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateMultipleItemJournalLines(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; NoOfLines: Integer) TotalAmount: Decimal
    var
        ItemJournalBatch: Record "Item Journal Batch";
        Counter: Integer;
        UnitAmount: Decimal;
    begin
        CreateItemJournalBatch(ItemJournalBatch);
        for Counter := 1 to NoOfLines do begin
            UnitAmount := UnitAmount + LibraryRandom.RandInt(10);  // To have different unit amounts on item Journal Lines.
            TotalAmount := TotalAmount + UnitAmount;  // Required to verify Unit Cost on Item Card.
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
              ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, 1);  // Using 1 for Quantity as value is important for test.
            ItemJournalLine.Validate("Document No.", ItemJournalLine."Journal Batch Name" + Format(ItemJournalLine."Line No."));  // Value is important for test for verification.
            ItemJournalLine.Validate("Unit Amount", UnitAmount);
            ItemJournalLine.Modify(true);
        end;
    end;

    local procedure CreatePurchaseLineForPlan(var PurchaseLine: Record "Purchase Line"; JobPlanningLine: Record "Job Planning Line"; Bin: Record Bin)
    begin
        LibraryJob.CreatePurchaseLineForPlan(JobPlanningLine, PurchaseLine."Job Line Type"::Budget, 1, PurchaseLine);
        PurchaseLine.Validate("Location Code", Bin."Location Code");
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateJob(var Job: Record Job; JobStatus: Enum "Job Status")
    var
        JobWIPMethod: Record "Job WIP Method";
        Resource: Record Resource;
    begin
        // Find Resource and Job WIP Method.
        Resource.SetRange(Type, Resource.Type::Person);
        LibraryResource.FindResource(Resource);
        JobWIPMethod.FindFirst();

        // Create a Job.
        LibraryJob.CreateJob(Job);
        Job.Validate(Status, JobStatus);
        Job.Validate("Person Responsible", Resource."No.");
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Modify(true);
    end;

    local procedure CreateJobGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; JobTask: Record "Job Task")
    begin
        LibraryJob.CreateJobGLJournalLine(GenJournalLine."Job Line Type"::Billable, JobTask, GenJournalLine);
        GenJournalLine.Validate("Job Unit Price (LCY)", LibraryRandom.RandDec(10, 2)); // Taking random value for Job Unit Price.
        GenJournalLine.Modify(true);
    end;

    local procedure CreateTrackingCodeWithLotSpecific(LotSpecificTracking: Boolean; SNSpecificTracking: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SNSpecificTracking, LotSpecificTracking);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateJobGLJournalLineFixedCost(var GenJournalLine: Record "Gen. Journal Line"; JobTask: Record "Job Task"; JobPrice: Decimal)
    begin
        LibraryJob.CreateJobGLJournalLine(GenJournalLine."Job Line Type"::Billable, JobTask, GenJournalLine);
        GenJournalLine.Validate("Job Unit Price (LCY)", JobPrice);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostInvtAdjustmentWithUnitCost(ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Qty);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostTwoItemJournalLinesWithTracking(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Item Tracking Lines page is handled in SerialNoItemTrackingLinesPageHandler.
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemNo, LocationCode, ItemJournalLine."Entry Type"::"Positive Adjmt.");
        LibraryVariableStorage.Enqueue(TrackingOption::AssignManualSN);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID());
        ItemJournalLine.OpenItemTrackingLines(false);
        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemNo, LocationCode, ItemJournalLine."Entry Type"::"Positive Adjmt.");
        LibraryVariableStorage.Enqueue(TrackingOption::AssignManualSN);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID());
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateSNTrackingReserveAlwaysItem(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
    end;

    local procedure CreateJobPlanningLineWithItemAndLocation(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; LineType: Enum "Job Planning Line Line Type"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryJob.CreateJobPlanningLine(LineType, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("Location Code", LocationCode);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJournalLineWithItemAndLocation(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task"; LineType: Enum "Job Line Type"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryJob.CreateJobJournalLine(LineType, JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", ItemNo);
        JobJournalLine.Validate("Location Code", LocationCode);
        JobJournalLine.Validate(Quantity, Quantity);
        JobJournalLine.Modify(true);
    end;

    local procedure CreateAndPostJobJournalWithItem(var JobJournalLine: Record "Job Journal Line"; ItemNo: Code[20]; Qty: Decimal)
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLine(
          JobPlanningLine, LibraryJob.PlanningLineTypeSchedule(), JobPlanningLine.Type::Item, JobTask, ItemNo, Qty, 0, 0);
        CreateJobJournalLineForItem(
          JobJournalLine, JobTask, LibraryJob.UsageLineTypeSchedule(), ItemNo, Qty);
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure FindDimensionValue(GlobalDimensionCode: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetRange("Dimension Code", GlobalDimensionCode);
        DimensionValue.FindLast();
        exit(DimensionValue.Code);
    end;

    local procedure CreateCustomerWithCurrency(var CustomerNo: Code[20]; var CurrencyCode: Code[10])
    begin
        CurrencyCode := CreateCurrency();
        CustomerNo := CreateCustomer(CurrencyCode);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20]; LocationCode: Code[10]; EntryType: Enum "Item Ledger Entry Type")
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, 1);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure FindJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; DocumentNo: Code[20]; No: Code[20])
    begin
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.SetRange("No.", No);
        JobLedgerEntry.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
    end;

    local procedure GenerateJobNo(): Code[20]
    var
        Job: Record Job;
    begin
        exit(
          CopyStr(
            LibraryUtility.GenerateRandomCode(Job.FieldNo("No."), DATABASE::Job), 1,
            LibraryUtility.GetFieldLength(DATABASE::Job, Job.FieldNo("No."))));
    end;

    local procedure ModifyQtyPerUnitOfMeasure(ItemUnitOfMeasure: Record "Item Unit of Measure"; QtyPerUnitOfMeasure: Decimal)
    begin
        ItemUnitOfMeasure.Validate("Qty. per Unit of Measure", QtyPerUnitOfMeasure);
        ItemUnitOfMeasure.Modify(true);
    end;

    local procedure OpenJobCard(JobNo: Code[20])
    var
        JobCard: TestPage "Job Card";
    begin
        JobCard.OpenEdit();
        JobCard.FILTER.SetFilter("No.", JobNo);
        JobCard."&Statistics".Invoke();
        JobCard.OK().Invoke();
    end;

    local procedure OpenJobTaskLines(JobNo: Code[20])
    var
        JobTaskLines: TestPage "Job Task Lines";
    begin
        JobTaskLines.OpenEdit();
        JobTaskLines.FILTER.SetFilter("Job No.", JobNo);
        JobTaskLines.JobTaskStatistics.Invoke();
        JobTaskLines.OK().Invoke();
    end;

    local procedure GetPostedDocumentLinesToReverse(No: Code[20])
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", No);
        PurchaseReturnOrder.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure PostPurchaseInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        CreatePurchaseDocumentWithJobAndItemTracking(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, PurchaseLine."Job Line Type"::" ", false, true);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        UpdateGeneralPostingSetup(GeneralPostingSetup, GLAccount."No.");
        PurchaseLine.OpenItemTrackingLines();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure PostPurchaseInvoiceWithItemTrackingLines(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateItemWithTrackingCode(false, true));
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);

        PurchaseLine.OpenItemTrackingLines();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostPurchaseReceipt(OrderNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderNo);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    local procedure PostPurchaseOrderWithItemTracking(var PurchaseLine: Record "Purchase Line"; Invoice: Boolean) DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order, CreateItemWithTrackingCode(true, false));
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        AssignItemTrackingLinesOnPurchaseOrder(PurchaseHeader);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);
    end;

    local procedure PostedPurchaseOrderWithJob(DocumentType: Enum "Purchase Document Type")
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        PostedOrderNo: Code[20];
    begin
        // Setup: Set Inventory Setup.
        Initialize();
        UpdateInventorySetupWithExpectedCost(true, true);

        // Excercise : Create And Post Purchase Order With Job No.
        CreateJobWithJobTask(JobTask);
        CreatePurchaseOrderWithJob(PurchaseLine, DocumentType, JobTask, CreateItem(), PurchaseLine."Job Line Type"::Billable);
        LibraryERM.CreateGLAccount(GLAccount);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        UpdateGeneralPostingSetup(GeneralPostingSetup, GLAccount."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PostedOrderNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: Verify G/L Entries.
        VerifyGLEntry(PostedOrderNo, PurchaseLine."Line Amount");
    end;

    local procedure PostSalesInvoice(CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Find and Post the Sales Invoice created from Job Planning Line.
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Bill-to Customer No.", CustomerNo);
        SalesLine.FindFirst();
        InvoicedCostFCY :=
          InvoicedCostFCY +
          Round(SalesLine."Unit Cost" * SalesLine.Quantity, LibraryJob.GetAmountRoundingPrecision(SalesLine."Currency Code"));  // Assigning value to Global Variable as required in page handler.
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure ReceivePurchaseOrderWithNewUOM(var PurchaseHeader: Record "Purchase Header") QtyPerUnitOfMeasure: Decimal
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // 1. Setup: Create New Unit of Measure, create and receive Purchase Order with Job and new Unit of Measure Code.
        CreateItemWithNewUOM(ItemUnitOfMeasure);
        CreateAndReceivePurchaseOrder(PurchaseHeader, ItemUnitOfMeasure."Item No.", ItemUnitOfMeasure.Code);
        QtyPerUnitOfMeasure := ItemUnitOfMeasure."Qty. per Unit of Measure" + LibraryRandom.RandInt(10);  // Use Random value to change Qty. per Unit of Measure.
    end;

    local procedure RunCopyJob(No: Code[20])
    var
        JobList: TestPage "Job List";
    begin
        JobList.OpenView();
        JobList.FILTER.SetFilter("No.", No);
        JobList.CopyJob.Invoke();
    end;

    local procedure SalesDocumentDoesNotExistWhenItemBlocked(SalesDocumentType: Boolean)
    var
        Item: Record Item;
        ItemForBlocking: Record Item;
        SalesHeader: Record "Sales Header";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ExtendedTextHeader: Record "Extended Text Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // Create Items with Automatic Extended Text and Block one of the created Item after creating Job Planning Lines.
        Initialize();
        CreateJobWithJobTask(JobTask);
        Job.Get(JobTask."Job No.");
        CreateItemWithAutomaticExtText(Item);
        UpdateAllLanguagesCodeOnExtendedTextHeader(ExtendedTextHeader, Item."No.");
        CreateItemWithAutomaticExtText(ItemForBlocking);
        CreateAndUpdateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, Item."No.", LibraryRandom.RandInt(10));
        CreateAndUpdateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable, ItemForBlocking."No.", LibraryRandom.RandInt(10));
        ItemForBlocking.Validate(Blocked, true);
        ItemForBlocking.Modify(true);

        // Exercise: Create Sales Document After Blocking the Item.
        Commit();
        asserterror JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, SalesDocumentType);

        // Verify: Verify Error Message and Sales Document should not be Created with Customer No.
        SalesHeader.SetRange("Sell-to Customer No.", Job."Bill-to Customer No.");
        Assert.IsFalse(not SalesHeader.IsEmpty(), SalesDocumentMsg);
    end;

    local procedure SalesDocumentExistWithExtendedText(SalesDocumentType: Boolean)
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // Create Item with Extended Text and Create Job Planning Line.
        Initialize();
        CreateJobWithJobTask(JobTask);
        Job.Get(JobTask."Job No.");
        CreateItemWithAutomaticExtText(Item);
        UpdateAllLanguagesCodeOnExtendedTextHeader(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, ExtendedTextHeader."No.");
        ExtendedTextLine.Modify(true);
        CreateAndUpdateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable, Item."No.", LibraryRandom.RandInt(10));

        // Exercise: Create Sales Document.
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, SalesDocumentType);

        // Verify: Verify Extended Text exist on Sales Line Description.
        VerifyDescriptionOnCreatedSalesHeader(Job."Bill-to Customer No.", ExtendedTextHeader."No.");
    end;

    local procedure SaveItemJnlLineInTempTable(var TempItemJournalLine: Record "Item Journal Line" temporary; ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        ItemJournalLine.FindSet();
        repeat
            TempItemJournalLine := ItemJournalLine;
            TempItemJournalLine.Insert();
        until ItemJournalLine.Next() = 0;
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; ItemJnlTemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJnlTemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJnlTemplateType, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure UndoPurchaseReceiptLine(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Document No.", DocumentNo);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);
    end;

    local procedure UpdateGeneralPostingSetup(GeneralPostingSetup: Record "General Posting Setup"; InventoryAdjmtAccount: Code[20])
    begin
        GeneralPostingSetup.Get(GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", InventoryAdjmtAccount);
        GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", InventoryAdjmtAccount);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateGlobalDimensionOnJob(var SourceJob: Record Job)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        SourceJob.Validate("Global Dimension 1 Code", FindDimensionValue(GeneralLedgerSetup."Global Dimension 1 Code"));
        SourceJob.Validate("Global Dimension 2 Code", FindDimensionValue(GeneralLedgerSetup."Global Dimension 2 Code"));
        SourceJob.Modify(true);
    end;

    local procedure UpdateInventorySetup(AutomaticCostPosting: Boolean; AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", AutomaticCostPosting);
        InventorySetup.Validate("Automatic Cost Adjustment", AutomaticCostAdjustment);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateInventorySetupWithExpectedCost(NewAutomaticCostPosting: Boolean; NewExpectedCostPosting: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", NewAutomaticCostPosting);
        InventorySetup.Validate("Expected Cost Posting to G/L", NewExpectedCostPosting);
        InventorySetup.Modify(true);
    end;

    local procedure UpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; JobNo: Code[20]; JobTaskNo: Code[20]; JobLineType: Enum "Job Line Type")
    begin
        PurchaseLine.Validate("Job No.", JobNo);
        PurchaseLine.Validate("Job Task No.", JobTaskNo);
        PurchaseLine.Validate("Job Line Type", JobLineType);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePurchasesAndPayablesSetup(ExactCostReversingMandatory: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateAllLanguagesCodeOnExtendedTextHeader(var ExtendedTextHeader: Record "Extended Text Header"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, ItemNo);
        ExtendedTextHeader.Validate("All Language Codes", true);
        ExtendedTextHeader.Modify(true);
    end;

    local procedure UndoReturnShipmentLine(DocumentNo: Code[20]; No: Code[20])
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        ReturnShipmentLine.SetRange("Document No.", DocumentNo);
        ReturnShipmentLine.SetRange("No.", No);
        ReturnShipmentLine.FindFirst();
        LibraryPurchase.UndoReturnShipmentLine(ReturnShipmentLine);
    end;

    local procedure SetupManualNosInJobNoSeries(ManualNos: Boolean)
    var
        JobsSetup: Record "Jobs Setup";
        NoSeries: Record "No. Series";
    begin
        JobsSetup.Get();
        NoSeries.Get(JobsSetup."Job Nos.");
        NoSeries."Manual Nos." := ManualNos;
        NoSeries.Modify();
    end;

    local procedure AttachJobTaskToPurchLine(var PurchLine: Record "Purchase Line")
    var
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);
        UpdatePurchaseLine(
          PurchLine, JobTask."Job No.", JobTask."Job Task No.", PurchLine."Job Line Type"::"Both Budget and Billable");
    end;

    local procedure VerifyBinIsEmpty(LocationCode: Code[10]; BinCode: Code[20])
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.CalcFields(Quantity);
        Assert.AreEqual(0, BinContent.Quantity, BinContentNotDeletedErr);
    end;

    local procedure VerifyDescriptionOnCreatedSalesHeader(SellToCustomerNo: Code[20]; Description: Text)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesHeader.FindFirst();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::" ");
        SalesLine.FindFirst();
        SalesLine.TestField(Description, Description);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyUnitCostOnItem(ItemNo: Code[20]; UnitCost: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.TestField("Unit Cost", UnitCost);
    end;

    local procedure VerifyItemLedgerEntries(var TempItemJournalLine: Record "Item Journal Line" temporary)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        TempItemJournalLine.FindSet();
        repeat
            VerifyItemLedgerEntry(
              TempItemJournalLine."Document No.", ItemLedgerEntry."Entry Type"::"Positive Adjmt.", 1, 1, TempItemJournalLine."Unit Amount");  // Remaining and Invoiced Quantity must be 1.
        until TempItemJournalLine.Next() = 0;
    end;

    local procedure VerifyItemLedgerEntry(DocumentNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; RemainingQuantity: Decimal; InvoicedQuantity: Decimal; CostAmount: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Remaining Quantity", RemainingQuantity);
        ItemLedgerEntry.TestField("Invoiced Quantity", InvoicedQuantity);
        ItemLedgerEntry.TestField("Cost Amount (Actual)", CostAmount);
    end;

    local procedure VerifyJob(Job: Record Job; JobNo: Code[20])
    var
        Job2: Record Job;
    begin
        Job2.Get(JobNo);
        Job2.TestField(Status, Job.Status);
        Job2.TestField("Bill-to Customer No.", Job."Bill-to Customer No.");
        Job2.TestField("Person Responsible", Job."Person Responsible");
        Job2.TestField("Job Posting Group", Job."Job Posting Group");
        Job2.TestField("WIP Method", Job."WIP Method");
    end;

    local procedure VerifyJobLedgerEntry(JobJournalLine: Record "Job Journal Line")
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Document No.", JobJournalLine."Document No.");
        JobLedgerEntry.SetRange("No.", JobJournalLine."No.");
        JobLedgerEntry.FindFirst();
        JobLedgerEntry.TestField("Job Task No.", JobJournalLine."Job Task No.");
        JobLedgerEntry.TestField(Quantity, JobJournalLine.Quantity);
    end;

    local procedure VerifyJobPlanningLine(JobJournalLine: Record "Job Journal Line"; LineType: Enum "Job Planning Line Line Type")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("No.", JobJournalLine."No.");
        JobPlanningLine.SetRange("Job No.", JobJournalLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobJournalLine."Job Task No.");
        JobPlanningLine.SetRange("Line Type", LineType);
        JobPlanningLine.FindFirst();
        JobPlanningLine.TestField(Quantity, JobJournalLine.Quantity);
    end;

    local procedure VerifyJobLedgerEntryUsingGeneralJournalLine(GenJournalLine: Record "Gen. Journal Line")
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Job No.", GenJournalLine."Job No.");
        JobLedgerEntry.FindFirst();
        JobLedgerEntry.TestField("Job Task No.", GenJournalLine."Job Task No.");
        JobLedgerEntry.TestField("No.", GenJournalLine."Account No.");
        JobLedgerEntry.TestField(Quantity, GenJournalLine."Job Quantity");
        JobLedgerEntry.TestField("Unit Price", GenJournalLine."Job Unit Price");
    end;

    local procedure VerifyJobPlanningLineUsingGeneralJournalLine(GenJournalLine: Record "Gen. Journal Line")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", GenJournalLine."Job No.");
        JobPlanningLine.FindFirst();
        JobPlanningLine.TestField("Job Task No.", GenJournalLine."Job Task No.");
        JobPlanningLine.TestField(Quantity, GenJournalLine."Job Quantity");
        JobPlanningLine.TestField("Unit Price", GenJournalLine."Job Unit Price");
    end;

    local procedure VerifyValueEntry(DocumentNo: Code[20]; ItemNo: Code[20]; CostAmountExpected: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Cost Amount (Expected)", CostAmountExpected);
    end;

    local procedure VerifyApplToItemEntry(PurchHeader: Record "Purchase Header")
    var
        ReservEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ReservEntry.SetRange("Source ID", PurchHeader."No.");
        ReservEntry.SetRange("Source Type", DATABASE::"Purchase Line");
        ReservEntry.SetRange("Source Subtype", PurchHeader."Document Type");
        ReservEntry.FindFirst();

        ItemLedgerEntry.SetRange("Item No.", ReservEntry."Item No.");
        ItemLedgerEntry.FindFirst();

        Assert.AreEqual(ItemLedgerEntry."Entry No.", ReservEntry."Appl.-to Item Entry", ApplToItemEntryErr);
    end;

    local procedure VerifyValuesOnJobPlanningLine(JobNo: Code[20]; JobTaskNo: Code[20]; LineNo: Integer; LineType: Enum "Job Planning Line Line Type"; No: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.Get(JobNo, JobTaskNo, LineNo);
        JobPlanningLine.TestField("Line Type", LineType);
        JobPlanningLine.TestField("No.", No);
        JobPlanningLine.TestField(Quantity, Quantity);
        JobPlanningLine.TestField("Unit Price", UnitPrice);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopyJobHandler(var CopyJob: TestPage "Copy Job")
    begin
        CopyJob.FromJobTaskNo.Lookup();
        CopyJob.ToJobTaskNo.Lookup();
        CopyJob.TargetJobNo.SetValue(TargetJobNo);
        CopyJob."From Source".SetValue(FromSource);
        CopyJob.CopyJobPrices.SetValue(true);
        CopyJob.CopyQuantity.SetValue(true);
        CopyJob.CopyDimensions.SetValue(true);
        CopyJob.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobTaskListHandler(var JobTaskList: TestPage "Job Task List")
    begin
        JobTaskList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerWithValidation(ActualQuestion: Text[1024]; var Reply: Boolean)
    var
        ExpectedQuestion: Text;
    begin
        ExpectedQuestion := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(ExpectedQuestion, ActualQuestion);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterCustomizedSNPageHandler(var EnterCustomizedSN: TestPage "Enter Customized SN")
    begin
        EnterCustomizedSN.CustomizedSN.SetValue(LibraryUtility.GenerateGUID());
        EnterCustomizedSN.QtyToCreate.SetValue(LibraryVariableStorage.DequeueDecimal());
        EnterCustomizedSN.Increment.SetValue(1);
        EnterCustomizedSN.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        if LibraryVariableStorage.DequeueBoolean() then begin
            ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingLines.OK().Invoke();
            exit;
        end;
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSelectEntriesPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesCreateSerialNoPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        "Count": Integer;
        Count2: Integer;
    begin
        if VerifyTrackingLine then begin
            Count := 1;
            ItemTrackingLines.First();
            repeat
                ItemTrackingLines."Serial No.".AssertEquals(SerialNo[Count]);
                Count := Count + 1;
            until not ItemTrackingLines.Next();
        end else begin
            ItemTrackingLines.CreateCustomizedSN.Invoke();
            Count2 := 1;
            ItemTrackingLines.First();
            repeat
                SerialNo[Count2] := ItemTrackingLines."Serial No.".Value();
                Count2 := Count2 + 1;
            until not ItemTrackingLines.Next();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch."Qty. to Assign".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobJournalTemplateListPageHandler(var JobJournalTemplateList: TestPage "Job Journal Template List")
    begin
        JobJournalTemplateList.FILTER.SetFilter(Name, JournalTemplateName);
        JobJournalTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinesPageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    begin
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure JobTaskStatisticsScheduleUsagePageHandler(var JobTaskStatistics: TestPage "Job Task Statistics")
    var
        Profit: Decimal;
        ProfitFCY: Decimal;
    begin
        // Verify Job Task Statistics Price, Cost and Profit for Schedule and Usage.
        Profit := Amount - Cost;
        ProfitFCY := AmountFCY - CostFCY;
        JobTaskStatistics.SchedulePriceLCY.AssertEquals(Amount);
        JobTaskStatistics.UsagePriceLCY.AssertEquals(Amount);
        JobTaskStatistics.ScheduleCostLCY.AssertEquals(Cost);
        JobTaskStatistics.UsageCostLCY.AssertEquals(Cost);
        JobTaskStatistics.ScheduleProfitLCY.AssertEquals(Profit);
        JobTaskStatistics.UsageProfitLCY.AssertEquals(Profit);
        JobTaskStatistics.SchedulePriceLCYItem.AssertEquals(Amount);
        JobTaskStatistics.UsagePriceLCYItem.AssertEquals(Amount);
        JobTaskStatistics.ScheduleCostLCYItem.AssertEquals(Cost);
        JobTaskStatistics.UsageCostLCYItem.AssertEquals(Cost);
        JobTaskStatistics.ScheduleProfitLCYItem.AssertEquals(Profit);
        JobTaskStatistics.UsageProfitLCYItem.AssertEquals(Profit);
        JobTaskStatistics.SchedulePriceLCYGLAcc.AssertEquals(Amount);
        JobTaskStatistics.UsagePriceLCYGLAcc.AssertEquals(Amount);
        JobTaskStatistics.ScheduleCostLCYGLAcc.AssertEquals(Cost);
        JobTaskStatistics.UsageCostLCYGLAcc.AssertEquals(Cost);
        JobTaskStatistics.ScheduleProfitLCYGLAcc.AssertEquals(Profit);
        asserterror JobTaskStatistics.UsageProfitLCYGLAcc.AssertEquals(Profit);
        // Multiplying by 3 as three Job Journal Lines for Resource,Item and GLAccount has been created.
        JobTaskStatistics.SchedulePriceLCYTotal.AssertEquals(Amount * 3);
        JobTaskStatistics.UsagePriceLCYTotal.AssertEquals(Amount * 3);
        JobTaskStatistics.ScheduleCostLCYTotal.AssertEquals(Cost * 3);
        JobTaskStatistics.UsageCostLCYTotal.AssertEquals(Cost * 3);
        JobTaskStatistics.ScheduleProfitLCYTotal.AssertEquals(Profit * 3);
        JobTaskStatistics.UsageProfitLCYTotal.AssertEquals(Profit * 3);
        JobTaskStatistics.SchedulePrice.AssertEquals(AmountFCY);
        JobTaskStatistics.UsagePrice.AssertEquals(AmountFCY);
        JobTaskStatistics.ScheduleCost.AssertEquals(CostFCY);
        JobTaskStatistics.UsageCost.AssertEquals(CostFCY);
        JobTaskStatistics.ScheduleProfit.AssertEquals(ProfitFCY);
        JobTaskStatistics.UsageProfit.AssertEquals(ProfitFCY);
        JobTaskStatistics.SchedulePriceItem.AssertEquals(AmountFCY);
        JobTaskStatistics.UsagePriceItem.AssertEquals(AmountFCY);
        JobTaskStatistics.ScheduleCostItem.AssertEquals(CostFCY);
        JobTaskStatistics.UsageCostItem.AssertEquals(CostFCY);
        JobTaskStatistics.ScheduleProfitItem.AssertEquals(ProfitFCY);
        JobTaskStatistics.UsageProfitItem.AssertEquals(ProfitFCY);
        JobTaskStatistics.SchedulePriceGLAcc.AssertEquals(AmountFCY);
        JobTaskStatistics.UsagePriceGLAcc.AssertEquals(AmountFCY);
        JobTaskStatistics.ScheduleCostGLAcc.AssertEquals(CostFCY);
        JobTaskStatistics.UsageCostGLAcc.AssertEquals(CostFCY);
        JobTaskStatistics.ScheduleProfitGLAcc.AssertEquals(ProfitFCY);
        asserterror JobTaskStatistics.UsageProfitGLAcc.AssertEquals(ProfitFCY);
        // Multiplying by 3 as three Job Journal Lines for Resource,Item and GLAccount has been created.
        JobTaskStatistics.SchedulePriceTotal.AssertEquals(AmountFCY * 3);
        JobTaskStatistics.UsagePriceTotal.AssertEquals(AmountFCY * 3);
        JobTaskStatistics.ScheduleCostTotal.AssertEquals(CostFCY * 3);
        JobTaskStatistics.UsageCostTotal.AssertEquals(CostFCY * 3);
        JobTaskStatistics.ScheduleProfitTotal.AssertEquals(ProfitFCY * 3);
        JobTaskStatistics.UsageProfitTotal.AssertEquals(ProfitFCY * 3);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure JobStatisticsScheduleUsagePageHandler(var JobStatistics: TestPage "Job Statistics")
    var
        Profit: Decimal;
        ProfitFCY: Decimal;
    begin
        // Verify Job Statistics Price, Cost and Profit for Schedule and Usage.
        Profit := Amount - Cost;
        ProfitFCY := AmountFCY - CostFCY;
        JobStatistics.SchedulePriceLCY.AssertEquals(Amount);
        JobStatistics.UsagePriceLCY.AssertEquals(Amount);
        JobStatistics.ScheduleCostLCY.AssertEquals(Cost);
        JobStatistics.UsageCostLCY.AssertEquals(Cost);
        JobStatistics.ScheduleProfitLCY.AssertEquals(Profit);
        JobStatistics.UsageProfitLCY.AssertEquals(Profit);
        JobStatistics.SchedulePriceLCYItem.AssertEquals(Amount);
        JobStatistics.UsagePriceLCYItem.AssertEquals(Amount);
        JobStatistics.ScheduleCostLCYItem.AssertEquals(Cost);
        JobStatistics.UsageCostLCYItem.AssertEquals(Cost);
        JobStatistics.ScheduleProfitLCYItem.AssertEquals(Profit);
        JobStatistics.UsageProfitLCYItem.AssertEquals(Profit);
        JobStatistics.SchedulePriceLCYGLAcc.AssertEquals(Amount);
        JobStatistics.UsagePriceLCYGLAcc.AssertEquals(Amount);
        JobStatistics.ScheduleCostLCYGLAcc.AssertEquals(Cost);
        JobStatistics.UsageCostLCYGLAcc.AssertEquals(Cost);
        JobStatistics.ScheduleProfitLCYGLAcc.AssertEquals(Profit);
        JobStatistics.UsageProfitLCYGLAcc.AssertEquals(Profit);
        // Multiplying by 3 as three Job Journal Lines for Resource,Item and GLAccount has been created.
        JobStatistics.SchedulePriceLCYTotal.AssertEquals(Amount * 3);
        JobStatistics.UsagePriceLCYTotal.AssertEquals(Amount * 3);
        JobStatistics.ScheduleCostLCYTotal.AssertEquals(Cost * 3);
        JobStatistics.UsageCostLCYTotal.AssertEquals(Cost * 3);
        JobStatistics.ScheduleProfitLCYTotal.AssertEquals(Profit * 3);
        JobStatistics.UsageProfitLCYTotal.AssertEquals(Profit * 3);
        JobStatistics.SchedulePrice.AssertEquals(AmountFCY);
        JobStatistics.UsagePrice.AssertEquals(AmountFCY);
        JobStatistics.ScheduleCost.AssertEquals(CostFCY);
        JobStatistics.UsageCost.AssertEquals(CostFCY);
        JobStatistics.ScheduleProfit.AssertEquals(ProfitFCY);
        JobStatistics.UsageProfit.AssertEquals(ProfitFCY);
        JobStatistics.SchedulePriceItem.AssertEquals(AmountFCY);
        JobStatistics.UsagePriceItem.AssertEquals(AmountFCY);
        JobStatistics.ScheduleCostItem.AssertEquals(CostFCY);
        JobStatistics.UsageCostItem.AssertEquals(CostFCY);
        JobStatistics.ScheduleProfitItem.AssertEquals(ProfitFCY);
        JobStatistics.UsageProfitItem.AssertEquals(ProfitFCY);
        JobStatistics.SchedulePriceGLAcc.AssertEquals(AmountFCY);
        JobStatistics.UsagePriceGLAcc.AssertEquals(AmountFCY);
        JobStatistics.ScheduleCostGLAcc.AssertEquals(CostFCY);
        JobStatistics.UsageCostGLAcc.AssertEquals(CostFCY);
        JobStatistics.ScheduleProfitGLAcc.AssertEquals(ProfitFCY);
        JobStatistics.UsageProfitGLAcc.AssertEquals(ProfitFCY);
        // Multiplying by 3 as three Job Journal Lines for Resource,Item and GLAccount has been created.
        JobStatistics.SchedulePriceTotal.AssertEquals(AmountFCY * 3);
        JobStatistics.UsagePriceTotal.AssertEquals(AmountFCY * 3);
        JobStatistics.ScheduleCostTotal.AssertEquals(CostFCY * 3);
        JobStatistics.UsageCostTotal.AssertEquals(CostFCY * 3);
        JobStatistics.ScheduleProfitTotal.AssertEquals(ProfitFCY * 3);
        JobStatistics.UsageProfitTotal.AssertEquals(ProfitFCY * 3);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure JobTaskStatisticsContractInvoicedPageHandler(var JobTaskStatistics: TestPage "Job Task Statistics")
    var
        Profit: Decimal;
        ProfitFCY: Decimal;
    begin
        // Verify Job Task Statistics Price, Cost and Profit for Contract and Invoiced.
        Profit := Amount - Cost;
        ProfitFCY := AmountFCY - CostFCY;
        JobTaskStatistics.ContractPriceLCY.AssertEquals(Amount);
        JobTaskStatistics.InvoicedPriceLCY.AssertEquals(Amount);
        JobTaskStatistics.ContractCostLCY.AssertEquals(Cost);
        JobTaskStatistics.InvoicedCostLCY.AssertEquals(Cost);
        JobTaskStatistics.ContractProfitLCY.AssertEquals(Profit);
        JobTaskStatistics.InvoicedProfitLCY.AssertEquals(Profit);
        JobTaskStatistics.ContractPriceLCYItem.AssertEquals(Amount);
        JobTaskStatistics.InvoicedPriceLCYItem.AssertEquals(Amount);
        JobTaskStatistics.ContractCostLCYItem.AssertEquals(Cost);
        JobTaskStatistics.InvoicedCostLCYItem.AssertEquals(Cost);
        JobTaskStatistics.ContractProfitLCYItem.AssertEquals(Profit);
        JobTaskStatistics.InvoicedProfitLCYItem.AssertEquals(Profit);
        JobTaskStatistics.ContractPriceLCYGLAcc.AssertEquals(Amount);
        JobTaskStatistics.InvoicedPriceLCYGLAcc.AssertEquals(Amount);
        JobTaskStatistics.ContractCostLCYGLAcc.AssertEquals(Cost);
        JobTaskStatistics.InvoicedCostLCYGLAcc.AssertEquals(Cost);
        JobTaskStatistics.ContractProfitLCYGLAcc.AssertEquals(Profit);
        JobTaskStatistics.InvoicedProfitLCYGLAcc.AssertEquals(Profit);
        // Multiplying by 3 as three Job Planning Lines for Resource,Item and GLAccount has been created.
        JobTaskStatistics.ContractPriceLCYTotal.AssertEquals(Amount * 3);
        JobTaskStatistics.InvoicedPriceLCYTotal.AssertEquals(Amount * 3);
        JobTaskStatistics.ContractCostLCYTotal.AssertEquals(Cost * 3);
        JobTaskStatistics.InvoicedCostLCYTotal.AssertEquals(Cost * 3);
        JobTaskStatistics.ContractProfitLCYTotal.AssertEquals(Profit * 3);
        JobTaskStatistics.InvoicedProfitLCYTotal.AssertEquals(Profit * 3);
        JobTaskStatistics.ContractPrice.AssertEquals(AmountFCY);
        JobTaskStatistics.InvoicedPrice.AssertEquals(AmountFCY);
        JobTaskStatistics.ContractCost.AssertEquals(CostFCY);
        JobTaskStatistics.InvoicedCost.AssertEquals(InvoicedCostFCY);
        JobTaskStatistics.ContractProfit.AssertEquals(ProfitFCY);
        JobTaskStatistics.InvoicedProfit.AssertEquals(AmountFCY - InvoicedCostFCY);
        JobTaskStatistics.ContractPriceItem.AssertEquals(AmountFCY);
        JobTaskStatistics.InvoicedPriceItem.AssertEquals(AmountFCY);
        JobTaskStatistics.ContractCostItem.AssertEquals(CostFCY);
        JobTaskStatistics.InvoicedCostItem.AssertEquals(InvoicedCostFCY);
        JobTaskStatistics.ContractProfitItem.AssertEquals(ProfitFCY);
        JobTaskStatistics.InvoicedProfitItem.AssertEquals(AmountFCY - InvoicedCostFCY);
        JobTaskStatistics.ContractPriceGLAcc.AssertEquals(AmountFCY);
        JobTaskStatistics.InvoicedPriceGLAcc.AssertEquals(AmountFCY);
        JobTaskStatistics.ContractCostGLAcc.AssertEquals(CostFCY);
        JobTaskStatistics.InvoicedCostGLAcc.AssertEquals(InvoicedCostFCY);
        JobTaskStatistics.ContractProfitGLAcc.AssertEquals(ProfitFCY);
        JobTaskStatistics.InvoicedProfitGLAcc.AssertEquals(AmountFCY - InvoicedCostFCY);
        // Multiplying by 3 as three Job Planning lines for Resource,Item and GLAccount has been created.
        JobTaskStatistics.ContractPriceTotal.AssertEquals(AmountFCY * 3);
        JobTaskStatistics.InvoicedPriceTotal.AssertEquals(AmountFCY * 3);
        JobTaskStatistics.ContractCostTotal.AssertEquals(CostFCY * 3);
        JobTaskStatistics.InvoicedCostTotal.AssertEquals(InvoicedCostFCY * 3);
        JobTaskStatistics.ContractProfitTotal.AssertEquals(ProfitFCY * 3);
        JobTaskStatistics.InvoicedProfitTotal.AssertEquals((AmountFCY - InvoicedCostFCY) * 3);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure JobStatisticsContractInvoicedPageHandler(var JobStatistics: TestPage "Job Statistics")
    var
        Profit: Decimal;
        ProfitFCY: Decimal;
    begin
        // Verify Job Statistics Price, Cost and Profit for Contract and Invoiced.
        Profit := Amount - Cost;
        ProfitFCY := AmountFCY - CostFCY;
        JobStatistics.ContractPriceLCY.AssertEquals(Amount);
        JobStatistics.InvoicedPriceLCY.AssertEquals(Amount);
        JobStatistics.ContractCostLCY.AssertEquals(Cost);
        JobStatistics.InvoicedCostLCY.AssertEquals(Cost);
        JobStatistics.ContractProfitLCY.AssertEquals(Profit);
        JobStatistics.InvoicedProfitLCY.AssertEquals(Profit);
        JobStatistics.ContractPriceLCYItem.AssertEquals(Amount);
        JobStatistics.InvoicedPriceLCYItem.AssertEquals(Amount);
        JobStatistics.ContractCostLCYItem.AssertEquals(Cost);
        JobStatistics.InvoicedCostLCYItem.AssertEquals(Cost);
        JobStatistics.ContractProfitLCYItem.AssertEquals(Profit);
        JobStatistics.InvoicedProfitLCYItem.AssertEquals(Profit);
        JobStatistics.ContractPriceLCYGLAcc.AssertEquals(Amount);
        JobStatistics.InvoicedPriceLCYGLAcc.AssertEquals(Amount);
        JobStatistics.ContractCostLCYGLAcc.AssertEquals(Cost);
        JobStatistics.InvoicedCostLCYGLAcc.AssertEquals(Cost);
        JobStatistics.ContractProfitLCYGLAcc.AssertEquals(Profit);
        JobStatistics.InvoicedProfitLCYGLAcc.AssertEquals(Profit);
        // Multiplying by 3 as three Job Planning Lines for Resource,Item and GLAccount has been created.
        JobStatistics.ContractPriceLCYTotal.AssertEquals(Amount * 3);
        JobStatistics.InvoicedPriceLCYTotal.AssertEquals(Amount * 3);
        JobStatistics.ContractCostLCYTotal.AssertEquals(Cost * 3);
        JobStatistics.InvoicedCostLCYTotal.AssertEquals(Cost * 3);
        JobStatistics.ContractProfitLCYTotal.AssertEquals(Profit * 3);
        JobStatistics.InvoicedProfitLCYTotal.AssertEquals(Profit * 3);
        JobStatistics.ContractPrice.AssertEquals(AmountFCY);
        JobStatistics.InvoicedPrice.AssertEquals(AmountFCY);
        JobStatistics.ContractCost.AssertEquals(CostFCY);
        JobStatistics.InvoicedCost.AssertEquals(InvoicedCostFCY);
        JobStatistics.ContractProfit.AssertEquals(ProfitFCY);
        JobStatistics.InvoicedProfit.AssertEquals(AmountFCY - InvoicedCostFCY);
        JobStatistics.ContractPriceItem.AssertEquals(AmountFCY);
        JobStatistics.InvoicedPriceItem.AssertEquals(AmountFCY);
        JobStatistics.ContractCostItem.AssertEquals(CostFCY);
        JobStatistics.InvoicedCostItem.AssertEquals(InvoicedCostFCY);
        JobStatistics.ContractProfitItem.AssertEquals(ProfitFCY);
        JobStatistics.InvoicedProfitItem.AssertEquals(AmountFCY - InvoicedCostFCY);
        JobStatistics.ContractPriceGLAcc.AssertEquals(AmountFCY);
        JobStatistics.InvoicedPriceGLAcc.AssertEquals(AmountFCY);
        JobStatistics.ContractCostGLAcc.AssertEquals(CostFCY);
        JobStatistics.InvoicedCostGLAcc.AssertEquals(InvoicedCostFCY);
        JobStatistics.ContractProfitGLAcc.AssertEquals(ProfitFCY);
        JobStatistics.InvoicedProfitGLAcc.AssertEquals(AmountFCY - InvoicedCostFCY);
        // Multiplying by 3 as three Job Planning Lines for Resource,Item and GLAccount has been created.
        JobStatistics.ContractPriceTotal.AssertEquals(AmountFCY * 3);
        JobStatistics.InvoicedPriceTotal.AssertEquals(AmountFCY * 3);
        JobStatistics.ContractCostTotal.AssertEquals(CostFCY * 3);
        JobStatistics.InvoicedCostTotal.AssertEquals(InvoicedCostFCY * 3);
        JobStatistics.ContractProfitTotal.AssertEquals(ProfitFCY * 3);
        JobStatistics.InvoicedProfitTotal.AssertEquals((AmountFCY - InvoicedCostFCY) * 3);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure JobTaskStatisticsPageHander(var JobTaskStatistics: TestPage "Job Task Statistics")
    begin
        // Verify Job Task Statistics Price, Cost and Profit for Schedule and Usage with Planning and Posting Date Filters.
        JobTaskStatistics.FILTER.SetFilter(
          "Posting Date Filter", Format(CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate())));  // Using date greater than WORKDATE.
        JobTaskStatistics.FILTER.SetFilter(
          "Planning Date Filter", Format(CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate())));
        JobTaskStatistics.SchedulePriceLCY.AssertEquals(0);
        JobTaskStatistics.UsagePriceLCY.AssertEquals(0);
        JobTaskStatistics.ScheduleCostLCY.AssertEquals(0);
        JobTaskStatistics.UsageCostLCY.AssertEquals(0);
        JobTaskStatistics.ScheduleProfitLCY.AssertEquals(0);
        JobTaskStatistics.UsageProfitLCY.AssertEquals(0);
        JobTaskStatistics.SchedulePrice.AssertEquals(0);
        JobTaskStatistics.UsagePrice.AssertEquals(0);
        JobTaskStatistics.ScheduleCost.AssertEquals(0);
        JobTaskStatistics.UsageCost.AssertEquals(0);
        JobTaskStatistics.ScheduleProfit.AssertEquals(0);
        JobTaskStatistics.UsageProfit.AssertEquals(0);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure JobStatisticsPageHandler(var JobStatistics: TestPage "Job Statistics")
    begin
        // Verify Job Statistics Price, Cost and Profit for Schedule and Usage with Planning and Posting Date Filters.
        JobStatistics.FILTER.SetFilter(
          "Posting Date Filter", Format(CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate())));  // Using date greater than WORKDATE.
        JobStatistics.FILTER.SetFilter(
          "Planning Date Filter", Format(CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate())));
        JobStatistics.SchedulePriceLCY.AssertEquals(0);
        JobStatistics.UsagePriceLCY.AssertEquals(0);
        JobStatistics.ScheduleCostLCY.AssertEquals(0);
        JobStatistics.UsageCostLCY.AssertEquals(0);
        JobStatistics.ScheduleProfitLCY.AssertEquals(0);
        JobStatistics.UsageProfitLCY.AssertEquals(0);
        JobStatistics.SchedulePrice.AssertEquals(0);
        JobStatistics.UsagePrice.AssertEquals(0);
        JobStatistics.ScheduleCost.AssertEquals(0);
        JobStatistics.UsageCost.AssertEquals(0);
        JobStatistics.ScheduleProfit.AssertEquals(0);
        JobStatistics.UsageProfit.AssertEquals(0);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToSalesInvoiceHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToSalesCreditMemoHandler(var JobTransferToCreditMemo: TestRequestPage "Job Transfer to Credit Memo")
    begin
        JobTransferToCreditMemo.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinePageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    begin
        PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue('Posted Invoices');
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SerialNoItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        TrackingOptionValue: Option;
    begin
        TrackingOptionValue := LibraryVariableStorage.DequeueInteger();
        case TrackingOptionValue of
            TrackingOption::SelectSerialNo:
                ItemTrackingLines."Serial No.".AssistEdit();
            TrackingOption::AssignManualSN:
                begin
                    ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(1);
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

    // Setups Item A with default bin code A and item B with non-default bin code B.
    local procedure InitSetupForDefaultBinCodeTests(
        var ItemA: Record Item;
        var ItemB: Record Item;
        var JobPlanningLine: Record "Job Planning Line";
        var LocationA: Record Location;
        var LocationB: Record Location;
        var BinA: Record Bin;
        var BinB: Record Bin
    )
    var
        JobTask: Record "Job Task";
        BinContentA: Record "Bin Content";
        BinContentB: Record "Bin Content";
    begin
        Initialize();

        // Two locations, A and B.
        LibraryWarehouse.CreateLocationWMS(LocationA, true, true, false, false, false);
        LibraryWarehouse.CreateLocationWMS(LocationB, true, true, false, false, false);

        // Two items A and B.
        LibraryInventory.CreateItem(ItemA);
        LibraryInventory.CreateItem(ItemB);

        // Two bins, one default for item A and one not default for item B.
        LibraryWarehouse.CreateBin(
            BinA,
            LocationA.Code,
            CopyStr(
                LibraryUtility.GenerateRandomCode(BinA.FieldNo(Code), DATABASE::Bin),
                1,
                LibraryUtility.GetFieldLength(DATABASE::Bin, BinA.FieldNo(Code))
            ),
            '',
            ''
        );
        LibraryWarehouse.CreateBinContent(
            BinContentA, BinA."Location Code", '', BinA.Code, ItemA."No.", '', ItemA."Base Unit of Measure"
        );
        BinContentA.Validate(Fixed, true);
        BinContentA.Validate(Default, true);
        BinContentA.Modify(true);

        LibraryWarehouse.CreateBin(
            BinB,
            LocationB.Code,
            CopyStr(
                LibraryUtility.GenerateRandomCode(BinB.FieldNo(Code), DATABASE::Bin),
                1,
                LibraryUtility.GetFieldLength(DATABASE::Bin, BinB.FieldNo(Code))
            ),
            '',
            ''
        );
        LibraryWarehouse.CreateBinContent(
            BinContentB, BinB."Location Code", '', BinB.Code, ItemB."No.", '', ItemB."Base Unit of Measure"
        );

        // A job with an item planning line.
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.UsageLineTypeSchedule(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
    end;
}
