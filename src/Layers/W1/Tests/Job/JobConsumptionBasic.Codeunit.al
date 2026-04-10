codeunit 136300 "Job Consumption Basic"
{
    // This test codeunit tests all the different ways to consume something for a job:
    //
    // - job journal
    // - purchase order
    // - purchase invoice
    // - general journal
    //
    // All valid combinations (32) of account type (resource, g/l account, item) and job journal line type
    // (blank, budget, billable, both) are exercised.
    //
    // The following aspects are validated:
    //
    // - job ledger (number of entries, unit cost/price)
    // - job planning lines (number and type of lines, unit cost/price)
    // - g/l (job no.)

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job]
        IsInitialized := false;
    end;

    var
        DummyJobsSetup: Record "Jobs Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryJob: Codeunit "Library - Job";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        RollingBackChangesErr: Label 'Rolling back changes...';
        FieldValueIncorrectErr: Label 'Field %1 value is incorrect.';
        IsInitialized: Boolean;
        IsServiceTypeItemErr: Label 'Is Service Type item';
        IsNonInventoryTypeItemErr: Label 'Is Non-inventory Type item';
        IsInventoryTypeItemErr: Label 'Is Inventory Type item';
        TotalCostErr: Label '%1 must be %2 in %3', Comment = '%1 Total Cost, %2 = Unit Cost * Quanity of Job Ledger Entry, %3 = Job Ledger Entry';

    local procedure Initialize()
    var
        PurchasePrice: Record "Purchase Price";
        SalesPrice: Record "Sales Price";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Job Consumption Basic");

        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Job Consumption Basic");

        // Removing special prices
        PurchasePrice.DeleteAll(true);
        SalesPrice.DeleteAll(true);

        LibraryJob.ConfigureGeneralPosting();
        LibraryJob.ConfigureVATPosting();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        DummyJobsSetup."Allow Sched/Contract Lines Def" := false;
        DummyJobsSetup."Apply Usage Link by Default" := false;
        DummyJobsSetup.Modify();
        LibraryJob.SetJobNoSeriesCode();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Job Consumption Basic");
    end;

    [Normal]
    local procedure TearDown()
    begin
        asserterror Error(RollingBackChangesErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestJobJournalResBlank()
    begin
        JobJournalConsumption(LibraryJob.UsageLineTypeBlank(), LibraryJob.ResourceType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestJobJournalResSchedule()
    begin
        JobJournalConsumption(LibraryJob.UsageLineTypeSchedule(), LibraryJob.ResourceType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestJobJournalResContract()
    begin
        JobJournalConsumption(LibraryJob.UsageLineTypeContract(), LibraryJob.ResourceType());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestJobJournalResBoth()
    begin
        JobJournalConsumption(LibraryJob.UsageLineTypeBoth(), LibraryJob.ResourceType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestJobJournalGLAccBlank()
    begin
        JobJournalConsumption(LibraryJob.UsageLineTypeBlank(), LibraryJob.GLAccountType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestJobJournalGLAccSchedule()
    begin
        JobJournalConsumption(LibraryJob.UsageLineTypeSchedule(), LibraryJob.GLAccountType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestJobJournalGLAccContract()
    begin
        JobJournalConsumption(LibraryJob.UsageLineTypeContract(), LibraryJob.GLAccountType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestJobJournalGLAccountBoth()
    begin
        JobJournalConsumption(LibraryJob.UsageLineTypeBoth(), LibraryJob.GLAccountType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestJobJournalItemBlank()
    begin
        JobJournalConsumption(LibraryJob.UsageLineTypeBlank(), LibraryJob.ItemType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestJobJournalItemSchedule()
    begin
        JobJournalConsumption(LibraryJob.UsageLineTypeSchedule(), LibraryJob.ItemType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestJobJournalItemContract()
    begin
        JobJournalConsumption(LibraryJob.UsageLineTypeContract(), LibraryJob.ItemType())
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestJobJournalItemBoth()
    begin
        JobJournalConsumption(LibraryJob.UsageLineTypeBoth(), LibraryJob.ItemType())
    end;

    local procedure JobJournalConsumption(LineType: Enum "Job Line Type"; ConsumableType: Enum "Job Planning Line Type")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        TempJobJournalLine: Record "Job Journal Line" temporary;
    begin
        // Parameterized test

        // LineType IN ["",Budget,Billable,Both Budget and Billable]
        // Type IN [Resource,G/L Account,Item]

        // Setup
        Initialize();
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // Exercise
        LibraryJob.CreateJobJournalLineForType(LineType, ConsumableType, JobTask, JobJournalLine);

        // Verify
        VerifyJobJournalLineCostPrice(JobJournalLine);

        // Exercise
        LibraryJob.CopyJobJournalLines(JobJournalLine, TempJobJournalLine);
        LibraryJob.PostJobJournal(JobJournalLine);

        // Verify (planning lines and job ledger)
        LibraryJob.VerifyJobJournalPosting(false, TempJobJournalLine);

        TearDown();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestJobJournalMultipleLines()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        TempJobJournalLine: Record "Job Journal Line" temporary;
        Idx: Integer;
    begin
        // Setup
        Initialize();
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // Exercise
        // Create 2 - 5 job journal lines
        for Idx := 2 to 2 + LibraryRandom.RandInt(3) do
            LibraryJob.CreateJobJournalLineForType(
              "Job Line Type".FromInteger(LibraryRandom.RandInt(4) - 1), "Job Planning Line Type".FromInteger(LibraryRandom.RandInt(3) - 1), JobTask, JobJournalLine);

        VerifyJobJournalLineCostPrice(JobJournalLine);

        LibraryJob.CopyJobJournalLines(JobJournalLine, TempJobJournalLine);
        LibraryJob.PostJobJournal(JobJournalLine);

        // Verify (planning lines and job ledger)
        LibraryJob.VerifyJobJournalPosting(false, TempJobJournalLine);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrderJobGLAccBlank()
    begin
        JobPurchaseConsumption("Purchase Document Type"::Order, LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeBlank())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrderJobGLAccSchedule()
    begin
        JobPurchaseConsumption("Purchase Document Type"::Order, LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeSchedule())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrderJobGLAccContract()
    begin
        JobPurchaseConsumption("Purchase Document Type"::Order, LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeContract())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrderJobGLAccBoth()
    begin
        JobPurchaseConsumption("Purchase Document Type"::Order, LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeBoth())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrderJobItemBlank()
    begin
        JobPurchaseConsumption("Purchase Document Type"::Order, LibraryJob.ItemType(), LibraryJob.UsageLineTypeBlank())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrderJobItemSchedule()
    begin
        JobPurchaseConsumption("Purchase Document Type"::Order, LibraryJob.ItemType(), LibraryJob.UsageLineTypeSchedule())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrderJobItemContract()
    begin
        JobPurchaseConsumption("Purchase Document Type"::Order, LibraryJob.ItemType(), LibraryJob.UsageLineTypeContract())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrderJobItemBoth()
    begin
        JobPurchaseConsumption("Purchase Document Type"::Order, LibraryJob.ItemType(), LibraryJob.UsageLineTypeBoth())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchInvJobGLAccBlank()
    begin
        JobPurchaseConsumption("Purchase Document Type"::Invoice, LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeBlank())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchInvJobGLAccSchedule()
    begin
        JobPurchaseConsumption("Purchase Document Type"::Invoice, LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeSchedule())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchInvJobGLAccContract()
    begin
        JobPurchaseConsumption("Purchase Document Type"::Invoice, LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeContract())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchInvJobGLAccBoth()
    begin
        JobPurchaseConsumption("Purchase Document Type"::Invoice, LibraryJob.GLAccountType(), LibraryJob.UsageLineTypeBoth())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchInvJobItemBlank()
    begin
        JobPurchaseConsumption("Purchase Document Type"::Invoice, LibraryJob.ItemType(), LibraryJob.UsageLineTypeBlank())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchInvJobItemSchedule()
    begin
        JobPurchaseConsumption("Purchase Document Type"::Invoice, LibraryJob.ItemType(), LibraryJob.UsageLineTypeSchedule())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchInvJobItemContract()
    begin
        JobPurchaseConsumption("Purchase Document Type"::Invoice, LibraryJob.ItemType(), LibraryJob.UsageLineTypeContract())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchInvJobItemBoth()
    begin
        JobPurchaseConsumption("Purchase Document Type"::Invoice, LibraryJob.ItemType(), LibraryJob.UsageLineTypeBoth())
    end;

    local procedure JobPurchaseConsumption(PurchaseDocumentType: Enum "Purchase Document Type"; ConsumableType: Enum "Job Planning Line Type"; JobLineType: Enum "Job Line Type")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        JobLedgerEntry: Record "Job Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // Parameterized test

        // PurchaseDocumentType IN [Order,Invoice]
        // PurchaseLineType IN [Item,G/L Account]
        // JobLineType IN ["",Budget,Billable,Both Budget and Billable]

        // Setup
        Initialize();
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // Exercise
        CreateSingleLinePurchaseDoc(PurchaseDocumentType, PurchaseHeader);

        // Attach requested account type to the created purchase line
        GetPurchaseLines(PurchaseHeader, PurchaseLine);

        UpdatePurchLine(PurchaseLine, LibraryJob.Job2PurchaseConsumableType(ConsumableType));
        LibraryJob.AttachJobTask2PurchaseLine(JobTask, PurchaseLine);
        PurchaseLine.Validate("Job Line Type", JobLineType);
        PurchaseLine.Description := LibraryUtility.GenerateGUID();
        PurchaseLine.Modify(true);
        LibraryJob.CopyPurchaseLines(PurchaseLine, TempPurchaseLine);
        PostPurchaseDocument(PurchaseHeader, PurchInvHeader);

        // Verify (planning lines, job ledger)
        LibraryJob.VerifyPurchaseDocPostingForJob(TempPurchaseLine);
        JobLedgerEntry.SetRange(Description, TempPurchaseLine.Description);
        Assert.AreEqual(1, JobLedgerEntry.Count, '# job ledger entries');
        JobLedgerEntry.FindFirst();

        LibraryJob.VerifyGLEntries(JobLedgerEntry);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJobGLJournalBlank()
    begin
        JobGLJournalConsumption(LibraryJob.UsageLineTypeBlank())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJobGLJournalSchedule()
    begin
        JobGLJournalConsumption(LibraryJob.UsageLineTypeSchedule())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJobGLJournalContract()
    begin
        JobGLJournalConsumption(LibraryJob.UsageLineTypeContract())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJobGLJournalBoth()
    begin
        JobGLJournalConsumption(LibraryJob.UsageLineTypeBoth())
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJobGLJournalUpdateVATAmount()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobGenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        MaxVATDiff: Decimal;
    begin
        // [SCENARIO 360964] Job G/l Journal field Job Total Cost is updated after users changes VAT Amount
        // [GIVEN] Enable Allow VAT Difference for General Ledger Setup and Job Journal Batch/Template
        Initialize();
        MaxVATDiff := SetupJobJournalVATDifference(GenJournalBatch);
        // [GIVEN] Job and Job Task
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Job G/L Journal Line
        CreateJobGLJournalLineGLAccWithVATPostingSetup(JobGenJournalLine, JobTask, JobGenJournalLine."Job Line Type"::" ", GenJournalBatch);
        // [WHEN] User modifies VAT Amount within the 'Max. VAT Difference Allowed' limit
        JobGenJournalLine.Validate(
          "VAT Amount",
          JobGenJournalLine."VAT Amount" + LibraryRandom.RandDecInDecimalRange(0, MaxVATDiff, 2));
        // [THEN] Job Total Cost is updated involving updated VAT Amount value
        Assert.AreEqual(
          JobGenJournalLine.Amount - JobGenJournalLine."VAT Amount",
          JobGenJournalLine."Job Total Cost",
          StrSubstNo(FieldValueIncorrectErr, JobGenJournalLine."Job Total Cost"));
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceWIthNegativeAmountAssignsActualCostToJobUsageEntry()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        VendorNo: Code[20];
        Qty: Integer;
    begin
        // [FEATURE] [Purchase] [Receipt] [Invoice]
        // [SCENARIO] Purchase invoice for a receipt with job and negative quantity should assign actual cost amount to both item ledger entries - purchase receipt and job usage

        Initialize();

        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // Item "I" with unit cost 100
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(200, 2));
        Item.Modify(true);

        VendorNo := LibraryPurchase.CreateVendorNo();
        Qty := LibraryRandom.RandInt(100);

        // [GIVEN] Post purchase receipt for 5 psc of item "I" with job "J"
        PostPurchaseReceiptWithJob(VendorNo, Item."No.", Qty, JobTask);
        // [GIVEN] Post purchase receipt for -5 psc of item "I" with job "J"
        PostPurchaseReceiptWithJob(VendorNo, Item."No.", -Qty, JobTask);

        // [GIVEN] Create purchase invoice and get receipt lines
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        GetPurchaseReceiptLines(VendorNo, PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [WHEN] Post the invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] All inbound item ledger entries have "Cost Amount (Actual)" = 500, outbound entries - "Cost Amount (Actual)" = -500, "Cost Amount (Expected)" = 0 for all entries
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
            ItemLedgerEntry.TestField("Cost Amount (Actual)", Item."Unit Cost" * ItemLedgerEntry.Quantity);
            ItemLedgerEntry.TestField("Cost Amount (Expected)", 0);
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure JobGLJournalConsumption(JobLineType: Enum "Job Line Type")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobGenJournalLine: Record "Gen. Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Parameterized test

        // JobLineType IN ["",Budget,Billable,Both Budget and Billable]

        // Setup
        Initialize();
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobGLJournalLineGLAcc(JobGenJournalLine, JobTask, JobLineType);

        // Exercise
        LibraryERM.PostGeneralJnlLine(JobGenJournalLine);

        // Verify (planning lines, job ledger)
        VerifyJobGenJournalPosting(JobGenJournalLine);

        JobLedgerEntry.SetRange(Description, JobGenJournalLine.Description);
        Assert.AreEqual(1, JobLedgerEntry.Count, 'Found multiple job ledger entries.');
        LibraryJob.VerifyGLEntries(JobLedgerEntry);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineIsNonInventoriableItemTypeGLAccount()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [FEATURE] [Job] [Item] [Item Type] [UT]
        // [SCENARIO 260178] Function "Job Planning Line".IsNonInventoriableItem returns FALSE when Type is "G/L Account".
        MockJobPlanningLine(JobPlanningLine);
        JobPlanningLine.Type := JobPlanningLine.Type::"G/L Account";
        JobPlanningLine.Modify();
        Assert.IsFalse(JobPlanningLine.IsNonInventoriableItem(), IsInventoryTypeItemErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineIsNonInventoriableItemNoBlank()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [FEATURE] [Job] [Item] [Item Type] [UT]
        // [SCENARIO 260178] Function "Job Planning Line".IsNonInventoriableItem returns FALSE when "No." is blank.
        MockJobPlanningLine(JobPlanningLine);
        JobPlanningLine.Type := JobPlanningLine.Type::Item;
        JobPlanningLine.Modify();
        Assert.IsFalse(JobPlanningLine.IsNonInventoriableItem(), IsInventoryTypeItemErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineIsNonInventoriableItemTypeInventory()
    var
        JobPlanningLine: Record "Job Planning Line";
        Item: Record Item;
    begin
        // [FEATURE] [Job] [Item] [Item Type] [UT]
        // [SCENARIO 260178] Function "Job Planning Line".IsNonInventoriableItem returns FALSE when Item.Type is Inventory.
        MockItem(Item);
        MockJobPlanningLine(JobPlanningLine);
        JobPlanningLine.Type := JobPlanningLine.Type::Item;
        JobPlanningLine."No." := Item."No.";
        JobPlanningLine.Modify();
        Assert.IsFalse(JobPlanningLine.IsNonInventoriableItem(), IsInventoryTypeItemErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineIsNonInventoriableItemTypeService()
    var
        JobPlanningLine: Record "Job Planning Line";
        Item: Record Item;
    begin
        // [FEATURE] [Job] [Item] [Item Type] [UT]
        // [SCENARIO 260178] Function "Job Planning Line".IsNonInventoriableItem returns TRUE when Item.Type is Service.
        MockItem(Item);
        Item.Type := Item.Type::Service;
        Item.Modify();

        MockJobPlanningLine(JobPlanningLine);
        JobPlanningLine.Type := JobPlanningLine.Type::Item;
        JobPlanningLine."No." := Item."No.";
        JobPlanningLine.Modify();
        Assert.IsTrue(JobPlanningLine.IsNonInventoriableItem(), IsServiceTypeItemErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineIsNonInventoriableItemTypeNonInventory()
    var
        JobPlanningLine: Record "Job Planning Line";
        Item: Record Item;
    begin
        // [FEATURE] [Job] [Item] [Item Type] [UT]
        // [SCENARIO 260178] Function "Job Planning Line".IsNonInventoriableItem returns TRUE when Item.Type is Non-inventory.
        MockItem(Item);
        Item.Type := Item.Type::"Non-Inventory";
        Item.Modify();

        MockJobPlanningLine(JobPlanningLine);
        JobPlanningLine.Type := JobPlanningLine.Type::Item;
        JobPlanningLine."No." := Item."No.";
        JobPlanningLine.Modify();
        Assert.IsTrue(JobPlanningLine.IsNonInventoriableItem(), IsNonInventoryTypeItemErr);
    end;

    [Test]
    procedure TotalCostInProjectLedgerEntryHavingCurrencyCodeIsCalculatedWithUnitOfMeasureCode()
    var
        Currency: Record Currency;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        UnitOfMeasure: Record "Unit of Measure";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 551005] Total Unit Cost in Job Ledger Entry having Currency Code is calculated based on Unit of Measure Code selected.
        Initialize();

        // [GIVEN] Create a Currency.
        LibraryERM.CreateCurrency(Currency);

        // [GIVEN] Create a Random Currency Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);

        // [GIVEN] Create an Item and Validate Unit Cost.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Unit of Measure Code.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Create an Item Unit of Measure.
        LibraryInventory.CreateItemUnitOfMeasure(
            ItemUnitOfMeasure,
            Item."No.",
            UnitOfMeasure.Code,
            LibraryRandom.RandIntInRange(100, 100));

        // [GIVEN] Create a Job and a Job task.
        CreateJobAndJobTask(Job, JobTask, false, Currency.Code);

        // [GIVEN] Create a Vendor and Validate Currency Code.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", Currency.Code);
        Vendor.Modify(true);

        // [GIVEN] Create a Job Planning Line and Validate Type and No.
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Modify(true);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] Create a Purchase Line.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::Item,
            Item."No.",
            LibraryRandom.RandIntInRange(5, 5));

        // [GIVEN] Validate Job No., Job Task No., Unit of Measure Code and Direct Unit Cost in Purchase Line.
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 100));
        PurchaseLine.Modify(true);

        // [GIVEN] Post Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [WHEN] Find Job Ledger Entry.
        JobLedgerEntry.SetRange("Job No.", Job."No.");
        JobLedgerEntry.FindFirst();

        // [THEN] Total Cost in Job Ledger Entry is equal to Unit Cost * Quantity of Job Ledger Entry.
        Assert.AreEqual(
            JobLedgerEntry."Unit Cost" * JobLedgerEntry.Quantity,
            JobLedgerEntry."Total Cost",
            StrSubstNo(
                TotalCostErr,
                JobLedgerEntry.FieldCaption("Total Cost"),
                JobLedgerEntry."Unit Cost" * JobLedgerEntry.Quantity,
                JobLedgerEntry.TableCaption()));
    end;

    local procedure CreateSingleLinePurchaseDoc(PurchaseDocumentType: Enum "Purchase Document Type"; var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create a purchase document with a single line.
        CreateSingleLinePurchDocWithVendorAndItem(
          PurchaseHeader, PurchaseLine, PurchaseDocumentType, LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo(),
          LibraryRandom.RandInt(100));
    end;

    local procedure CreateSingleLinePurchDocWithVendorAndItem(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PurchaseDocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseDocumentType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
    end;

    local procedure CreateJobGLJournalLineGLAcc(var GenJournalLine: Record "Gen. Journal Line"; JobTask: Record "Job Task"; JobLineType: Enum "Job Line Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        SelectJobGLJournalBatch(GenJournalBatch);
        CreateJobGLJournalLine(GenJournalLine, JobTask, JobLineType, GLAccount."No.", GenJournalBatch);
    end;

    local procedure CreateJobGLJournalLineGLAccWithVATPostingSetup(var GenJournalLine: Record "Gen. Journal Line"; JobTask: Record "Job Task"; JobLineType: Enum "Job Line Type"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        CreateJobGLJournalLine(GenJournalLine, JobTask, JobLineType, LibraryERM.CreateGLAccountWithSalesSetup(), GenJournalBatch);
    end;

    local procedure CreateJobGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; JobTask: Record "Job Task"; JobLineType: Enum "Job Line Type"; GLAccountNo: Code[20]; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Job Line Type", JobLineType);
        GenJournalLine.Validate("Job No.", JobTask."Job No.");
        GenJournalLine.Validate("Job Task No.", JobTask."Job Task No.");
        GenJournalLine.Validate("Job Quantity", LibraryRandom.RandInt(10));
        GenJournalLine.Validate("Job Line Type", JobLineType);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroupCode: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, VATProductPostingGroup.Code);
        if VATPostingSetup."VAT Identifier" = '' then
            VATPostingSetup.Validate("VAT Identifier", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(5, 25));
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure MockJobPlanningLine(var JobPlanningLine: Record "Job Planning Line")
    var
        RecordRef: RecordRef;
    begin
        JobPlanningLine."Job No." := LibraryUtility.GenerateRandomCode20(
            JobPlanningLine.FieldNo("Job No."), DATABASE::"Job Planning Line");
        JobPlanningLine."Job Task No." := LibraryUtility.GenerateRandomCode20(
            JobPlanningLine.FieldNo("Job Task No."), DATABASE::"Job Planning Line");
        RecordRef.GetTable(JobPlanningLine);
        JobPlanningLine."Line No." := LibraryUtility.GetNewLineNo(RecordRef, JobPlanningLine.FieldNo("Line No."));
        JobPlanningLine.Insert();
    end;

    local procedure MockItem(var Item: Record Item)
    begin
        Item."No." := LibraryUtility.GenerateRandomCode20(Item.FieldNo("No."), DATABASE::Item);
        Item.Insert();
    end;

    local procedure PostPurchaseDocument(PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        // Receive and invoice the purchase document
        // Returns the purchase invoice.

        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Order:
                begin
                    LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
                    PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true))
                end;
            PurchaseHeader."Document Type"::Invoice:
                PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true))
            else
                Assert.Fail(StrSubstNo('Unsupported document type %1', PurchaseHeader."Document Type"));
        end
    end;

    local procedure GetPurchaseLines(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
    end;

    local procedure GetPurchaseReceiptLines(VendorNo: Code[20]; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchRcptLine.SetRange("Buy-from Vendor No.", VendorNo);
        PurchRcptLine.FindSet();
        repeat
            PurchaseLine."Document Type" := DocumentType;
            PurchaseLine."Document No." := DocumentNo;
            LibraryVariableStorage.Enqueue(PurchRcptLine."Document No.");
            LibraryVariableStorage.Enqueue(PurchRcptLine."Line No.");
            LibraryPurchase.GetPurchaseReceiptLine(PurchaseLine);
        until PurchRcptLine.Next() = 0;
    end;

    local procedure PostPurchaseReceiptWithJob(VendorNo: Code[20]; ItemNo: Code[20]; Qty: Decimal; JobTask: Record "Job Task")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateSingleLinePurchDocWithVendorAndItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, VendorNo, ItemNo, Qty);
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure UpdatePurchLine(var PurchLine: Record "Purchase Line"; ConsumableType: Enum "Purchase Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
    begin
        if ConsumableType <> PurchLine.Type::Item then
            LibraryJob.Attach2PurchaseLine(ConsumableType, PurchLine)
        else begin
            CreateVATPostingSetup(VATPostingSetup, PurchLine."VAT Bus. Posting Group");
            PurchLine.Validate(Type, ConsumableType);
            LibraryInventory.CreateItem(Item);
            Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            Item.Modify(true);
            PurchLine.Validate("No.", Item."No.");
            PurchLine.Validate(Quantity, LibraryRandom.RandInt(100));
            PurchLine.Modify(true)
        end;
    end;

    local procedure SelectJobGLJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure VerifyJobGenJournalPosting(GenJournalLine: Record "Gen. Journal Line")
    var
        TempJobJournalLine: Record "Job Journal Line" temporary;
    begin
        // Use a job journal line to verify a posted general journal line.
        TempJobJournalLine."Job No." := GenJournalLine."Job No.";
        TempJobJournalLine."Job Task No." := GenJournalLine."Job Task No.";
        TempJobJournalLine."Document No." := GenJournalLine."Document No.";
        TempJobJournalLine.Description := GenJournalLine.Description;
        TempJobJournalLine."Line Type" := GenJournalLine."Job Line Type";
        TempJobJournalLine.Quantity := GenJournalLine."Job Quantity";
        TempJobJournalLine."Unit Cost (LCY)" := GenJournalLine."Job Unit Cost (LCY)";
        TempJobJournalLine."Unit Price (LCY)" := GenJournalLine."Job Unit Price (LCY)";
        TempJobJournalLine.Insert();

        LibraryJob.VerifyJobJournalPosting(false, TempJobJournalLine)
    end;

    local procedure VerifyJobJournalLineCostPrice(JobJournalLine: Record "Job Journal Line")
    var
        Resource: Record Resource;
        Item: Record Item;
        GeneralLedgerSetup: Record "General Ledger Setup";
        UnitCost: Decimal;
        UnitPrice: Decimal;
    begin
        case JobJournalLine.Type of
            JobJournalLine.Type::Resource:
                begin
                    Resource.Get(JobJournalLine."No.");
                    UnitCost := Resource."Unit Cost";
                    UnitPrice := Resource."Unit Price"
                end;
            JobJournalLine.Type::Item:
                begin
                    Item.Get(JobJournalLine."No.");
                    UnitCost := Item."Unit Cost";
                    UnitPrice := Item."Unit Price"
                end;
            JobJournalLine.Type::"G/L Account":
                begin
                    UnitCost := JobJournalLine."Unit Cost (LCY)";
                    UnitPrice := JobJournalLine."Unit Price (LCY)"
                end;
            else
                Assert.Fail(StrSubstNo('Job journal line account type %1 not supported.', Format(JobJournalLine.Type)))
        end;
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(UnitCost, JobJournalLine."Unit Cost (LCY)",
          GeneralLedgerSetup."Unit-Amount Rounding Precision", StrSubstNo('JobJournalLine."Unit Cost (LCY)", %1', JobJournalLine."No."));
        Assert.AreNearlyEqual(UnitPrice, JobJournalLine."Unit Price (LCY)",
          GeneralLedgerSetup."Unit-Amount Rounding Precision", StrSubstNo('JobJournalLine."Unit Price (LCY)", %1', JobJournalLine."No."))
    end;

    local procedure UpdateGeneralLedgerSetupMaxVATDiff(MaxVATDiffAmt: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Max. VAT Difference Allowed", MaxVATDiffAmt);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure SetupJobJournalVATDifference(var GenJournalBatch: Record "Gen. Journal Batch") MaxVATDiff: Decimal
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        MaxVATDiff := LibraryRandom.RandDec(2, 2);
        UpdateGeneralLedgerSetupMaxVATDiff(MaxVATDiff);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Jobs);
        GenJournalTemplate.Validate("Allow VAT Difference", true);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Allow VAT Difference", true);
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateSimpleJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task")
    begin
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", JobTask."Job No.");
        JobPlanningLine.Validate("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.Validate("Line No.", LibraryJob.GetNextLineNo(JobPlanningLine));
        JobPlanningLine.Insert(true);
    end;

    local procedure CreateJobAndJobTask(var Job: Record Job; var JobTask: Record "Job Task"; ApplyUsageLink: Boolean; CurrencyCode: Code[10])
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", ApplyUsageLink);
        Job.Validate("Currency Code", CurrencyCode);
        Job.Modify(true);

        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
        Assert.IsTrue(StrPos(Msg, 'The journal lines were successfully posted.') = 1,
          StrSubstNo('Unexpected Message: %1', Msg))
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReceiptLinesPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    begin
        GetReceiptLines.GotoKey(LibraryVariableStorage.DequeueText(), LibraryVariableStorage.DequeueInteger());
        GetReceiptLines.OK().Invoke();
    end;
}
