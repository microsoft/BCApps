codeunit 136316 "Job Jnl. Error Handling"
{
    Subtype = Test;
    TestPermissions = Disabled;
    Permissions = tabledata "Feature Key" = m,
                  tabledata "Feature Data Update Status" = imd;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [UI] [Journal Error Handling]
    end;

    var
        LibraryJob: Codeunit "Library - Job";
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        TestFieldMustHaveValueErr: Label '%1 must have a value', Comment = '%1 - field caption';
        SkipCheckText: Label 'SkipCheckCustomerAssosEntriesExist';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure JobJournalSunshine()
    var
        JobJournalLine: Record "Job Journal Line";
        JobJournal: TestPage "Job Journal";
    begin
        // [FEATURE] [Job Journal]
        // [SCENARIO 411162] Journal errors factbox works for Job journal
        Initialize();

        // [GIVEN] Create journal line with empty "Quantity"
        CreateJobJournalLineWithEmptyQuantity(JobJournalLine);

        // [WHEN] Open Job Journal for batch "XXX"
        Commit();
        JobJournal.Trap();
        Page.Run(Page::"Job Journal", JobJournalLine);

        // [THEN] Journal Errors factbox shows message "Quantity must have a value."
        VerifyErrorMessageText(
            JobJournal.JournalErrorsFactBox.Error1.Value,
            StrSubstNo(TestFieldMustHaveValueErr, JobJournalLine.FieldCaption("Quantity")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJournalNumberOfBatchErrors()
    var
        JobJournalLine: Record "Job Journal Line";
        JobJournalBatch: Record "Job Journal Batch";
        JobJournal: TestPage "Job Journal";
        i: Integer;
        NumbefOfLines: Integer;
    begin
        // [FEATURE] [Job Journal]
        // [SCENARIO 411162] Journal errors factbox shows the number of batch errors
        Initialize();

        // [GIVEN] Create 5 journal lines with empty "Quantity"
        CreateJobJournalBatch(JobJournalBatch);
        NumbefOfLines := LibraryRandom.RandIntInRange(5, 10);
        for i := 1 to NumbefOfLines do
            CreateJobJournalLineWithEmptyQuantity(JobJournalLine, JobJournalBatch);

        // [WHEN] Open Job Journal for batch "XXX".
        Commit();
        JobJournal.Trap();
        Page.Run(Page::"Job Journal", JobJournalLine);

        // [THEN] Journal Errors factbox shows Lines with Issues = 5
        JobJournal.JournalErrorsFactBox.NumberOfBatchErrors.AssertEquals(NumbefOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteJnlLineWithErrors()
    var
        JobJournalLine: array[2] of Record "Job Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        JobJournalBatch: Record "Job Journal Batch";
        ErrorHandlingParameters: Record "Error Handling Parameters";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        JobJournalErrorsMgt: Codeunit "Job Journal Errors Mgt.";
        Args: Dictionary of [Text, Text];
    begin
        // [FEATURE] [Job Journal]
        // [SCENARIO 411162] Errors for deleted journal lines removed from error messages
        Initialize();

        // [GIVEN] journal lines with empty "Quantity" ress: Line1 and Line2
        CreateJobJournalBatch(JobJournalBatch);
        CreateJobJournalLineWithEmptyQuantity(JobJournalLine[1], JobJournalBatch);

        CreateJobJournalLineWithEmptyQuantity(JobJournalLine[2], JobJournalBatch);

        // [GIVEN] Mock 2 error messages for Line1 and Line2
        MockFullBatchCheck(
            JobJournalLine[1]."Journal Template Name",
            JobJournalLine[1]."Journal Batch Name",
            TempErrorMessage);

        // [GIVEN] Mock Line2 deleted
        JobJournalErrorsMgt.InsertDeletedJobJnlLine(JobJournalLine[2]);
        JobJournalLine[2].Delete();

        // [WHEN] Run CleanTempErrorMessages 
        BackgroundErrorHandlingMgt.PackDeletedDocumentsToArgs(Args); // Mock call from "Journal Errors Factbox".CheckErrorsInBackground
        SetErrorHandlingParameters(ErrorHandlingParameters, JobJournalLine[1], 0);
        BackgroundErrorHandlingMgt.CleanJobJnlTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);

        // [THEN] Error message about Line2 deleted
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange("Context Record ID", JobJournalLine[2].RecordId);
        Assert.IsTrue(TempErrorMessage.IsEmpty, 'Error message for line 2 has to be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJournalShowAllLinesActionsEnabledState()
    var
        JobJournalLine: Record "Job Journal Line";
        JobJournal: TestPage "Job Journal";
        LinesWithIssuesCounter: Integer;
    begin
        // [SCENARIO 411162] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateJobJournalLineWithEmptyQuantity(JobJournalLine);

        // [GIVEN] Open Job Journal for batch "XXX"
        Commit();
        JobJournal.Trap();
        Page.Run(Page::"Job Journal", JobJournalLine);
        // [WHEN] Action "Show Lines with Errors" is selected
        JobJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Check that there is one line shown in the journal
        if JobJournal.First() then
            repeat
                LinesWithIssuesCounter += 1;
            until not JobJournal.Next();
        Assert.AreEqual(1, LinesWithIssuesCounter - 1, 'There must be exactly one line shown in the journal');

        // [WHEN] Action "Show All Lines" is being selected
        JobJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        Assert.IsTrue(JobJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        Assert.IsFalse(JobJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJournalCheckUpdatedLineWithError()
    var
        JobJournalLine: array[2] of Record "Job Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        JobJournalBatch: Record "Job Journal Batch";
        ErrorHandlingParameters: Record "Error Handling Parameters";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        JobJournalErrorsMgt: Codeunit "Job Journal Errors Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 411162] Updated line checked after moving focus to another line and fixed error deleted
        Initialize();

        // [GIVEN] journal lines with empty "Quantity": Line1 and Line2
        CreateJobJournalBatch(JobJournalBatch);
        CreateJobJournalLineWithEmptyQuantity(JobJournalLine[1], JobJournalBatch);

        CreateJobJournalLineWithEmptyQuantity(JobJournalLine[2], JobJournalBatch);

        // [GIVEN] Mock 2 error messages for Line1 and Line2
        MockFullBatchCheck(
            JobJournalLine[1]."Journal Template Name",
            JobJournalLine[1]."Journal Batch Name",
            TempErrorMessage);
        TempErrorMessage.Reset();
        Assert.AreEqual(2, TempErrorMessage.Count, 'Invalid number of error messages');

        // [GIVEN] Set Quantity = 'XXX' for Line 2 and mock it is modified
        JobJournalLine[2]."Quantity" := JobJournalLine[1]."Quantity";
        JobJournalLine[2].Modify();
        JobJournalErrorsMgt.SetJobJnlLineOnModify(JobJournalLine[2]);

        // [WHEN] Run CleanTempErrorMessages
        SetErrorHandlingParameters(ErrorHandlingParameters, JobJournalLine[1], JobJournalLine[2]."Line No.");
        BackgroundErrorHandlingMgt.CleanJobJnlTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);

        // [THEN] Error message about Line2 deleted
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange("Context Record ID", JobJournalLine[2].RecordId);
        Assert.IsTrue(TempErrorMessage.IsEmpty, 'Error message for line 2 has to be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJournalCheckUpdatedLineNewError()
    var
        JobJournalLine: array[2] of Record "Job Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        JobJournalBatch: Record "Job Journal Batch";
        ErrorHandlingParameters: Record "Error Handling Parameters";
        JobJournalErrorsMgt: Codeunit "Job Journal Errors Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 411162] Updated line checked after moving focus to another line and new error found
        Initialize();

        // [GIVEN] journal lines with not empty Quantity: Line1 and Line2
        CreateJobJournalBatch(JobJournalBatch);
        CreateJobJournalLine(JobJournalLine[1], JobJournalBatch);
        CreateJobJournalLine(JobJournalLine[2], JobJournalBatch);

        // [GIVEN] Set Quantity = 0 for Line 2 and mock it is modified
        JobJournalLine[2].Validate(Quantity, 0);
        JobJournalLine[2].Modify();
        JobJournalErrorsMgt.SetJobJnlLineOnModify(JobJournalLine[2]);

        // [WHEN] Run background check
        SetErrorHandlingParameters(ErrorHandlingParameters, JobJournalLine[1], JobJournalLine[2]."Line No.");
        RunBackgroundCheck(ErrorHandlingParameters, TempErrorMessage);

        // [THEN] Empty Quantity error message about Line2 created
        TempErrorMessage.Reset();
        TempErrorMessage.FindFirst();

        VerifyErrorMessageText(
            TempErrorMessage."Message",
            StrSubstNo(TestFieldMustHaveValueErr, JobJournalLine[2].FieldCaption("Quantity")));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CustomerNoCanBeChangedWhenSkippingAssosEntriesValidation()
    var
        Job: Record Job;
        JobCard: TestPage "Job Card";
        JobJnlErrorHandling: codeunit "Job Jnl. Error Handling";
        NewCustomerNo: Code[20];
    begin
        // [BUG 457148] Changing Customer No. on Job Card throws error
        Initialize();

        // [GIVEN] We open the Job Card of a Job in progress with Planning Lines and Tasks
        // Set the Job description to SkipCheckText as a flag for the EventSubscriber (LibraryVariableStorage doesn't work with EventSubscribers)
        CreateElaborateJob(Job, SkipCheckText);
        JobCard.OpenEdit();
        JobCard.Filter.SetFilter("No.", Job."No.");

        // [GIVEN] We skip checking for Associated Job Ledger Entries and Job Planning Lines when changing the Customer No.
        BindSubscription(JobJnlErrorHandling);

        // [WHEN] We try to change the Customer No.
        NewCustomerNo := LibrarySales.CreateCustomerNo();
        JobCard."Sell-to Customer No.".SetValue(NewCustomerNo);

        // [THEN] No error occurs because the validation was skipped
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Job Jnl. Error Handling");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        SetEnableDataCheck(true);
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Job Jnl. Error Handling");
        Commit();
        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Job Jnl. Error Handling");
    end;

    local procedure CreateElaborateJob(var Job: Record Job; Description: Text)
    var
        JobTaskA: Record "Job Task";
        JobTaskB: Record "Job Task";
        JobPlanningLineA: Record "Job Planning Line";
        JobPlanningLineB: Record "Job Planning Line";
        JobDefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        JobJournalLine: Record "Job Journal Line";
    begin
        LibraryJob.CreateJob(Job);

        Job.Description := Description;
        Job.Modify();

        // Create Default Dimension
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimension(
          JobDefaultDimension, DATABASE::Job, Job."No.", DimensionValue."Dimension Code", DimensionValue.Code);

        // Create Job Task
        LibraryJob.CreateJobTask(Job, JobTaskA);
        LibraryJob.CreateJobTask(Job, JobTaskB);

        // Create Planning Line
        LibraryJob.CreateJobPlanningLine("Job Planning Line Line Type"::Budget, "Job Planning Line Type"::Item, JobTaskA, JobPlanningLineA);
        LibraryJob.CreateJobPlanningLine("Job Planning Line Line Type"::Budget, "Job Planning Line Type"::Item, JobTaskB, JobPlanningLineB);

        // Post a Job Journal Line
        JobJournalLine.Init();
        LibraryJob.CreateJobJournalLineForType("Job Line Type"::Budget, "Job Planning Line Type"::Item, JobTaskA, JobJournalLine);
        JobJournalLine.Validate(Quantity, 1);
        JobJournalLine.Validate("Unit Cost", 1);
        JobJournalLine.Modify();
        LibraryJob.PostJobJournal(JobJournalLine);

        // Post another Job Journal Line 
        JobJournalLine.Init();
        LibraryJob.CreateJobJournalLineForType("Job Line Type"::Budget, "Job Planning Line Type"::Item, JobTaskB, JobJournalLine);
        JobJournalLine.Validate(Quantity, 1);
        JobJournalLine.Validate("Unit Cost", 100000);
        JobJournalLine.Modify();
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure SetEnableDataCheck(Enabled: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Enable Data Check", Enabled);
        GLSetup.Modify();
    end;

    local procedure CreateJobJournalLine(var JobJournalLine: Record "Job Journal Line"; JobJournalBatch: Record "Job Journal Batch")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        NoSeries: Codeunit "No. Series";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        JobJournalLine.SetRange("Journal Template Name", JobJournalBatch."Journal Template Name");
        JobJournalLine.SetRange("Journal Batch Name", JobJournalBatch.Name);
        if JobJournalLine.FindLast() then;
        JobJournalLine.Init();
        JobJournalLine.Validate("Journal Template Name", JobJournalBatch."Journal Template Name");
        JobJournalLine.Validate("Journal Batch Name", JobJournalBatch.Name);
        JobJournalLine.Validate("Line No.", JobJournalLine."Line No." + 10000);

        JobJournalLine.Validate("Posting Date", WorkDate());
        JobJournalLine.Validate("Job No.", JobTask."Job No.");
        JobJournalLine.Validate("Job Task No.", JobTask."Job Task No.");
        JobJournalLine.Validate("Document No.", NoSeries.PeekNextNo(JobJournalBatch."No. Series", JobJournalLine."Posting Date"));

        JobJournalLine.Validate("Line Type", "Job Planning Line Type"::Resource);
        JobJournalLine.Validate("No.", LibraryResource.CreateResourceNo());
        JobJournalLine.Validate(Quantity, LibraryRandom.RandIntInRange(1, 5));
        JobJournalLine.Validate("Unit Price (LCY)", LibraryRandom.RandDec(100, 2));
        JobJournalLine.Insert(true);
    end;

    local procedure CreateJobJournalLineWithEmptyQuantity(var JobJournalLine: Record "Job Journal Line"; JobJournalBatch: Record "Job Journal Batch")
    begin
        CreateJobJournalLine(JobJournalLine, JobJournalBatch);
        JobJournalLine.Validate("Quantity", 0);
        JobJournalLine.Modify();
    end;

    local procedure CreateJobJournalLineWithEmptyQuantity(var JobJournalLine: Record "Job Journal Line")
    var
        JobJournalBatch: Record "Job Journal Batch";
    begin
        CreateJobJournalBatch(JobJournalBatch);
        CreateJobJournalLineWithEmptyQuantity(JobJournalLine, JobJournalBatch);
    end;

    local procedure CreateJobJournalBatch(var JobJournalBatch: Record "Job Journal Batch")
    var
        JobJournalTemplate: Record "Job Journal Template";
    begin
        JobJournalTemplate.SetRange("Page ID", PAGE::"Job Journal");
        JobJournalTemplate.SetRange(Recurring, false);
        JobJournalTemplate.FindFirst();
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);
        ClearJobJournalLines(JobJournalBatch);
    end;

    local procedure ClearJobJournalLines(var JobJournalBatch: Record "Job Journal Batch")
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        JobJournalLine.SetRange("Journal Template Name", JobJournalBatch."Journal Template Name");
        JobJournalLine.SetRange("Journal Batch Name", JobJournalBatch.Name);
        JobJournalLine.DeleteAll(true);
    end;

    local procedure ClearTempErrorMessage(var TempErrorMessage: Record "Error Message" temporary)
    begin
        TempErrorMessage.Reset();
        TempErrorMessage.DeleteAll();
    end;

    local procedure MockFullBatchCheck(TemplateName: Code[10]; BatchName: Code[10]; var TempErrorMessage: Record "Error Message" temporary)
    var
        ErrorHandlingParameters: Record "Error Handling Parameters";
    begin
        ClearTempErrorMessage(TempErrorMessage);

        SetErrorHandlingParameters(ErrorHandlingParameters, TemplateName, BatchName, true);
        RunBackgroundCheck(ErrorHandlingParameters, TempErrorMessage);
    end;

    local procedure RunBackgroundCheck(ErrorHandlingParameters: Record "Error Handling Parameters"; var TempErrorMessage: Record "Error Message" temporary)
    var
        Params: Dictionary of [Text, Text];
        CheckJobJnlLineBackgr: Codeunit "Check Job Jnl. Line. Backgr.";
    begin
        ErrorHandlingParameters.ToArgs(Params);
        Commit();
        CheckJobJnlLineBackgr.RunCheck(Params, TempErrorMessage);
    end;

    local procedure SetErrorHandlingParameters(var ErrorHandlingParameters: Record "Error Handling Parameters"; TemplateName: Code[10]; BatchName: Code[10]; FullBatchCheck: Boolean)
    begin
        ErrorHandlingParameters.Init();
        ErrorHandlingParameters."Journal Template Name" := TemplateName;
        ErrorHandlingParameters."Journal Batch Name" := BatchName;
        ErrorHandlingParameters."Full Batch Check" := FullBatchCheck;
    end;

    local procedure SetErrorHandlingParameters(var ErrorHandlingParameters: Record "Error Handling Parameters"; JobJournalLine: Record "Job Journal Line"; PreviosLineNo: Integer)
    begin
        ErrorHandlingParameters.Init();
        ErrorHandlingParameters."Journal Template Name" := JobJournalLine."Journal Template Name";
        ErrorHandlingParameters."Journal Batch Name" := JobJournalLine."Journal Batch Name";
        ErrorHandlingParameters."Line No." := JobJournalLine."Line No.";
        ErrorHandlingParameters."Previous Line No." := PreviosLineNo;
    end;

    local procedure VerifyErrorMessageText(ActualText: Text; ExpectedText: Text)
    begin
        Assert.IsSubstring(ActualText, ExpectedText);
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

    [EventSubscriber(ObjectType::Table, Database::Job, 'OnBeforeCheckBillToCustomerAssosEntriesExist', '', false, false)]
    procedure OnBeforeCheckBillToCustomerAssosEntriesExist(var Job: Record Job; var xJob: Record Job; var IsHandled: Boolean)
    begin
        if Job.Description = SkipCheckText then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, 'OnBeforeCheckSellToCustomerAssosEntriesExist', '', false, false)]
    procedure OnBeforeCheckSellToCustomerAssosEntriesExist(var Job: Record Job; var xJob: Record Job; var IsHandled: Boolean)
    begin
        if Job.Description = SkipCheckText then
            IsHandled := true;
    end;
}