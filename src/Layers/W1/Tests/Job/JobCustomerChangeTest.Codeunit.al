codeunit 136324 "Job Customer Change Test"
{
    Description = 'Description';
    Subtype = Test;
    TestPermissions = Restrictive;
    Permissions =
        tabledata "Job Ledger Entry" = i;

    trigger OnRun();
    begin
        IsInitialized := false;
    end;

    var
        Any: Codeunit Any;
        LibraryJob: Codeunit "Library - Job";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryAssert: Codeunit "Library Assert";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;

    [Test]
    procedure ChangeOfCustAllowedTest()
    var
        Customer: Record Customer;
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [FEATURE] [Jobs][Customer]
        // [SCENARIO] A customer of a Job can be changed and the Job Planning line is updated correctly
        Initialize();

        // [GIVEN] Given Job
        CreateJobWithJoblanningLine(Job);

        // [GIVEN] Customer for Customer Change in Job
        CreateCustomerWithUniquePriceGroup(Customer);

        // [GIVEN] A minimum set of permissions
        LibraryLowerPermissions.SetRead();
        LibraryLowerPermissions.AddO365Basic();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] When Sell-to Customer No. is changed
        Job.SetHideValidationDialog(true); //Skip ConfirmChange Confirm
        Job.Validate("Sell-to Customer No.", Customer."No.");
        Job.Modify(true);

        // [THEN] Verify Job Planning Line is updated
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.FindFirst();
        LibraryAssert.AreEqual(Customer."Customer Price Group", JobPlanningLine."Customer Price Group", JobPlanningLine.FieldCaption("Customer Price Group"));
    end;


    [Test]
    procedure ChangeOfCustNotAllowedTest()
    var
        Customer: Record Customer;
        Job: Record Job;
        AssociatedEntriesExistErr: Label 'You cannot change %1 because one or more entries are associated with this %2.', Comment = '%1 = Name of field used in the error; %2 = The name of the Project table';
    begin
        // [FEATURE] [Jobs][Customer]
        // [SCENARIO] A customer of a Job must not be changed if job ledger entries of type sales exists
        Initialize();

        // [GIVEN] Given Job With Ledger Entries
        CreateJobWithSalesLedgerEntries(Job);

        // [GIVEN] Customer for Customer Change in Job
        CreateCustomerWithUniquePriceGroup(Customer);

        // [GIVEN] A minimum set of permissions
        LibraryLowerPermissions.SetRead();
        LibraryLowerPermissions.AddO365Basic();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] When Sell-to Customer No. is changed
        Job.SetHideValidationDialog(true); //Skip ConfirmChange Confirm
        asserterror Job.Validate("Sell-to Customer No.", Customer."No.");

        // [THEN] Verify Error
        LibraryAssert.ExpectedError(StrSubstNo(AssociatedEntriesExistErr, Job.FieldCaption("Sell-to Customer No."), Job.TableCaption()));
    end;


    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Job Customer Change Test");
        ClearLastError();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Job Customer Change Test");

        Any.SetDefaultSeed();

        // CUSTOMIZATION: Prepare setup tables etc. that are used for all test functions

        IsInitialized := true;
        Commit();

        // CUSTOMIZATION: Add all setup tables that are changed by tests to the SetupStorage, so they can be restored for each test function that calls Initialize.
        // This is done InMemory, so it could be run after the COMMIT above
        //   LibrarySetupStorage.Save(DATABASE::"[SETUP TABLE ID]");

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Job Customer Change Test");
    end;

    local procedure CreateCustomerWithUniquePriceGroup(var Customer: Record Customer)
    var
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        Customer.Validate("Customer Price Group", CustomerPriceGroup.Code);
        Customer.Modify(true);
    end;

    local procedure CreateJobWithJoblanningLine(var Job: Record Job)
    var
        JobTask: Record "Job Task";
    begin
        // Create Job, JobTask, JobPlanningLine
        CreateJobWithJoblanningLine(Job, JobTask);
    end;

    local procedure CreateJobWithSalesLedgerEntries(var Job: Record Job)
    var
        JobTask: Record "Job Task";
        RandomInput: Decimal;
    begin
        // Create Job, JobTask, JobPlanningLine
        CreateJobWithJoblanningLine(Job, JobTask);
        RandomInput := Any.DecimalInRange(1, 10, 2);  // Using Random Value for Quantity,Unit Cost and Unit Price.

        MockJobLedgEntry(Job."No.", Enum::"Job Journal Line Entry Type"::Sale);
    end;

    local procedure CreateJobWithJoblanningLine(var Job: Record Job; var JobTask: Record "Job Task")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ResourceType(), JobTask, JobPlanningLine);
    end;

    local procedure MockJobLedgEntry(JobNo: Code[20]; JLEntryType: Enum "Job Journal Line Entry Type")
    var
        JLAmount: Decimal;
        JLCost: Decimal;
    begin
        JLCost := Any.DecimalInRange(100, 2);
        JLAmount := Any.DecimalInRange(100, 2);
        MockJobLedgEntry(JobNo, JLCost, JLCost, Enum::"Job Journal Line Type"::"G/L Account", JLEntryType);
    end;

    local procedure MockJobLedgEntry(JobNo: Code[20]; JLCost: Decimal; JLAmount: Decimal; JobJournalLineType: Enum "Job Journal Line Type"; JLEntryType: Enum "Job Journal Line Entry Type")
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.Init();
        JobLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(JobLedgerEntry, JobLedgerEntry.FieldNo("Entry No."));
        JobLedgerEntry."Job No." := JobNo;
        JobLedgerEntry."Total Cost" := JLCost;
        JobLedgerEntry."Total Cost (LCY)" := JLCost;
        JobLedgerEntry."Line Amount" := JLAmount;
        JobLedgerEntry."Line Amount (LCY)" := JLAmount;
        JobLedgerEntry.Type := JobJournalLineType;
        JobLedgerEntry."Entry Type" := JLEntryType;
        JobLedgerEntry.Insert(false);
    end;
}