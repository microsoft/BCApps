codeunit 134979 "Reminder Automation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CreateRemindersSetup: Record "Create Reminders Setup";
        IssueReminderSetup: Record "Issue Reminders Setup";
        SendRemindersSetup: Record "Send Reminders Setup";
        ReminderActionGroup: Record "Reminder Action Group";
    begin
        LibraryVariableStorage.Clear();
        ReminderActionGroup.DeleteAll(true);
        CreateRemindersSetup.DeleteAll(true);
        IssueReminderSetup.DeleteAll(true);
        SendRemindersSetup.DeleteAll(true);

        if IsInitialized then
            exit;

        if not SalesReceivablesSetup.Get() then
            SalesReceivablesSetup.Insert();

        SalesReceivablesSetup."Posting Date Check on Posting" := false;
        SalesReceivablesSetup.Modify();
        Commit();
        IsInitialized := true;
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandler')]
    [Test]
    procedure TestSetupCreateReminder()
    var
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        ReminderActionCode: Code[50];
    begin
        // [GIVEN] System with no reminders
        Initialize();

        // [WHEN] User creates a reminder automation group with a create action        
        ReminderActionCode := CreateReminderAutomationWithCreateAction(ReminderAutomationCard);

        // [THEN] The UI is updated correctly
        ReminderAutomationCard.ReminderActionsPart.First();
        Assert.AreEqual(Format(Enum::"Reminder Action"::"Create Reminder"), ReminderAutomationCard.ReminderActionsPart.ActionType.Value(), 'Wrong reminder action type created');
        Assert.AreEqual(ReminderActionCode, ReminderAutomationCard.ReminderActionsPart.Code.Value(), 'Wrong code was set');

        // [THEN] The reminder automation group is created with correct tables
        VerifySetupRecordForCreateAction(ReminderAutomationCard.Code.Value());
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandler')]
    [Test]
    procedure TestDeleteCreateReminderSetup()
    var
        ReminderAction: Record "Reminder Action";
        CreateRemindersSetup: Record "Create Reminders Setup";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
    begin
        Initialize();

        // [GIVEN] A reminder automation group with a create action        
        CreateReminderAutomationWithCreateAction(ReminderAutomationCard);
        VerifySetupRecordForCreateAction(ReminderAutomationCard.Code.Value());

        // [WHEN] User deletes the reminder automation group
        ReminderAutomationCard.ReminderActionsPart.First();
        ReminderAutomationCard.ReminderActionsPart.Delete.Invoke();

        // [THEN] The reminder action is deleted
        ReminderAction.SetRange("Reminder Action Group Code", ReminderAutomationCard.Code.Value());
        Assert.IsTrue(ReminderAction.IsEmpty(), 'The reminder action was not deleted');
        Assert.IsTrue(CreateRemindersSetup.IsEmpty(), 'The setup record was not deleted');
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandler,SelectRemTermsAutomationHandler')]
    [Test]
    procedure TestCreateReminderAutomationCreatesEntries()
    var
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        ReminderActionGroup: Record "Reminder Action Group";
        JobQueueEntry: Record "Job Queue Entry";
        ReminderAutomationJob: Codeunit "Reminders Automation Job";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        NumberOfOverdueEntries: Integer;
        ExpectedReminderLevel: Integer;
    begin
        Initialize();

        // [GIVEN] A customer with overdue entries
        CreateReminderTermsWithLevels(ReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        NumberOfOverdueEntries := Any.IntegerInRange(2, 5);
        CreateCustomerWithOverdueEntries(Customer, ReminderTerms, NumberOfOverdueEntries);

        // [GIVEN] A reminder automation group with a create action        
        CreateReminderAutomationWithCreateAction(ReminderAutomationCard, ReminderTerms);
        ReminderActionGroup.Get(ReminderAutomationCard.Code.Value());

        // [WHEN] User runs the reminder automation
        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);
        ReminderAutomationJob.Run(JobQueueEntry);

        // [THEN] The reminder automation creates draft reminders
        VerifyJobWasSuccesfull(ReminderActionGroup);
        ExpectedReminderLevel := 0;
        VerifyDraftRemindersCreatedForCustomer(Customer, ExpectedReminderLevel, NumberOfOverdueEntries);
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandler,SelectRemTermsAutomationHandler')]
    [Test]
    procedure TestCreateReminderAutomationDoesNotCreateEntries()
    var
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        ReminderActionGroup: Record "Reminder Action Group";
        JobQueueEntry: Record "Job Queue Entry";
        ReminderHeader: Record "Reminder Header";
        ReminderAutomationJob: Codeunit "Reminders Automation Job";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        NumberOfOverdueEntries: Integer;
    begin
        Initialize();

        // [GIVEN] A customer with all entries paid
        NumberOfOverdueEntries := Any.IntegerInRange(2, 5);
        CreateReminderTermsWithLevels(ReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        CreateCustomerWithPaidOverdueEntries(Customer, ReminderTerms, NumberOfOverdueEntries);

        // [GIVEN] A reminder automation group with a create action        
        CreateReminderAutomationWithCreateAction(ReminderAutomationCard, ReminderTerms);
        ReminderActionGroup.Get(ReminderAutomationCard.Code.Value());

        // [WHEN] User runs the reminder automation
        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);
        ReminderAutomationJob.Run(JobQueueEntry);

        // [THEN] The reminder automation will not create any entries
        VerifyJobWasSuccesfull(ReminderActionGroup);
        ReminderHeader.SetRange("Customer No.", Customer."No.");
        Assert.IsTrue(ReminderHeader.IsEmpty(), 'The reminder automation created reminders for a customer with no overdue entries');
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandler,SelectRemTermsAutomationHandler')]
    [Test]
    procedure TestCreateReminderAutomationExcludesEntriesFromOtherPaymentTerms()
    var
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        CustomerReminderTerms: Record "Reminder Terms";
        ReminderActionGroup: Record "Reminder Action Group";
        JobQueueEntry: Record "Job Queue Entry";
        ReminderHeader: Record "Reminder Header";
        ReminderAutomationJob: Codeunit "Reminders Automation Job";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        NumberOfOverdueEntries: Integer;
    begin
        Initialize();

        // [GIVEN] A customer with overdue entries
        NumberOfOverdueEntries := Any.IntegerInRange(2, 5);
        CreateReminderTermsWithLevels(CustomerReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        CreateCustomerWithOverdueEntries(Customer, CustomerReminderTerms, NumberOfOverdueEntries);

        // [GIVEN] A reminder automation group with a create action that does not apply to the customer
        CreateReminderTermsWithLevels(ReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        CreateReminderAutomationWithCreateAction(ReminderAutomationCard, ReminderTerms);
        ReminderActionGroup.Get(ReminderAutomationCard.Code.Value());

        // [WHEN] User runs the reminder automation
        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);
        ReminderAutomationJob.Run(JobQueueEntry);

        // [THEN] The reminder automation will not create any entries
        VerifyJobWasSuccesfull(ReminderActionGroup);
        ReminderHeader.SetRange("Customer No.", Customer."No.");
        Assert.IsTrue(ReminderHeader.IsEmpty(), 'The reminder automation created reminders for a customer with no overdue entries');
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandler,SelectRemTermsAutomationHandler')]
    [Test]
    procedure TestCreateReminderAutomationRunTwice()
    var
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        ReminderActionGroup: Record "Reminder Action Group";
        JobQueueEntry: Record "Job Queue Entry";
        ReminderAutomationJob: Codeunit "Reminders Automation Job";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        NumberOfOverdueEntries: Integer;
        ExpectedReminderLevel: Integer;
        LastLogID: Integer;
    begin
        Initialize();

        // [GIVEN] A customer with overdue entries
        CreateReminderTermsWithLevels(ReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        NumberOfOverdueEntries := Any.IntegerInRange(2, 5);
        CreateCustomerWithOverdueEntries(Customer, ReminderTerms, NumberOfOverdueEntries);

        // [GIVEN] A reminder automation group with a create action        
        CreateReminderAutomationWithCreateAction(ReminderAutomationCard, ReminderTerms);
        ReminderActionGroup.Get(ReminderAutomationCard.Code.Value());

        // [GIVEN] User runs the reminder automation
        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);
        ReminderAutomationJob.Run(JobQueueEntry);

        // [THEN] The reminder automation creates draft reminders
        LastLogID := VerifyJobWasSuccesfull(ReminderActionGroup);
        ExpectedReminderLevel := 0;
        VerifyDraftRemindersCreatedForCustomer(Customer, ExpectedReminderLevel, NumberOfOverdueEntries);

        // [WHEN] User runs the reminder automation again
        if JobQueueEntry.Find() then
            JobQueueEntry.Delete();

        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);
        ReminderAutomationJob.Run(JobQueueEntry);

        // [THEN] The reminder automation updates the draft reminders
        VerifyJobWasSuccesfull(ReminderActionGroup, LastLogID);
        VerifyDraftRemindersCreatedForCustomer(Customer, ExpectedReminderLevel, NumberOfOverdueEntries);
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandler,SelectRemTermsAutomationHandler')]
    [Test]
    procedure TestCreateReminderAutomationCreatesEntriesForMultipleCustomers()
    var
        FirstCustomer: Record Customer;
        SecondCustomer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        ReminderActionGroup: Record "Reminder Action Group";
        JobQueueEntry: Record "Job Queue Entry";
        ReminderAutomationJob: Codeunit "Reminders Automation Job";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        NumberOfOverdueEntries: Integer;
        ExpectedReminderLevel: Integer;
    begin
        Initialize();

        // [GIVEN] A customer with overdue entries
        CreateReminderTermsWithLevels(ReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        NumberOfOverdueEntries := Any.IntegerInRange(2, 5);
        CreateCustomerWithOverdueEntries(FirstCustomer, ReminderTerms, NumberOfOverdueEntries);
        CreateCustomerWithOverdueEntries(SecondCustomer, ReminderTerms, NumberOfOverdueEntries);

        // [GIVEN] A reminder automation group with a create action        
        CreateReminderAutomationWithCreateAction(ReminderAutomationCard, ReminderTerms);
        ReminderActionGroup.Get(ReminderAutomationCard.Code.Value());

        // [WHEN] User runs the reminder automation
        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);
        ReminderAutomationJob.Run(JobQueueEntry);

        // [THEN] The reminder automation creates draft reminders
        VerifyJobWasSuccesfull(ReminderActionGroup);
        ExpectedReminderLevel := 0;
        VerifyDraftRemindersCreatedForCustomer(FirstCustomer, ExpectedReminderLevel, NumberOfOverdueEntries);
        VerifyDraftRemindersCreatedForCustomer(SecondCustomer, ExpectedReminderLevel, NumberOfOverdueEntries);
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandler,SelectRemTermsAutomationHandler')]
    [Test]
    procedure TestCreateRemindersAutomationIsAbleToCreateMissingRemindersAfterBeingStoppedByError()
    var
        FirstCustomer: Record Customer;
        SecondCustomer: Record Customer;
        ReminderHeader: Record "Reminder Header";
        ReminderTerms: Record "Reminder Terms";
        ReminderActionGroup: Record "Reminder Action Group";
        JobQueueEntry: Record "Job Queue Entry";
        ReminderAutomationJob: Codeunit "Reminders Automation Job";
        ReminderAutomationMock: Codeunit "Reminder Automation Mock";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        NumberOfOverdueEntries: Integer;
        ExpectedReminderLevel: Integer;
    begin
        Initialize();

        // [GIVEN] A customer with overdue entries
        CreateReminderTermsWithLevels(ReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        NumberOfOverdueEntries := Any.IntegerInRange(2, 5);
        CreateCustomerWithOverdueEntries(FirstCustomer, ReminderTerms, NumberOfOverdueEntries);
        CreateCustomerWithOverdueEntries(SecondCustomer, ReminderTerms, NumberOfOverdueEntries);

        // [GIVEN] A reminder automation group with a create action        
        CreateReminderAutomationWithCreateAction(ReminderAutomationCard, ReminderTerms);
        ReminderActionGroup.Get(ReminderAutomationCard.Code.Value());

        // [WHEN] An error is thrown after creating the reminders is done for first customer
        ReminderAutomationMock.SetBlockCreateAutomation(true);
        ReminderAutomationMock.SetErrorForLastRecordUpdated(FirstCustomer.RecordId);
        BindSubscription(ReminderAutomationMock);
        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);

        // Test cannot use the isolated events because it runs in a single transaction so we must assert error
        Commit();
        asserterror ReminderAutomationJob.Run(JobQueueEntry);
        ClearLastError();
        UnbindSubscription(ReminderAutomationMock);

        // [THEN] The reminder automation creates draft reminders only for the first customer
        ExpectedReminderLevel := 0;
        VerifyDraftRemindersCreatedForCustomer(FirstCustomer, ExpectedReminderLevel, NumberOfOverdueEntries);
        ReminderHeader.SetRange("Customer No.", SecondCustomer."No.");
        Assert.IsTrue(ReminderHeader.IsEmpty(), 'The reminder automation created reminders for the second customer');

        // [WHEN] We run the job again
        ReminderAutomationJob.Run(JobQueueEntry);

        // [THEN] The reminder automation creates draft reminders only for the second customer, first customer reminder is not affected
        VerifyDraftRemindersCreatedForCustomer(FirstCustomer, ExpectedReminderLevel, NumberOfOverdueEntries);
        VerifyDraftRemindersCreatedForCustomer(SecondCustomer, ExpectedReminderLevel, NumberOfOverdueEntries);
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,IssueRemindersSetupModalPageHandler')]
    [Test]
    procedure TestSetupIssueReminder()
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        ReminderActionCode: Code[50];
    begin
        // [GIVEN] System with no reminders
        Initialize();

        // [WHEN] User creates a reminder automation group with a issue action        
        ReminderActionCode := CreateReminderAutomationWithIssueAction(ReminderAutomationCard, ReminderTerms);

        // [THEN] The UI is updated correctly
        ReminderAutomationCard.ReminderActionsPart.First();
        Assert.AreEqual(Format(Enum::"Reminder Action"::"Issue Reminder"), ReminderAutomationCard.ReminderActionsPart.ActionType.Value(), 'Wrong reminder action type created');
        Assert.AreEqual(ReminderActionCode, ReminderAutomationCard.ReminderActionsPart.Code.Value(), 'Wrong code was set');

        // [THEN] The reminder automation group is created with correct tables
        VerifySetupRecordForIssueAction(ReminderAutomationCard.Code.Value());
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,IssueRemindersSetupModalPageHandler')]
    [Test]
    procedure TestDeleteIssueReminderSetup()
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderAction: Record "Reminder Action";
        IssueRemindersSetup: Record "Issue Reminders Setup";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
    begin
        Initialize();

        // [GIVEN] A reminder automation group with a create action        
        CreateReminderAutomationWithIssueAction(ReminderAutomationCard, ReminderTerms);
        VerifySetupRecordForIssueAction(ReminderAutomationCard.Code.Value());

        // [WHEN] User deletes the reminder automation group
        ReminderAutomationCard.ReminderActionsPart.First();
        ReminderAutomationCard.ReminderActionsPart.Delete.Invoke();

        // [THEN] The reminder action is deleted
        ReminderAction.SetRange("Reminder Action Group Code", ReminderAutomationCard.Code.Value());
        Assert.IsTrue(ReminderAction.IsEmpty(), 'The reminder action was not deleted');
        Assert.IsTrue(IssueRemindersSetup.IsEmpty(), 'The setup record was not deleted');
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandler,IssueRemindersSetupModalPageHandler,SelectRemTermsAutomationHandler')]
    [Test]
    procedure TestIssueReminderAutomation()
    var
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        ReminderActionGroup: Record "Reminder Action Group";
        JobQueueEntry: Record "Job Queue Entry";
        ReminderAutomationJob: Codeunit "Reminders Automation Job";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        NumberOfOverdueEntries: Integer;
        ExpectedReminderLevel: Integer;
    begin
        Initialize();

        // [GIVEN] A customer with overdue entries
        CreateReminderTermsWithLevels(ReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        NumberOfOverdueEntries := Any.IntegerInRange(2, 5);
        CreateCustomerWithOverdueEntries(Customer, ReminderTerms, NumberOfOverdueEntries);

        // [GIVEN] A reminder automation group with a create and issue action        
        CreateReminderAutomationGroupViaUI(ReminderAutomationCard, ReminderTerms);
        CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Create Reminder");
        CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Issue Reminder");

        ReminderActionGroup.Get(ReminderAutomationCard.Code.Value());

        // [WHEN] User runs the reminder automation
        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);
        ReminderAutomationJob.Run(JobQueueEntry);

        // [THEN] The reminder automation creates Issued reminders
        VerifyJobWasSuccesfull(ReminderActionGroup);
        ExpectedReminderLevel := 0;
        VerifyIssuedRemindersCreatedForCustomer(Customer, ExpectedReminderLevel, NumberOfOverdueEntries);
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandler,IssueRemindersSetupModalPageHandler,SelectRemTermsAutomationHandler')]
    [Test]
    procedure TestIssueReminderAutomationMultipleCustomers()
    var
        FirstCustomer: Record Customer;
        SecondCustomer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        ReminderActionGroup: Record "Reminder Action Group";
        JobQueueEntry: Record "Job Queue Entry";
        ReminderAutomationJob: Codeunit "Reminders Automation Job";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        NumberOfOverdueEntries: Integer;
        ExpectedReminderLevel: Integer;
    begin
        Initialize();

        // [GIVEN] A customer with overdue entries
        CreateReminderTermsWithLevels(ReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        NumberOfOverdueEntries := Any.IntegerInRange(2, 5);
        CreateCustomerWithOverdueEntries(FirstCustomer, ReminderTerms, NumberOfOverdueEntries);
        CreateCustomerWithOverdueEntries(SecondCustomer, ReminderTerms, NumberOfOverdueEntries);

        // [GIVEN] A reminder automation group with a create and issue action        
        CreateReminderAutomationGroupViaUI(ReminderAutomationCard, ReminderTerms);
        CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Create Reminder");
        CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Issue Reminder");

        ReminderActionGroup.Get(ReminderAutomationCard.Code.Value());

        // [WHEN] User runs the reminder automation
        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);
        ReminderAutomationJob.Run(JobQueueEntry);

        // [THEN] The reminder automation creates Issued reminders
        VerifyJobWasSuccesfull(ReminderActionGroup);
        ExpectedReminderLevel := 0;
        VerifyIssuedRemindersCreatedForCustomer(FirstCustomer, ExpectedReminderLevel, NumberOfOverdueEntries);
        VerifyIssuedRemindersCreatedForCustomer(SecondCustomer, ExpectedReminderLevel, NumberOfOverdueEntries);
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandler,IssueRemindersSetupModalPageHandler,SelectRemTermsAutomationHandler')]
    [Test]
    procedure TestIssueReminderAutomationExcludesEntriesFromOtherPaymentTerms()
    var
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        CustomerReminderTerms: Record "Reminder Terms";
        ReminderActionGroup: Record "Reminder Action Group";
        JobQueueEntry: Record "Job Queue Entry";
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderAutomationJob: Codeunit "Reminders Automation Job";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        NumberOfOverdueEntries: Integer;
    begin
        Initialize();

        // [GIVEN] A customer with overdue entries
        NumberOfOverdueEntries := Any.IntegerInRange(2, 5);
        CreateReminderTermsWithLevels(CustomerReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        CreateCustomerWithOverdueEntries(Customer, CustomerReminderTerms, NumberOfOverdueEntries);

        // [GIVEN] A reminder automation group with a create action that applies to the customer
        CreateReminderTermsWithLevels(ReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        CreateReminderAutomationWithCreateAction(ReminderAutomationCard, CustomerReminderTerms);
        ReminderAutomationCard.Close();

        // [GIVEN] A reminder automation group with an issue action that does not apply to the customer
        CreateReminderAutomationWithIssueAction(ReminderAutomationCard, ReminderTerms);
        ReminderActionGroup.Get(ReminderAutomationCard.Code.Value());

        // [WHEN] User runs the issue reminder automation
        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);
        ReminderAutomationJob.Run(JobQueueEntry);

        // [THEN] The reminder automation will not create any entries
        VerifyJobWasSuccesfull(ReminderActionGroup);
        IssuedReminderHeader.SetRange("Customer No.", Customer."No.");
        Assert.IsTrue(IssuedReminderHeader.IsEmpty(), 'The reminder automation created issued reminders for a customer outside of the reminder terms filter.');
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandler,IssueRemindersSetupModalPageHandler,SelectRemTermsAutomationHandler')]
    [Test]
    procedure TestIssueReminderAutomationRunTwice()
    var
        Customer: Record Customer;
        CustomerReminderTerms: Record "Reminder Terms";
        ReminderActionGroup: Record "Reminder Action Group";
        JobQueueEntry: Record "Job Queue Entry";
        ReminderAutomationJob: Codeunit "Reminders Automation Job";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        NumberOfOverdueEntries: Integer;
    begin
        Initialize();

        // [GIVEN] A customer with overdue entries
        NumberOfOverdueEntries := Any.IntegerInRange(2, 5);
        CreateReminderTermsWithLevels(CustomerReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        CreateCustomerWithOverdueEntries(Customer, CustomerReminderTerms, NumberOfOverdueEntries);

        // [GIVEN] A reminder automation group with a create action that applies to the customer
        CreateReminderAutomationWithCreateAction(ReminderAutomationCard, CustomerReminderTerms);
        CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Issue Reminder");

        // [GIVEN] A reminder automation group with an issue action that applies to the customer
        ReminderActionGroup.Get(ReminderAutomationCard.Code.Value());

        // [GIVEN] User runs the issue reminder automation
        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);
        ReminderAutomationJob.Run(JobQueueEntry);

        // [THEN] The reminder automation creates issued reminders
        VerifyIssuedRemindersCreatedForCustomer(Customer, 0, NumberOfOverdueEntries);

        // [WHEN] User runs the issue reminder automation again
        if JobQueueEntry.Find() then
            JobQueueEntry.Delete();

        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);
        ReminderAutomationJob.Run(JobQueueEntry);

        // [THEN] The reminder automation will not create any additional entries and issued entries will stay the same
        VerifyIssuedRemindersCreatedForCustomer(Customer, 0, NumberOfOverdueEntries);
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,SendRemindersSetupModalPageHandler')]
    [Test]
    procedure TestSetupEmailReminder()
    var
        DummyReminderTerms: Record "Reminder Terms";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        ReminderActionCode: Code[50];
    begin
        // [GIVEN] System with no reminders
        Initialize();

        // [WHEN] User creates a reminder automation group with a send action        
        CreateReminderAutomationGroupViaUI(ReminderAutomationCard, DummyReminderTerms);
        ReminderActionCode := CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Send Reminder");

        // [THEN] The UI is updated correctly
        ReminderAutomationCard.ReminderActionsPart.First();
        Assert.AreEqual(Format(Enum::"Reminder Action"::"Send Reminder"), ReminderAutomationCard.ReminderActionsPart.ActionType.Value(), 'Wrong reminder action type created');
        Assert.AreEqual(ReminderActionCode, ReminderAutomationCard.ReminderActionsPart.Code.Value(), 'Wrong code was set');

        // [THEN] The reminder automation group is created with correct tables
        VerifySetupRecordForSendAction(ReminderAutomationCard.Code.Value());
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,SendRemindersSetupModalPageHandler')]
    [Test]
    procedure TestDeleteSendReminderSetup()
    var
        DummyReminderTerms: Record "Reminder Terms";
        ReminderAction: Record "Reminder Action";
        SendRemindersSetup: Record "Send Reminders Setup";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
    begin
        Initialize();

        // [GIVEN] A reminder automation group with a Send action        
        CreateReminderAutomationGroupViaUI(ReminderAutomationCard, DummyReminderTerms);
        CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Send Reminder");
        VerifySetupRecordForSendAction(ReminderAutomationCard.Code.Value());

        // [WHEN] User deletes the reminder automation group
        ReminderAutomationCard.ReminderActionsPart.First();
        ReminderAutomationCard.ReminderActionsPart.Delete.Invoke();

        // [THEN] The reminder action is deleted
        ReminderAction.SetRange("Reminder Action Group Code", ReminderAutomationCard.Code.Value());
        Assert.IsTrue(ReminderAction.IsEmpty(), 'The reminder action was not deleted');
        Assert.IsTrue(SendRemindersSetup.IsEmpty(), 'The setup record was not deleted');
    end;


    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandler,IssueRemindersSetupModalPageHandler,SendRemindersSetupModalPageHandler,SelectRemTermsAutomationHandler')]
    [Test]
    procedure TestSendReminderAutomation()
    var
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        ReminderActionGroup: Record "Reminder Action Group";
        JobQueueEntry: Record "Job Queue Entry";
        SendEmailMock: Codeunit "Send Email Mock";
        ReminderAutomationJob: Codeunit "Reminders Automation Job";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        NumberOfOverdueEntries: Integer;
        NumberOfSentEmails: Integer;
    begin
        Initialize();

        // [GIVEN] A customer with overdue entries
        CreateReminderTermsWithLevels(ReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        NumberOfOverdueEntries := Any.IntegerInRange(2, 5);
        CreateCustomerWithOverdueEntries(Customer, ReminderTerms, NumberOfOverdueEntries);

        // [GIVEN] A reminder automation group with a create and issue action        
        CreateReminderAutomationGroupViaUI(ReminderAutomationCard, ReminderTerms);
        CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Create Reminder");
        CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Issue Reminder");
        CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Send Reminder");

        ReminderActionGroup.Get(ReminderAutomationCard.Code.Value());

        // [WHEN] User runs the reminder automation
        BindSubscription(SendEmailMock);
        SendEmailMock.AddSupportedScenario(Enum::"Email Scenario"::Reminder);
        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);
        ReminderAutomationJob.Run(JobQueueEntry);
        UnbindSubscription(SendEmailMock);

        // [THEN] The reminder automation sends the issued reminders
        VerifyJobWasSuccesfull(ReminderActionGroup);
        NumberOfSentEmails := 1;
        VerifyRemindersSentForCustomer(Customer, NumberOfSentEmails, SendEmailMock);
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandler,IssueRemindersSetupModalPageHandler,SendRemindersSetupModalPageHandler,SelectRemTermsAutomationHandler')]
    [Test]
    procedure TestSendReminderAutomationMultipleCustomers()
    var
        FirstCustomer: Record Customer;
        SecondCustomer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        ReminderActionGroup: Record "Reminder Action Group";
        JobQueueEntry: Record "Job Queue Entry";
        SendEmailMock: Codeunit "Send Email Mock";
        ReminderAutomationJob: Codeunit "Reminders Automation Job";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        NumberOfOverdueEntries: Integer;
        TotalNumberOfSentEmails: Integer;
    begin
        Initialize();

        // [GIVEN] A customer with overdue entries
        CreateReminderTermsWithLevels(ReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        NumberOfOverdueEntries := Any.IntegerInRange(2, 5);
        CreateCustomerWithOverdueEntries(FirstCustomer, ReminderTerms, NumberOfOverdueEntries);
        CreateCustomerWithOverdueEntries(SecondCustomer, ReminderTerms, NumberOfOverdueEntries);

        // [GIVEN] A reminder automation group with a create and issue action        
        CreateReminderAutomationGroupViaUI(ReminderAutomationCard, ReminderTerms);
        CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Create Reminder");
        CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Issue Reminder");
        CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Send Reminder");

        ReminderActionGroup.Get(ReminderAutomationCard.Code.Value());

        // [WHEN] User runs the reminder automation
        BindSubscription(SendEmailMock);
        SendEmailMock.AddSupportedScenario(Enum::"Email Scenario"::Reminder);
        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);
        ReminderAutomationJob.Run(JobQueueEntry);
        UnbindSubscription(SendEmailMock);

        // [THEN] The reminder automation sends the issued reminders
        VerifyJobWasSuccesfull(ReminderActionGroup);
        TotalNumberOfSentEmails := 2;
        VerifyRemindersSentForCustomer(FirstCustomer, TotalNumberOfSentEmails, SendEmailMock);
        VerifyRemindersSentForCustomer(SecondCustomer, TotalNumberOfSentEmails, SendEmailMock);
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandler,IssueRemindersSetupModalPageHandler,SelectRemTermsAutomationHandler')]
    [Test]
    procedure TestSendReminderAutomationExcludesEntriesFromOtherPaymentTerms()
    var
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        CustomerReminderTerms: Record "Reminder Terms";
        ReminderActionGroup: Record "Reminder Action Group";
        JobQueueEntry: Record "Job Queue Entry";
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderAutomationJob: Codeunit "Reminders Automation Job";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        NumberOfOverdueEntries: Integer;
    begin
        Initialize();

        // [GIVEN] A customer with overdue entries
        NumberOfOverdueEntries := Any.IntegerInRange(2, 5);
        CreateReminderTermsWithLevels(CustomerReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        CreateCustomerWithOverdueEntries(Customer, CustomerReminderTerms, NumberOfOverdueEntries);

        // [GIVEN] A reminder automation group with a create action that applies to the customer
        CreateReminderTermsWithLevels(ReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        CreateReminderAutomationWithCreateAction(ReminderAutomationCard, CustomerReminderTerms);
        ReminderAutomationCard.Close();

        // [GIVEN] A reminder automation group with an issue action that does not apply to the customer
        CreateReminderAutomationWithIssueAction(ReminderAutomationCard, ReminderTerms);
        ReminderActionGroup.Get(ReminderAutomationCard.Code.Value());

        // [WHEN] User runs the issue reminder automation
        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);
        ReminderAutomationJob.Run(JobQueueEntry);

        // [THEN] The reminder automation will not create any entries
        VerifyJobWasSuccesfull(ReminderActionGroup);
        IssuedReminderHeader.SetRange("Customer No.", Customer."No.");
        Assert.IsTrue(IssuedReminderHeader.IsEmpty(), 'The reminder automation created issued reminders for a customer outside of the reminder terms filter.');
    end;

    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandler,IssueRemindersSetupModalPageHandler,SendRemindersSetupModalPageHandler,SelectRemTermsAutomationHandler')]
    [Test]
    procedure TestSendReminderAutomationRunTwice()
    var
        Customer: Record Customer;
        CustomerReminderTerms: Record "Reminder Terms";
        ReminderActionGroup: Record "Reminder Action Group";
        JobQueueEntry: Record "Job Queue Entry";
        TempEmaiiItemSent: Record "Email Item" temporary;
        ReminderAutomationJob: Codeunit "Reminders Automation Job";
        SendEmailMock: Codeunit "Send Email Mock";
        SecondRunSendEmailMock: Codeunit "Send Email Mock";
        ReminderAutomationCard: TestPage "Reminder Automation Card";
        NumberOfOverdueEntries: Integer;
        TotalNumberOfSentEmails: Integer;
    begin
        Initialize();

        // [GIVEN] A customer with overdue entries
        NumberOfOverdueEntries := Any.IntegerInRange(2, 5);
        CreateReminderTermsWithLevels(CustomerReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));
        CreateCustomerWithOverdueEntries(Customer, CustomerReminderTerms, NumberOfOverdueEntries);

        // [GIVEN] A reminder automation group with a create and issue action        
        CreateReminderAutomationGroupViaUI(ReminderAutomationCard, CustomerReminderTerms);
        CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Create Reminder");
        CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Issue Reminder");
        CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Send Reminder");

        // [GIVEN] A reminder automation group with an issue action that applies to the customer
        ReminderActionGroup.Get(ReminderAutomationCard.Code.Value());

        // [GIVEN] User runs the issue reminder automation
        BindSubscription(SendEmailMock);
        SendEmailMock.AddSupportedScenario(Enum::"Email Scenario"::Reminder);
        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);
        ReminderAutomationJob.Run(JobQueueEntry);
        UnbindSubscription(SendEmailMock);

        // [THEN] The reminder automation creates issued reminders
        TotalNumberOfSentEmails := 1;
        VerifyRemindersSentForCustomer(Customer, TotalNumberOfSentEmails, SendEmailMock);

        // [WHEN] User runs the issue reminder automation again
        if JobQueueEntry.Find() then
            JobQueueEntry.Delete();

        BindSubscription(SecondRunSendEmailMock);
        JobQueueEntry := CreateTestJobQueueEntry(ReminderActionGroup);
        ReminderAutomationJob.Run(JobQueueEntry);
        UnbindSubscription(SecondRunSendEmailMock);

        // [THEN] The reminder automation will not create any additional entries and issued entries will stay the same
        VerifyRemindersSentForCustomer(Customer, TotalNumberOfSentEmails, SendEmailMock);
        SecondRunSendEmailMock.GetEmailsSent(TempEmaiiItemSent);
        Assert.AreEqual(0, TempEmaiiItemSent.Count(), 'No emails should be sent on the second run');
    end;

    [Test]
    procedure TestSendReminderByEmailWithAttachment()
    var
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        ReminderHeader: Record "Reminder Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
        SendEmailMock: Codeunit "Send Email Mock";
        LanguageCode: Code[10];
    begin
        // [FEATURE] [Issued Reminders]
        // [SCENARIO 539690] Set file name from "File Name" on "Reminder Attachment Text"
        Initialize();

        // [GIVEN] Create reminder term with levels
        CreateReminderTermsWithLevels(ReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));

        // [GIVEN] Create reminder attachment text, file name = XXX, language code = Y
        LanguageCode := LibraryERM.GetAnyLanguageDifferentFromCurrent();
        CreateReminderAttachmentText(ReminderTerms, LanguageCode);

        // [GIVEN] Create a customer X with overdue entries
        CreateCustomerWithOverdueEntries(Customer, ReminderTerms, Any.IntegerInRange(2, 5));

        // [GIVEN] Set language code Y for customer X
        Customer."Language Code" := LanguageCode;
        Customer.Modify();

        // [GIVEN] Create and issue reminder for customer X 
        CreateAndIssueReminder(ReminderHeader, Customer."No.");

        // [WHEN] Run action "Send by mail" on issued reminder
        IssuedReminderHeader.SetRange("Pre-Assigned No.", ReminderHeader."No.");
        IssuedReminderHeader.FindFirst();
        BindSubscription(SendEmailMock);
        SendEmailMock.AddSupportedScenario(Enum::"Email Scenario"::Reminder);
        IssuedReminderHeader.PrintRecords(false, true, false);
        UnbindSubscription(SendEmailMock);

        // [THEN] The issued reminder has been sent on mail with file name XXX
        VerifyReminderMailWithAttachmentSentForCustomer(Customer, 1, SendEmailMock);
    end;

    [Test]
    [HandlerFunctions('NewReminderActionModalPageHandler,CreateRemindersSetupModalPageHandlerWithFilterSaveCheck,CreateReminderSetupPageCustomerFilterHandler')]
    procedure CustomerFilterAppliedInTheCreateReminderSetupPageShouldBeSaved()
    var
        ReminderAutomationCard: TestPage "Reminder Automation Card";
    begin
        // [SCENARIO 562688] Filters should be saved in the Create Reminders Setup page in Reminder Automation.
        Initialize();

        // [WHEN] Create a Remainders Automation.
        CreateReminderAutomationWithCreateAction(ReminderAutomationCard);

        // [THEN] Verify through the "CreateRemindersSetupModalPageHandlerWithFilterSaveCheck" that all filters applied in the "Customer Filter" of the Create Reminder Setup page are saved.
        ReminderAutomationCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,ReminderLevelCommunicationPageHandler,LanguagesPageHandler')]
    procedure AddTextforLanguageInReminderLevelCommunication()
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        ReminderTermSetupPage: TestPage "Reminder Terms Setup";
    begin
        // [SCENARIO 568005] Adding text for language in Reminder Level Communication.
        Initialize();

        // [GIVEN] Create Reminder Term with levels
        LibraryErm.CreateReminderTerms(ReminderTerms);
        LibraryErm.CreateReminderLevel(ReminderLevel, ReminderTerms.Code);

        // [WHEN] Open Reminder Term Setup page and add text for language
        ReminderTermSetupPage.OpenEdit();
        ReminderTermSetupPage.GoToRecord(ReminderTerms);
        ReminderTermSetupPage.ReminderLevelSetup.First();

        // [THEN] Varify that the text for language is added in Reminder Level Communication.
        ReminderTermSetupPage.ReminderLevelSetup.CustomerCommunications.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ModalEmailEditorHandler,CancelMailSendingStrMenuHandler')]
    procedure SendIssuedReminderByEmailAndEntryCreatedInEmailRelatedRecords()
    var
        Customer: Record Customer;
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderTerms: Record "Reminder Terms";
        ReminderHeader: Record "Reminder Header";
        LanguageCode: Code[10];
        FileName: Text;
    begin
        // [SCENARIO 591799] Issued reminder emails are not logged in sent e-mail history of a customer
        Initialize();

        // [WHEN] A connector is installed and an account is added
        InstallConnectorAndAddAccount();

        // [GIVEN] Create reminder term with levels
        CreateReminderTermsWithLevels(ReminderTerms, GetDefaultDueDatePeriodForReminderLevel(), Any.IntegerInRange(2, 5));

        // [GIVEN] Create reminder attachment text, file name = XXX, language code = Y
        LanguageCode := LibraryERM.GetAnyLanguageDifferentFromCurrent();
        CreateReminderAttachmentText(ReminderTerms, LanguageCode);

        // [GIVEN] Create a customer X with overdue entries
        CreateCustomerWithOverdueEntries(Customer, ReminderTerms, Any.IntegerInRange(2, 5));

        // [GIVEN] Set language code Y for customer X
        Customer."Language Code" := LanguageCode;
        Customer.Modify();
        FileName := LibraryVariableStorage.DequeueText();
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(FileName);

        // [GIVEN] Create and issue reminder for customer X 
        CreateAndIssueReminder(ReminderHeader, Customer."No.");

        // [WHEN] Run action "Send by mail" on issued reminder
        IssuedReminderHeader.SetRange("Pre-Assigned No.", ReminderHeader."No.");
        IssuedReminderHeader.FindFirst();
        CustomReportSelectionPrint(IssuedReminderHeader, Enum::"Report Selection Usage"::Reminder, 1);

        // [THEN] Verified in ModalEmailEditorHandler page
        LibraryVariableStorage.Clear();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure ReminderTermTransferTextNewLanguage()
    var
        Language: Record Language;
        ReminderTerms: Record "Reminder Terms";
        ReminderAttachText: Record "Reminder Attachment Text Line";
        ReminderLevel: Record "Reminder Level";
        ReminderTermList: TestPage "Reminder Terms List";
        LanguageCode: Code[10];
    begin
        // [SCENARIO 609485] When using Transfer Texts from the old reminder term text to the new customer communications the used language is not considered
        Initialize();

        // [GIVEN] Create reminder term with levels
        CreateReminderTerm(ReminderTerms);

        // [GIVEN] Set Global Language
        SetLanguageInUserPersonalization(1031);
        GlobalLanguage(1031);
        Language.SetRange("Windows Language ID", 1031);
        if Language.FindFirst() then
            LanguageCode := Language.Code;

        // [GIVEN] Page Reminder Term Invoke Action Transfer Texts 
        ReminderTermList.OpenEdit();
        ReminderTermList.TransferOldTexts.Invoke();

        // [VERIFY] Language on the new Reminder Text is same as Global Language
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTerms.Code);
        if ReminderLevel.FindFirst() then begin
            ReminderAttachText.SetRange(id, ReminderLevel."Reminder Attachment Text");
            if ReminderAttachText.FindFirst() then
                assert.AreEqual(ReminderAttachText."Language Code", LanguageCode, 'Not Match');
        end;

        // Tear Down  Return back the old value of language
        SetLanguageInUserPersonalization(1033);
        GlobalLanguage(1033);
    end;

    local procedure CreateReminderTerm(var ReminderTerms: Record "Reminder Terms")
    var
        ReminderLevel: Record "Reminder Level";
        ReminderText: Record "Reminder Text";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTerms.Code);
        ReminderLevel.Validate("Calculate Interest", true);
        ReminderLevel.Modify(true);

        LibraryERM.CreateReminderText(
          ReminderText, ReminderTerms.Code, ReminderLevel."No.",
          ReminderText.Position::Beginning, LibraryUtility.GenerateGUID());
    end;

    local procedure SetLanguageInUserPersonalization(ID: Integer)
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.Get(UserSecurityId());
        UserPersonalization."Language ID" := ID;
        UserPersonalization.Modify();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure CreateReminderAttachmentText(ReminderTerms: Record "Reminder Terms"; LanguageCode: Code[10])
    var
        ReminderLevel: Record "Reminder Level";
        ReminderAttachmentText: Record "Reminder Attachment Text";
    begin
        ReminderAttachmentText.Id := CreateGuid();
        ReminderAttachmentText."Language Code" := LanguageCode;
        ReminderAttachmentText."File Name" := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(ReminderAttachmentText."File Name"));
        ReminderAttachmentText.Insert();

        ReminderLevel.SetRange("Reminder Terms Code", ReminderTerms.Code);
        ReminderLevel.FindFirst();
        ReminderLevel."Reminder Attachment Text" := ReminderAttachmentText.Id;
        ReminderLevel.Modify();

        LibraryVariableStorage.Enqueue(ReminderAttachmentText."File Name" + '.pdf');
    end;

    local procedure CreateAndIssueReminder(var ReminderHeader: Record "Reminder Header"; CustomerNo: Code[20])
    var
        SuggestReminderLines: Report "Suggest Reminder Lines";
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Modify(true);

        ReminderHeader.SetRange("No.", ReminderHeader."No.");
        SuggestReminderLines.SetTableView(ReminderHeader);
        SuggestReminderLines.UseRequestPage(false);
        SuggestReminderLines.Run();

        ReminderHeader.SetRecFilter();
        Report.RunModal(Report::"Issue Reminders", false, true, ReminderHeader);
    end;

    local procedure GetDefaultDueDatePeriodForReminderLevel(): Integer
    begin
        exit(14);
    end;

    local procedure VerifyDraftRemindersCreatedForCustomer(var Customer: Record Customer; ExpectedLevel: Integer; ExpectedNumberOfLines: Integer)
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLines: Record "Reminder Line";
    begin
        ReminderHeader.SetRange("Customer No.", Customer."No.");
        Assert.IsFalse(ReminderHeader.IsEmpty(), 'No reminders were created for the customer');
        Assert.AreEqual(ExpectedLevel, ReminderHeader."Reminder Level", 'Wrong reminder level created');
        ReminderHeader.FindFirst();

        ReminderLines.SetRange("Reminder No.", ReminderHeader."No.");
        Assert.AreEqual(ExpectedNumberOfLines, ReminderLines.Count, 'Wrong number of reminder lines created');
        ReminderLines.CalcSums(Amount, "Remaining Amount");
        Assert.AreNotEqual(0, ReminderLines."Remaining Amount", 'The reminder lines were created with wrong Remaining Amount.');
    end;

    local procedure VerifyIssuedRemindersCreatedForCustomer(var Customer: Record Customer; ExpectedLevel: Integer; ExpectedNumberOfLines: Integer)
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLines: Record "Issued Reminder Line";
    begin
        IssuedReminderHeader.SetRange("Customer No.", Customer."No.");
        Assert.IsFalse(IssuedReminderHeader.IsEmpty(), 'No issued reminders were created for the customer');
        Assert.AreEqual(ExpectedLevel, IssuedReminderHeader."Reminder Level", 'Wrong issued reminder level created');
        IssuedReminderHeader.FindFirst();

        IssuedReminderLines.SetRange("Reminder No.", IssuedReminderHeader."No.");
        Assert.AreEqual(ExpectedNumberOfLines, IssuedReminderLines.Count, 'Wrong number of issued reminder lines created');
        IssuedReminderLines.CalcSums(Amount, "Remaining Amount");
        Assert.AreNotEqual(0, IssuedReminderLines."Remaining Amount", 'The issues reminder lines were created with wrong Remaining Amount.');
    end;

    local procedure VerifyRemindersSentForCustomer(var Customer: Record Customer; TotalNumberOfRemindersSent: Integer; SendEmailMock: Codeunit "Send Email Mock")
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        TempEmailItemSent: Record "Email Item" temporary;
        BlankDate: Date;
        IssuedReminderEmailCount: Integer;
    begin
        Clear(BlankDate);
        IssuedReminderHeader.SetRange("Customer No.", Customer."No.");
        Assert.IsFalse(IssuedReminderHeader.IsEmpty(), 'No issued reminders exist for the customer');
        IssuedReminderHeader.FindFirst();
        IssuedReminderEmailCount := 1;
        Assert.AreNotEqual(IssuedReminderHeader."Last Email Sent Date Time", BlankDate, 'The email sent date was not updated');
        Assert.AreEqual(true, IssuedReminderHeader."Sent For Current Level", 'The sent flag for current level was not updated');
        Assert.AreEqual(IssuedReminderHeader."Reminder Level", IssuedReminderHeader."Email Sent Level", 'The email sent level was not updated');
        Assert.AreEqual(IssuedReminderEmailCount, IssuedReminderHeader."Last Level Email Sent Count", 'The number of emails sent was not updated');
        Assert.AreEqual(IssuedReminderEmailCount, IssuedReminderHeader."Total Email Sent Count", 'The total number of emails sent was not updated');

        SendEmailMock.GetEmailsSent(TempEmailItemSent);
        Assert.AreEqual(TempEmailItemSent.Count(), TotalNumberOfRemindersSent, 'The number of emails sent was not correct');
        TempEmailItemSent.SetRange("Send to", Customer."E-Mail");
        Assert.IsTrue(TempEmailItemSent.FindFirst(), 'The email was not sent to the customer');
        Assert.IsTrue(TempEmailItemSent.HasAttachments(), 'The email has no attachments');
    end;

    local procedure VerifyReminderMailWithAttachmentSentForCustomer(var Customer: Record Customer; TotalNumberOfRemindersSent: Integer; SendEmailMock: Codeunit "Send Email Mock")
    var
        TempEmailItemSent: Record "Email Item" temporary;
        TempBlobList: Codeunit "Temp Blob List";
        AttachmentNames: List of [Text];
        AttachmentName: Text;
    begin
        SendEmailMock.GetEmailsSent(TempEmailItemSent);
        Assert.AreEqual(TempEmailItemSent.Count(), TotalNumberOfRemindersSent, 'The number of emails sent was not correct');
        TempEmailItemSent.SetRange("Send to", Customer."E-Mail");
        Assert.IsTrue(TempEmailItemSent.FindFirst(), 'The email was not sent to the customer');
        Assert.IsTrue(TempEmailItemSent.HasAttachments(), 'The email has no attachments');

        TempEmailItemSent.GetAttachments(TempBlobList, AttachmentNames);
        AttachmentNames.Get(1, AttachmentName);
        Assert.AreEqual(AttachmentName, LibraryVariableStorage.DequeueText(), 'The file name is not correct.');
    end;

    local procedure IncludeReminderTermsInFilter(var ReminderAutomationCard: TestPage "Reminder Automation Card"; var ReminderTerms: Record "Reminder Terms")
    begin
        LibraryVariableStorage.Enqueue(ReminderTerms.Code);
        ReminderAutomationCard.ReminderTerms.AssistEdit();
    end;

    local procedure CreateReminderAutomationWithCreateAction(var ReminderAutomationCard: TestPage "Reminder Automation Card"): Code[50]
    var
        DummyReminderTerms: Record "Reminder Terms";
    begin
        exit(CreateReminderAutomationWithCreateAction(ReminderAutomationCard, DummyReminderTerms));
    end;

    local procedure CreateReminderAutomationWithCreateAction(var ReminderAutomationCard: TestPage "Reminder Automation Card"; var ReminderTerms: Record "Reminder Terms"): Code[50]
    begin
        CreateReminderAutomationGroupViaUI(ReminderAutomationCard, ReminderTerms);
        exit(CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Create Reminder"))
    end;

    local procedure CreateReminderAutomationWithIssueAction(var ReminderAutomationCard: TestPage "Reminder Automation Card"; var ReminderTerms: Record "Reminder Terms"): Code[50]
    begin
        CreateReminderAutomationGroupViaUI(ReminderAutomationCard, ReminderTerms);
        exit(CreateReminderAction(ReminderAutomationCard, Enum::"Reminder Action"::"Issue Reminder"))
    end;

    local procedure CreateReminderAction(var ReminderAutomationCard: TestPage "Reminder Automation Card"; ReminderActonEnum: Enum "Reminder Action"): Code[50]
    var
        ReminderActionCode: Code[50];
    begin
        ReminderActionCode := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(ReminderActionCode);
        LibraryVariableStorage.Enqueue(ReminderActonEnum);
        ReminderAutomationCard.ReminderActionsPart.New.Invoke();

        exit(ReminderActionCode);
    end;

    local procedure VerifySetupRecordForCreateAction(ReminderAutomationGroupCode: Text)
    var
        ReminderActionGroup: Record "Reminder Action Group";
        ReminderAction: Record "Reminder Action";
        CreateRemindersSetup: Record "Create Reminders Setup";
        ReminderActionInterface: Interface "Reminder Action";
        SetupRecordTableID: Integer;
        SetupRecordSystemID: Guid;
    begin
        // [THEN] The reminder action is created with the correct setup record
        Assert.IsTrue(ReminderActionGroup.Get(ReminderAutomationGroupCode), 'Could not find the Reminder Automation Group');
        ReminderAction.SetRange("Reminder Action Group Code", ReminderActionGroup.Code);
        Assert.AreEqual(1, ReminderAction.Count, 'Wrong number of reminder actions created');
        Assert.IsTrue(ReminderAction.FindFirst(), 'Could not find the reminder action');
        Assert.AreEqual(Enum::"Reminder Action"::"Create Reminder", ReminderAction.Type, 'Wrong reminder action created');

        // [THEN] The interface returns the correct values
        ReminderActionInterface := ReminderAction.GetReminderActionInterface();
        ReminderActionInterface.GetSetupRecord(SetupRecordTableID, SetupRecordSystemID);
        Assert.AreEqual(Database::"Create Reminders Setup", SetupRecordTableID, 'Wrong setup record returned from interface');
        Assert.AreEqual(ReminderAction.SystemId, ReminderActionInterface.GetReminderActionSystemId(), 'Wrong system ID returned from interface');

        Assert.IsTrue(CreateRemindersSetup.GetBySystemId(SetupRecordSystemID), 'Could not find the setup record');
    end;

    local procedure VerifySetupRecordForIssueAction(ReminderAutomationGroupCode: Text)
    var
        ReminderActionGroup: Record "Reminder Action Group";
        ReminderAction: Record "Reminder Action";
        IssueRemindersSetup: Record "Issue Reminders Setup";
        ReminderActionInterface: Interface "Reminder Action";
        SetupRecordTableID: Integer;
        SetupRecordSystemID: Guid;
    begin
        // [THEN] The reminder action is created with the correct setup record
        Assert.IsTrue(ReminderActionGroup.Get(ReminderAutomationGroupCode), 'Could not find the Reminder Automation Group');
        ReminderAction.SetRange("Reminder Action Group Code", ReminderActionGroup.Code);
        Assert.AreEqual(1, ReminderAction.Count, 'Wrong number of reminder actions created');
        Assert.IsTrue(ReminderAction.FindFirst(), 'Could not find the reminder action');
        Assert.AreEqual(Enum::"Reminder Action"::"Issue Reminder", ReminderAction.Type, 'Wrong reminder action created');

        // [THEN] The interface returns the correct values
        ReminderActionInterface := ReminderAction.GetReminderActionInterface();
        ReminderActionInterface.GetSetupRecord(SetupRecordTableID, SetupRecordSystemID);
        Assert.AreEqual(Database::"Issue Reminders Setup", SetupRecordTableID, 'Wrong setup record returned from interface');
        Assert.AreEqual(ReminderAction.SystemId, ReminderActionInterface.GetReminderActionSystemId(), 'Wrong system ID returned from interface');

        Assert.IsTrue(IssueRemindersSetup.GetBySystemId(SetupRecordSystemID), 'Could not find the setup record');
    end;

    local procedure VerifySetupRecordForSendAction(ReminderAutomationGroupCode: Text)
    var
        ReminderActionGroup: Record "Reminder Action Group";
        ReminderAction: Record "Reminder Action";
        SendRemindersSetup: Record "Send Reminders Setup";
        ReminderActionInterface: Interface "Reminder Action";
        SetupRecordTableID: Integer;
        SetupRecordSystemID: Guid;
    begin
        // [THEN] The reminder action is created with the correct setup record
        Assert.IsTrue(ReminderActionGroup.Get(ReminderAutomationGroupCode), 'Could not find the Reminder Automation Group');
        ReminderAction.SetRange("Reminder Action Group Code", ReminderActionGroup.Code);
        Assert.AreEqual(1, ReminderAction.Count, 'Wrong number of reminder actions created');
        Assert.IsTrue(ReminderAction.FindFirst(), 'Could not find the reminder action');
        Assert.AreEqual(Enum::"Reminder Action"::"Send Reminder", ReminderAction.Type, 'Wrong reminder action created');

        // [THEN] The interface returns the correct values
        ReminderActionInterface := ReminderAction.GetReminderActionInterface();
        ReminderActionInterface.GetSetupRecord(SetupRecordTableID, SetupRecordSystemID);
        Assert.AreEqual(Database::"Send Reminders Setup", SetupRecordTableID, 'Wrong setup record returned from interface');
        Assert.AreEqual(ReminderAction.SystemId, ReminderActionInterface.GetReminderActionSystemId(), 'Wrong system ID returned from interface');

        Assert.IsTrue(SendRemindersSetup.GetBySystemId(SetupRecordSystemID), 'Could not find the setup record');
    end;

    local procedure CreateCustomerWithPaidOverdueEntries(var Customer: Record Customer; var ReminderTerms: Record "Reminder Terms"; NumberOfEntries: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CreateCustomerWithOverdueEntries(Customer, ReminderTerms, NumberOfEntries);
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetAutoCalcFields("Remaining Amount");
        CustLedgerEntry.FindSet();
        repeat
            LibrarySales.CreatePaymentAndApplytoInvoice(GenJournalLine, Customer."No.", CustLedgerEntry."Document No.", -CustLedgerEntry."Remaining Amount");
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure CreateCustomerWithOverdueEntries(var Customer: Record Customer; var ReminderTerms: Record "Reminder Terms"; NumberOfEntries: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReminderLevel: Record "Reminder Level";
        Item: Record Item;
        PostingDate: Date;
        I: Integer;
    begin
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTerms.Code);
        ReminderLevel.FindFirst();

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", ReminderTerms.Code);
        Customer.Modify(true);

        PostingDate := WorkDate() + (WorkDate() - CalcDate(ReminderLevel."Due Date Calculation", WorkDate()));
        PostingDate := CalcDate('<-5M>', PostingDate);

        for I := 1 to NumberOfEntries do begin
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
            SalesHeader.Validate("Posting Date", PostingDate);
            SalesHeader.Validate("Due Date", PostingDate);
            SalesHeader.Validate("Document Date", PostingDate);
            SalesHeader.Modify(true);
            LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
              Item, Any.DecimalInRange(1, 100, 2), Any.DecimalInRange(1, 100, 2));
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Any.IntegerInRange(1, 10));
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
        end;
    end;

    local procedure CreateReminderAutomationGroupViaUI(var ReminderAutomationCard: TestPage "Reminder Automation Card"; var ReminderTerms: Record "Reminder Terms")
    begin
        ReminderAutomationCard.OpenNew();
        ReminderAutomationCard.Code.SetValue(LibraryUtility.GenerateGUID());
        if ReminderTerms.Code <> '' then
            IncludeReminderTermsInFilter(ReminderAutomationCard, ReminderTerms);
    end;

    [ModalPageHandler()]
    procedure NewReminderActionModalPageHandler(var NewReminderAction: TestPage "New Reminder Action")
    var
        NewActionCode: Code[50];
        ActionID: Text;
    begin
        NewActionCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(NewActionCode));
        NewReminderAction.ActionId.SetValue(NewActionCode);

        ActionID := LibraryVariableStorage.DequeueText();
        Assert.IsTrue(NewReminderAction.FindFirstField(Name, ActionID), 'Could not find the reminder automation action with ID ' + ActionID);

        NewReminderAction.OK().Invoke();
    end;

    local procedure CreateTestJobQueueEntry(var ReminderActionGroup: Record "Reminder Action Group"): Record "Job Queue Entry"
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        ReminderActionGroup.CreateUniqueJobQueue(ReminderActionGroup, JobQueueEntry);
        exit(JobQueueEntry);
    end;

    local procedure VerifyJobWasSuccesfull(var ReminderActionGroup: Record "Reminder Action Group"): Integer
    begin
        exit(VerifyJobWasSuccesfull(ReminderActionGroup, 0));
    end;

    local procedure VerifyJobWasSuccesfull(var ReminderActionGroup: Record "Reminder Action Group"; MinimumID: Integer): Integer
    var
        ReminderActionGroupLog: Record "Reminder Action Group Log";
    begin
        ReminderActionGroupLog.SetFilter("Run Id", '>%1', MinimumID);
        ReminderActionGroupLog.SetRange("Reminder Action Group ID", ReminderActionGroup.Code);
        Assert.IsTrue(ReminderActionGroupLog.FindLast(), 'The job was not successful');
        Assert.AreEqual(ReminderActionGroupLog.Status, ReminderActionGroupLog.Status::Completed, 'The job was not successful');
        exit(ReminderActionGroupLog."Run Id");
    end;

    local procedure CreateReminderTermsWithLevels(var ReminderTerms: Record "Reminder Terms"; DueDateCalculationDays: Integer; NumberOfLevels: Integer)
    var
        ReminderLevel: Record "Reminder Level";
        I: Integer;
    begin
        LibraryErm.CreateReminderTerms(ReminderTerms);
        for I := 1 to NumberOfLevels do begin
            Clear(ReminderLevel);
            LibraryErm.CreateReminderLevel(ReminderLevel, ReminderTerms.Code);
            Evaluate(ReminderLevel."Due Date Calculation", '<' + Format(DueDateCalculationDays, 0, 9) + 'D>');
            ReminderLevel.Modify(true);
        end;
    end;

    local procedure InstallConnectorAndAddAccount()
    var
        TempAccount: Record "Email Account" temporary;
        ConnectorMock: Codeunit "Connector Mock";
        EmailScenarioMock: Codeunit "Email Scenario Mock";
    begin
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);
        EmailScenarioMock.DeleteAllMappings();
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::Default, TempAccount."Account Id", TempAccount.Connector);
    end;

    local procedure CustomReportSelectionPrint(Document: Variant; ReportUsage: Enum "Report Selection Usage"; CustomerNoFieldNo: Integer)
    var
        ReportSelections: Record "Report Selections";
        TempReportSelections: Record "Report Selections" temporary;
        RecRef: RecordRef;
        FieldRef: FieldRef;
        CustomerNo: Code[20];
    begin
        RecRef.GetTable(Document);
        FieldRef := RecRef.Field(CustomerNoFieldNo);
        CustomerNo := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(CustomerNo));

        RecRef.SetRecFilter();
        RecRef.SetTable(Document);

        ReportSelections.FindEmailAttachmentUsageForCust(ReportUsage, CustomerNo, TempReportSelections);
        ReportSelections.SendEmailToCust(ReportUsage.AsInteger(), Document, '', '', true, CustomerNo);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CancelMailSendingStrMenuHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 1; //Save as Draft //Discard email	
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalEmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    var
        Customer: Record Customer;
        EmailRelatedRecord: Record "Email Related Record";
    begin
        Customer.Get(LibraryVariableStorage.DequeueText());
        EmailRelatedRecord.SetRange("Table Id", Database::Customer);
        EmailRelatedRecord.SetRange("System Id", Customer.SystemId);
        Assert.IsTrue(EmailRelatedRecord.FindFirst(), EmailRelatedRecordNotFoundErr);
    end;

    [ModalPageHandler()]
    procedure CreateRemindersSetupModalPageHandler(var CreateRemindersSetup: TestPage "Create Reminders Setup")
    begin
        CreateRemindersSetup.OK().Invoke();
    end;

    [ModalPageHandler()]
    procedure IssueRemindersSetupModalPageHandler(var IssueRemindersSetup: TestPage "Issue Reminders Setup")
    begin
        IssueRemindersSetup.OK().Invoke();
    end;

    [ModalPageHandler()]
    procedure SendRemindersSetupModalPageHandler(var SendRemindersSetup: TestPage "Send Reminders Setup")
    begin
        SendRemindersSetup.SendByEmail.SetValue(true);
        SendRemindersSetup.Print.SetValue(false);
        SendRemindersSetup.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SelectRemTermsAutomationHandler(var SelectRemTermsAutomation: TestPage "Select Rem. Terms Automation")
    begin
        SelectRemTermsAutomation.FindFirstField(Code, LibraryVariableStorage.DequeueText());
        SelectRemTermsAutomation.Selected.SetValue(true);
        SelectRemTermsAutomation.OK().Invoke();
    end;

    [ModalPageHandler()]
    procedure CreateRemindersSetupModalPageHandlerWithFilterSaveCheck(var CreateRemindersSetupPage: TestPage "Create Reminders Setup")
    var
        CreateReminderSetup: Record "Create Reminders Setup";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateReminderSetup.SetRange(Code, CreateRemindersSetupPage.Code.Value);
        CreateReminderSetup.FindFirst();

        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(Customer."Customer Posting Group");
        CreateRemindersSetupPage.CustomerFilter.AssistEdit();
        Assert.IsTrue(CreateReminderSetup.GetCustomerSelectionDisplayText() <> '', FiltersAreNotSavedErr);

        // Now remove the "Customer Posting Group" filter in customer filter and check.
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue('');
        CreateRemindersSetupPage.CustomerFilter.AssistEdit();
        Assert.IsTrue(CreateReminderSetup.GetCustomerSelectionDisplayText() <> '', FiltersAreNotSavedErr);
    end;

    [FilterPageHandler]
    procedure CreateReminderSetupPageCustomerFilterHandler(var CustomerRecordRef: RecordRef): Boolean
    var
        Customer: Record Customer;
    begin
        CustomerRecordRef.GetTable(Customer);
        Customer.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Customer.SetFilter("Customer Posting Group", LibraryVariableStorage.DequeueText());
        CustomerRecordRef.SetView(Customer.GetView());
        exit(true);
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerFalse(QuestionText: Text[1024]; var Relpy: Boolean)
    begin
        Relpy := false;
    end;

    [PageHandler]
    procedure ReminderLevelCommunicationPageHandler(var ReminderLevelCommunication: TestPage "Reminder Level Communication")
    begin
        ReminderLevelCommunication."Add New Language".Invoke();
    end;

    [ModalPageHandler]
    procedure LanguagesPageHandler(var Languages: TestPage "Languages")
    begin
        Languages.Filter.SetFilter("Code", 'ENG');
        Languages.OK().Invoke();
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryErm: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        IsInitialized: Boolean;
        FiltersAreNotSavedErr: Label 'Filters are not saved';
        EmailRelatedRecordNotFoundErr: Label 'Email related record not found';
}