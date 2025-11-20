codeunit 136305 "Job Journal"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job]
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        FieldCodeError: Label '%1 cannot be specified when %2 is %3.';
        TestForBlankValuesPassed: Label 'It was expected a known failure for ''%1'', since it contains invalid blank field values.';
        RecordNotFound: Label 'DB:RecordNotFound';
        JobPlanningLineError: Label '%1 must not be %2 in Project Planning Line Project No.=''%3'',Project Task No.=''%4'',Line No.=''%5''.', Comment = '%1: Field Caption;%2: Project Planning Type Value;%3:Project No; %4 Project Task No;%5: Line No';
        Initialized: Boolean;
        NoSeriesCode: Code[20];
        SourceCodeEqualError: Label '%1 in %2 must not be equal to %3 in %4.', Comment = '%1=Field,%2=TableName,%3=Fieldname,%4=TableName';
        IncorrectFieldValueErr: Label 'Incorrect field value %1.';
        AmountErr: Label 'Amount must be right';
        CurrencyDateConfirmTxt: Label 'The currency dates on all planning lines will be updated based on the invoice posting date because there is a difference in currency exchange rates. Recalculations will be based on the Exch. Calculation setup for the Cost and Price values for the project. Do you want to continue?';
        ControlNotFoundErr: Label 'Expected control not found on the page';
        ProjectTotalCostErr: Label 'Project Total Cost(LCY) must be updated.';

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostOnJobJournalLine()
    var
        Resource: Record Resource;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ResourceNo: Code[20];
    begin
        // [SCENARIO] Test Unit Cost, Unit Price on Job Journal Line.

        // [GIVEN] A Job with Job Task and Resource.
        Initialize();
        CreateJobWithJobTask(JobTask);
        ResourceNo := LibraryJob.CreateConsumable("Job Planning Line Type"::Resource);
        Resource.Get(ResourceNo);

        // [WHEN] Creating Job Journal Line with created Resource.
        CreateJobJournalLine(JobJournalLine, JobTask, Resource."No.");

        // [THEN] Verify values on Job Journal Lines.
        VerifyJobJournalLine(JobJournalLine, Resource, Resource."Base Unit of Measure", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeUOMOnJobJournalLine()
    var
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        Resource: Record Resource;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ResourceNo: Code[20];
    begin
        // [SCENARIO] Test Unit Cost, Unit Price on Job Journal Line after changing Unit of Measure.

        // [GIVEN] A Job with Job Task, Resource and Create another Resource Unit Of Measure.
        Initialize();
        CreateJobWithJobTask(JobTask);
        ResourceNo := LibraryJob.CreateConsumable("Job Planning Line Type"::Resource);
        Resource.Get(ResourceNo);
        CreateResourceUnitOfMeasure(ResourceUnitOfMeasure, Resource);

        // [WHEN] Creating Job Journal Line with created Resource and Change Unit of Measure on Job Journal Line.
        CreateJobJournalLine(JobJournalLine, JobTask, Resource."No.");
        JobJournalLine.Validate("Unit of Measure Code", ResourceUnitOfMeasure.Code);
        JobJournalLine.Modify(true);

        // [THEN] Verify values on Job Journal Lines.
        VerifyJobJournalLine(JobJournalLine, Resource, ResourceUnitOfMeasure.Code, ResourceUnitOfMeasure."Qty. per Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostOnJobPlanningLine()
    var
        Resource: Record Resource;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ResourceNo: Code[20];
    begin
        // [SCENARIO] Test Unit Cost, Unit Price on Job Planning Line.

        // [GIVEN] A Job with Job Task and Resource.
        Initialize();
        CreateJobWithJobTask(JobTask);
        ResourceNo := LibraryJob.CreateConsumable("Job Planning Line Type"::Resource);
        Resource.Get(ResourceNo);

        // [WHEN] Creating Job Planning Line with created Resource.
        CreateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable, Resource."No.", JobPlanningLine.Type::Resource);

        // [THEN] Verify values on Job Planning Lines.
        VerifyCostAndPriceOnJobPlanningLine(JobPlanningLine, Resource, Resource."Base Unit of Measure", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeUOMOnJobPlanningLine()
    var
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        Resource: Record Resource;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ResourceNo: Code[20];
    begin
        // [SCENARIO] Test Unit Cost, Unit Price on Job Planning Line after changing Unit of Measure.

        // [GIVEN] A Job with Job Task, Resource and Create another Resource Unit Of Measure.
        Initialize();
        CreateJobWithJobTask(JobTask);
        ResourceNo := LibraryJob.CreateConsumable("Job Planning Line Type"::Resource);
        Resource.Get(ResourceNo);
        CreateResourceUnitOfMeasure(ResourceUnitOfMeasure, Resource);

        // [WHEN] Creating Job Planning Line with created Resource and Change Unit of Measure on Job Planning Line.
        CreateJobPlanningLineAndModifyUOM(
          JobPlanningLine, JobTask, JobPlanningLine.Type::Resource, Resource."No.", ResourceUnitOfMeasure.Code);

        // [THEN] Verify values on Job Planning Lines.
        VerifyCostAndPriceOnJobPlanningLine(
          JobPlanningLine, Resource, ResourceUnitOfMeasure.Code, ResourceUnitOfMeasure."Qty. per Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('JobJournalTemplateListPageHandler,ItemUnitsOfMeasurePageHandler')]
    [Scope('OnPrem')]
    procedure LookupItemUnitOfMeasureJobJournal()
    var
        JobJournalLine: Record "Job Journal Line";
        Item: Record Item;
        UnitOfMeasureCode: Code[10];
    begin
        // [SCENARIO 362516] Lookup "Unit of Measure" for Item on page "Job Journal" opening and containing relevant data
        LightInit();
        // [GIVEN] Item - "I" with "Unit of Measure" - "UM"
        LibraryInventory.CreateItem(Item);
        UnitOfMeasureCode := Item."Base Unit of Measure";
        // [GIVEN] Job Journal Line, where "Type" = "Item" with Item "I"
        CreateJobJournalLineWithBlankUOM(JobJournalLine, Item."No.", JobJournalLine.Type::Item);
        LibraryVariableStorage.Enqueue(JobJournalLine."Journal Template Name");
        // [WHEN] Lookup "Unit of Measure" in Job Journal Line
        OpenJobJournalAndLookupUnitofMeasure(JobJournalLine."Journal Batch Name");
        // [THEN] Page "Item Units of Measure" is open and contains lines related to Item "I"
        // [THEN] "JJL"."Unit of Measure" = "UM"
        JobJournalLine.Find();
        Assert.AreEqual(UnitOfMeasureCode, JobJournalLine."Unit of Measure Code",
          JobJournalLine.FieldCaption("Unit of Measure Code"));
    end;

    [Test]
    [HandlerFunctions('JobJournalTemplateListPageHandler,ResourceUnitsOfMeasurePageHandler')]
    [Scope('OnPrem')]
    procedure LookupResourceUnitOfMeasureJobJournal()
    var
        JobJournalLine: Record "Job Journal Line";
        ResourceNo: Code[20];
        UnitOfMeasureCode: Code[10];
    begin
        // [SCENARIO 362516] Lookup "Unit of Measure" for Resource on page "Job Journal" opening and containing relevant data
        LightInit();
        // [GIVEN] Resource - "R" with "Unit of Measure" - "UM"
        ResourceNo := CreateResourceNo(UnitOfMeasureCode);
        // [GIVEN] Job Journal Line, where "Type" = "Resource" with Resource "R"
        CreateJobJournalLineWithBlankUOM(JobJournalLine, ResourceNo, JobJournalLine.Type::Resource);
        LibraryVariableStorage.Enqueue(JobJournalLine."Journal Template Name");
        // [WHEN] Lookup "Unit of Measure" in Job Journal Line
        OpenJobJournalAndLookupUnitofMeasure(JobJournalLine."Journal Batch Name");
        // [THEN] Page "Resource Units of Measure" is open and contains lines related to Resource "R"
        // [THEN] "JJL"."Unit of Measure" = "UM"
        JobJournalLine.Find();
        Assert.AreEqual(UnitOfMeasureCode, JobJournalLine."Unit of Measure Code",
          JobJournalLine.FieldCaption("Unit of Measure Code"));
    end;

    [Test]
    [HandlerFunctions('JobJournalTemplateListPageHandler,UnitsOfMeasurePageHandler')]
    [Scope('OnPrem')]
    procedure LookupUnitOfMeasureJobJournal()
    var
        JobJournalLine: Record "Job Journal Line";
        UnitOfMeasure: Record "Unit of Measure";
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 362516] Lookup "Unit of Measure" for "G/L Account" on page "Job Journal" opening and containing data
        LightInit();
        // [GIVEN] "G/L Account" - "GLA" and "Unit of Measure" - "UM"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        // [GIVEN] Job Journal Line "Type" = "G/L Account" with "GLA"
        CreateJobJournalLineWithBlankUOM(JobJournalLine, GLAccountNo, JobJournalLine.Type::"G/L Account");
        LibraryVariableStorage.Enqueue(JobJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(UnitOfMeasure.Code);
        // [WHEN] Lookup "Unit of Measure" in Job Journal Line
        OpenJobJournalAndLookupUnitofMeasure(JobJournalLine."Journal Batch Name");
        // [THEN] Page "Units of Measure" is open and contains lines
        // [THEN] "JJL"."Unit of Measure" = "UM"
        JobJournalLine.Find();
        Assert.AreEqual(UnitOfMeasure.Code, JobJournalLine."Unit of Measure Code",
          JobJournalLine.FieldCaption("Unit of Measure Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostFactorOnJobGLJournalLine()
    var
        JobTask: Record "Job Task";
        JobGLAccountPrice: Record "Job G/L Account Price";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PriceListLine: Record "Price List Line";
        JobUnitCost: Decimal;
        JobUnitPrice: Decimal;
    begin
        // [SCENARIO] Test Job Unit Cost, Job Unit Price on Job G/L Journal Line when Unit Cost Factor is defined on Job Card.
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] A Job with Job Task and Job G/L Account Price.
        CreateJobJournalBatch(GenJournalBatch);
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobGLAccountPrice(
          JobGLAccountPrice, JobTask."Job No.", JobTask."Job Task No.", LibraryERM.CreateGLAccountNo(), '');
        UpdateUnitCostFactorOnJobGLAccountPrice(JobGLAccountPrice);
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [WHEN] Creating Job G/L Journal Line, Taking rounding precision as used in General Journal Line Table rounding precision.
        CreateJobGLJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Bal. Account Type"::"G/L Account", JobGLAccountPrice."G/L Account No.",
          LibraryERM.CreateGLAccountNo(), JobGLAccountPrice."Job No.", JobGLAccountPrice."Job Task No.", '');  // Passing Blank for Currency Code.
        JobUnitCost := GenJournalLine.Amount / GenJournalLine."Job Quantity";
        JobUnitPrice :=
          Round(
            (GenJournalLine.Amount / GenJournalLine."Job Quantity") * JobGLAccountPrice."Unit Cost Factor",
            LibraryJob.GetUnitAmountRoundingPrecision(GenJournalLine."Currency Code"));

        // [THEN] Verify values on Job G/L Journal Lines.
        VerifyJobGLJournalLine(GenJournalLine, JobUnitCost, JobUnitPrice);

        // Tear Down: Delete newly created batch.
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        GenJournalBatch.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateLineAmountOnJobJournalLine()
    var
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ResourceNo: Code[20];
        LineAmount: Decimal;
        LineDiscountAmount: Decimal;
        LineDiscountPct: Decimal;
    begin
        // [SCENARIO] Test Line Discount Amount and Line Discount Percentage on Job Journal Line after updating Line Amount.

        // [GIVEN] A Job with Job Task and Job Journal Line.
        Initialize();
        CreateJobWithJobTask(JobTask);
        ResourceNo := LibraryJob.CreateConsumable("Job Planning Line Type"::Resource);
        CreateJobJournalLine(JobJournalLine, JobTask, ResourceNo);
        LineAmount := JobJournalLine."Line Amount";

        // [WHEN] Updating Line Amount on Job Journal Line, Taking rounding precision as used in Job Journal Line Table rounding precision.
        JobJournalLine.Validate("Line Amount", JobJournalLine."Line Amount" - LibraryUtility.GenerateRandomFraction());  // Update Line Amount for generating Line Discount Amount.
        JobJournalLine.Modify(true);
        LineDiscountAmount := LineAmount - JobJournalLine."Line Amount";
        LineDiscountPct := Round((LineDiscountAmount / LineAmount) * 100, 0.00001);

        // [THEN] Verify Line Discount Amount and Line Discount Percentage.
        JobJournalLine.Get(JobJournalLine."Journal Template Name", JobJournalLine."Journal Batch Name", JobJournalLine."Line No.");
        JobJournalLine.TestField("Line Discount Amount", LineDiscountAmount);
        JobJournalLine.TestField("Line Discount %", LineDiscountPct);

        // Tear Down: Delete newly created batch.
        DeleteJobJournalTemplate(JobJournalLine."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobItemPriceCreation()
    var
        JobItemPrice: Record "Job Item Price";
    begin
        // [SCENARIO] Test the creation of Job Item Price.

        Initialize();

        // [WHEN] Creating a job item price
        CreateJobItemPrice(JobItemPrice);

        // [THEN] Verify the creation of Job Item Price, by getting the created line.
        JobItemPrice.Get(
          JobItemPrice."Job No.", JobItemPrice."Job Task No.", JobItemPrice."Item No.", JobItemPrice."Variant Code",
          JobItemPrice."Unit of Measure Code", JobItemPrice."Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobItemPriceWithBlankJobNo()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        JobItemPrice: Record "Job Item Price";
    begin
        // [SCENARIO] Test the error message while creating the Job Item Price with blank Job No.

        // [GIVEN] A Job with a Job Task
        Initialize();
        Item.Get(LibraryJob.FindItem());
        CreateJobWithJobTask(JobTask);

        // [WHEN] Creating the Job Item Price with blank Job No.
        asserterror LibraryJob.CreateJobItemPrice(JobItemPrice, '', JobTask."Job Task No.", Item."No.", '', '', Item."Base Unit of Measure");  // Blank value is for Job No., Currency Code and Variant Code.

        // [THEN] Verify error message for Blank Job No.
        Assert.ExpectedTestFieldError(JobItemPrice.FieldCaption("Job No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobItemPriceWithBlankJobTaskNo()
    var
        Item: Record Item;
        Job: Record Job;
        JobItemPrice: Record "Job Item Price";
    begin
        // [SCENARIO] Test Job Item Price creation with blank Job Task No.

        // [GIVEN] An Item and a Job
        Initialize();
        Item.Get(LibraryJob.FindItem());
        LibraryJob.CreateJob(Job);

        // [WHEN] Creating the Job Item Price
        LibraryJob.CreateJobItemPrice(JobItemPrice, Job."No.", '', Item."No.", '', '', Item."Base Unit of Measure");  // Blank value is for Job Task No., Currency Code and Variant Code.

        // [THEN] Verify that the Job Item Price can be retrieved
        JobItemPrice.Get(
          JobItemPrice."Job No.", JobItemPrice."Job Task No.", JobItemPrice."Item No.", JobItemPrice."Variant Code",
          JobItemPrice."Unit of Measure Code", JobItemPrice."Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobItemPriceWithJobTaskNoWithTypeNotPosting()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        JobItemPrice: Record "Job Item Price";
    begin
        // [SCENARIO] Test the error message when create Job Item Price with Job Task No. whose Job Task type is not Posting.

        // [GIVEN] A Job with a Job Task where the Job Task Type is not posting
        Initialize();
        Item.Get(LibraryJob.FindItem());
        CreateJobWithJobTask(JobTask);
        JobTask.Validate("Job Task Type", JobTask."Job Task Type"::"Begin-Total");
        JobTask.Modify(true);

        // [WHEN] Creating the Job Item Price
        asserterror LibraryJob.CreateJobItemPrice(
            JobItemPrice, JobTask."Job No.", JobTask."Job Task No.", Item."No.", '', '', Item."Base Unit of Measure");  // Blank value is for Currency Code and Variant Code.

        // [THEN] Verify the contents of the error message
        Assert.ExpectedTestFieldError(JobTask.FieldCaption("Job Task Type"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceOnJobItemPrice()
    var
        JobItemPrice: Record "Job Item Price";
    begin
        // [SCENARIO] Test the Unit Price field becomes empty as Unit Cost Factor field is filled on the Job Item Price.

        // [GIVEN] A Job Item Price with Unit Price.
        Initialize();
        CreateJobItemPrice(JobItemPrice);
        ModifyJobItemPriceForUnitPrice(JobItemPrice, LibraryRandom.RandDec(100, 2));  // Use Random value for Unit Price.

        // [WHEN] The Unit Cost Factor is filled
        ModifyJobItemPriceForUnitCostFactor(JobItemPrice, LibraryRandom.RandDec(100, 2));  // Use Random value for Unit Cost Factor.

        // [THEN] The Unit Price is zero
        JobItemPrice.TestField("Unit Price", 0);  // Unit Price must be zero.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostFactorOnJobItemPrice()
    var
        JobItemPrice: Record "Job Item Price";
    begin
        // [SCENARIO] Test the Unit Cost Factor field becomes empty as Unit Price field is filled on the Job Item Price.

        // [GIVEN] A Job Item Price with Unit Cost Factor.
        Initialize();
        CreateJobItemPrice(JobItemPrice);
        ModifyJobItemPriceForUnitCostFactor(JobItemPrice, LibraryRandom.RandDec(100, 2));  // Use Random value for Unit Cost Factor.

        // [WHEN] The Unit Price is filled
        ModifyJobItemPriceForUnitPrice(JobItemPrice, LibraryRandom.RandDec(100, 2));  // Use Random value for Unit Price.

        // [THEN] The Unit Cost Factor is zero
        JobItemPrice.TestField("Unit Cost Factor", 0);  // Unit Cost Factor must be zero.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobItemPriceWithBlankItemNo()
    var
        JobTask: Record "Job Task";
        JobItemPrice: Record "Job Item Price";
    begin
        // [SCENARIO] Test the error message when create Job Item Price with blank Item No.

        // [GIVEN] A Job with a Job Task
        Initialize();
        CreateJobWithJobTask(JobTask);

        // [WHEN] Creating a Job Item Price with blank item no.
        asserterror LibraryJob.CreateJobItemPrice(JobItemPrice, JobTask."Job No.", JobTask."Job Task No.", '', '', '', '');  // Blank value is for Item No., Currency Code, Variant Code and Unit of Measure Code.

        // [THEN] Verify that the creation failed
        Assert.VerifyFailure(RecordNotFound, StrSubstNo(TestForBlankValuesPassed, JobItemPrice.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityErrorForTextTypeJobPlanningLine()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Check Error Message while updating Quantity on Job Planning Line when Type = TEXT.

        // [GIVEN] A Job Planning Line for Job with Text Type.
        Initialize();
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithTypeText(JobPlanningLine, JobPlanningLine."Line Type"::Budget, JobTask);

        // [WHEN] Trying to update Quantity when Type = Text on Job Planning Line.
        asserterror JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random value.

        // [THEN] Verify Error Message.
        Assert.ExpectedError(
          StrSubstNo(
            JobPlanningLineError, JobPlanningLine.FieldCaption(Type), JobPlanningLine.Type::Text, JobTask."Job No.",
            JobTask."Job Task No.", JobPlanningLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostingGroupOnJobLedgerEntry()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Check Job Posting Group In Job Ledger Entry after posting Sales Invoice created from Job Planning Line.

        // [GIVEN] A Job Planning Line for a new Job, Create Sales Invoice from Job Planning Line and find the created Sales Invoice.
        Initialize();
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        Commit();  // Using Commit to prevent Test Failure.
        LibraryVariableStorage.Enqueue(WorkDate());
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        FindSalesHeader(SalesHeader, SalesLine."Document Type"::Invoice, JobTask."Job No.", SalesLine.Type::Item);

        // [WHEN] Posting Sales Invoice created from Job Planning Line.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify that Job Posting Group on Job Ledger Entries has been taken from Item.
        VerifyPostingGroupOnJobLedgerEntry(DocumentNo, JobTask."Job No.", JobPlanningLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobResourcePricesWithTypeResource()
    var
        JobResourcePrice: Record "Job Resource Price";
    begin
        // [SCENARIO] Test the creation of Job Resource Price with Type Resource.

        Initialize();

        // [WHEN] Creating a Job Resource Price
        CreateJobResourcePrice(JobResourcePrice, JobResourcePrice.Type::Resource, LibraryResource.CreateResourceNo());

        // [THEN] Verify the creation of Job Resource Price.
        JobResourcePrice.Get(
          JobResourcePrice."Job No.", JobResourcePrice."Job Task No.", JobResourcePrice.Type::Resource, JobResourcePrice.Code,
          JobResourcePrice."Work Type Code", JobResourcePrice."Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobResourcePriceWithBlankJobNo()
    var
        JobResourcePrice: Record "Job Resource Price";
        JobTask: Record "Job Task";
    begin
        // [SCENARIO] Test the error message while creating the Job Resource Price with blank Job No.

        // [GIVEN] A Job with a Job Task
        Initialize();
        CreateJobWithJobTask(JobTask);

        // [WHEN] Using Blank value for Job No.
        asserterror LibraryJob.CreateJobResourcePrice(
            JobResourcePrice, '', JobTask."Job Task No.", JobResourcePrice.Type::Resource, LibraryResource.CreateResourceNo(), '', '');  // Blank value is for Work Type Code and Currency Code.

        // [THEN] Verify error message for Blank Job No.
        Assert.ExpectedTestFieldError(JobResourcePrice.FieldCaption("Job No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobResourcePriceWithBlankJobTaskNo()
    var
        Resource: Record Resource;
        Job: Record Job;
        JobResourcePrice: Record "Job Resource Price";
    begin
        // [SCENARIO] Test Job Resource Price creation with blank Job Task No.

        // [GIVEN] A Job and a Resource
        Initialize();
        Resource.Get(LibraryResource.CreateResourceNo());
        LibraryJob.CreateJob(Job);

        // [WHEN] Creating a Job Resource Price
        LibraryJob.CreateJobResourcePrice(JobResourcePrice, Job."No.", '', JobResourcePrice.Type, Resource."No.", '', '');  // Blank value is for Job Task No., Work type Code and Currency Code.

        // [THEN] Verify that the Job Resource Price was created
        JobResourcePrice.Get(
          JobResourcePrice."Job No.", JobResourcePrice."Job Task No.", JobResourcePrice.Type, JobResourcePrice.Code,
          JobResourcePrice."Work Type Code", JobResourcePrice."Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobResourcePriceWithJobTaskNoWithTypeNotPosting()
    var
        Resource: Record Resource;
        JobTask: Record "Job Task";
        JobResourcePrice: Record "Job Resource Price";
    begin
        // [SCENARIO] Test the error message when creating Job Resource Price with Job Task No. for Job Task type is not Posting.

        // [GIVEN] A resource and a job with a Job Task where the task type is not posting
        Initialize();
        Resource.Get(LibraryResource.CreateResourceNo());
        CreateJobWithJobTask(JobTask);
        JobTask.Validate("Job Task Type", JobTask."Job Task Type"::"Begin-Total");
        JobTask.Modify(true);

        // [WHEN] Creating a Job Resource Price
        asserterror LibraryJob.CreateJobResourcePrice(
            JobResourcePrice, JobTask."Job No.", JobTask."Job Task No.", JobResourcePrice.Type::Resource, Resource."No.", '', '');  // Blank value is for Work Type Code and Currency Code.

        // [THEN] Verify that the correct error is reported
        Assert.ExpectedTestFieldError(JobTask.FieldCaption("Job Task Type"), Format(JobTask."Job Task Type"::Posting));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceOnJobResourcePrice()
    var
        JobResourcePrice: Record "Job Resource Price";
    begin
        // [SCENARIO] Test the Unit Price field becomes empty as Unit Cost Factor field is filled on the Job Resource Price.

        // [GIVEN] A Job resource price
        Initialize();
        CreateJobResourcePrice(JobResourcePrice, JobResourcePrice.Type::Resource, LibraryResource.CreateResourceNo());
        ModifyJobResourcePriceForUnitPrice(JobResourcePrice, LibraryRandom.RandDec(100, 2));  // Use Random value for Unit Price.

        // [WHEN] Modifying the job resource Unit Cost Factor
        ModifyJobResourcePriceForUnitCostFactor(JobResourcePrice, LibraryRandom.RandDec(100, 2));  // Use Random value for Unit Cost Factor.

        // [THEN] The Unit Price becomes zero
        JobResourcePrice.TestField("Unit Price", 0);  // Unit Price must be empty.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostFactorOnJobResourcePrice()
    var
        JobResourcePrice: Record "Job Resource Price";
    begin
        // [SCENARIO] Test the Unit Cost Factor field becomes empty as Unit Price field is filled on the Job Resource Price.

        // [GIVEN] A Job Resource Price
        Initialize();
        CreateJobResourcePrice(JobResourcePrice, JobResourcePrice.Type::Resource, LibraryResource.CreateResourceNo());
        ModifyJobResourcePriceForUnitCostFactor(JobResourcePrice, LibraryRandom.RandDec(100, 2));  // Use Random value for Unit Cost Factor.

        // [WHEN] Modifying the Job Resource Unit Price
        ModifyJobResourcePriceForUnitPrice(JobResourcePrice, LibraryRandom.RandDec(100, 2));  // Use Random value for Unit Price.

        // [THEN] The Unit Cost Factor becomes zero
        JobResourcePrice.TestField("Unit Cost Factor", 0);  // Unit Cost Factor must be empty.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobResourcePriceWithBlankResourceNo()
    var
        JobTask: Record "Job Task";
        JobResourcePrice: Record "Job Resource Price";
    begin
        // [SCENARIO] Test the error message when creating Job Resource Price with blank Resource No.

        // [GIVEN] A Job with a Job Task
        Initialize();
        CreateJobWithJobTask(JobTask);

        // [WHEN] Creating a Job with a blank resource no.
        asserterror LibraryJob.CreateJobResourcePrice(
            JobResourcePrice, JobTask."Job No.", JobTask."Job Task No.", JobResourcePrice.Type::Resource, '', '', '');  // Blank value is for Code, Work Type Code, Currency Code.

        // [THEN] Verify the content of the error
        Assert.VerifyFailure(RecordNotFound, StrSubstNo(TestForBlankValuesPassed, JobResourcePrice.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyJobDiscountOnJobResourcePrice()
    var
        JobResourcePrice: Record "Job Resource Price";
        ApplyJobDiscount: Boolean;
    begin
        // [SCENARIO] Test the Apply Job Discount field on the Job Resource Price.

        // [GIVEN] A Job Resource Price
        Initialize();
        CreateJobResourcePrice(JobResourcePrice, JobResourcePrice.Type::Resource, LibraryResource.CreateResourceNo());

        // [WHEN] Changing the job discount field
        JobResourcePrice.Validate("Apply Job Discount", false);
        JobResourcePrice.Modify(true);
        ApplyJobDiscount := JobResourcePrice."Apply Job Discount";

        // [THEN] Verify that the Job Discount Field was changed
        JobResourcePrice.TestField("Apply Job Discount", ApplyJobDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyJobPriceOnJobResourcePrice()
    var
        JobResourcePrice: Record "Job Resource Price";
        ApplyJobPrice: Boolean;
    begin
        // [SCENARIO] Test the Apply Job Price field on the Job Resource Price.

        // [GIVEN] A Job Resource Price
        Initialize();
        CreateJobResourcePrice(JobResourcePrice, JobResourcePrice.Type::Resource, LibraryResource.CreateResourceNo());

        // [WHEN] Changing the job price field
        JobResourcePrice.Validate("Apply Job Price", false);
        JobResourcePrice.Modify(true);
        ApplyJobPrice := JobResourcePrice."Apply Job Price";

        // [THEN] Verify that the job price field was changed
        JobResourcePrice.TestField("Apply Job Price", ApplyJobPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobResourcePricesWithTypeGroupResource()
    var
        JobResourcePrice: Record "Job Resource Price";
        ResourceGroup: Record "Resource Group";
    begin
        // [SCENARIO] Test the creation of Job Resource Price with Type Group(Resource).

        // [GIVEN] A Job Resource Group
        Initialize();
        LibraryResource.CreateResourceGroup(ResourceGroup);

        // [WHEN] Creating a Job Resource Price
        CreateJobResourcePrice(JobResourcePrice, JobResourcePrice.Type::"Group(Resource)", ResourceGroup."No.");

        // [THEN] To verify the creation of Job Resource Price.
        JobResourcePrice.Get(
          JobResourcePrice."Job No.", JobResourcePrice."Job Task No.", JobResourcePrice.Type::"Group(Resource)", JobResourcePrice.Code,
          JobResourcePrice."Work Type Code", JobResourcePrice."Currency Code");
    end;

    [Test]
    [HandlerFunctions('JobJournalTemplateListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ServiceItemNoStockWarning()
    var
        Item: Record Item;
        JobJournalLine: Record "Job Journal Line";
    begin
        // [SCENARIO] Creating a job journal line with a service item does not generate out of stock warnings

        // [GIVEN] A Job journal line with type item, and item type service
        Initialize();
        CreateAndUpdateJobJournalLine(JobJournalLine);
        Item.Get(JobJournalLine."No.");
        Item.Type := Item.Type::Service;
        Item.Modify();
        ChangeItemQuantityAndVerifyNoStockWarning(JobJournalLine);
    end;

    [Test]
    [HandlerFunctions('JobJournalTemplateListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoStockItemNoStockWarning()
    var
        Item: Record Item;
        JobJournalLine: Record "Job Journal Line";
    begin
        // [SCENARIO] Creating a job journal line with a Non-Inventory item does not generate out of stock warnings

        // [GIVEN] A Job journal line with type item, and item type Non-Inventory
        Initialize();
        CreateAndUpdateJobJournalLine(JobJournalLine);
        Item.Get(JobJournalLine."No.");
        Item.Type := Item.Type::"Non-Inventory";
        Item.Modify();
        ChangeItemQuantityAndVerifyNoStockWarning(JobJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobResourcePricesWithBlankTypeGroupResource()
    var
        JobResourcePrice: Record "Job Resource Price";
        ResourceGroup: Record "Resource Group";
    begin
        // [SCENARIO] Test the creation of Job Resource Price with Blank Group Resource in the field Code.

        // [GIVEN] A Job Resource Group
        Initialize();
        LibraryResource.CreateResourceGroup(ResourceGroup);

        // [WHEN] Creating a Job Resource Price with a blank group resource
        asserterror CreateJobResourcePrice(JobResourcePrice, JobResourcePrice.Type::"Group(Resource)", '');

        // [THEN] Verify the content of error message
        Assert.VerifyFailure(
          RecordNotFound,
          StrSubstNo(FieldCodeError, JobResourcePrice.FieldCaption(Code), JobResourcePrice.FieldCaption(Type), JobResourcePrice.Type));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobResourcePricesWithTypeAll()
    var
        JobResourcePrice: Record "Job Resource Price";
    begin
        // [SCENARIO] Test the creation of Job Resource Price with Type All.

        Initialize();

        // [WHEN] Creating a Job Resource Price with type all
        asserterror CreateJobResourcePrice(JobResourcePrice, JobResourcePrice.Type::All, LibraryResource.CreateResourceNo());

        // [THEN] Verify the content of the error message
        Assert.ExpectedError(
          StrSubstNo(FieldCodeError, JobResourcePrice.FieldCaption(Code), JobResourcePrice.FieldCaption(Type), JobResourcePrice.Type));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostFactorOnJobGLAccountPrice()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Check Unit Price on Job Journal Line after updating Unit Cost Factor on Job GL Account Price.

        // [GIVEN] A Job with a Job Task and a job GL account price
        Initialize();
        PriceListLine.DeleteAll();
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobGLAccountPrice(
          JobGLAccountPrice, JobTask."Job No.", JobTask."Job Task No.", LibraryERM.CreateGLAccountWithSalesSetup(), '');
        UpdateUnitCostFactorOnJobGLAccountPrice(JobGLAccountPrice);
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [WHEN] Updating Unit Cost on Job Journal Line for G/L Account, take Random Unit Cost.
        UpdateUnitCostOnJobJournalLine(
          JobJournalLine, JobTask, JobGLAccountPrice."G/L Account No.", LibraryRandom.RandDec(100, 2));

        // [THEN] Verify Unit Price updated on Job Journal Line.
        Assert.AreNearlyEqual(
          JobJournalLine."Unit Cost" * JobGLAccountPrice."Unit Cost Factor", JobJournalLine."Unit Price", 0.001,
          'Unit Price Matched Computed Unit Price');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobGLAccountPriceErrorWithoutJobNo()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
    begin
        // [SCENARIO] Check the error message when Job No. is not filled while creating Job GL Account Price.

        Initialize();

        // [WHEN] Trying to create Job GL Account Price without Job No.
        asserterror LibraryJob.CreateJobGLAccountPrice(JobGLAccountPrice, '', '', '', '');  // Passing blank values for Job No, Job Task No, GL Account No. and Currency Code.

        // [THEN] Verify error message when Job No. is not filled for Job GL Account Price.
        Assert.ExpectedTestFieldError(JobGLAccountPrice.FieldCaption("Job No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobGLAccountPriceErrorWithoutGLAccountNo()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobTask: Record "Job Task";
    begin
        // [SCENARIO] Check the error message when GL Account No. is not filled for Job GL Account Price.

        // [GIVEN] A Job with a Job Task
        Initialize();
        CreateJobWithJobTask(JobTask);

        // [WHEN] Trying to create Job GL Account Price without GL Account No.
        asserterror LibraryJob.CreateJobGLAccountPrice(JobGLAccountPrice, JobTask."Job No.", '', '', '');  // Passing blank values for Job Task No, GL Account No. and Currency Code.

        // [THEN] Verify error message when GL Account No. is not filled for Job GL Account Price.
        Assert.ExpectedTestFieldError(JobGLAccountPrice.FieldCaption("G/L Account No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobGLAccountPriceCreation()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobTask: Record "Job Task";
    begin
        // [SCENARIO] Check that Job G/L Account Price Created successfully.

        // [GIVEN] A Job with a Job Task
        Initialize();
        CreateJobWithJobTask(JobTask);

        // [WHEN] Creating a job gl account price
        LibraryJob.CreateJobGLAccountPrice(JobGLAccountPrice, JobTask."Job No.", '', LibraryERM.CreateGLAccountWithSalesSetup(), '');  // Passing blank values for Job Task No. and Currency Code.

        // [THEN] Verify that Job GL Account Price created successfully and check its Description.
        JobGLAccountPrice.Get(JobGLAccountPrice."Job No.", '', JobGLAccountPrice."G/L Account No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostFactorZeroOnJobGLAccountPrice()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobTask: Record "Job Task";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Check that Unit Cost Factor becomes Zero after updating Unit Price on Job G/L Account Price.

        // [GIVEN] A Job GL Account Price with Unit Cost Factor.
        Initialize();
        PriceListLine.DeleteAll();
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobGLAccountPrice(
          JobGLAccountPrice, JobTask."Job No.", JobTask."Job Task No.", LibraryERM.CreateGLAccountWithSalesSetup(), '');
        UpdateUnitCostFactorOnJobGLAccountPrice(JobGLAccountPrice);
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [WHEN] Updating the Unit Price on the job gl account price
        UpdateUnitPriceOnJobGLAccountPrice(JobGLAccountPrice);

        // [THEN] Verify that after updating Unit Price, Unit Cost Factor will be Zero.
        JobGLAccountPrice.Get(JobGLAccountPrice."Job No.", JobTask."Job Task No.", JobGLAccountPrice."G/L Account No.", '');
        JobGLAccountPrice.TestField("Unit Cost Factor", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceOnJobGLAccountPrice()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobTask: Record "Job Task";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Check that Unit Price becomes Zero after updating Unit Cost Factor on Job G/L Account Price.
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] A Job GL Account Price with Unit Price.
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobGLAccountPrice(
          JobGLAccountPrice, JobTask."Job No.", JobTask."Job Task No.", LibraryERM.CreateGLAccountWithSalesSetup(), '');  // Passing blank value for Currency Code.
        UpdateUnitPriceOnJobGLAccountPrice(JobGLAccountPrice);
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [WHEN] Updating the Unit Cost Factor on the job gl account price
        UpdateUnitCostFactorOnJobGLAccountPrice(JobGLAccountPrice);

        // [THEN] Verify that after updating Unit Cost Factor, Unit Price will be Zero.
        JobGLAccountPrice.Get(JobGLAccountPrice."Job No.", JobTask."Job Task No.", JobGLAccountPrice."G/L Account No.", '');
        JobGLAccountPrice.TestField("Unit Price", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceOnJobJournalLineWithCurrency()
    var
        Currency: Record Currency;
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Check Unit Price on Job Journal Line when Unit Cost Factor and Currency Code is attached on Job GL Account Price.
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] A Job task, a currency and a job gl account price
        LibraryERM.FindCurrency(Currency);
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobGLAccountPrice(
          JobGLAccountPrice, JobTask."Job No.", JobTask."Job Task No.", LibraryERM.CreateGLAccountWithSalesSetup(), Currency.Code);
        UpdateUnitCostFactorOnJobGLAccountPrice(JobGLAccountPrice);
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [WHEN] Updating Unit Cost on Job Journal Line for G/L Account, take Random Unit Cost.
        UpdateUnitCostOnJobJournalLine(
          JobJournalLine, JobTask, JobGLAccountPrice."G/L Account No.", LibraryRandom.RandDec(100, 2));

        // [THEN] Verify Unit Price on Job Journal Line.
        JobJournalLine.TestField(
          "Unit Price", JobJournalLine."Unit Cost" * JobGLAccountPrice."Unit Cost Factor" * Currency."Currency Factor");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceOnJobJournalLineWithoutCostFactor()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Check that Unit Price on Job Journal Line updated according to Job GL Account Price's Unit Price.

        // [GIVEN] A Job GL Account Price with Unit Price.
        Initialize();
        PriceListLine.DeleteAll();
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobGLAccountPrice(
          JobGLAccountPrice, JobTask."Job No.", JobTask."Job Task No.", LibraryERM.CreateGLAccountWithSalesSetup(), '');  // Passing blank value for Currency Code.
        UpdateUnitPriceOnJobGLAccountPrice(JobGLAccountPrice);
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [WHEN] Creating Job Journal Line with Zero Unit Cost.
        UpdateUnitCostOnJobJournalLine(JobJournalLine, JobTask, JobGLAccountPrice."G/L Account No.", 0);

        // [THEN] Verify Unit Price on Job Journal Line.
        JobJournalLine.TestField("Unit Price", JobGLAccountPrice."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostOnJobJournalLineForGLAccount()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Check that Unit Cost on Job Journal Line updated according to Job GL Account Price's Unit Cost.
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] A Job GL Account Price with Unit Cost, Create Job Journal Line.
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobGLAccountPrice(
          JobGLAccountPrice, JobTask."Job No.", JobTask."Job Task No.", LibraryERM.CreateGLAccountWithSalesSetup(), '');  // Passing blank value for Currency Code.
        UpdateUnitCostOnJobGLAccountPrice(JobGLAccountPrice);
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        LibraryJob.CreateJobJournalLineForType(
          JobJournalLine."Line Type"::" ", JobJournalLine.Type::"G/L Account", JobTask, JobJournalLine);

        // [WHEN] Updating GL Account No. on Job Journal Line as per Job GL Account Price.
        JobJournalLine.Validate("No.", JobGLAccountPrice."G/L Account No.");
        JobJournalLine.Modify(true);

        // [THEN] Verify that Unit Cost on Job Journal Line updated according to Job GL Account Price's Unit Cost.
        JobJournalLine.TestField("Unit Cost", JobGLAccountPrice."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountPctOnJobJournalLine()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Check that Line Discount Percent correctly updated on Job Journal Line when Account Type is GL Account and GL Account used is from Job GL Account Price.
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] A Job GL Account Price with Discount Percent.
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobGLAccountPrice(
          JobGLAccountPrice, JobTask."Job No.", JobTask."Job Task No.", LibraryERM.CreateGLAccountWithSalesSetup(), '');  // Passing blank value for Currency Code.
        UpdateLineDiscountPctOnJobGLAccountPrice(JobGLAccountPrice);
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [WHEN] Updating Unit Cost on Job Journal Line for G/L Account, take Random Unit Cost.
        UpdateUnitCostOnJobJournalLine(
          JobJournalLine, JobTask, JobGLAccountPrice."G/L Account No.", LibraryRandom.RandDec(100, 2));

        // [THEN] Verify Discount Percent.
        JobJournalLine.TestField("Line Discount %", JobGLAccountPrice."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceOnJobPlanningLine()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Check Unit Price on Job Planning Line updated according to Unit Price on Job GL Account Price.
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] A Job with a Job Task and a Job GL Account Price.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Modify(true);
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobGLAccountPrice(
          JobGLAccountPrice, JobTask."Job No.", JobTask."Job Task No.", GLAccount."No.", '');  // Passing blank value for Currency Code.
        UpdateUnitPriceOnJobGLAccountPrice(JobGLAccountPrice);
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [WHEN] Creating a job planning line
        CreateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable, GLAccount."No.", JobPlanningLine.Type::"G/L Account");

        // [THEN] Verify Unit Price updated on Job Planning Line.
        JobPlanningLine.TestField("Unit Price", JobGLAccountPrice."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceOnJobPlanningLineWithCurrency()
    var
        Currency: Record Currency;
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Check Unit Price on Job Planning Line when Unit Cost Factor and Currency Code is attached on Job GL Account Price.
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] A Job Task, Find a Currency, Create and update GL Account Price with Currency, Create Job Planning Line for GL Account.
        LibraryERM.FindCurrency(Currency);
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobGLAccountPrice(
          JobGLAccountPrice, JobTask."Job No.", JobTask."Job Task No.", LibraryERM.CreateGLAccountWithSalesSetup(), Currency.Code);
        UpdateUnitCostFactorOnJobGLAccountPrice(JobGLAccountPrice);
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        CreateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable, JobGLAccountPrice."G/L Account No.",
          JobPlanningLine.Type::"G/L Account");

        // [WHEN] Updating Unit Cost on Job Planning Line for G/L Account, take Random Unit Cost.
        JobPlanningLine.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        JobPlanningLine.Modify(true);

        // [THEN] Verify Unit Price on Job Planning Line.
        JobPlanningLine.TestField(
          "Unit Price", JobPlanningLine."Unit Cost" * JobGLAccountPrice."Unit Cost Factor" * Currency."Currency Factor");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostOnJobPlanningLineForGLAccount()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Check Unit Cost on Job Planning Line updated according to Unit Cost on Job GL Account Price.
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] A Job with a Job Task
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobGLAccountPrice(
          JobGLAccountPrice, JobTask."Job No.", JobTask."Job Task No.", LibraryERM.CreateGLAccountWithSalesSetup(), '');  // Passing blank value for Currency Code.
        UpdateUnitCostOnJobGLAccountPrice(JobGLAccountPrice);
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [WHEN] Creating a job planning line
        CreateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable,
          JobGLAccountPrice."G/L Account No.", JobPlanningLine.Type::"G/L Account");

        // [THEN] Verify Unit Cost updated on Job Planning Line.
        JobPlanningLine.TestField("Unit Cost", JobGLAccountPrice."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountPctOnJobPlanningLine()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Check that Line Discount Percent correctly updated on Job Planning Line.
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] A Job GL Account Price with Discount Percent.
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobGLAccountPrice(
          JobGLAccountPrice, JobTask."Job No.", JobTask."Job Task No.", LibraryERM.CreateGLAccountWithSalesSetup(), '');  // Passing blank value for Currency Code.
        UpdateLineDiscountPctOnJobGLAccountPrice(JobGLAccountPrice);
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [WHEN] Creating a job planning line
        CreateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable,
          JobGLAccountPrice."G/L Account No.", JobPlanningLine.Type::"G/L Account");

        // [THEN] Verify Discount Percent on Job Planning Line.
        JobPlanningLine.TestField("Line Discount %", JobGLAccountPrice."Line Discount %");
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceOnSalesInvoiceForJobGLAccountPrice()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        SalesLine: Record "Sales Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Check Unit Price on Sales Line created from Job Planning Line using GL Account used for Job GL Account Price.
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] A Job GL Price with Discount Percent and Unit Price, Create and Update Job Planning Line.
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobGLAccountPrice(
          JobGLAccountPrice, JobTask."Job No.", JobTask."Job Task No.", LibraryERM.CreateGLAccountWithSalesSetup(), '');  // Passing blank value for Currency Code.
        UpdateUnitPriceOnJobGLAccountPrice(JobGLAccountPrice);
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);
        UpdateJobPlanningLine(JobPlanningLine, JobTask, JobGLAccountPrice."G/L Account No.");
        Commit();  // Using Commit to prevent Test Failure.

        // [WHEN] Creating Sales Invoice from Job Planning Line.
        LibraryVariableStorage.Enqueue(WorkDate());
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);  // Passing False to avoid Credit Memo creation.

        // [THEN] Verify Unit Price and Quantity on Sales Line.
        FindSalesLine(SalesLine, SalesLine."Document Type"::Invoice, SalesLine.Type::"G/L Account", JobTask."Job No.");
        SalesLine.TestField("Unit Price", JobGLAccountPrice."Unit Price");
        SalesLine.TestField(Quantity, JobPlanningLine.Quantity);
        SalesLine.TestField("Gen. Prod. Posting Group", JobPlanningLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceForJobGLAccountPrice()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Check Unit Price, Discount Percent and Discount Amount on Job Ledger Entry after posting Sales Invoice created from Job Planning Line.
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] "Copy Line Descr. to G/L Entry" = true in Sales Receivables Setup
        UpdateSalesSetupCopyLineDescr(true);
        // [GIVEN] A Job GL Price with Discount Percent and Unit Price, Create and Update Job Planning Line, Create Sales Invoice from Job Planning Line.
        CreateJobWithJobTask(JobTask);
        CreateAndUpdateJobGLAccountPrice(JobGLAccountPrice, JobTask);
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        UpdateJobPlanningLine(JobPlanningLine, JobTask, JobGLAccountPrice."G/L Account No.");
        Commit();  // Using Commit to prevent Test Failure.
        LibraryVariableStorage.Enqueue(WorkDate());
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);  // Passing False to avoid Credit Memo creation.
        FindSalesHeader(SalesHeader, SalesLine."Document Type"::Invoice, JobTask."Job No.", SalesLine.Type::"G/L Account");

        // [WHEN] Post Sales Invoice created from Job Planning Line.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify Unit Price after posting Sales Invoice on Job Ledger Entry.
        VerifyDiscountOnJobLedgerEntry(
          DocumentNo, JobTask."Job No.", JobGLAccountPrice."G/L Account No.", JobGLAccountPrice."Unit Price",
          JobGLAccountPrice."Line Discount %",
          Round(-JobPlanningLine.Quantity * JobGLAccountPrice."Unit Price" * JobGLAccountPrice."Line Discount %" / 100));
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLEntryToJobLedgerEntryMatchingForPostedSalesInvoiceForJobGLAccount()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [SCENARIO] When "Copy Line Descr. to G/L Entry" every entry should have different "Ledger Entry No." on Job Ledger Entry after posting Sales Invoice created from Job Planning Line.
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] "Copy Line Descr. to G/L Entry" = true in Sales Receivables Setup
        UpdateSalesSetupCopyLineDescr(true);

        // [GIVEN] GL Account with Sales Setup
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();

        // [GIVEN] A Job GL Price with Discount Percent and Unit Price
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Create and Update 2 Job Planning Line
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable, GLAccountNo, JobPlanningLine.Type::"G/L Account");
        UpdateJobPlanningLineCostAndPrice(JobPlanningLine);
        Clear(JobPlanningLine);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable, GLAccountNo, JobPlanningLine.Type::"G/L Account");
        UpdateJobPlanningLineCostAndPrice(JobPlanningLine);
        Commit();  // Using Commit to prevent Test Failure.

        // [GIVEN] Create Sales Invoice from Job Planning Line
        JobPlanningLine.Reset();
        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.FindSet();
        LibraryVariableStorage.Enqueue(WorkDate());
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);  // Passing False to avoid Credit Memo creation.
        FindSalesHeader(SalesHeader, SalesLine."Document Type"::Invoice, JobTask."Job No.", SalesLine.Type::"G/L Account");

        // [WHEN] Post Sales Invoice created from Job Planning Line.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify Job Ledger Entries have different G/L entry no.
        VerifyGLEntriesOnJobLedgerEntry(DocumentNo, JobTask."Job No.", GLAccountNo);
    end;

    local procedure UpdateJobPlanningLineCostAndPrice(var JobPlanningLine: Record "Job Planning Line");
    begin
        JobPlanningLine.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        JobPlanningLine.Validate("Unit Price", 2 * JobPlanningLine."Unit Cost");
        JobPlanningLine.Modify(true);
    end;

    local procedure VerifyGLEntriesOnJobLedgerEntry(DocumentNo: Code[20]; JobNo: Code[20]; AccountNo: Code[20])
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        LastGLEntryNo: Integer;
    begin
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobNo, JobLedgerEntry.Type::"G/L Account", AccountNo);
        Assert.IsTrue(JobLedgerEntry.Count > 1, 'Ledger Entry Count is 1');
        repeat
            Assert.AreNotEqual(LastGLEntryNo, JobLedgerEntry."Ledger Entry No.", '');
            LastGLEntryNo := JobLedgerEntry."Ledger Entry No.";
        until JobLedgerEntry.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure GLEntryToJobLedgerEntryMatchingForPostedPurchaseInvoiceForJobGLAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        JobTask: Record "Job Task";
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [SCENARIO] When "Copy Line Descr. to G/L Entry" every entry should have different "Ledger Entry No." on Job Ledger Entry after posting Purchase Invoice linked with Job Planning Line.

        Initialize();

        // [GIVEN] "Copy Line Descr. to G/L Entry" = true in Purchase & Payables Setup
        UpdatePurchaseSetupCopyLineDescr(true);

        // [GIVEN] Purchase order with job
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        CreateJobWithJobTask(JobTask);
        CreatePurchaseOrderWithTwoGlAccountLinesLinkedWithJobTask(PurchaseHeader, GLAccountNo, JobTask);

        // [GIVEN] Post receipt and invoice from purchase order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify Job Ledger Entries have different G/L entry no.
        VerifyGLEntriesOnJobLedgerEntry(DocumentNo, JobTask."Job No.", GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobJournalWithBinAndPositiveQuantity()
    var
        ItemJournalLine: Record "Item Journal Line";
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [SCENARIO] Test Warehouse Entry and Bin Content Entry after posting the Job Journal with Bin and positive Quantity.

        // [GIVEN] A and post Item Journal Lines, Create Job Journal Line with positive Quantity.
        Initialize();
        CreateItemJournalWithBinLocation(ItemJournalLine);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateJobWithJobTask(JobTask);
        CreateJobJournalLineWithBin(JobJournalLine, JobTask, ItemJournalLine, ItemJournalLine.Quantity - ItemJournalLine.Quantity / 2);

        // [WHEN] Posting the job journal line
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Verify the Warehouse Entry and Bin Content Entry
        VerifyWarehouseEntry(
          WarehouseEntry."Source Document"::"Job Jnl.", WarehouseEntry."Entry Type"::"Negative Adjmt.", JobJournalLine."No.",
          JobJournalLine."Location Code", JobJournalLine."Bin Code", JobJournalLine."Unit of Measure Code", -JobJournalLine.Quantity);
        VerifyBinContentEntry(
          JobJournalLine."No.", JobJournalLine."Location Code", JobJournalLine."Bin Code",
          ItemJournalLine.Quantity - JobJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobJournalWithBinAndNegativeQuantity()
    var
        ItemJournalLine: Record "Item Journal Line";
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        WarehouseEntry: Record "Warehouse Entry";
        PositiveQuantity: Decimal;
    begin
        // [SCENARIO] Test Warehouse Entry and Bin Content Entry after posting the Job Journal with Bin and negative Quantity.

        // [GIVEN] A and post Item Journal Lines, Create and Post Job Journal Line with positive Quantity. Create Job Journal Line with negative Quantity.
        Initialize();
        CreateItemJournalWithBinLocation(ItemJournalLine);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateJobWithJobTask(JobTask);
        CreateJobJournalLineWithBin(JobJournalLine, JobTask, ItemJournalLine, ItemJournalLine.Quantity - ItemJournalLine.Quantity / 2);
        PositiveQuantity := JobJournalLine.Quantity;
        LibraryJob.PostJobJournal(JobJournalLine);
        CreateJobJournalLineWithBin(JobJournalLine, JobTask, ItemJournalLine, -(JobJournalLine.Quantity - JobJournalLine.Quantity / 2));

        // [WHEN] Posting the job journal line
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Verify the Warehouse Entry and Bin Content Entry
        VerifyWarehouseEntry(
          WarehouseEntry."Source Document"::"Job Jnl.", WarehouseEntry."Entry Type"::"Positive Adjmt.", JobJournalLine."No.",
          JobJournalLine."Location Code", JobJournalLine."Bin Code", JobJournalLine."Unit of Measure Code", -JobJournalLine.Quantity);
        VerifyBinContentEntry(
          JobJournalLine."No.", JobJournalLine."Location Code", JobJournalLine."Bin Code",
          ItemJournalLine.Quantity - PositiveQuantity - JobJournalLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountAmountAndPctOnJobJournalLine()
    var
        JobJournalLine: Record "Job Journal Line";
        LineAmount: Decimal;
        LineDiscountAmount: Decimal;
        LineDiscountPct: Decimal;
    begin
        // [SCENARIO] Test the Line Discount Amount and Line Discount% on Job Journal after updating Line Amount.

        // [GIVEN] A Job journal line
        Initialize();
        CreateAndUpdateJobJournalLine(JobJournalLine);
        LineAmount := Round(JobJournalLine.Quantity * JobJournalLine."Unit Price (LCY)") - LibraryUtility.GenerateRandomFraction();
        LineDiscountAmount := JobJournalLine."Line Amount" - LineAmount;
        LineDiscountPct := Round(LineDiscountAmount * 100 / JobJournalLine."Line Amount", 0.00001);  // 0.00001 is used for Rounding Precision.

        // [WHEN] Changing the line amount on the job journal line
        JobJournalLine.Validate("Line Amount", LineAmount);
        JobJournalLine.Modify(true);

        // [THEN] Verify that the discount amount and percent is correct
        JobJournalLine.TestField("Line Discount Amount", LineDiscountAmount);
        JobJournalLine.TestField("Line Discount %", LineDiscountPct);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,JobTransferToSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceThroughJobPlanningLines()
    var
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        SalesLine: Record "Sales Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [SCENARIO] Test the Sales Invoice which is created from Job Planning Lines after posting the Job Journal with updated Line Amount.

        // [GIVEN] A Job Journal Line and update Line Amount.
        Initialize();
        CreateJobPlanningLineToCreateInvoice(JobJournalLine, JobPlanningLine);

        // [WHEN] Creating a sales invoice from the job planning line
        LibraryVariableStorage.Enqueue(WorkDate());
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Verify that the sales lines contain the updated line discounts
        FindSalesLine(SalesLine, SalesLine."Document Type"::Invoice, SalesLine.Type::Item, JobJournalLine."Job No.");
        SalesLine.TestField("Line Discount %", JobJournalLine."Line Discount %");
        SalesLine.TestField("Line Discount Amount", JobJournalLine."Line Discount Amount");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,JobTransferToSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostingSalesInvoiceThroughJobPlanningLines()
    var
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Test Job Ledger Entry after posting Sales Invoice which is created from Job Planning Lines after posting the Job Journal with updated Line Amount.

        // [GIVEN] A Job Journal Line and update Line Amount. Create Sales Invoice through Job Planning Line.
        Initialize();
        CreateJobPlanningLineToCreateInvoice(JobJournalLine, JobPlanningLine);
        LibraryVariableStorage.Enqueue(WorkDate());
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        FindSalesHeader(SalesHeader, SalesLine."Document Type"::Invoice, JobJournalLine."Job No.", SalesLine.Type::Item);

        // [WHEN] Post Sales Invoice created from Job Planning Line.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify that the sales lines contain the updated line discounts
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobJournalLine."Job No.", JobLedgerEntry.Type::Item, JobJournalLine."No.");
        JobLedgerEntry.TestField("Line Discount %", JobJournalLine."Line Discount %");
        JobLedgerEntry.TestField("Line Discount Amount", -JobJournalLine."Line Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobGLJournalWithCurrency()
    var
        JobTask: Record "Job Task";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        // [SCENARIO] Test that different Costs updated correctly after Posting Job G/L Journal with Currency Code and Copy VAT Setup to Jnl. Lines = False for Job G/L Journal batch.

        // [GIVEN] A and Update Job Journal Batch, Job with Job Task and Job Journal Line with Currency Code.
        Initialize();
        CreateAndUpdateJobJournalBatch(GenJournalBatch);
        CreateJobWithJobTask(JobTask);
        CreateJobGLJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Bal. Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo(), JobTask."Job No.", JobTask."Job Task No.", CreateCurrency());
        Amount := LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', WorkDate());  // Calculate Amount in LCY.

        // [WHEN] Posting the General Journal Lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify GL Entries and verify different Costs in Job Ledger Entries.
        VerifyGLEntry(GenJournalLine."Document No.", GenJournalLine."Account No.", Amount);
        VerifyGLEntry(GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", -Amount);
        VerifyDifferentCostsInJobLedgerEntry(GenJournalLine, Amount);
    end;

    [Test]
    [HandlerFunctions('JobJournalTemplateListPageHandler,JobCalcRemainingUsageRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcRemainingUsageForJobJournalLine()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        JobJournalBatch: Record "Job Journal Batch";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobItemPrice: Record "Job Item Price";
        PriceListLine: Record "Price List Line";
        UnitPrice: Decimal;
    begin
        // [SCENARIO] Test that after running Calculate Remaining Usage from Job Journal, correct Quantity, Unit of Measure and Unit Price updated on Job Journal Line.
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] A Job Task, Item with Two Unit of Measures, Create Item Price, Create Job Planning Line with second Unit Of Measure.
        CreateJobWithJobTask(JobTask);
        CreateItemWithTwoUnitOfMeasures(ItemUnitOfMeasure);  // Two Item Unit of Measures needed because the new Item Unit of Measure is used in Test Case.
        UnitPrice := LibraryRandom.RandDec(100, 2);  // Take Random Unit Price.
        CreateJobItemPriceWithNewItemAndUnitPrice(JobTask, ItemUnitOfMeasure."Item No.", ItemUnitOfMeasure.Code, UnitPrice);
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);

        CreateJobPlanningLineAndModifyUOM(
          JobPlanningLine, JobTask, JobPlanningLine.Type::Item, ItemUnitOfMeasure."Item No.", ItemUnitOfMeasure.Code);

        // [WHEN] Calculating the remaining use from job journal
        RunCalcRemainingUsageFromJobJournalPage(JobJournalBatch, JobTask."Job No.");

        // [THEN] Verify that correct Quantity, Unit Of Measure Code and Unit Price updated on Job Journal Line for Item.
        FindJobJournalLine(JobJournalLine, JobJournalBatch."Journal Template Name", JobJournalBatch.Name);
        JobJournalLine.TestField(Quantity, JobPlanningLine.Quantity);
        JobJournalLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);
        JobJournalLine.TestField("Unit Price", UnitPrice);

        // Tear Down:
        DeleteJobJournalTemplate(JobJournalBatch."Journal Template Name");
    end;

    [Test]
    [HandlerFunctions('JobJournalTemplateListPageHandler,JobCalcRemainingUsageRequestPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobLedgerEntriesAfterCalcRemainingUsage()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        JobJournalBatch: Record "Job Journal Batch";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobItemPrice: Record "Job Item Price";
        PriceListLine: Record "Price List Line";
        UnitPrice: Decimal;
    begin
        // [SCENARIO] Test that after running Calculate Remaining Usage from Job Journal and Posting it, correct Quantity, Unit of Measure and Unit Price updated in Job Ledger Entries.
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] A Job Task, Item with Two Unit of Measures, Create Item Price, Create Job Planning Line with other Unit of Measure and Run Calculate Remaining Usage For Job.
        CreateJobWithJobTask(JobTask);
        CreateItemWithTwoUnitOfMeasures(ItemUnitOfMeasure);
        UnitPrice := LibraryRandom.RandDec(100, 2);  // Take Random Unit Price.
        CreateJobItemPriceWithNewItemAndUnitPrice(JobTask, ItemUnitOfMeasure."Item No.", ItemUnitOfMeasure.Code, UnitPrice);
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);

        CreateJobPlanningLineAndModifyUOM(
          JobPlanningLine, JobTask, JobPlanningLine.Type::Item, ItemUnitOfMeasure."Item No.", ItemUnitOfMeasure.Code);
        RunCalcRemainingUsageFromJobJournalPage(JobJournalBatch, JobTask."Job No.");
        FindJobJournalLine(JobJournalLine, JobJournalBatch."Journal Template Name", JobJournalBatch.Name);

        // [WHEN] Posting the job journal line
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Verify that Job Ledger Entry carries correct Quantity, Unit Of Measure Code and Unit Price for Item.
        FindJobLedgerEntry(
          JobLedgerEntry, JobJournalLine."Document No.", JobTask."Job No.", JobLedgerEntry.Type::Item, ItemUnitOfMeasure."Item No.");
        JobLedgerEntry.TestField(Quantity, JobPlanningLine.Quantity);
        JobLedgerEntry.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);
        JobLedgerEntry.TestField("Unit Price", UnitPrice);

        // Tear Down: Delete the Job Journal Template created.
        DeleteJobJournalTemplate(JobJournalBatch."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiscountUpdationOnJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        LineAmount: Decimal;
        LineDiscountAmount: Decimal;
    begin
        // [SCENARIO] Test Line Discount Amount and Line Amount on Job Planning Line for GL Account when Line Discount Percent mentioned on Job Planning Line.

        Initialize();

        // [WHEN] Creating Job Planning Line with Line Discount Percent and Unit Price.
        CreateJobPlanningLineWithUnitPriceAndLineDiscountPct(JobPlanningLine, LibraryRandom.RandInt(10));  // Take Random Value for Discount Percent.
        LineDiscountAmount := Round(JobPlanningLine."Unit Price" * JobPlanningLine.Quantity * JobPlanningLine."Line Discount %" / 100);
        LineAmount := (JobPlanningLine."Unit Price" * JobPlanningLine.Quantity) - LineDiscountAmount;

        // [THEN] Verify Line Discount Amount and Line Amount on Job Planning Line.
        VerifyAmountsOnJobPlanningLine(JobPlanningLine, LineAmount, LineDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeQuantityUpdationOnJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        LineAmount: Decimal;
        LineDiscountAmount: Decimal;
    begin
        // [SCENARIO] Test Line Discount Amount and Line Amount updated correctly for GL Account when Quantity updated with negative sign.

        // [GIVEN] A Job Planning Line for GL Account with Line Discount Percent and Unit Price. Calculate Line Discount Amount and Line Amount.
        Initialize();
        CreateJobPlanningLineWithUnitPriceAndLineDiscountPct(JobPlanningLine, LibraryRandom.RandInt(10));  // Take Random Value for Discount Percent.
        LineDiscountAmount := Round(JobPlanningLine."Unit Price" * JobPlanningLine.Quantity * JobPlanningLine."Line Discount %" / 100);
        LineAmount := (JobPlanningLine."Unit Price" * JobPlanningLine.Quantity) - LineDiscountAmount;

        // [WHEN] Modifying Quantity to negative Quantity on Job Planning Line.
        JobPlanningLine.Validate(Quantity, -JobPlanningLine.Quantity);
        JobPlanningLine.Modify(true);

        // [THEN] Verify that Line Discount Amount and Line Amount updated with negative values.
        VerifyAmountsOnJobPlanningLine(JobPlanningLine, -LineAmount, -LineDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeQuantityAndLineDiscountAmountUpdateOnJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        LineAmount: Decimal;
        LineDiscountPct: Decimal;
        LineDiscountAmount: Decimal;
    begin
        // [SCENARIO] Test Line Discount Percent and Line Amount updated correctly for GL Account when Line Discount Amount and Negative Quantity used on Job Planning Line.

        // [GIVEN] A Job Planning Line for GL Account, Calculate Line Amount and Line Discount Percent.
        Initialize();
        CreateJobPlanningLineWithUnitPriceAndLineDiscountPct(JobPlanningLine, 0);  // Take Zero for Line Discount Percent.
        LineAmount := JobPlanningLine."Unit Price" * JobPlanningLine.Quantity;
        LineDiscountAmount := LibraryRandom.RandDec(10, 2);  // Take Random Discount Amount.
        LineDiscountPct := Round((LineDiscountAmount * 100) / LineAmount, LibraryJob.GetUnitAmountRoundingPrecision(''));  // Passing Blank Value for Currency Code.

        // [WHEN] Updating negative Quantity and Line Discount Amount on Job Planning Line.
        UpdateQuantityAndDiscountOnPlanningLine(JobPlanningLine, -LineDiscountAmount);

        // [THEN] Verify Line Discount entries updated correctly after updating Line Discount Amount.
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        Assert.AreNearlyEqual(LineDiscountPct, JobPlanningLine."Line Discount %", 0.001, 'Line Discount % matches');
        Assert.AreNearlyEqual(-(LineAmount - LineDiscountAmount), JobPlanningLine."Line Amount", 0.001, 'Line Amount matches');
    end;

    [Test]
    [HandlerFunctions('JobTransferToCreditMemoRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DiscountOnSalesCreditMemoFromJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        SalesLine: Record "Sales Line";
        LineDiscountPct: Decimal;
        LineDiscountAmount: Decimal;
    begin
        // [SCENARIO] Test Line Discount Percent and Line Amount transformed successfully on Sales Credit Memo created from Job Planning Line with Negative Quantity.

        // [GIVEN] A Job Planning Line for GL Account with negative Quantity.
        Initialize();
        CreateJobPlanningLineWithUnitPriceAndLineDiscountPct(JobPlanningLine, 0);  // Take Zero for Line Discount Percent.
        LineDiscountAmount := LibraryRandom.RandDec(10, 2);  // Take Random Discount Amount.
        LineDiscountPct :=
          Round((LineDiscountAmount * 100) / JobPlanningLine."Line Amount", LibraryJob.GetUnitAmountRoundingPrecision(''));  // Passing Blank Value for Currency Code.
        UpdateQuantityAndDiscountOnPlanningLine(JobPlanningLine, -LineDiscountAmount);

        // [WHEN] Creating a credit memo from job planning line
        CreateCreditMemoFromJobPlanningLine(JobPlanningLine);

        // [THEN] Verify Discount Entries updated correctly on Sale Credit Memo Line created using Job Planning Line.
        FindSalesLine(SalesLine, SalesLine."Document Type"::"Credit Memo", SalesLine.Type::"G/L Account", JobPlanningLine."Job No.");

        Assert.AreNearlyEqual(LineDiscountPct, SalesLine."Line Discount %", 0.001, 'Sales Line Discount % matches');
        Assert.AreNearlyEqual(LineDiscountAmount, SalesLine."Line Discount Amount", 0.001, 'Sales Line Discount Amount matches');
        SalesLine.TestField("Line Amount", -JobPlanningLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('JobTransferToCreditMemoRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DiscountAfterPostingSalesCreditMemo()
    var
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Test Line Discount Percent and Line Amount in Job Ledger Entry for Posted Credit Memo, that is created from Job Planning Line.

        // [GIVEN] A Job Planning Line for GL Account with Negative Quantity and Discount Amount, Create Sales Credit Memo from Job Planning Line.
        Initialize();
        CreateJobPlanningLineWithUnitPriceAndLineDiscountPct(JobPlanningLine, 0);  // Take Zero for Line Discount Percent.
        UpdateQuantityAndDiscountOnPlanningLine(JobPlanningLine, -LibraryRandom.RandDec(10, 2));  // Taking Random Discount Amount.
        CreateCreditMemoFromJobPlanningLine(JobPlanningLine);
        FindSalesHeader(SalesHeader, SalesLine."Document Type"::"Credit Memo", JobPlanningLine."Job No.", SalesLine.Type::"G/L Account");

        // [WHEN] Posting the credit memo
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify Unit Price, Discount Percent and Discount Amount after posting Sales Credit Memo on Job Ledger Entry.
        VerifyDiscountOnJobLedgerEntry(
          DocumentNo, JobPlanningLine."Job No.", JobPlanningLine."No.", JobPlanningLine."Unit Price", JobPlanningLine."Line Discount %",
          -JobPlanningLine."Line Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameSourceCodeForJobGenJournalTemplateAndJobGLWIP()
    var
        SourceCodeSetup: Record "Source Code Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        JobTask: Record "Job Task";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [SCENARIO] Verify Posting of Job G/L Journal is not allowed when Source Code value in General Journal Template is same as Job G/L WIP value in Source Code Setup.

        // [GIVEN] A Job with Job Task, Update Source Code Setup for "Job G/L Journal" and "Job G/L WIP" as blank, Create Job General Journal Template with Source Code as blank, Create Job G/L Journal Line.
        Initialize();
        CreateJobWithJobTask(JobTask);
        SourceCodeSetup.Get();
        UpdateSourceCodeSetup('', '');
        CreateGeneralJournalTemplateAndBatch(GenJournalBatch);
        CreateJobGLJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Bal. Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryERM.CreateGLAccountNo(), JobTask."Job No.", JobTask."Job Task No.", '');

        // [WHEN] Post Job G/L Journal.
        asserterror PostGeneralJournalLine(GenJournalLine);

        // [THEN] Error populates for Source Code in Gen. Journal Template must not be equal to Job G/L WIP in Source Code Setup.
        Assert.ExpectedError(
          StrSubstNo(
            SourceCodeEqualError, GenJournalTemplate.FieldCaption("Source Code"), GenJournalTemplate.TableCaption(),
            SourceCodeSetup.FieldCaption("Job G/L WIP"), SourceCodeSetup.TableCaption()));

        // Tear Down: Roll Back the values for Source Code Setup.
        UpdateSourceCodeSetup(SourceCodeSetup."Job G/L Journal", SourceCodeSetup."Job G/L WIP");
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckSalesInvoicePostingWithTypeText()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Test posting of sales invoice when sales invoice created from job planning line with type text.

        // [GIVEN] A Sales Invoice from Job Planning Line.
        Initialize();
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        CreateJobPlanningLineWithTypeText(JobPlanningLine, JobPlanningLine."Line Type"::Billable, JobTask);

        Commit();
        LibraryVariableStorage.Enqueue(WorkDate());
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        FindSalesHeader(SalesHeader, SalesLine."Document Type"::Invoice, JobTask."Job No.", SalesLine.Type::Item);

        // [WHEN] Post Sales Invoice created from Job Planning Line.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify that sales invoice posted successfully.
        SalesInvoiceHeader.Get(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobUpdateBillToContactNoBlockedPosting()
    var
        Job: Record Job;
    begin
        JobUpdateBillToContactNoBlocked(Job.Blocked::Posting);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobUpdateBillToContactNoBlockedAll()
    var
        Job: Record Job;
    begin
        JobUpdateBillToContactNoBlocked(Job.Blocked::All);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostJobsGLJournalWithBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JobTask: Record "Job Task";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        // [SCENARIO] Setup: Create Job with Job Task, Create Job General Journal Template, Create Job G/L Journal Line with Bank Account.
        Initialize();
        CreateJobWithJobTask(JobTask);
        CreateGeneralJournalTemplateAndBatch(GenJournalBatch);
        LibraryERM.CreateBankAccount(BankAccount);
        CreateJobGLJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Bal. Account Type"::"Bank Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), BankAccount."No.", JobTask."Job No.", JobTask."Job Task No.", '');

        // [WHEN] Posting Job G/L Journal.
        PostGeneralJournalLine(GenJournalLine);

        // [THEN] Verify Bank Account No. of Bank Account Ledger Entries.
        VerifyBankAccNoOnBankAccountLedgerEntries(BankAccount."No.", -GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJnlLineSettingUnitPriceToZeroUpdatesLCYAmounts()
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        // [FEATURE] [Job Journal] [LCY]
        // [SCENARIO] Setting "Unit Price" = 0 in job journal line sets "Line Amount (LCY)" and "Line Discount Amount (LCY)" to 0
        // [GIVEN] Job Journal Line with "Line Amount (LCY)" <> 0 and "Line Discount Amount (LCY)" <> 0
        JobJournalLine.Init();
        JobJournalLine."Line Amount (LCY)" := LibraryRandom.RandDecInRange(100, 200, 2);
        JobJournalLine."Line Discount Amount (LCY)" := LibraryRandom.RandDecInRange(100, 200, 2);
        // [WHEN] Set "Unit Price" = 0
        JobJournalLine.Validate("Unit Price", 0);
        // [THEN] "Line Amount (LCY)" = 0 and "Line Discount Amount (LCY)" = 0
        JobJournalLine.TestField("Line Amount (LCY)", 0);
        JobJournalLine.TestField("Line Discount Amount (LCY)", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJournalAppliesFromEntryExpectedCostOnly()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobJournalLine: Record "Job Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Job Journal] [Applies-from Entry]
        // [SCENARIO 380651] When setting "Applies-from Entry" fields in job journal to an entry with expected cost only, unit cost should be calculated from expected cost

        Initialize();

        // [GIVEN] Purchase order with job. Cost amount = 7.00, quantity = 2.00
        CreatePurchaseOrderWithJob(PurchaseHeader, PurchaseLine);
        // [GIVEN] Post receipt from purchase order. Posted item ledger entry no. = "N"
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create job journal line
        // [WHEN] Set "Applies-from Entry" = "N"
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."Job No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        CreateJobJournalLineAppliedFromItemLedgerEntry(JobJournalLine, ItemLedgerEntry);

        // [THEN] Unit cost in job journal line is 7.00 / 2.00 = 3.50
        ItemLedgerEntry.CalcFields("Cost Amount (Expected)");
        JobJournalLine.TestField("Unit Cost", ItemLedgerEntry."Cost Amount (Expected)" / ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure JobJournalAppliesFromEntryPartiallyInvoiced()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobJournalLine: Record "Job Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Job Journal] [Applies-from Entry]
        // [SCENARIO 380651] When setting "Applies-from Entry" fields in job journal to a partially invoiced entry, unit cost should be calculated from the sum of expected and actual cost

        Initialize();

        // [GIVEN] Purchase order with job. Set Quantity = 10, "Qty. to Receive" = 10, "Qty. to Invoice" = 4
        CreatePurchaseOrderWithJob(PurchaseHeader, PurchaseLine);
        // [GIVEN] Post receipt and invoice from purchase order. Posted item ledger entry no. = "N". Actual cost amount = 30, expected cost amount = 20
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create job journal line
        // [WHEN] Set "Applies-from Entry" = "N"
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."Job No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        CreateJobJournalLineAppliedFromItemLedgerEntry(JobJournalLine, ItemLedgerEntry);

        // [THEN] Unit cost in job journal line is (30 + 20) / 10 = 5.00
        ItemLedgerEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
        JobJournalLine.TestField(
          "Unit Cost", (ItemLedgerEntry."Cost Amount (Actual)" + ItemLedgerEntry."Cost Amount (Expected)") / ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceActionFromJobPlanningLineWhenCurrFactorIsTheSame()
    var
        JobPlanningLine: Record "Job Planning Line";
        Currency: Record Currency;
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 204032] "Create Sales Invoice" on "Job Planning Lines" page when Job Planning Line and Sales Invoice have the same Exchange Rate
        Initialize();

        // [GIVEN] Currency with Exchanges Rate: 01.01 = 10,00. 03.01 = 10,50.
        CreateCurrencyAndTwoCurrencyRates(Currency, WorkDate(), WorkDate() + 2);
        // [GIVEN] Job, Job Task and Job Planning Line with "Posting Date" = 01.01 and "Exchange Rate" = 10,00
        CreateJobPlanningLineWithCurrency(JobPlanningLine, Currency.Code);

        // [WHEN]  Run "Job Transfer to Sales Invoice" with "Posting Date" = 02.01
        LibraryVariableStorage.Enqueue(WorkDate() + 1);
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Sales Invoice created with Exchange Rate 10,00; no confirm messages appears.
        VerifyCurrencyFactor(JobPlanningLine, WorkDate() + 1);
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler,CurrencyRateConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceActionFromJobPlanningLineWhenCurrFactorsForInvoiceAndJobPlanningLineAreDifferent()
    var
        JobPlanningLine: Record "Job Planning Line";
        Currency: Record Currency;
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 204032] "Create Sales Invoice" on "Job Planning Lines" page when Exchange Rate of Job Planning Line Date is not equal the Sales Invoice's one.
        Initialize();

        // [GIVEN] Currency with Exchanges Rate: 01.01 = 10,00. 03.01 = 10,50.
        CreateCurrencyAndTwoCurrencyRates(Currency, WorkDate(), WorkDate() + 2);
        // [GIVEN] Job, Job Task and Job Planning Line with "Posting Date" = 01.01 and "Exchange Rate" = 10,00
        CreateJobPlanningLineWithCurrency(JobPlanningLine, Currency.Code);

        // [WHEN]  Run "Job Transfer to Sales Invoice" with "Posting Date" = 04.01
        LibraryVariableStorage.Enqueue(WorkDate() + 3);
        LibraryVariableStorage.Enqueue(CurrencyDateConfirmTxt);
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Sales Invoice created with Exchange Rate 10,50; Job Planning Line Exchange Rate changed to 10,50 after confirmation by user.
        VerifyCurrencyFactor(JobPlanningLine, WorkDate() + 3);
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler,CurrencyRateConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceActionFromJobPlanningLineWhenJobPlanningLineCurrFactorIsChanged()
    var
        JobPlanningLine: Record "Job Planning Line";
        Currency: Record Currency;
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 204032] "Create Sales Invoice" on "Job Planning Lines" page when Job Planning Line and Sales Invoice Dates are equal, but currency factors are different
        Initialize();

        // [GIVEN] Currency with Exchanges Rate: 01.01 = 10,00. 03.01 = 10,50.
        CreateCurrencyAndTwoCurrencyRates(Currency, WorkDate(), WorkDate() + 2);
        // [GIVEN] Job, Job Task and Job Planning Line with "Posting Date" = 01.01 and "Exchange Rate" = 11,00
        CreateJobPlanningLineWithCurrency(JobPlanningLine, Currency.Code);
        JobPlanningLine.Validate("Currency Factor", LibraryRandom.RandDec(100, 2));
        JobPlanningLine.Modify(true);

        // [WHEN]  Run "Job Transfer to Sales Invoice" with "Posting Date" = 02.01
        LibraryVariableStorage.Enqueue(WorkDate() + 1);
        LibraryVariableStorage.Enqueue(CurrencyDateConfirmTxt);
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Sales Invoice created with Exchange Rate 10,00; Job Planning Line Exchange Rate changed to 10,00 after confirmation by user.
        VerifyCurrencyFactor(JobPlanningLine, WorkDate() + 1);
    end;

    [Test]
    [HandlerFunctions('JobJournalTemplateListPageHandler,JobCalcRemainingUsageRequestPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostingChangedJobRecordsWithOverBudgetRecalculation()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // [SCENARIO 230967] Job Journal with several lines must be posted correctly when Over Budget value recalculation is required

        Initialize();

        // [GIVEN] Job with two Job Planning Lines of Resource, "Unit Cost" = 0 and "Usage Link" = TRUE
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        CreateJobPlanningLineWithResource(JobTask);
        CreateJobPlanningLineWithResource(JobTask);

        // [GIVEN] Prepare Job Journal Lines
        RunCalcRemainingUsageFromJobJournalPage(JobJournalBatch, Job."No.");
        FindJobJournalLine(JobJournalLine, JobJournalBatch."Journal Template Name", JobJournalBatch.Name);

        // [WHEN] Post Job Journal
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Lines successfully posted, two Job Ledger Entries created
        JobLedgerEntry.SetRange("Job No.", Job."No.");
        Assert.RecordCount(JobLedgerEntry, 2);
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcInvoiceDiscountOnSalesInvoicesCreatedFromJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesLine: Record "Sales Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 204032] "Create Sales Invoice" on "Job Planning Lines" when customer has Invoice Discount settings
        Initialize();

        // [GIVEN] Enabled "Calc. Invoice Discoutn" in "Sales & Receivables Setup"
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Invoice discount code "I" with "Discount %" = 5%
        // [GIVEN] Customer "C" with "Invoice Discount Code" = "I"
        // [GIVEN] Given job for customer "C" with "Billable" job planning line
        CreateJobPlanningLineWithCurrency(JobPlanningLine, '');

        Job.Get(JobPlanningLine."Job No.");
        Customer.Get(Job."Bill-to Customer No.");
        CreateCustomerInvoiceDiscount(CustInvoiceDisc);
        Customer.Validate("Invoice Disc. Code", CustInvoiceDisc.Code);
        Customer.Modify(true);

        Commit();

        // [WHEN] User creates sales invoice "SI" from job
        LibraryVariableStorage.Enqueue(WorkDate() + 1);
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [GIVEN] "Inv. Disc. Amount to Invoice" is calculated in sales line.
        SalesLine.SetRange("Bill-to Customer No.", Customer."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Inv. Disc. Amount to Invoice");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringJobJournalUnitCostVisible()
    var
        RecurringJobJnl: TestPage "Recurring Job Jnl.";
    begin
        // [FEATURE] [Recurring Job Journal] [UT] [UI]
        // [SCENARIO 260131] Fields "Unit Cost" and "Total Cost" should be available on the page "Recurring Job Journal"

        RecurringJobJnl.OpenView();
        Assert.IsTrue(RecurringJobJnl."Unit Cost".Visible(), ControlNotFoundErr);
        Assert.IsTrue(RecurringJobJnl."Total Cost".Visible(), ControlNotFoundErr);
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceFCYTotalUnitPriceRounding()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        DocumentNo: Code[20];
        ExpectedTotalUnitPriceLCY: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice] [FCY] [Rounding]
        // [SCENARIO 259933] Stan gets equal amounts in "Job Ledger Entry"."Total Price (LCY)" and "General Ledger Entry".Amount after posting sales invoice create job planning lines with currency.

        // [GIVEN] Currency "C" with exchange rate = "27.02"
        LibraryERM.CreateCurrency(Currency);
        CreateCurrencyExchangeRate(CurrencyExchangeRate, Currency.Code);

        // [GIVEN] Job with job planning line "JPL" where "Currency Code" = "C", Quantity = 1 and "Unit Price" = "18,318.7149"
        CreateJobPlanningLineWithCurrency(JobPlanningLine, Currency.Code);
        JobPlanningLine.Validate("Unit Price", LibraryRandom.RandDecInRange(20000, 30000, 5));
        JobPlanningLine.Modify(true);

        // [GIVEN] Sales invoice "I" created from "JPL"
        LibraryVariableStorage.Enqueue(WorkDate());
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        FindSalesLine(SalesLine, SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, JobPlanningLine."Job No.");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        ExpectedTotalUnitPriceLCY :=
          Round(SalesLine."Line Amount" * CurrencyExchangeRate."Relational Exch. Rate Amount", Currency."Amount Rounding Precision");
        JobPlanningLine.TestField("Total Price (LCY)", ExpectedTotalUnitPriceLCY);

        // [WHEN] Post sales invoice "I"
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] GLE.Amount = ROUND(ROUND(18,318.7149 * 1) * 27.02) = "494 971,54"
        GLEntry.SetRange("Document Type", SalesHeader."Document Type".AsInteger());
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -ExpectedTotalUnitPriceLCY);

        // [THEN] JLE."Total Price (LCY)" = ROUND(ROUND(18,318.7149 * 1) * 27.02) = "494 971,54"
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobPlanningLine."Job No.", JobPlanningLine.Type, JobPlanningLine."No.");
        JobLedgerEntry.TestField("Total Price (LCY)", -ExpectedTotalUnitPriceLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJnlPostBatchResetsAutoCalcFields()
    var
        JobJournalLine: Record "Job Journal Line";
        DummyJobTask: Record "Job Task";
        JobJournal: Codeunit "Job Journal";
    begin
        // [FEATURE] [UT] [Batch] [Performance]
        // [SCENARIO 301026] COD 1013 "Job Jnl.-Post Batch" resets auto calc fields
        Initialize();

        // [GIVEN] Job Journal Line with enabled auto calc fields for "Reserved Qty. (Base)" field
        LibraryJob.CreateJobJournalLine("Job Line Type"::" ", DummyJobTask, JobJournalLine);
        JobJournalLine.SetAutoCalcFields("Reserved Qty. (Base)");
        // [GIVEN] Linked "Reservation Entry" record with "Quantity (Base)" = 100
        MockReservationEntry(JobJournalLine);
        // [GIVEN] Ensure "Job Journal Line"."Reserved Qty. (Base)" = 100 after FIND
        JobJournalLine.Find();
        JobJournalLine.TestField("Reserved Qty. (Base)");

        // [WHEN] Perform COD 1013 "Job Jnl.-Post Batch".RUN()
        BindSubscription(JobJournal);
        CODEUNIT.Run(CODEUNIT::"Job Jnl.-Post Batch", JobJournalLine);

        // [THEN] Auto calc field is reset within COD1013: "Reserved Qty. (Base)" = 0 after FIND
        // See [EventSubscriber] OnBeforeRunCheck
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,JobTransferToSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BinCodeOnSalesLineFromJobPlanningLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        SalesLine: Record "Sales Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [FEATURE] [Bin]
        // [SCENARIO 365042] "Bin Code" is transferred from Job Planning Line when we run Create Sales Invoice from line
        Initialize();

        // [GIVEN] Created Bin and Job Journal Line with accordin Bin Code
        CreateItemJournalWithBinLocation(ItemJournalLine);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateJobWithJobTask(JobTask);
        CreateJobJournalLineWithBin(JobJournalLine, JobTask, ItemJournalLine, ItemJournalLine.Quantity - ItemJournalLine.Quantity / 2);

        // [GIVEN] Posted Job Journal Line
        JobJournalLine.Validate("Line Type", JobJournalLine."Line Type"::Billable);
        JobJournalLine.Validate("Line Amount", JobJournalLine."Line Amount" - LibraryUtility.GenerateRandomFraction());
        JobJournalLine.Modify(true);
        LibraryJob.PostJobJournal(JobJournalLine);

        // [WHEN] Creating a sales invoice from the Job Planning Line
        FindJobPlanningLine(JobPlanningLine, JobJournalLine."Job No.", JobJournalLine."Job Task No.");
        LibraryVariableStorage.Enqueue(WorkDate());
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Verify that the sales lines contain the updated line discounts
        FindSalesLine(SalesLine, SalesLine."Document Type"::Invoice, SalesLine.Type::Item, JobJournalLine."Job No.");
        SalesLine.TestField("Bin Code", JobPlanningLine."Bin Code");
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceForGLAccountOnJobLedgerEntry()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 364448] Posting Sales Invoice for G/L Account Job Planning Line when "Copy Line Descr. to G/L Entry" = false.

        Initialize();
        // [GIVEN] "Copy Line Descr. to G/L Entry" = false in Sales Receivables Setup
        UpdateSalesSetupCopyLineDescr(false);
        // [GIVEN] G/L Account in a Job Planning Line, Sales Invoice from Job Planning Line and created Sales Invoice.
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        Commit();
        LibraryVariableStorage.Enqueue(WorkDate());
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        FindSalesHeader(SalesHeader, SalesLine."Document Type"::Invoice, JobTask."Job No.", SalesLine.Type::"G/L Account");

        // [WHEN] Posting Sales Invoice created from Job Planning Line.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Job Ledger Entry is created for posted sales invoice
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobTask."Job No.", JobLedgerEntry.Type::"G/L Account", JobPlanningLine."No.");
    end;

    [Test]
    [HandlerFunctions('JobJournalTemplateListPageHandler,JobCalcRemainingUsageRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcRemainingUsageForJobJournalLineWithUnitPrice()
    var
        JobJournalBatch: Record "Job Journal Batch";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        Item: Record Item;
        UnitPrice: Decimal;
    begin
        // [SCENARIO 379137] Test that after running Calculate Remaining Usage from Job Journal, correct Quantity and Unit Price updated on Job Journal Line from Job Planning Line
        Initialize();

        // [GIVEN] A Job Task, Item with Unit Price, Create Item Price, Create Job Planning Line and change "Unit Price" there.
        CreateJobWithJobTask(JobTask);
        UnitPrice := LibraryRandom.RandDec(100, 2);  // Take Random Unit Price.
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, UnitPrice * 2, UnitPrice * 2);
        CreateJobPlanningLineAndModifyUnitPrice(
          JobPlanningLine, JobTask, JobPlanningLine.Type::Item, LibraryInventory.CreateItemNo(), UnitPrice);

        // [WHEN] Calculating the remaining use from job journal
        RunCalcRemainingUsageFromJobJournalPage(JobJournalBatch, JobTask."Job No.");

        // [THEN] Verify that correct Quantity, Unit Of Measure Code and Unit Price updated on Job Journal Line for Item.
        FindJobJournalLine(JobJournalLine, JobJournalBatch."Journal Template Name", JobJournalBatch.Name);
        JobJournalLine.TestField(Quantity, JobPlanningLine.Quantity);
        JobJournalLine.TestField("Unit Price", UnitPrice);
        DeleteJobJournalTemplate(JobJournalBatch."Journal Template Name");
    end;

    [Test]
    procedure UpdateContactInfoAfterChangeBilltoContactNoinJobCardByValidatePageField()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        Contact2: Record Contact;
        Job: Record Job;
        JobCard: TestPage "Job Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] When user change Bill-to Contact No. in Job Card then contact info must be updated
        Initialize();

        // [GIVEN] Customer with two contacts
        // [GIVEN] First contact "C1" with phone = "111111111", mobile phone = "222222222" and email = "contact1@mail.com"
        // [GIVEN] Second contact "C2" with phone = "333333333", mobile phone = "444444444" and email = "contact2@mail.com"
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        UpdateContactInfo(Contact, '111111111', '222222222', 'contact1@mail.com');
        Contact.Modify(true);
        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Modify(true);
        LibraryMarketing.CreatePersonContact(Contact2);
        UpdateContactInfo(Contact2, '333333333', '444444444', 'contact2@mail.com');
        Contact2.Validate("Company No.", Contact."Company No.");
        Contact2.Modify(true);

        // [GIVEN] Job with "Bill-to Contact No." = "C1"
        LibraryJob.CreateJob(Job, Customer."No.");
        JobCard.Trap();
        Page.Run(Page::"Job Card", Job);

        // [WHEN] User set "Bill-to Contact No." = "C2" by validate page field
        JobCard."Bill-to Contact No.".SetValue(Contact2."No.");

        // [THEN] "Job Card"."Phone No." = "333333333"
        JobCard.ContactPhoneNo.AssertEquals(Contact2."Phone No.");

        // [THEN] "Job Card"."Mobile Phone No." = "444444444"
        JobCard.ContactMobilePhoneNo.AssertEquals(Contact2."Mobile Phone No.");

        // [THEN] "Job Card"."Email" = "contact2@mail.com"
        JobCard.ContactEmail.AssertEquals(Contact2."E-Mail");
    end;

    [Test]
    [HandlerFunctions('ContactListPageHandler')]
    procedure UpdateContactInfoAfterChangeBilltoContactNoinJobCardByLookup()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        Contact2: Record Contact;
        Job: Record Job;
        JobCard: TestPage "Job Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] When user change Bill-to Contact No. in Job Card then contact info must be updated
        Initialize();

        // [GIVEN] Customer with two contacts
        // [GIVEN] First contact "C1" with phone = "111111111", mobile phone = "222222222" and email = "contact1@mail.com"
        // [GIVEN] Second contact "C2" with phone = "333333333", mobile phone = "444444444" and email = "contact2@mail.com"
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        UpdateContactInfo(Contact, '111111111', '222222222', 'contact1@mail.com');
        Contact.Modify(true);
        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Modify(true);
        LibraryMarketing.CreatePersonContact(Contact2);
        UpdateContactInfo(Contact2, '333333333', '444444444', 'contact2@mail.com');
        Contact2.Validate("Company No.", Contact."Company No.");
        Contact2.Modify(true);

        // [GIVEN] Job with "Bill-to Contact No." = "C1"
        LibraryJob.CreateJob(Job, Customer."No.");
        JobCard.Trap();
        Page.Run(Page::"Job Card", Job);

        // [WHEN] User set "Bill-to Contact No." = "C2" by validate page field
        LibraryVariableStorage.Enqueue(Contact2."No.");
        JobCard."Bill-to Contact No.".Lookup();

        // [THEN] "Job Card"."Phone No." = "333333333"
        JobCard.ContactPhoneNo.AssertEquals(Contact2."Phone No.");

        // [THEN] "Job Card"."Mobile Phone No." = "444444444"
        JobCard.ContactMobilePhoneNo.AssertEquals(Contact2."Mobile Phone No.");

        // [THEN] "Job Card"."Email" = "contact2@mail.com"
        JobCard.ContactEmail.AssertEquals(Contact2."E-Mail");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure LocationForNonInventoryItemsAllowed()
    var
        ServiceItem: Record Item;
        NonInventoryItem: Record Item;
        Location: Record Location;
        JobJournalLine1: Record "Job Journal Line";
        JobJournalLine2: Record "Job Journal Line";
        JobTask: Record "Job Task";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO] Posting job journal lines containing non-inventory items with location set.
        Initialize();

        // [GIVEN] A non-inventory item and a service item.
        LibraryInventory.CreateServiceTypeItem(ServiceItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] A Location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A job with job tasks containing two job journal lines for the non-inventory items with location set.
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobJournalLine(JobJournalLine1."Line Type"::Budget, JobTask, JobJournalLine1);
        LibraryJob.CreateJobJournalLine(JobJournalLine2."Line Type"::Budget, JobTask, JobJournalLine2);

        JobJournalLine1.Validate(Type, JobJournalLine1.Type::Item);
        JobJournalLine1.Validate("No.", ServiceItem."No.");
        JobJournalLine1.Validate(Quantity, 1);
        JobJournalLine1.Validate("Location Code", Location.Code);
        JobJournalLine1.Modify(true);

        JobJournalLine2.Validate(Type, JobJournalLine1.Type::Item);
        JobJournalLine2.Validate("No.", NonInventoryItem."No.");
        JobJournalLine2.Validate(Quantity, 1);
        JobJournalLine2.Validate("Location Code", Location.Code);
        JobJournalLine2.Modify(true);

        // [WHEN] Posting the job journal lines.
        LibraryJob.PostJobJournal(JobJournalLine1);
        LibraryJob.PostJobJournal(JobJournalLine2);

        // [THEN] An item ledger entry is created for non-inventory items with location set.
        ItemLedgerEntry.SetRange("Item No.", ServiceItem."No.");
        Assert.AreEqual(1, ItemLedgerEntry.Count, 'Expected only one ILE to be created.');
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(-1, ItemLedgerEntry.Quantity, 'Expected quantity to be -1.');
        Assert.AreEqual(Location.Code, ItemLedgerEntry."Location Code", 'Expected location to be set.');

        ItemLedgerEntry.SetRange("Item No.", NonInventoryItem."No.");
        Assert.AreEqual(1, ItemLedgerEntry.Count, 'Expected only one ILE to be created.');
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(-1, ItemLedgerEntry.Quantity, 'Expected quantity to be -1.');
        Assert.AreEqual(Location.Code, ItemLedgerEntry."Location Code", 'Expected location to be set.');
    end;

    [Test]
    procedure BinCodeNotAllowedForNonInventoryItems()
    var
        Item: Record Item;
        ServiceItem: Record Item;
        NonInventoryItem: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        JobJournalLine1: Record "Job Journal Line";
        JobJournalLine2: Record "Job Journal Line";
        JobJournalLine3: Record "Job Journal Line";
        JobTask: Record "Job Task";
    begin
        // [SCENARIO] Bin code is not allowed for non-inventory items in job journal line.
        Initialize();

        // [GIVEN] An item, A non-inventory item and a service item.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateServiceTypeItem(ServiceItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] A location with require bin and a default bin code.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        LibraryWarehouse.CreateBinContent(
            BinContent, Bin."Location Code", '', Bin.Code, Item."No.", '', Item."Base Unit of Measure"
        );
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] A job with job tasks containing 3 job journal lines for for the item and non-inventory items.
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobJournalLine(JobJournalLine1."Line Type"::Budget, JobTask, JobJournalLine1);
        LibraryJob.CreateJobJournalLine(JobJournalLine2."Line Type"::Budget, JobTask, JobJournalLine2);
        LibraryJob.CreateJobJournalLine(JobJournalLine3."Line Type"::Budget, JobTask, JobJournalLine3);

        // [WHEN] Setting the location code for the job journal lines.
        JobJournalLine1.Validate(Type, JobJournalLine1.Type::Item);
        JobJournalLine1.Validate("No.", Item."No.");
        JobJournalLine1.Validate(Quantity, 1);
        JobJournalLine1.Validate("Location Code", Location.Code);
        JobJournalLine1.Modify(true);

        JobJournalLine2.Validate(Type, JobJournalLine1.Type::Item);
        JobJournalLine2.Validate("No.", NonInventoryItem."No.");
        JobJournalLine2.Validate(Quantity, 1);
        JobJournalLine2.Validate("Location Code", Location.Code);
        JobJournalLine2.Modify(true);

        JobJournalLine3.Validate(Type, JobJournalLine3.Type::Item);
        JobJournalLine3.Validate("No.", ServiceItem."No.");
        JobJournalLine3.Validate(Quantity, 1);
        JobJournalLine3.Validate("Location Code", Location.Code);
        JobJournalLine3.Modify(true);

        // [THEN] Bin code is set for the item.
        Assert.AreEqual(Bin.Code, JobJournalLine1."Bin Code", 'Expected bin code to be set');
        Assert.AreEqual('', JobJournalLine2."Bin Code", 'Expected no bin code set');
        Assert.AreEqual('', JobJournalLine3."Bin Code", 'Expected no bin code set');

        // [WHEN] Setting bin code on non-inventory items.
        asserterror JobJournalLine2.Validate("Bin Code", Bin.Code);
        asserterror JobJournalLine3.Validate("Bin Code", Bin.Code);

        // [THEN] An error is thrown.
    end;

    [Test]
    procedure CreatingJobJournalForTrackedItemAndResource()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        ResourceNo: Code[20];
    begin
        // [FEATURE] [Job Journal] [Item Tracking] [Resource]
        // [SCENARIO 414283] Creating job journal for two planning lines - first for tracked item, second for resource.
        Initialize();

        LibraryItemTracking.CreateLotItem(Item);
        ResourceNo := LibraryResource.CreateResourceNo();

        CreateJobWithJobTask(JobTask);

        CreateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, Item."No.", JobPlanningLine.Type::Item);
        JobPlanningLine.Validate(Quantity, 1);
        JobPlanningLine.Modify(true);
        LibraryJob.CreateJobJournalLineForPlan(JobPlanningLine, LibraryJob.UsageLineTypeBlank(), 1, JobJournalLine);

        JobJournalLine.TestField(Type, JobJournalLine.Type::Item);
        JobJournalLine.TestField("No.", Item."No.");

        CreateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, ResourceNo, JobPlanningLine.Type::Resource);
        JobPlanningLine.Validate(Quantity, 1);
        JobPlanningLine.Modify(true);
        LibraryJob.CreateJobJournalLineForPlan(JobPlanningLine, LibraryJob.UsageLineTypeBlank(), 1, JobJournalLine);

        JobJournalLine.TestField(Type, JobJournalLine.Type::Resource);
        JobJournalLine.TestField("No.", ResourceNo);
    end;

    [Test]
    procedure UnitCostAndDirectUnitCostFromPurchPriceToJobJnlLineInFCY()
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceListLine: Record "Price List Line";
        Currency: Record Currency;
        Resource: Record Resource;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ExchRate: Decimal;
        UnitCostLCY: Decimal;
        UnitCostFCY: Decimal;
    begin
        // [FEATURE] [Price] [Resource] [Currency]
        // [SCENARIO 432481] Unit Cost and Direct Unit Cost from purchase prices to a job journal line in foreign currency.
        Initialize();
        ExchRate := LibraryRandom.RandIntInRange(2, 5);
        UnitCostLCY := LibraryRandom.RandDec(100, 2);
        UnitCostFCY := UnitCostLCY * ExchRate;

        // [GIVEN] Enable new prices expirience.
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
          PriceCalculationSetup, "Price Calculation Method"::"Lowest Price", "Price Type"::Purchase,
          "Price Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);

        // [GIVEN] Currency "FCY", set exchange rate 1 "LCY" = 1.5 "FCY".
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRate, ExchRate));

        // [GIVEN] Job with Currency Code = "FCY".
        LibraryJob.CreateJob(Job);
        Job.Validate("Currency Code", Currency.Code);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Resource "R".
        Resource.Get(LibraryJob.CreateConsumable("Job Planning Line Type"::Resource));

        // [GIVEN] Create purchase price for the job and resource:
        // [GIVEN] Currency Code = "FCY", Unit Cost = 150 FCY, Direct Unit Cost = 150 FCY.
        LibraryPriceCalculation.CreatePurchPriceLine(
          PriceListLine, '', "Price Source Type"::Job, Job."No.", "Price Asset Type"::Resource, Resource."No.");
        PriceListLine.Validate("Currency Code", Currency.Code);
        PriceListLine.Validate("Direct Unit Cost", UnitCostFCY);
        PriceListLine.Validate("Unit Cost", UnitCostFCY);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();

        // [WHEN] Create job journal line, select the job and resource "R".
        LibraryJob.CreateJobJournalLineForType("Job Line Type"::" ", JobJournalLine.Type::Resource, JobTask, JobJournalLine);
        JobJournalLine.Validate("No.", Resource."No.");

        // [THEN] "Unit Cost" = 150 FCY, "Unit Cost (LCY)" = 100 LCY, "Direct Unit Cost (LCY)" = 100 LCY.
        JobJournalLine.TestField("Currency Code", Currency.Code);
        JobJournalLine.TestField("Unit Cost", UnitCostFCY);
        JobJournalLine.TestField("Unit Cost (LCY)", UnitCostLCY);
        JobJournalLine.TestField("Direct Unit Cost (LCY)", UnitCostLCY);
    end;

    [Test]
    procedure UnitCostAndDirectUnitCostFromResourceToJobJnlLineInFCY()
    var
        Currency: Record Currency;
        Resource: Record Resource;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ExchRate: Decimal;
        UnitCostLCY: Decimal;
        UnitCostFCY: Decimal;
    begin
        // [FEATURE] [Price] [Resource] [Currency]
        // [SCENARIO 432481] Unit Cost and Direct Unit Cost from resource card to a job journal line in foreign currency.
        Initialize();
        ExchRate := LibraryRandom.RandIntInRange(2, 5);
        UnitCostLCY := LibraryRandom.RandDec(100, 2);
        UnitCostFCY := UnitCostLCY * ExchRate;

        // [GIVEN] Currency "FCY", set exchange rate 1 "LCY" = 1.5 "FCY".
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRate, ExchRate));

        // [GIVEN] Job with Currency Code = "FCY".
        LibraryJob.CreateJob(Job);
        Job.Validate("Currency Code", Currency.Code);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Resource "R", set "Unit Cost" = 100 LCY, "Direct Unit Cost" = 100 LCY.
        Resource.Get(LibraryJob.CreateConsumable("Job Planning Line Type"::Resource));
        Resource.Validate("Unit Cost", UnitCostLCY);
        Resource.Validate("Direct Unit Cost", UnitCostLCY);
        Resource.Modify(true);

        // [WHEN] Create job journal line, select the job and resource "R".
        LibraryJob.CreateJobJournalLineForType("Job Line Type"::" ", JobJournalLine.Type::Resource, JobTask, JobJournalLine);
        JobJournalLine.Validate("No.", Resource."No.");

        // [THEN] "Unit Cost" = 150 FCY, "Unit Cost (LCY)" = 100 LCY, "Direct Unit Cost (LCY)" = 100 LCY.
        JobJournalLine.TestField("Currency Code", Currency.Code);
        JobJournalLine.TestField("Unit Cost", UnitCostFCY);
        JobJournalLine.TestField("Unit Cost (LCY)", UnitCostLCY);
        JobJournalLine.TestField("Direct Unit Cost (LCY)", UnitCostLCY);
    end;

    [Test]
    procedure UnitCostAndDirectUnitCostFromResourceToJobPlanningLineInFCY()
    var
        Currency: Record Currency;
        Resource: Record Resource;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ExchRate: Decimal;
        UnitCostLCY: Decimal;
        UnitCostFCY: Decimal;
    begin
        // [FEATURE] [Price] [Resource] [Currency] [Job Planning Line]
        // [SCENARIO 432481] Unit Cost and Direct Unit Cost from resource card to a job planning line in foreign currency.
        Initialize();
        ExchRate := LibraryRandom.RandIntInRange(2, 5);
        UnitCostLCY := LibraryRandom.RandDec(100, 2);
        UnitCostFCY := UnitCostLCY * ExchRate;

        // [GIVEN] Currency "FCY", set exchange rate 1 "LCY" = 1.5 "FCY".
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRate, ExchRate));

        // [GIVEN] Job with Currency Code = "FCY".
        LibraryJob.CreateJob(Job);
        Job.Validate("Currency Code", Currency.Code);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Resource "R", set "Unit Cost" = 100 LCY, "Direct Unit Cost" = 100 LCY.
        Resource.Get(LibraryJob.CreateConsumable("Job Planning Line Type"::Resource));
        Resource.Validate("Unit Cost", UnitCostLCY);
        Resource.Validate("Direct Unit Cost", UnitCostLCY);
        Resource.Modify(true);

        // [WHEN] Create job planning line, select the job and resource "R".
        LibraryJob.CreateJobPlanningLine(
          "Job Planning Line Line Type"::Budget, "Job Planning Line Type"::Resource, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Resource."No.");

        // [THEN] "Unit Cost" = 150 FCY, "Unit Cost (LCY)" = 100 LCY, "Direct Unit Cost (LCY)" = 100 LCY.
        JobPlanningLine.TestField("Currency Code", Currency.Code);
        JobPlanningLine.TestField("Unit Cost", UnitCostFCY);
        JobPlanningLine.TestField("Unit Cost (LCY)", UnitCostLCY);
        JobPlanningLine.TestField("Direct Unit Cost (LCY)", UnitCostLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyUnitCostLCYOnJobJournalLine()
    var
        Resource: Record Resource;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ResourceNo: Code[20];
        CurrencyCode: Code[10];
        UnitCost: Decimal;
    begin
        // [SCENARIO 445152] The Unit Cost (LCY) gets updated incorrectly in case of a posting involving a Job in a different currency than the local one and different exchange rates.
        Initialize();
        LibraryPriceCalculation.DisableExtendedPriceCalculation();

        // [GIVEN] Create Currency code and exchange rates for 2days. and save unit cost in variable
        CurrencyCode := SetupCurrencyWithExchRates();
        UnitCost := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Create Job with task and update currency code.
        CreateJobWithJobTask(JobTask);
        Job.Get(JobTask."Job No.");
        Job.Validate("Currency Code", CurrencyCode);
        Job.Modify();

        // [GIVEN] Create Resource as person and update unit cost
        ResourceNo := LibraryJob.CreateConsumable("Job Planning Line Type"::Resource);
        Resource.Get(ResourceNo);
        Resource.Validate(Type, Resource.Type::Person);
        Resource.Validate("Unit Cost", UnitCost);
        Resource.Modify();

        // [WHEN] Creating Job Journal Line with created Resource. Validate Posting date wirh Resource no.
        LibraryJob.CreateJobJournalLineForType("Job Line Type"::" ", JobJournalLine.Type::Resource, JobTask, JobJournalLine);  // Use 0 for Resource.
        JobJournalLine.Validate("Posting Date", WorkDate());
        JobJournalLine.Validate("No.", ResourceNo);

        // [THEN] Validate the posting date for changing the Exch. rate on Job Journal line.
        JobJournalLine.Validate("Posting Date", WorkDate() + 1);
        JobJournalLine.Modify();
        JobJournalLine."Unit Cost (LCY)" := Round(JobJournalLine."Unit Cost (LCY)", 0.01);

        // [VERIFY] Verify Unit Cost (LCY) after changing the posting date. Unit Cost will update Correctly.
        JobJournalLine.TestField("Unit Cost (LCY)", Resource."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDefaultBillToCustomerAfterChangeSellToContactNoinJobCardByValidatePageField()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        Contact2: Record Contact;
        Job: Record Job;
        JobCard: TestPage "Job Card";
        BillToOptions: Enum "Sales Bill-to Options";
    begin
        // [SCENARIO 456124] When user change Bill-to to "Default (Customer)" after changing Sell-to contact in Job Card
        Initialize();

        // [GIVEN] Customer with two contacts [C1, C2]
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Modify(true);
        LibraryMarketing.CreatePersonContact(Contact2);
        Contact2.Validate("Company No.", Contact."Company No.");
        Contact2.Modify(true);

        // [GIVEN] Job with "Sell-to Contact No." = "C1"
        LibraryJob.CreateJob(Job, Customer."No.");

        JobCard.Trap();
        Page.Run(Page::"Job Card", Job);

        // [WHEN] User set "Sell-to Contact No." to C2 by validate page field
        JobCard."Sell-to Contact No.".SetValue(Contact2."No.");

        // [WHEN] User set "Bill-to" to Default (Customer) by validate page field
        JobCard.BillToOptions.SetValue(BillToOptions::"Default (Customer)");

        // [THEN]: Verify that the "Job Card"."Bill-to Contact No." = "Job Card"."Sell-to Contact No."
        JobCard."Bill-to Contact No.".AssertEquals(JobCard."Sell-to Contact No.");
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AddCampaignOnInvoice()
    var
        Campaign: Record Campaign;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibraryJob: Codeunit "Library - Job";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [FEATURE] [Sales] [Campaign]
        // [SCENARIO 465382] Campaign No. can not be set when sales invoice is created from Job Planning
        Initialize();

        // [GIVEN] Create campaign
        LibraryMarketing.CreateCampaign(Campaign);

        // [GIVEN] A Job Planning Line for a new Job, Create Sales Invoice from Job Planning Line and find the created Sales Invoice.
        Initialize();
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        Commit();  // Using Commit to prevent Test Failure.
        LibraryVariableStorage.Enqueue(WorkDate());
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        FindSalesHeader(SalesHeader, SalesLine."Document Type"::Invoice, JobTask."Job No.", SalesLine.Type::Item);

        //Exercise: Campaign No. is not set
        Assert.AreEqual('', SalesHeader."Campaign No.", 'Campaign is already assigned to sales invoice');

        // [WHEN] Set campaign no. on sales invoice
        // [THEN] Veirfy an error
        asserterror SalesHeader.Validate("Campaign No.", Campaign."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure VerifyJobPlanningLineAfterPostingJobJournalWithResourceAndAdditionalUoM()
    var
        UnitOfMeasure: Record "Unit of Measure";
        ResUnitOfMeasure: Record "Resource Unit of Measure";
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        ResourceNo: Code[20];
    begin
        // [SCENARIO 470263] Verify Job Planning Line after posting Job Journal with Resource and Additional UoM
        Initialize();

        // [GIVEN] Create Resource
        ResourceNo := LibraryResource.CreateResourceNo();

        // [GIVEN] Create additional UoM for Resource
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryResource.CreateResourceUnitOfMeasure(ResUnitOfMeasure, ResourceNo, UnitOfMeasure.Code, 8);

        // [GIVEN] Create Job Journal Line with Resource and Additional UoM
        CreateResourceJobJournalLine(JobJournalLine, ResourceNo, UnitOfMeasure.Code);

        // [WHEN] Post Job Journal
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Verify result
        JobPlanningLine.SetRange("Job No.", JobJournalLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobJournalLine."Job Task No.");
        Assert.RecordCount(JobPlanningLine, 1);
    end;

    [Test]
    procedure ProjectAmountUpdatedWhenAmountLCYIsInserted()
    var
        JobTask: Record "Job Task";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        Currency: Record Currency;
        PreviousProjectTotalCostLCY: Decimal;
    begin
        // [SCENARIO 537315] The Project G/L Ledgers line after changing the "Amount (LCY)" value changes Project Total Cost(LCY).
        Initialize();

        // [GIVEN] Create a Job and job Task.
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Create a Job Journal Batch.
        CreateAndUpdateJobJournalBatch(GenJournalBatch);

        // [GIVEN] Create a GL Account.
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Create a Bank Account.
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] Get any existing Currency.
        LibraryERM.FindCurrency(Currency);

        // [GIVEN] Create General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));

        //[GIVEN] Validate Balancing Accounts.
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Currency Code", Currency.Code);
        GenJournalLine.Validate("Job Line Type", GenJournalLine."Job Line Type"::"Both Budget and Billable");
        GenJournalLine.Validate("Job No.", JobTask."Job No.");
        GenJournalLine.Validate("Job Task No.", JobTask."Job Task No.");
        GenJournalLine.Validate("Job Quantity", LibraryRandom.RandDec(10, 2));

        // [GIVEN] Store Project Total Cost LCY and Validate Amount (LCY) to new Amount.
        PreviousProjectTotalCostLCY := GenJournalLine."Job Total Cost (LCY)";
        GenJournalLine.Validate("Amount (LCY)", LibraryRandom.RandDec(12, 2));
        GenJournalLine.Modify(true);

        // [THEN] Project Total Cost (LCY) must be updated.
        Assert.AreNotEqual(GenJournalLine."Job Total Cost (LCY)", PreviousProjectTotalCostLCY, ProjectTotalCostErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure CheckUnitCostAndPriceNotZeroInRecurringJobJnlAfterPosting()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Resource: Record Resource;
        RecurringJobJnl: TestPage "Recurring Job Jnl.";
    begin
        // [SCENARIO 575092] Verify that the Unit Price and Unit Cost are not 0 in the recurring job journal after posting.
        Initialize();

        // [GIVEN] Create a Resource.
        FindResource(Resource);

        // [GIVEN] Create Job, job task & multiple Job planning line.
        CreateFullJob(Job, JobTask, Resource);

        // [GIVEN] Create Recurring Job Journal.
        OpenRecurringJobJnl(RecurringJobJnl, JobTask, Resource."No.");

        // [WHEN] Post Recurring Job Journal.
        PostRecurringJobJnl(RecurringJobJnl);

        // [THEN] Verify that the Unit Price and Unit Cost are not zero in the recurring job journal after posting.
        RecurringJobJnl."Unit Price".AssertEquals(Resource."Unit Price");
        RecurringJobJnl."Unit Cost".AssertEquals(Resource."Unit Cost");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Journal");
        LibrarySetupStorage.Restore();
        LightInit();
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Journal");

        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibrarySales.SetExtDocNo(false);

        Initialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Journal");
    end;

    local procedure LightInit()
    begin
        ClearGlobalVariables();
        LibraryVariableStorage.Clear();
    end;

    local procedure ClearGlobalVariables()
    begin
        NoSeriesCode := '';
    end;

    local procedure CreateAndUpdateJobGLAccountPrice(var JobGLAccountPrice: Record "Job G/L Account Price"; JobTask: Record "Job Task")
    begin
        LibraryJob.CreateJobGLAccountPrice(
          JobGLAccountPrice, JobTask."Job No.", JobTask."Job Task No.", LibraryERM.CreateGLAccountWithSalesSetup(), '');
        JobGLAccountPrice.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        JobGLAccountPrice.Validate("Line Discount %", LibraryRandom.RandDec(5, 2));
        JobGLAccountPrice.Modify(true);
    end;

    local procedure CreateAndUpdateJobJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        CreateJobJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("Copy VAT Setup to Jnl. Lines", false);
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateAndUpdateJobJournalLine(var JobJournalLine: Record "Job Journal Line")
    var
        JobTask: Record "Job Task";
    begin
        // Create Job Journal Line with Random Quantity and Unit Price.
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::Billable, JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", CreateItem());
        JobJournalLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        JobJournalLine.Validate("Unit Price (LCY)", LibraryRandom.RandDec(100, 2));
        JobJournalLine.Modify(true);
    end;

    local procedure CreateResourceJobJournalLine(var JobJournalLine: Record "Job Journal Line"; ResourceNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        JobTask: Record "Job Task";
    begin
        // Create Job Journal Line with Random Quantity and Unit Price.
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::"Both Budget and Billable", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
        JobJournalLine.Validate("No.", ResourceNo);
        JobJournalLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        JobJournalLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        JobJournalLine.Modify(true);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCreditMemoFromJobPlanningLine(var JobPlanningLine: Record "Job Planning Line")
    var
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.Validate("Qty. to Transfer to Invoice", JobPlanningLine.Quantity);
        JobPlanningLine.Modify(true);
        Commit();  // Required to avoid test failure.
        LibraryVariableStorage.Enqueue(WorkDate());
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, true);
    end;

    local procedure CreateGeneralJournalTemplateAndBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Jobs);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure CreateItemJournalWithBinLocation(var ItemJournalLine: Record "Item Journal Line")
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        // Create Warehouse Location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);

        // Create Warehouse Employee and create a new Bin.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // Create Item and Bin Content for it.
        LibraryWarehouse.CreateBinContent(
          BinContent, Location.Code, '', Bin.Code, LibraryInventory.CreateItem(Item), '', Item."Base Unit of Measure");

        // Create Item Journal Line with Location, Bin and Random Quantity.
        ItemJournalSetup(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(1000, 2));
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Bin Code", Bin.Code);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemWithTwoUnitOfMeasures(var ItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, CreateItem(), 1 + LibraryUtility.GenerateRandomFraction());
    end;

    local procedure CreateCustomerInvoiceDiscount(var CustInvoiceDisc: Record "Cust. Invoice Disc.")
    begin
        CustInvoiceDisc.Init();
        CustInvoiceDisc.Code := LibraryUtility.GenerateGUID();
        CustInvoiceDisc."Discount %" := LibraryRandom.RandIntInRange(5, 10);
        CustInvoiceDisc.Insert(true);
    end;

    local procedure CreateCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10])
    begin
        CurrencyExchangeRate.Init();
        CurrencyExchangeRate.Validate("Currency Code", CurrencyCode);
        CurrencyExchangeRate.Validate("Starting Date", CalcDate('<-CY>', WorkDate()));

        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 1);

        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDecInRange(20, 30, 2));
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", LibraryRandom.RandDecInRange(20, 30, 2));
        CurrencyExchangeRate.Insert(true);
    end;

    local procedure CreateResourceNo(var UnitOfMeasureCode: Code[10]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        Resource: Record Resource;
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
        LibraryResource.CreateResource(Resource, VATBusPostingGroup.Code);
        UnitOfMeasureCode := Resource."Base Unit of Measure";
        exit(Resource."No.");
    end;

    local procedure CreateJobItemPrice(var JobItemPrice: Record "Job Item Price")
    var
        Item: Record Item;
        JobTask: Record "Job Task";
    begin
        Item.Get(LibraryJob.FindItem());
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobItemPrice(
          JobItemPrice, JobTask."Job No.", JobTask."Job Task No.", Item."No.", '', '', Item."Base Unit of Measure");  // Blank value is for Currency Code and Variant Code.
    end;

    local procedure CreateJobItemPriceWithNewItemAndUnitPrice(JobTask: Record "Job Task"; ItemNo: Code[20]; ItemUnitOfMeasureCode: Code[10]; UnitPrice: Decimal)
    var
        JobItemPrice: Record "Job Item Price";
    begin
        LibraryJob.CreateJobItemPrice(JobItemPrice, JobTask."Job No.", JobTask."Job Task No.", ItemNo, '', '', ItemUnitOfMeasureCode);  // Blank value is for Currency Code and Variant Code.
        JobItemPrice.Validate("Unit Price", UnitPrice);
        JobItemPrice.Modify(true);
    end;

    local procedure CreateJobGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; BalAccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountNo: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20]; CurrencyCode: Code[10])
    begin
        // Taking Random value for Job Quantity and Amount.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", AccountNo, LibraryRandom.RandDec(100, 2));

        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Job Line Type", GenJournalLine."Job Line Type"::"Both Budget and Billable");
        GenJournalLine.Validate("Job No.", JobNo);
        GenJournalLine.Validate("Job Task No.", JobTaskNo);
        GenJournalLine.Validate("Job Quantity", LibraryRandom.RandDec(10, 2));
        GenJournalLine.Modify(true);
    end;

    local procedure CreateJobJournalLine(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task"; ResourceNo: Code[20])
    begin
        LibraryJob.CreateJobJournalLineForType("Job Line Type"::" ", JobJournalLine.Type::Resource, JobTask, JobJournalLine);  // Use 0 for Resource.
        JobJournalLine.Validate("No.", ResourceNo);
        JobJournalLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random value.
        JobJournalLine.Modify(true);
    end;

    local procedure CreateJobJournalLineAppliedFromItemLedgerEntry(var JobJournalLine: Record "Job Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    var
        JobTask: Record "Job Task";
    begin
        JobTask.Get(ItemLedgerEntry."Job No.", ItemLedgerEntry."Job Task No.");
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);

        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", ItemLedgerEntry."Item No.");
        JobJournalLine.Validate(Quantity, ItemLedgerEntry.Quantity);
        JobJournalLine.Validate("Applies-from Entry", ItemLedgerEntry."Entry No.");
    end;

    local procedure CreateJobJournalLineWithBlankUOM(var JobJournalLine: Record "Job Journal Line"; ItemNo: Code[20]; JobJournalLineType: Enum "Job Journal Line Type")
    var
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLineType);
        JobJournalLine.Validate("No.", ItemNo);
        JobJournalLine.Validate("Unit of Measure Code", '');
        JobJournalLine.Modify(true);
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; LineType: Enum "Job Planning Line Line Type"; No: Code[20]; ConsumableType: Enum "Job Planning Line Type")
    begin
        LibraryJob.CreateJobPlanningLine(LineType, ConsumableType, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", No);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random value.
        JobPlanningLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateJobPlanningLineWithResource(JobTask: Record "Job Task")
    var
        JobPlanningLine: Record "Job Planning Line";
        ResourceNo: Code[20];
    begin
        ResourceNo := LibraryJob.CreateConsumable("Job Planning Line Type"::Resource);

        CreateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, ResourceNo, JobPlanningLine.Type::Resource);
        JobPlanningLine.Validate("Unit Cost", 0);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobPlanningLineWithTypeText(var JobPlanningLine: Record "Job Planning Line"; LineType: Enum "Job Planning Line Line Type"; JobTask: Record "Job Task")
    var
        StandardText: Record "Standard Text";
    begin
        StandardText.FindFirst();
        LibraryJob.CreateJobPlanningLine(LineType, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Text);
        JobPlanningLine.Validate("No.", StandardText.Code);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobPlanningLineAndModifyUOM(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; ConsumableType: Enum "Job Planning Line Type"; No: Code[20]; UnitOfMeasureCode: Code[10])
    begin
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, No, ConsumableType);
        JobPlanningLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobPlanningLineWithUnitPriceAndLineDiscountPct(var JobPlanningLine: Record "Job Planning Line"; LineDiscountPct: Decimal)
    var
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable,
          LibraryERM.CreateGLAccountWithSalesSetup(), JobPlanningLine.Type::"G/L Account");
        JobPlanningLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        JobPlanningLine.Validate("Line Discount %", LineDiscountPct);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Jobs);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobJournalLineWithBin(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task"; ItemJournalLine: Record "Item Journal Line"; Quantity: Decimal)
    begin
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", ItemJournalLine."Item No.");
        JobJournalLine.Validate("Location Code", ItemJournalLine."Location Code");
        JobJournalLine.Validate("Bin Code", ItemJournalLine."Bin Code");
        JobJournalLine.Validate(Quantity, Quantity);
        JobJournalLine.Modify(true);
    end;

    local procedure CreateCurrencyAndTwoCurrencyRates(var Currency: Record Currency; FirstExchageRateDate: Date; SecondExchageRateDate: Date)
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, FirstExchageRateDate, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
        LibraryERM.CreateExchangeRate(Currency.Code, SecondExchageRateDate, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateJobPlanningLineWithCurrency(var JobPlanningLine: Record "Job Planning Line"; CurrencyCode: Code[10])
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Currency Code", CurrencyCode);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
    end;

    local procedure CreateJobPlanningLineToCreateInvoice(var JobJournalLine: Record "Job Journal Line"; var JobPlanningLine: Record "Job Planning Line")
    begin
        CreateAndUpdateJobJournalLine(JobJournalLine);
        JobJournalLine.Validate("Line Amount", JobJournalLine."Line Amount" - LibraryUtility.GenerateRandomFraction());
        JobJournalLine.Modify(true);
        LibraryJob.PostJobJournal(JobJournalLine);
        FindJobPlanningLine(JobPlanningLine, JobJournalLine."Job No.", JobJournalLine."Job Task No.");
    end;

    local procedure CreatePurchaseOrderWithJob(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        JobTask: Record "Job Task";
    begin
        LibraryInventory.CreateItem(Item);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 20));

        CreateJobWithJobTask(JobTask);

        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity / 2);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithTwoGlAccountLinesLinkedWithJobTask(var PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; JobTask: Record "Job Task")
    var
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        CreatePurchaseLineForGLAccountLinkedWithJobTask(PurchaseHeader, GLAccountNo, JobTask);
        CreatePurchaseLineForGLAccountLinkedWithJobTask(PurchaseHeader, GLAccountNo, JobTask);
    end;

    local procedure CreatePurchaseLineForGLAccountLinkedWithJobTask(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; JobTask: Record "Job Task")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity / 2);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateResourceUnitOfMeasure(var ResourceUnitOfMeasure: Record "Resource Unit of Measure"; Resource: Record Resource)
    begin
        LibraryResource.CreateResourceUnitOfMeasure(
          ResourceUnitOfMeasure, Resource."No.", FindUnitOfMeasure(), 1);

        // Use 1 to insure that Qty per Unit of Measure greater than Qty per Unit of Measure for Base Unit of Measure.
        ResourceUnitOfMeasure.Validate("Qty. per Unit of Measure", 1 + LibraryRandom.RandInt(10));
        ResourceUnitOfMeasure.Modify(true);
    end;

    local procedure CreateJobResourcePrice(var JobResourcePrice: Record "Job Resource Price"; Type: Option; No: Code[20])
    var
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobResourcePrice(JobResourcePrice, JobTask."Job No.", JobTask."Job Task No.", Type, No, '', '');  // Blank value is for Work Type Code and Currency Code.
    end;

    local procedure MockReservationEntry(JobJournalLine: Record "Job Journal Line")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.Init();
        ReservationEntry."Source Type" := Database::"Job Journal Line";
        ReservationEntry."Source ID" := JobJournalLine."Journal Template Name";
        ReservationEntry."Source Batch Name" := JobJournalLine."Journal Batch Name";
        ReservationEntry."Source Ref. No." := JobJournalLine."Line No.";
        ReservationEntry."Source Subtype" := JobJournalLine."Entry Type".AsInteger();
        ReservationEntry."Source Prod. Order Line" := 0;
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Reservation;
        ReservationEntry."Quantity (Base)" := LibraryRandom.RandDecInRange(1000, 2000, 2);
        ReservationEntry.Insert();
    end;

    local procedure DeleteJobJournalTemplate(Name: Code[10])
    var
        JobJournalTemplate: Record "Job Journal Template";
    begin
        JobJournalTemplate.Get(Name);
        JobJournalTemplate.Delete(true);
    end;

    local procedure ItemJournalSetup(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; JobNo: Code[20]; EntryType: Enum "Item Ledger Entry Type")
    begin
        ItemLedgerEntry.SetRange("Job No.", JobNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindJobJournalLine(var JobJournalLine: Record "Job Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        JobJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        JobJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        JobJournalLine.FindFirst();
    end;

    local procedure FindJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; DocumentNo: Code[20]; JobNo: Code[20]; ConsumableType: Enum "Job Planning Line Type"; No: Code[20])
    begin
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.SetRange(Type, ConsumableType);
        JobLedgerEntry.SetRange("No.", No);
        JobLedgerEntry.FindFirst();
    end;

    local procedure FindJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.SetRange("Job Task No.", JobTaskNo);
        JobPlanningLine.FindLast();
    end;

    local procedure FindUnitOfMeasure(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        exit(UnitOfMeasure.Code);
    end;

    local procedure FindSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; JobNo: Code[20]; Type: Enum "Sales Line Type")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, DocumentType, Type, JobNo);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; JobNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange(Type, Type);
        SalesLine.SetRange("Job No.", JobNo);
        SalesLine.FindFirst();
    end;

    local procedure ModifyJobItemPriceForUnitPrice(var JobItemPrice: Record "Job Item Price"; UnitPrice: Decimal)
    begin
        JobItemPrice.Validate("Unit Price", UnitPrice);
        JobItemPrice.Modify(true);
    end;

    local procedure ModifyJobItemPriceForUnitCostFactor(var JobItemPrice: Record "Job Item Price"; UnitCostFactor: Decimal)
    begin
        JobItemPrice.Validate("Unit Cost Factor", UnitCostFactor);
        JobItemPrice.Modify(true);
    end;

    local procedure ModifyJobResourcePriceForUnitPrice(var JobResourcePrice: Record "Job Resource Price"; UnitPrice: Decimal)
    begin
        JobResourcePrice.Validate("Unit Price", UnitPrice);
        JobResourcePrice.Modify(true);
    end;

    local procedure ModifyJobResourcePriceForUnitCostFactor(var JobResourcePrice: Record "Job Resource Price"; UnitCostFactor: Decimal)
    begin
        JobResourcePrice.Validate("Unit Cost Factor", UnitCostFactor);
        JobResourcePrice.Modify(true);
    end;

    local procedure PostGeneralJournalLine(GenJournalLine: Record "Gen. Journal Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJournalLine);
    end;

    local procedure RunCalcRemainingUsageFromJobJournalPage(var JobJournalBatch: Record "Job Journal Batch"; JobNo: Code[20])
    var
        JobJournalTemplate: Record "Job Journal Template";
        JobJournal: TestPage "Job Journal";
    begin
        LibraryJob.CreateJobJournalBatch(LibraryJob.GetJobJournalTemplate(JobJournalTemplate), JobJournalBatch);
        NoSeriesCode := JobJournalBatch."No. Series";  // Assigning Batch No. Series to global variable.
        LibraryVariableStorage.Enqueue(JobJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(JobNo);
        Commit();  // Commit required to avoid test failures.

        // Need to Run Calc. Remaining Usage Batch Job from Job Journal page due to Code Written on Page and Job Journal Lines needed to be blank before running batch job.
        JobJournal.OpenEdit();
        JobJournal.CurrentJnlBatchName.SetValue(JobJournalBatch.Name);
        JobJournal.CalcRemainingUsage.Invoke();
    end;

    local procedure OpenJobJournalAndLookupUnitofMeasure(JobJournalBatchName: Code[10])
    var
        JobJournal: TestPage "Job Journal";
    begin
        JobJournal.OpenEdit();
        JobJournal.CurrentJnlBatchName.SetValue(JobJournalBatchName);
        JobJournal."Unit of Measure Code".Lookup();
        JobJournal.OK().Invoke();
    end;

    local procedure UpdateSalesSetupCopyLineDescr(CopyLineDescr: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Copy Line Descr. to G/L Entry" := CopyLineDescr;
        SalesReceivablesSetup.Modify();
    end;

    local procedure UpdatePurchaseSetupCopyLineDescr(CopyLineDescr: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Copy Line Descr. to G/L Entry" := CopyLineDescr;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure UpdateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; AccountNo: Code[20])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        CreateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Billable, AccountNo, JobPlanningLine.Type::"G/L Account");
        JobPlanningLine.Validate("Qty. to Transfer to Invoice", JobPlanningLine.Quantity);
        GenProductPostingGroup.SetFilter(Code, '<>%1', JobPlanningLine."Gen. Prod. Posting Group");
        GenProductPostingGroup.SetFilter("Def. VAT Prod. Posting Group", '<>%1', '');
        GenProductPostingGroup.FindFirst();
        JobPlanningLine.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        JobPlanningLine.Modify(true);
    end;

    local procedure UpdateLineDiscountPctOnJobGLAccountPrice(var JobGLAccountPrice: Record "Job G/L Account Price")
    begin
        JobGLAccountPrice.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));  // Taking Random value for Line Discount Percent.
        JobGLAccountPrice.Modify(true);
    end;

    local procedure UpdateQuantityAndDiscountOnPlanningLine(JobPlanningLine: Record "Job Planning Line"; LineDiscountAmount: Decimal)
    begin
        JobPlanningLine.Validate(Quantity, -JobPlanningLine.Quantity);
        JobPlanningLine.Validate("Line Discount Amount", LineDiscountAmount);
        JobPlanningLine.Modify(true);
    end;

    local procedure UpdateSourceCodeSetup(JobGLJournal: Code[10]; JobGLWIP: Code[10])
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        SourceCodeSetup.Validate("Job G/L Journal", JobGLJournal);
        SourceCodeSetup.Validate("Job G/L WIP", JobGLWIP);
        SourceCodeSetup.Modify(true);
    end;

    local procedure UpdateUnitCostFactorOnJobGLAccountPrice(var JobGLAccountPrice: Record "Job G/L Account Price")
    begin
        JobGLAccountPrice.Validate("Unit Cost Factor", LibraryRandom.RandDec(10, 2));  // Taking Random value for Unit Cost Factor.
        JobGLAccountPrice.Modify(true);
    end;

    local procedure UpdateUnitCostOnJobGLAccountPrice(var JobGLAccountPrice: Record "Job G/L Account Price")
    begin
        JobGLAccountPrice.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));  // Taking Random value for Unit Cost.
        JobGLAccountPrice.Modify(true);
    end;

    local procedure UpdateUnitPriceOnJobGLAccountPrice(var JobGLAccountPrice: Record "Job G/L Account Price")
    begin
        JobGLAccountPrice.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Taking Random value for Unit Price.
        JobGLAccountPrice.Modify(true);
    end;

    local procedure UpdateUnitCostOnJobJournalLine(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task"; No: Code[20]; UnitCost: Decimal)
    begin
        LibraryJob.CreateJobJournalLineForType(
          JobJournalLine."Line Type"::"Both Budget and Billable", JobJournalLine.Type::"G/L Account", JobTask, JobJournalLine);
        JobJournalLine.Validate("No.", No);
        JobJournalLine.Validate("Unit Cost", UnitCost);
        JobJournalLine.Modify(true);
    end;

    local procedure UpdateContactInfo(var Contact: Record Contact; PhoneNo: Text[30]; MobilePhoneNo: Text[30]; Email: Text[80])
    begin
        Contact.Validate("Phone No.", PhoneNo);
        Contact.Validate("Mobile Phone No.", MobilePhoneNo);
        Contact.Validate("E-Mail", Email);
        Contact.Modify(true);
    end;

    local procedure VerifyAmountsOnJobPlanningLine(JobPlanningLine: Record "Job Planning Line"; LineAmount: Decimal; LineDiscountAmount: Decimal)
    begin
        JobPlanningLine.TestField("Line Discount Amount", LineDiscountAmount);
        JobPlanningLine.TestField("Line Amount", LineAmount);
    end;

    local procedure VerifyBinContentEntry(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.FindFirst();
        BinContent.CalcFields(Quantity);
        BinContent.TestField(Quantity, Quantity);
    end;

    local procedure VerifyBankAccNoOnBankAccountLedgerEntries(BankAccNo: Code[20]; Amount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccNo);
        BankAccountLedgerEntry.FindFirst();
        Assert.AreEqual(Amount, BankAccountLedgerEntry.Amount, AmountErr);
    end;

    local procedure VerifyDifferentCostsInJobLedgerEntry(GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    var
        Currency: Record Currency;
        JobLedgerEntry: Record "Job Ledger Entry";
        Cost: Decimal;
    begin
        Currency.Get(GenJournalLine."Currency Code");
        Cost := Round(Amount / GenJournalLine."Job Quantity", Currency."Unit-Amount Rounding Precision");  // Round the Amount as per Currency's Unit Amount Rounding Precision.
        FindJobLedgerEntry(
          JobLedgerEntry, GenJournalLine."Document No.", GenJournalLine."Job No.", JobLedgerEntry.Type::"G/L Account",
          GenJournalLine."Account No.");
        JobLedgerEntry.TestField(Quantity, GenJournalLine."Job Quantity");
        Assert.AreNearlyEqual(Cost, JobLedgerEntry."Direct Unit Cost (LCY)", 0.001, 'Direct Unit Cost (LCY) must match');
        Assert.AreNearlyEqual(Cost, JobLedgerEntry."Unit Cost (LCY)", 0.001, 'Unit Cost (LCY) must match');
        JobLedgerEntry.TestField("Total Cost (LCY)", Amount);
        JobLedgerEntry.TestField("Original Total Cost (LCY)", Amount);
        Assert.AreNearlyEqual(Cost, JobLedgerEntry."Original Unit Cost (LCY)", 0.001, 'Original Unit Cost (LCY) must match');
        JobLedgerEntry.TestField("Unit Cost", Amount / GenJournalLine."Job Quantity");
        JobLedgerEntry.TestField("Total Cost", Amount);
        JobLedgerEntry.TestField("Original Unit Cost", Amount / GenJournalLine."Job Quantity");
        JobLedgerEntry.TestField("Original Total Cost", Amount);
    end;

    local procedure VerifyDiscountOnJobLedgerEntry(DocumentNo: Code[20]; JobNo: Code[20]; AccountNo: Code[20]; UnitPrice: Decimal; LineDiscountPct: Decimal; LineDiscountAmount: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobNo, JobLedgerEntry.Type::"G/L Account", AccountNo);
        JobLedgerEntry.TestField("Unit Price", UnitPrice);
        JobLedgerEntry.TestField("Line Discount %", LineDiscountPct);
        JobLedgerEntry.TestField("Line Discount Amount", LineDiscountAmount);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyJobGLJournalLine(GenJournalLine: Record "Gen. Journal Line"; JobUnitCost: Decimal; JobUnitPrice: Decimal)
    begin
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        GenJournalLine.TestField("Job Unit Cost", JobUnitCost);
        GenJournalLine.TestField("Job Unit Price", JobUnitPrice);
    end;

    local procedure VerifyJobJournalLine(JobJournalLine: Record "Job Journal Line"; Resource: Record Resource; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Decimal)
    begin
        JobJournalLine.TestField("Unit Cost (LCY)", Resource."Unit Cost" * QtyPerUnitOfMeasure);
        JobJournalLine.TestField("Total Cost (LCY)", Resource."Unit Cost" * QtyPerUnitOfMeasure * JobJournalLine.Quantity);
        JobJournalLine.TestField("Unit Price (LCY)", Resource."Unit Price" * QtyPerUnitOfMeasure);
        JobJournalLine.TestField("Total Price (LCY)", Resource."Unit Price" * QtyPerUnitOfMeasure * JobJournalLine.Quantity);
        JobJournalLine.TestField("Unit Price", Resource."Unit Price" * QtyPerUnitOfMeasure);
        JobJournalLine.TestField("Unit Cost", Resource."Unit Cost" * QtyPerUnitOfMeasure);
        JobJournalLine.TestField("Total Price", Resource."Unit Price" * QtyPerUnitOfMeasure * JobJournalLine.Quantity);
        JobJournalLine.TestField("Direct Unit Cost (LCY)", Resource."Direct Unit Cost" * QtyPerUnitOfMeasure);
        JobJournalLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    local procedure VerifyCostAndPriceOnJobPlanningLine(JobPlanningLine: Record "Job Planning Line"; Resource: Record Resource; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Decimal)
    begin
        JobPlanningLine.TestField("Unit Cost (LCY)", Resource."Unit Cost" * QtyPerUnitOfMeasure);
        JobPlanningLine.TestField("Total Cost (LCY)", Resource."Unit Cost" * QtyPerUnitOfMeasure * JobPlanningLine.Quantity);
        JobPlanningLine.TestField("Unit Price (LCY)", Resource."Unit Price" * QtyPerUnitOfMeasure);
        JobPlanningLine.TestField("Total Price (LCY)", Resource."Unit Price" * QtyPerUnitOfMeasure * JobPlanningLine.Quantity);
        JobPlanningLine.TestField("Unit Price", Resource."Unit Price" * QtyPerUnitOfMeasure);
        JobPlanningLine.TestField("Unit Cost", Resource."Unit Cost" * QtyPerUnitOfMeasure);
        JobPlanningLine.TestField("Total Price", Resource."Unit Price" * QtyPerUnitOfMeasure * JobPlanningLine.Quantity);
        JobPlanningLine.TestField("Direct Unit Cost (LCY)", Resource."Direct Unit Cost" * QtyPerUnitOfMeasure);
        JobPlanningLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    local procedure VerifyPostingGroupOnJobLedgerEntry(DocumentNo: Code[20]; JobNo: Code[20]; No: Code[20])
    var
        Item: Record Item;
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        Item.Get(No);
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobNo, JobLedgerEntry.Type::Item, No);
        JobLedgerEntry.TestField("Job Posting Group", Item."Inventory Posting Group");
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

    local procedure VerifyCurrencyFactor(JobPlanningLine: Record "Job Planning Line"; CurrencyExcahgeRateDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        SalesLine.SetRange("Job No.", JobPlanningLine."Job No.");
        SalesLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        SalesLine.FindFirst();
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.TestField("Currency Factor", CurrencyExchangeRate.ExchangeRate(CurrencyExcahgeRateDate, SalesHeader."Currency Code"));
        JobPlanningLine.TestField("Currency Factor", SalesHeader."Currency Factor");
    end;

    [Scope('OnPrem')]
    procedure ChangeItemQuantityAndVerifyNoStockWarning(JobJournalLine: Record "Job Journal Line")
    var
        JobJournal: TestPage "Job Journal";
        NewQuantity: Decimal;
    begin
        // [WHEN] The item quantity is changed through the job journal
        LibraryVariableStorage.Enqueue(JobJournalLine."Journal Template Name");
        JobJournal.OpenEdit();
        JobJournal.GotoKey(JobJournalLine."Journal Template Name", JobJournalLine."Journal Batch Name", JobJournalLine."Line No.");
        NewQuantity := LibraryRandom.RandDec(100, 1);
        JobJournal.Quantity.SetValue(NewQuantity);
        JobJournal.Next();

        // [THEN] No out of stock warning is generated (no SendNotification UI unhandled) and the job journal line quantity is updated
        JobJournalLine.Find();
        JobJournalLine.TestField(Quantity, NewQuantity);
    end;

    local procedure JobUpdateBillToContactNoBlocked(Blocked: Enum "Job Blocked")
    var
        Job: Record Job;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Bill-to Contact No.", '');
        Job.Validate(Blocked, Blocked);

        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Job."Bill-to Customer No.");
        ContactBusinessRelation.FindFirst();

        Job.Validate("Bill-to Contact No.", ContactBusinessRelation."Contact No.");

        Assert.AreEqual(ContactBusinessRelation."Contact No.", Job."Bill-to Contact No.", IncorrectFieldValueErr);
    end;

    local procedure CreateJobPlanningLineAndModifyUnitPrice(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; Type: Enum "Job Planning Line Type"; No: Code[20]; UnitPrice: Decimal)
    begin
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::Budget, No, Type);
        JobPlanningLine.Validate("Unit Price", UnitPrice);
        JobPlanningLine.Modify(true);
    end;

    local procedure SetupCurrencyWithExchRates(): Code[10]
    var
        Currency: Record Currency;
        CurrExchRateAmount: Decimal;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Realized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Unit-Amount Rounding Precision", 0.001);
        Currency.Modify(true);

        CurrExchRateAmount := LibraryRandom.RandDec(100, 2);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 1 / CurrExchRateAmount, 1 / CurrExchRateAmount);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate() + 1, 1 / (CurrExchRateAmount - 1), 1 / (CurrExchRateAmount - 1));
        exit(Currency.Code);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CurrencyRateConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobCalcRemainingUsageRequestPageHandler(var JobCalcRemainingUsage: TestRequestPage "Job Calc. Remaining Usage")
    var
        NoSeries: Codeunit "No. Series";
    begin
        JobCalcRemainingUsage."Job Task".SetFilter("Job No.", LibraryVariableStorage.DequeueText());
        JobCalcRemainingUsage.DocumentNo.SetValue(NoSeries.PeekNextNo(NoSeriesCode));
        JobCalcRemainingUsage.PostingDate.SetValue(Format(WorkDate()));
        JobCalcRemainingUsage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobJournalTemplateListPageHandler(var JobJournalTemplateList: TestPage "Job Journal Template List")
    var
        TemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(TemplateName);
        JobJournalTemplateList.FILTER.SetFilter(Name, TemplateName);
        JobJournalTemplateList.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToSalesInvoiceRequestPageHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice.PostingDate.SetValue(LibraryVariableStorage.DequeueDate());
        JobTransferToSalesInvoice.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToCreditMemoRequestPageHandler(var JobTransferToCreditMemo: TestRequestPage "Job Transfer to Credit Memo")
    begin
        JobTransferToCreditMemo.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemUnitsOfMeasurePageHandler(var ItemUnitsofMeasure: TestPage "Item Units of Measure")
    begin
        ItemUnitsofMeasure.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceUnitsOfMeasurePageHandler(var ResourceUnitsofMeasure: TestPage "Resource Units of Measure")
    begin
        ResourceUnitsofMeasure.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnitsOfMeasurePageHandler(var UnitsofMeasure: TestPage "Units of Measure")
    var
        UnitOfMeasureCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(UnitOfMeasureCode);
        UnitsofMeasure.FILTER.SetFilter(Code, UnitOfMeasureCode);
        UnitsofMeasure.OK().Invoke();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Jnl.-Check Line", 'OnBeforeRunCheck', '', false, false)]
    local procedure OnBeforeRunCheck(var JobJnlLine: Record "Job Journal Line")
    begin
        // Verify auto calc field is reset
        JobJnlLine.Find();
        JobJnlLine.TestField("Reserved Qty. (Base)", 0);
    end;

    local procedure FindResource(var Resource: Record Resource)
    begin
        Resource.Get(LibraryJob.CreateConsumable("Job Planning Line Type"::Resource));
        Resource.Validate(Type, Resource.Type::Person);
        Resource.Validate("Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        Resource.Validate("Unit Price", LibraryRandom.RandIntInRange(300, 500));
        Resource.Modify(true);
    end;

    local procedure CreateFullJob(var Job: Record Job; var JobTask: Record "Job Task"; Resource: Record Resource)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        LibraryJob.CreateJobPlanningLine(
            JobTask, JobPlanningLine."Line Type"::"Both Budget and Billable",
            JobPlanningLine.Type::Resource, Resource."No.", LibraryRandom.RandInt(10), JobPlanningLine);
    end;

    local procedure OpenRecurringJobJnl(var RecurringJobJnl: TestPage "Recurring Job Jnl."; JobTask: Record "Job Task"; ResourceNo: Code[20])
    var
        JobJournalLineType: Enum "Job Journal Line Type";
        RecurringMethod: Option ,Fixed,Variable;
    begin
        RecurringJobJnl.OpenEdit();
        RecurringJobJnl."Recurring Method".SetValue(Format(RecurringMethod::Variable));
        RecurringJobJnl."Recurring Frequency".SetValue('10D');
        RecurringJobJnl."Document No.".SetValue(JobTask."Job No.");
        RecurringJobJnl."Job No.".SetValue(JobTask."Job No.");
        RecurringJobJnl."Job Task No.".SetValue(JobTask."Job Task No.");
        RecurringJobJnl.Type.SetValue(Format(JobJournalLineType::Resource));
        RecurringJobJnl."No.".SetValue(ResourceNo);
        RecurringJobJnl.Quantity.SetValue(Format(LibraryRandom.RandInt(5)));
        RecurringJobJnl.Close();
    end;

    local procedure PostRecurringJobJnl(var RecurringJobJnl: TestPage "Recurring Job Jnl.")
    begin
        RecurringJobJnl.OpenEdit();
        RecurringJobJnl."P&ost".Invoke();
        Commit();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactListPageHandler(var ContactList: TestPage "Contact List")
    begin
        ContactList.GoToKey(LibraryVariableStorage.DequeueText());
        ContactList.OK().Invoke();
    end;
}
