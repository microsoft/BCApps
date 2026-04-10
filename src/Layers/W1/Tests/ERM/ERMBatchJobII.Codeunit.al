codeunit 134919 "ERM Batch Job II"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Budget]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJob: Codeunit "Library - Job";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        TargetJobStatus: Enum "Job Status";
        GLAccountNo: Code[20];
        Amount: Decimal;
        BudgetNameErrorMessage: Label 'You must specify a budget name to copy from.';
        DateIntervalErrorMessage: Label 'You must specify a date interval to copy from.';
        CopyToErrorMessage: Label 'You must specify a budget name to copy to.';
        BudgetName: Code[10];
        BudgetError: Label 'G/L Budget: %1 must not exist.', Comment = '%1=G/L Budget Name';
        JobsCopyMsg: Label 'The project no. %1 was successfully copied to the new project no. %2 with the status %3.', Comment = '%1 - The "No." of source project; %2 - The "No." of target project, %3 - project status.';
        PurchaseHeaderMustNotBeFoundErr: Label 'Purchase Header must not be found.';

    [Test]
    [Scope('OnPrem')]
    procedure CopyFromGLBudgetError()
    var
        FromSource: Option "G/L Entry","G/L Budget Entry";
    begin
        // Check Error Message when Copy From Budget Field is not filled up while running Copy GL Budget Batch Job.

        // Setup.
        Initialize();

        // Exercise: Try to Run Copy GL Budget Batch job without Copy From GL Budget Name, GL Account No, Date Interval, Copy To GL Budget Name, Blank Rounding Method Code.
        asserterror RunCopyGLBudget(FromSource::"G/L Budget Entry", '', '', '', '', 1, '');  // Take 1 as Adjustment Factor.

        // Verify: Verify Error Message.
        Assert.ExpectedError(StrSubstNo(BudgetNameErrorMessage));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyFromDateIntervalError()
    var
        FromSource: Option "G/L Entry","G/L Budget Entry";
    begin
        // Check Error Message when Copy From Date Field is not filled up while running Copy GL Budget Batch Job.

        // Setup.
        Initialize();

        // Exercise: Try to Run Copy GL Budget Batch job without GL Account No, Date Interval, Copy To GL Budget Name and Blank Rounding Method Code, take 1 as Adjustment Factor.
        asserterror RunCopyGLBudget(FromSource::"G/L Entry", '', '', '', '', 1, '');

        // Verify: Verify Error Message.
        Assert.ExpectedError(StrSubstNo(DateIntervalErrorMessage));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyToGLBudgetError()
    var
        FromSource: Option "G/L Entry","G/L Budget Entry";
    begin
        // Check Error Message when Copy to Budget Field is not filled up while running Copy GL Budget Batch Job.

        // Setup.
        Initialize();

        // Exercise: Try to Run Copy GL Budget Batch job without Copy From GL Budget Name, GL Account No, Copy To GL Budget Name and Blank Rounding Method Code.
        asserterror RunCopyGLBudget(FromSource::"G/L Entry", '', '', Format(WorkDate()), '', 1, '');  // Take 1 as Adjustment Factor.

        // Verify: Verify Error Message.
        Assert.ExpectedError(StrSubstNo(CopyToErrorMessage));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetCreation()
    var
        GLBudgetName: Record "G/L Budget Name";
        FromSource: Option "G/L Entry","G/L Budget Entry";
        NewBudgetName: Code[10];
    begin
        // Check that new GL Budget created after confirming message asked to create GL Budget while running Copy GL Budget.

        // Setup: Take a Random Name for Copy To GL Budget Name.
        Initialize();
        NewBudgetName := Format(LibraryRandom.RandInt(100));

        // Exercise: Run Copy GL Budget Using blank for Copy From GL Budget, Rounding Method and 1 for Adjustment Factor.
        RunCopyGLBudget(FromSource::"G/L Entry", '', GLAccountNo, Format(WorkDate()), NewBudgetName, 1, '');

        // Verify: Verify that new GL Budget Exists.
        GLBudgetName.Get(NewBudgetName);

        // Tear Down: Delete the GL Budget created earlier.
        GLBudgetName.Delete(true);
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetCreationDeclined()
    var
        GLBudgetName: Record "G/L Budget Name";
        FromSource: Option "G/L Entry","G/L Budget Entry";
        NewBudgetName: Code[10];
    begin
        // Check that GL Budget does not exist when creation confirmation message for GL Budget declined.

        // Setup: Create and Post General Journal Line for a GL Account with random Amount.
        Initialize();
        NewBudgetName := Format(LibraryRandom.RandInt(100));  // Taking a Random Name for New Budget to be created.
        GLBudgetName.FindFirst();

        // Exercise: Run Copy GL Budget using blank for Rounding Method, GL Account No. and 1 for Adjustment Factor.
        RunCopyGLBudget(FromSource::"G/L Budget Entry", GLBudgetName.Name, '', Format(WorkDate()), NewBudgetName, 1, '');

        // Verify: Verify that new GL Budget must not exists after declining to create a new Budget.
        GLBudgetName.SetRange(Name, NewBudgetName);
        Assert.IsFalse(GLBudgetName.FindFirst(), StrSubstNo(BudgetError, NewBudgetName));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetSourceGLEntry()
    var
        FromSource: Option "G/L Entry","G/L Budget Entry";
    begin
        // Check correct Amount copied to new GL Budget when Copy From Source is GL Entry.

        // Setup: Create and Post General Journal Line for a GL Account with random Amount.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountNo();  // Assign GL Account No. to global variable.
        Amount := LibraryRandom.RandDec(100, 2);  // Assign Random Amount to global variable.
        CreateAndPostGenJournalLine(GLAccountNo, Amount);
        CopyGLBudgetFromDifferentSources(FromSource::"G/L Entry", '', 1, '');  // Passing blanks for Copy From GL Budget Name and Rounding Method, 1 for Adjustment Factor.
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetSourceGLBudgetEntry()
    var
        GLBudgetName: Record "G/L Budget Name";
        FromSource: Option "G/L Entry","G/L Budget Entry";
    begin
        // Check correct Amount copied on new GL Budget when Copy From Source is GL Budget Entry.

        // Setup: Create GL Budget Entry for a GL Account with random Amount.
        Initialize();
        GLBudgetName.FindFirst();
        GLAccountNo := LibraryERM.CreateGLAccountNo();  // Assign GL Account No. to  global variable.
        Amount := LibraryRandom.RandDec(100, 2);  // Assign Random Amount to global variable.
        CreateGLBudgetEntry(GLBudgetName.Name, GLAccountNo, Amount);
        CopyGLBudgetFromDifferentSources(FromSource::"G/L Budget Entry", GLBudgetName.Name, 1, '');  // Passing blank for Rounding Method, 1 for Adjustment Factor.
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure GLEntryWithRoundingMethod()
    var
        FromSource: Option "G/L Entry","G/L Budget Entry";
    begin
        // Check correct Amount copied on new GL Budget while Copy From Source is GL Entry and a Rounding Method used.

        // Setup: Create and Post General Journal Line with random Amount.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountNo();  // Assign GL Account No. to global variable.
        Amount := LibraryRandom.RandDec(100, 2);  // Assign Random Amount to global variable.
        CreateAndPostGenJournalLine(GLAccountNo, Amount);
        CopyGLBudgetFromDifferentSources(FromSource::"G/L Entry", '', 1, CalculateAmountUsingRoundingMethod(Amount));  // Passing blank for Copy From GL Budget, 1 for Adjustment Factor.
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetEntryWithRoundingMethod()
    var
        GLBudgetName: Record "G/L Budget Name";
        FromSource: Option "G/L Entry","G/L Budget Entry";
    begin
        // Check correct Amount copied on new GL Budget while Copy From Source is GL Budget Entry and a Rounding Method Used.

        // Setup: Create GL Budget Entry for a GL Account with random Amount.
        Initialize();
        GLBudgetName.FindFirst();
        GLAccountNo := LibraryERM.CreateGLAccountNo();  // Assign GL Account No. to global variable.
        Amount := LibraryRandom.RandDec(100, 2);  // Assign Random Amount to global variable.
        CreateGLBudgetEntry(GLBudgetName.Name, GLAccountNo, Amount);
        CopyGLBudgetFromDifferentSources(FromSource::"G/L Budget Entry", GLBudgetName.Name, 1, CalculateAmountUsingRoundingMethod(Amount));  // Passing 1 for Adjustment Factor.
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure GLEntryWithAdjustmentFactor()
    var
        FromSource: Option "G/L Entry","G/L Budget Entry";
        AdjustmentFactor: Decimal;
    begin
        // Check correct Amount copied on new GL Budget while Copy From Source is GL Entry and random Adjustment Factor used.

        // Setup: Create and Post General Journal Line with random Amount, take random Adjustment Factor.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountNo();  // Assign GL Account No. to global variable.
        Amount := LibraryRandom.RandDec(100, 2);  // Assign Random Amount to global variable.
        AdjustmentFactor := LibraryRandom.RandDec(10, 2);
        CreateAndPostGenJournalLine(GLAccountNo, Amount);
        Amount := AdjustmentFactor * Amount;  // Calculate Expected Amount after using adjustment factor and assign it to global variable.
        CopyGLBudgetFromDifferentSources(FromSource::"G/L Entry", '', AdjustmentFactor, '');  // Passing blank for Copy From Budget and Rounding Method.
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetEntryWithAdjustmentFactor()
    var
        GLBudgetName: Record "G/L Budget Name";
        AdjustmentFactor: Decimal;
        FromSource: Option "G/L Entry","G/L Budget Entry";
    begin
        // Check correct Amount copied on new GL Budget while Copy From Source is GL Budget Entry and random Adjustment Factor used.

        // Setup: Create GL Budget Entry for a GL Account with random Amount, take random Adjustment Factor.
        Initialize();
        GLBudgetName.FindFirst();
        GLAccountNo := LibraryERM.CreateGLAccountNo();  // Assign GL Account No. to global variable.
        Amount := LibraryRandom.RandDec(100, 2);  // Assign Random Amount to global variable.
        AdjustmentFactor := LibraryRandom.RandDec(10, 2);
        CreateGLBudgetEntry(GLBudgetName.Name, GLAccountNo, Amount);
        Amount := AdjustmentFactor * Amount;  // Calculate Expected Amount after using adjustment factor and assign it to global variable.
        CopyGLBudgetFromDifferentSources(FromSource::"G/L Budget Entry", GLBudgetName.Name, AdjustmentFactor, '');  // Passing blank for Rounding Method.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvoiceRequestHandler')]
    [Scope('OnPrem')]
    procedure IsCorrectNumbersOfJobLedjerEntries()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [SCENARIO 338219] Create 1 Sales Invoice for 3 Job Planning Lines
        // [GIVEN] Created Job and Sales Invoice
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Job."Bill-to Customer No.");

        // [GIVEN] Created 3 Job Planning Line with "Both Budget and Billable" type
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        Commit();

        // [GIVEN] Added line to Sales Invoice
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [WHEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] 3 created lines in Job Planning Line Invoice in field "Job Ledger Entry No." had different value, not equal to 0.
        CompareJobLedgerEntryNos(Job, JobTask);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CopyJobModalPageHandler,CheckMessageHandler')]
    [Scope('OnPrem')]
    procedure CheckCorrectMessageAfterJobsCopy()
    var
        Job: Record Job;
        JobList: TestPage "Job List";
        TargetJobNo: Code[20];
        TargetJobDescription: Text;
    begin
        // [SCENARIO 363807] The correct message is shown after jobs copy
        Initialize();

        // [GIVEN] Created Job 
        LibraryJob.CreateJob(Job);

        // [GIVEN] Page Job List opened
        JobList.OpenEdit();
        JobList.Filter.SetFilter("No.", Job."No.");
        JobList.First();

        // [GIVEN] Create and Save for handler "Target Job No." and "Target Job Description"
        TargetJobNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TargetJobNo));
        TargetJobDescription := LibraryRandom.RandText(20);
        LibraryVariableStorage.Enqueue(TargetJobNo);
        LibraryVariableStorage.Enqueue(TargetJobDescription);

        // [WHEN] Invoke Copy Jobs
        JobList.CopyJob.Invoke();

        // [THEN] The Message is correct
        Assert.AreEqual(STRSUBSTNO(JobsCopyMsg, Job."No.", TargetJobNo, "Job Status"::Planning), LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationCodeAllowedOnJobLineForNonInventoryItems()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Item: Record Item;
        Location: Record Location;
    begin
        // [GIVEN] Location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Created Job.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Item of type Non-inventory for job planning line.
        LibraryInventory.CreateItem(Item);
        Item.Type := Item.Type::"Non-Inventory";
        Item.Modify();

        // [GIVEN] Created Job Planning Line with "Both Budget and Billable" type for the item.
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", JobTask."Job No.");
        JobPlanningLine.Validate("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.Validate("Line No.", LibraryJob.GetNextLineNo(JobPlanningLine));
        JobPlanningLine.Insert(true);

        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::"Both Budget and Billable");
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", Item."No.");

        // [WHEN] Setting the location code on the job planning line.
        JobPlanningLine.Validate("Location Code", Location.Code);

        // [THEN] No validation error is thrown.
    end;

    [Test]
    [HandlerFunctions('CopyJobModalPageHandler,CheckMessageHandler')]
    [Scope('OnPrem')]
    procedure CheckStatusAfterJobsCopy()
    var
        Job: Record Job;
        ERMBatchJobII: Codeunit "ERM Batch Job II";
        JobList: TestPage "Job List";
        TargetJobNo: Code[20];
        TargetJobDescription: Text;
    begin
        // [SCENARIO 413072] The message contains target job status after job copied
        Initialize();

        // [GIVEN] Created Job 
        LibraryJob.CreateJob(Job);

        // [GIVEN] Page Job List opened
        JobList.OpenEdit();
        JobList.Filter.SetFilter("No.", Job."No.");
        JobList.First();

        // [GIVEN] Create and Save for handler "Target Job No." and "Target Job Description"
        TargetJobNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TargetJobNo));
        TargetJobDescription := LibraryRandom.RandText(20);
        LibraryVariableStorage.Enqueue(TargetJobNo);
        LibraryVariableStorage.Enqueue(TargetJobDescription);

        // [GIVEN] Set new target job status = "Completed"
        BindSubscription(ERMBatchJobII);
        ERMBatchJobII.SetTargetJobStatus("Job Status"::Completed);

        // [WHEN] Invoke Copy Jobs
        JobList.CopyJob.Invoke();

        // [THEN] The Message is correct
        Assert.AreEqual(STRSUBSTNO(JobsCopyMsg, Job."No.", TargetJobNo, "Job Status"::Completed), LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
        UnbindSubscription(ERMBatchJobII);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure POHavingPurchLineWithJobPlanningLineNoIsReceivedAndInvoiced()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Vendor: Record Vendor;
        Location: Record Location;
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseLine: array[3] of Record "Purchase Line";
    begin
        // [SCENARIO 559229] Purchase Order having Job Planning Line No. 
        // Is received and invoiced without any error.
        Initialize();

        // [GIVEN] Create an Item and Validate Order Tracking Policy.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Job.
        LibraryJob.CreateJob(Job);

        // [GIVEN] Create a Job Task.
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create a Job Planning Line and Validate No., Quantity and Location Code.
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(0));
        JobPlanningLine.Validate("Location Code", Location.Code);
        JobPlanningLine.Modify(true);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader[1],
            PurchaseHeader[1]."Document Type"::Order,
            Vendor."No.");

        // [GIVEN] Create a Purchase Line [1] with Job Planning Line No.
        CreatePurchaseLineWithJobPlanningLineNo(
            PurchaseHeader[1],
            PurchaseLine[1],
            Item,
            Location,
            Job,
            JobTask,
            JobPlanningLine);

        // [GIVEN] Post Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader[2],
            PurchaseHeader[2]."Document Type"::Order,
            Vendor."No.");

        // [GIVEN] Create a Purchase Line [2] with Job Planning Line No.
        CreatePurchaseLineWithJobPlanningLineNo(
            PurchaseHeader[2],
            PurchaseLine[2],
            Item,
            Location,
            Job,
            JobTask,
            JobPlanningLine);

        // [GIVEN] Create a Purchase Line [3] with Job Planning Line No.
        CreatePurchaseLineWithJobPlanningLineNo(
            PurchaseHeader[2],
            PurchaseLine[3],
            Item,
            Location,
            Job,
            JobTask,
            JobPlanningLine);

        // [GIVEN] Receive Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], true, false);

        // [WHEN] Invoice Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], false, true);

        // [THEN] Find Purchase Header.
        Assert.IsFalse(
            PurchaseHeader[3].Get(PurchaseHeader[3]."Document Type"::Order, PurchaseHeader[2]."No."),
            PurchaseHeaderMustNotBeFoundErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Batch Job II");
        ClearGlobalVariables();
    end;

    local procedure CalculateAmountUsingRoundingMethod(OldAmount: Decimal): Code[10]
    var
        RoundingMethod: Record "Rounding Method";
    begin
        RoundingMethod.FindFirst();
        Amount := Round(OldAmount, RoundingMethod.Precision, InvoiceRoundingDirection(RoundingMethod.Type));  // Update the Amount as per Rounding Method and Assign it to global variable.
        exit(RoundingMethod.Code);
    end;

    local procedure ClearGlobalVariables()
    begin
        Amount := 0;
        Clear(GLAccountNo);
        Clear(BudgetName);
    end;

    local procedure CopyGLBudgetFromDifferentSources(FromSource: Option; FromGLBudgetName: Code[10]; AdjustmentFactor: Decimal; RoundingMethodCode: Code[10])
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Create GL Budget to copy an existing GL Budget.
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        BudgetName := GLBudgetName.Name;  // Assign GL Budget Name to global variable.

        // Exercise.
        RunCopyGLBudget(FromSource, FromGLBudgetName, GLAccountNo, Format(WorkDate()), BudgetName, AdjustmentFactor, RoundingMethodCode);

        // Verify: Verify Amount on GL Budget Page.
        OpenGLBudgetPage();

        // Tear Down: Delete earlier created GL Budget.
        GLBudgetName.Get(BudgetName);
        GLBudgetName.Delete(true);
    end;

    local procedure CreateAndPostGenJournalLine(AccountNo: Code[20]; LineAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", AccountNo, LineAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGLBudgetEntry(GLBudgetName: Code[10]; AccountNo: Code[20]; Amount2: Decimal)
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, WorkDate(), AccountNo, GLBudgetName);
        GLBudgetEntry.Validate(Amount, Amount2);  // Taking Variable name Amount2 due to global variable.
        GLBudgetEntry.Modify(true);
    end;

    local procedure InvoiceRoundingDirection(Type: Option Nearest,Up,Down): Text[1]
    begin
        // Taken the formula to return Rounding Type from Currency Table .
        case Type of
            Type::Nearest:
                exit('=');
            Type::Up:
                exit('>');
            Type::Down:
                exit('<');
        end;
    end;

    procedure SetTargetJobStatus(NewStatus: Enum "Job Status")
    begin
        TargetJobStatus := NewStatus;
    end;

    local procedure OpenGLBudgetPage()
    var
        GLBudgetNamesPage: TestPage "G/L Budget Names";
    begin
        GLBudgetNamesPage.OpenEdit();
        GLBudgetNamesPage.FILTER.SetFilter(Name, BudgetName);
        GLBudgetNamesPage.EditBudget.Invoke();
    end;

    local procedure RunCopyGLBudget(FromSource: Option; FromGLBudgetName: Code[10]; FromGLAccount: Code[20]; DateInterval: Text[30]; ToGlBudgetName: Code[10]; AdjustmentFactor: Decimal; RoundingMethodCode: Code[10])
    var
        SelectedDim: Record "Selected Dimension";
        CopyGLBudget: Report "Copy G/L Budget";
        ToDateCompression: Option "None",Day,Week,Month,Quarter,Year,Period;
        FromClosingEntryFilter: Option Include,Exclude;
        DateChangeFormula: DateFormula;
    begin
        Clear(CopyGLBudget);
        SelectedDim.DeleteAll();
        Evaluate(DateChangeFormula, '');  // Evaluating blank value in Date Formula variable.
        CopyGLBudget.InitializeRequest(
          FromSource, FromGLBudgetName, FromGLAccount, DateInterval, FromClosingEntryFilter::Include, '', ToGlBudgetName, '', AdjustmentFactor,
          RoundingMethodCode, DateChangeFormula, ToDateCompression::None);
        CopyGLBudget.UseRequestPage(false);
        CopyGLBudget.Run();
    end;

    local procedure CreatePurchaseLineWithJobPlanningLineNo(
        var PurchaseHeader: Record "Purchase Header";
        var PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Location: Record Location;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line")
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(0));
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Job Line Type", PurchaseLine."Job Line Type"::Budget);
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        PurchaseLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CompareJobLedgerEntryNos(Job: Record Job; JobTask: Record "Job Task")
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        JobPlanningLineInvoice2: Record "Job Planning Line Invoice";
    begin
        JobPlanningLineInvoice.SetRange("Job No.", Job."No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", JobTask."Job Task No.");
        Assert.RecordCount(JobPlanningLineInvoice, 3);
        JobPlanningLineInvoice2.CopyFilters(JobPlanningLineInvoice);
        JobPlanningLineInvoice.FindSet();
        repeat
            JobPlanningLineInvoice.TestField("Job Ledger Entry No.");
            JobPlanningLineInvoice2.SetRange("Job Ledger Entry No.", JobPlanningLineInvoice."Job Ledger Entry No.");
            Assert.RecordCount(JobPlanningLineInvoice2, 1);
        until JobPlanningLineInvoice.Next() = 0;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BudgetPageHandler(var Budget: TestPage Budget)
    begin
        Budget.PeriodType.SetValue('Day');
        Budget.DateFilter.SetValue(WorkDate());
        Budget.IncomeBalGLAccFilter.SetValue(0);
        Budget.GLAccCategory.SetValue(0);
        Budget.GLAccFilter.SetValue(GLAccountNo);
        Budget.MatrixForm.TotalBudgetedAmount.AssertEquals(Amount);
        Budget.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // For handle message
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure NoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateInvoiceRequestHandler(var JobTransfertoSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransfertoSalesInvoice.CreateNewInvoice.SetValue(false);
        JobTransfertoSalesInvoice.AppendToSalesInvoiceNo.SetValue(LibraryVariableStorage.DequeueText());
        JobTransfertoSalesInvoice.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopyJobModalPageHandler(var CopyJob: TestPage "Copy Job")
    begin
        CopyJob.TargetJobNo.SetValue(LibraryVariableStorage.DequeueText());
        CopyJob.TargetJobDescription.SetValue(LibraryVariableStorage.DequeueText());
        CopyJob.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CheckMessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Job", 'OnAfterCopyJob', '', false, false)]
    local procedure OnAfterCopyJob(var TargetJob: Record Job; SourceJob: Record Job)
    begin
        TargetJob.Status := TargetJobStatus;
    end;
}

