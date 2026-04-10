codeunit 136313 "Job Creation Wizard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [Job Creation Wizard] [UI]
        IsInitialized := false;
    end;

    var
        Job: Record Job;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        IsInitialized: Boolean;
        RollingBackChangesErr: Label 'Rolling back changes...';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Creation Wizard Tests");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Creation Wizard Tests");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Creation Wizard Tests");
    end;

    local procedure TearDown()
    begin
        Clear(Job);
        asserterror Error(RollingBackChangesErr);
        IsInitialized := false;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectNoOnFirstPage()
    var
        LibraryJob: Codeunit "Library - Job";
        JobCreationWizard: TestPage "Job Creation Wizard";
        JobCard: TestPage "Job Card";
    begin
        // [GIVEN] A newly setup company, with a new job created
        Initialize();
        LibraryJob.CreateJob(Job);

        // [WHEN] The user runs the job creation wizard.
        JobCreationWizard.Trap();
        PAGE.Run(PAGE::"Job Creation Wizard", Job);
        // [THEN] Make sure default of Yes is checked on the first page.
        Assert.IsTrue(JobCreationWizard.FromExistingJob.AsBoolean(), 'Checkbox should be marked by default.');
        // [WHEN] User marks to note create job from existing job.
        JobCreationWizard.FromExistingJob.SetValue(false);

        JobCard.Trap();
        JobCreationWizard.ActionNext.Invoke();
        // Choosing next here should open up the Job card, with a new Job Number defaulted in.
        Assert.AreEqual(Format(JobCard."No."), Format(Job."No."), 'Job number should have a value when the Job page is opened.');
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectYesOnFirstPage()
    var
        LibraryJob: Codeunit "Library - Job";
        JobCreationWizard: TestPage "Job Creation Wizard";
    begin
        // [GIVEN] A newly setup company, with a new job created
        Initialize();
        LibraryJob.CreateJob(Job);

        // [WHEN] The user runs the job creation wizard.
        JobCreationWizard.Trap();
        PAGE.Run(PAGE::"Job Creation Wizard", Job);
        JobCreationWizard.FromExistingJob.SetValue(true);
        // [THEN] The checkbox is checked.
        JobCreationWizard.ActionNext.Invoke();
        // [THEN] The new job number was defaulted into the wizard page.
        Assert.AreEqual(Format(JobCreationWizard."No."), Format(Job."No."), 'Default job number does not match created job.');
        // [WHEN] The customer number for the new job is empty.
        JobCreationWizard."Sell-to Customer No.".SetValue('');
        // [THEN] An error occurs when you click the next button.
        asserterror JobCreationWizard.ActionNext.Invoke();
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectYesOnFirstPageThenNextToCopyJob()
    var
        LibraryJob: Codeunit "Library - Job";
        JobCreationWizard: TestPage "Job Creation Wizard";
        JobCard: TestPage "Job Card";
        CopyJobTasks: TestPage "Copy Job Tasks";
    begin
        // [GIVEN] A newly setup company, with a new job and new customer created (via the CreateJob() method)
        Initialize();
        LibraryJob.CreateJob(Job);

        // [WHEN] The user runs the job creation wizard.
        JobCreationWizard.Trap();
        PAGE.Run(PAGE::"Job Creation Wizard", Job);
        JobCreationWizard.ActionNext.Invoke();
        // [WHEN] The user has entered a descripton and a customer number for the new job, then clicks next.
        JobCreationWizard.Description.SetValue('Job description.');
        JobCreationWizard."Sell-to Customer No.".SetValue(Job."Bill-to Customer No.");

        CopyJobTasks.Trap();
        JobCreationWizard.ActionNext.Invoke();
        Assert.AreEqual(Format(CopyJobTasks.TargetJobNo), Format(Job."No."), 'Default job number does not match created job.');
        CopyJobTasks.Close();
        // [WHEN] The user closes the wizard
        JobCard.Trap();
        JobCreationWizard.ActionFinish.Invoke();
        // [THEN] Job card page displays with the new job number.
        Assert.AreEqual(Format(JobCard."No."), Format(Job."No."), 'Job number should have a value when the Job page is opened.');
        TearDown();
    end;

    [Test]
    [HandlerFunctions('CustomerLookupSelectCustomerPageHandler')]
    [Scope('OnPrem')]
    procedure CheckCreateJobForCustomerUsingCustomerLookup()
    var
        Customer: Record Customer;
        JobCard: TestPage "Job Card";
    begin
        Initialize();

        //[GIVEN] new customer created
        LibrarySales.CreateCustomer(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");

        // [WHEN] The user creates a new job for the customer using Customer Name lookup.
        JobCard.OpenNew();
        JobCard."Sell-to Customer Name".Lookup();

        // [THEN] The customer number should be the same as the one selected. system will not ask to update customer
        Assert.AreEqual(JobCard."Sell-to Customer No.".Value, Customer."No.", 'Customer number should be the same as the one selected.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectYesOnFirstPageThenBack()
    var
        LibraryJob: Codeunit "Library - Job";
        JobCreationWizard: TestPage "Job Creation Wizard";
    begin
        // [GIVEN] A newly setup company, with a new job and new customer created (via the CreateJob() method)
        Initialize();
        LibraryJob.CreateJob(Job);

        // [WHEN] The user runs the job creation wizard.
        JobCreationWizard.Trap();
        PAGE.Run(PAGE::"Job Creation Wizard", Job);
        JobCreationWizard.ActionNext.Invoke();
        // [WHEN] The user clicks back, Yes checkbox should still be checked, and no should be unchecked.
        JobCreationWizard.ActionBack.Invoke();
        // [THEN] The Yes checkbox is checked.
        Assert.IsTrue(JobCreationWizard.FromExistingJob.AsBoolean(), 'Checkbox should be marked true by default.');
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyJobCreationSetsNewDefaults()
    var
        JobsSetup: Record "Jobs Setup";
        LibraryJob: Codeunit "Library - Job";
    begin
        // [GIVEN] A newly setup company, with a new job and new customer created (via the CreateJob() method)
        Initialize();
        LibraryJob.CreateJob(Job);

        // [WHEN] Jobs Setup table is accessed
        if JobsSetup.FindFirst() then begin
            // [THEN] Defaults for "Apply Usage Link by Default" and "Allow Sched/Contract Lines Def" are true
            Assert.IsTrue(JobsSetup."Apply Usage Link by Default", '"Apply Usage Link by Default" should be true.');
            Assert.IsTrue(JobsSetup."Allow Sched/Contract Lines Def", '"Allow Sched/Contract Lines Def" should be true.');
        end;

        // [WHEN] Job record is accessed for newly-created job
        // [THEN] Values for "Apply Usage Link by Default" and "Allow Sched/Contract Lines Def" are true
        Assert.IsTrue(Job."Apply Usage Link", '"Apply Usage Link" should be true.');
        Assert.IsTrue(Job."Allow Schedule/Contract Lines", '"Allow Schedule/Contract Lines" should be true.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerLookupSelectCustomerPageHandler(var CustomerLookup: TestPage "Customer Lookup")
    begin
        CustomerLookup.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CustomerLookup.OK().Invoke();
    end;
}

