codeunit 136503 "RES Time Sheets Creation"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Time Sheet]
        IsInitialized := false;
    end;

    var
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        Text001Err: Label 'Rolling back changes...';
        NonExistentUserErr: Label 'NON EXISTENT USER ID';
        ErrorGeneratedIncorrectErr: Label 'Incorrect Error Message';
        NewUserIDTok: Label 'NEWUSERID';
        SameUserIDMessageErr: Label 'User ID should be modified';
        ResourceIsNotDeletedErr: Label 'Resource is not deleted';
        YouCannotDeleteResourceErr: Label 'You cannot delete Resource %1 because unprocessed time sheet lines exist for this resource.';
        FirstWeekDayCannotBeChangedErr: Label 'Time Sheet First Weekday cannot be changed, because there is at least one time sheet.';
        LibraryResource: Codeunit "Library - Resource";
        ThereIsNoEmployeeLinkedWithResErr: Label 'There is no employee linked with resource %1.';
        DayTimeAllocation: array[7] of Decimal;
        UseTimeSheetCannotBeChangedErr: Label 'Use Time Sheet cannot be changed since unprocessed time sheet lines exist for this resource.';
        TimeSheetsHaveBeenMovedtoArchErr: Label '%1 time sheets have been moved to archive.';
        YouHaveChangedADimensionMsg: Label 'You have changed a dimension';
        DoYouWantToUpdateTheLinesQst: Label 'Do you want to update the lines?';
        GlobalJobNo: Code[20];
        GlobalJobTaskNo: Code[20];
        GlobalTSAllocationValues: array[9] of Decimal;
        GlobalTimeSheetNo: Code[20];
        GlobalTextVariable: Code[20];
        TimeSheetDoesNotExistErr: Label 'Time Sheet does not exist';
        IncorrectTSArchiveNoOpenedErr: Label 'Incorrect Manager Time Sheet Archive No. opened';
        IncorrectPostingEntryOpenedErr: Label 'Incorrect Posting Entry No. page opened';
        IncorrectPostingEntryQuantityErr: Label 'Incorrect Posting Entry Quantity';
        IsInitialized: Boolean;
        IncorrectHRUnitOfMeasureTableRelationErr: Label 'The field Unit of Measure Code of table Cause of Absence contains a value (%1) that cannot be found in the related table (Human Resource Unit of Measure)', Locked = true;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"RES Time Sheets Creation");
        SetUp();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"RES Time Sheets Creation");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"RES Time Sheets Creation");
    end;

    local procedure SetUp()
    var
        ResourcesSetup: Record "Resources Setup";
        Resource: Record Resource;
        UserSetup: Record "User Setup";
    begin
        LibraryTimeSheet.Initialize();
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        ResourcesSetup.Get();
        // clear "Time Sheet Owner User ID"
        Resource.ModifyAll("Time Sheet Owner User ID", '');
    end;

    local procedure TearDown()
    begin
        asserterror Error(Text001Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkResourceToNonExistUser()
    var
        Resource: Record Resource;
    begin
        // Test case checks that Resource cannot be linked with non-existent USER ID
        Initialize();

        // 1. Create User ID, Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        // 2. Fill 'User ID' field with non-existent User ID
        asserterror Resource.Validate("Time Sheet Owner User ID", NonExistentUserErr);
        // 3. Verify: Verify User does not exist error message.
        Assert.AssertPrimRecordNotFound();

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkResourceToNonExistManager()
    var
        Resource: Record Resource;
    begin
        // Test case checks that Resource cannot be linked with non-existent Time Sheet Owner USER ID
        Initialize();

        // 1. Create User ID, Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        // 2. Fill 'Manager User ID' field with non-existent User ID
        asserterror Resource.Validate("Time Sheet Approver User ID", NonExistentUserErr);
        // 3. Verify: Verify User does not exist error message.
        Assert.AssertPrimRecordNotFound();

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeResourceUserIDNoTS()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
    begin
        // Test case checks that Resource field Time Sheet Owner User ID can be changed
        Initialize();

        // 1. Create User ID, Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        // 2. Add new User ID
        if not UserSetup.Get(NewUserIDTok) then begin
            UserSetup."User ID" := NewUserIDTok;
            UserSetup.Insert();
        end;
        // 3. Modify Time Sheet Owner User ID field
        Resource.Validate("Time Sheet Owner User ID", NewUserIDTok);
        // 4. Check that Time Sheet Owner User ID was modified
        Assert.AreEqual(Resource."Time Sheet Owner User ID", NewUserIDTok, SameUserIDMessageErr);
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteResourceLinkedWithUserID()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        ResourceNo: Text[30];
    begin
        // Test case checks that Resource cannot be linked with non-existent USER ID
        Initialize();

        // 1. Create User Setup (User ID)
        LibraryTimeSheet.CreateUserSetup(UserSetup, false);
        // 2. Create Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        // 3. Setup Time Sheet functionality for Resource
        SetupTSResourceUserID(Resource, UserSetup);
        // 4. Delete Resource
        ResourceNo := Resource."No.";
        Resource.Delete();

        Resource.Reset();
        Resource.SetRange("No.", ResourceNo);
        // 5. Check that Resource was deleted
        Assert.IsFalse(Resource.FindFirst(), ResourceIsNotDeletedErr);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteResourceWithUseTimesheet()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // Test case check that Resource with non-posted Timesheets cannot be deleted
        Initialize();

        // 1. Create User Setup, Resource, Time Sheet
        LibraryTimeSheet.InitResourceScenario(TimeSheetHeader, TimeSheetLine, true);
        Resource.Get(TimeSheetHeader."Resource No.");
        // 2. Try to Delete Resource
        asserterror Resource.Delete(true);
        // 3. Verify: Verify User cannot be deleted error message.
        Assert.ExpectedError(StrSubstNo(YouCannotDeleteResourceErr, Resource."No."));

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimesheetFuncRemoveWithUseTS()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // Test case check that "Use Time Sheet" option cannot be unchecked when not posted Time Sheet exists
        Initialize();

        // 1. Create User Setup, Resource, Time Sheet
        LibraryTimeSheet.InitResourceScenario(TimeSheetHeader, TimeSheetLine, true);
        Resource.Get(TimeSheetHeader."Resource No.");
        // 2. Try to set Use Time Sheet = False (Turn off Time Sheet functionality for Resource)
        asserterror Resource.Validate("Use Time Sheet", false);
        // 3. Verify: Verify Field cannot be changed error message.
        Assert.IsTrue(StrPos(GetLastErrorText, UseTimeSheetCannotBeChangedErr) > 0, ErrorGeneratedIncorrectErr);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimesheetForMultipleResource()
    var
        UserSetup1: Record "User Setup";
        UserSetup2: Record "User Setup";
        Resource1: Record Resource;
        AccountingPeriod: Record "Accounting Period";
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        Resource2: Record Resource;
        ResourcesSetup: Record "Resources Setup";
        CreateTimeSheets: Report "Create Time Sheets";
    begin
        // Test case check creation of Time Sheets for multiple Resources
        Initialize();

        // 1. Create user setup (User ID1, User ID2)
        LibraryTimeSheet.CreateUserSetup(UserSetup1, false);
        LibraryTimeSheet.CreateUserSetup(UserSetup2, false);
        // 2. Create Resource 1 and setup Time Sheet functionality
        LibraryTimeSheet.CreateTimeSheetResource(Resource1);
        SetupTSResourceUserID(Resource1, UserSetup1);
        // 3. Create Resource 2 and setup Time Sheet functionality
        LibraryTimeSheet.CreateTimeSheetResource(Resource2);
        SetupTSResourceUserID(Resource2, UserSetup2);

        // 4. find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);

        // 5. find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);

        // 6. Create 1 Time Sheet
        CreateTimeSheets.InitParameters(Date."Period Start", 1, StrSubstNo('%1|%2', Resource1."No.", Resource2."No."), false, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run();

        // 7. Verify that time sheet is created for both Resources
        TimeSheetHeader.SetRange("Resource No.", Resource1."No.");
        Assert.IsTrue(TimeSheetHeader.FindFirst(), TimeSheetDoesNotExistErr);
        TimeSheetHeader.SetRange("Resource No.", Resource2."No.");
        Assert.IsTrue(TimeSheetHeader.FindFirst(), TimeSheetDoesNotExistErr);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetResourceNoUseTS()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        AccountingPeriod: Record "Accounting Period";
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        ResourcesSetup: Record "Resources Setup";
        CreateTimeSheets: Report "Create Time Sheets";
    begin
        // Test case checks that Time Sheets are not created for Resource with Use Time Sheet = false
        Initialize();

        // 1. Create user setup (User ID1)
        LibraryTimeSheet.CreateUserSetup(UserSetup, false);

        // 2. Create Resource and setup Time Sheet functionality
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);
        // 3. Set Use Time Sheet = false for Resource
        Resource.Validate("Use Time Sheet", false);
        Resource.Modify();

        // 4. Find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);

        // 5. Find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);

        // 6. Create Time sheet
        CreateTimeSheets.InitParameters(Date."Period Start", 1, Resource."No.", false, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run();
        // 7. Verify that time sheet is not created as Use Time Sheet = false for Resource
        TimeSheetHeader.Reset();
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
        Assert.IsFalse(TimeSheetHeader.FindFirst(), 'Time sheet is created, but should not.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SamePeriodTimesheet()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
    begin
        // Test case checks that Time Sheets cannot be created twice for the same period
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Create 1 extra time sheet for the same period
        TimeSheetCreate(Date."Period Start", 1, Resource, TimeSheetHeader);
        // 3. Verify that extra time sheet was not created
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
        Assert.IsTrue(TimeSheetHeader.Count = 1, 'Time Sheet is not created');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimesheetRandomFirstWeekDay()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        AccountingPeriod: Record "Accounting Period";
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        ResourcesSetup: Record "Resources Setup";
    begin
        // Test case checks that if Time Sheet First Weekday = Any Day of week, created time sheets begin from the same day
        Initialize();

        // 1. Create User Setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, false);
        // 2. Create new Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        // 3. Setup Time Sheet functionality for Resource
        SetupTSResourceUserID(Resource, UserSetup);
        // 4. Set Time Sheet First Weekday = random day of week in Resources Setup
        ResourcesSetup.FindFirst();
        ResourcesSetup."Time Sheet First Weekday" := LibraryRandom.RandInt(6);
        ResourcesSetup.Modify();
        // 5. find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        // 6. find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);
        // 7. Create 1 Time Sheet
        TimeSheetCreate(Date."Period Start", 1, Resource, TimeSheetHeader);
        // 8. Verify time sheet was created and Start Date = First Weekday
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
        Assert.IsTrue(TimeSheetHeader.FindFirst(), TimeSheetDoesNotExistErr);
        Assert.IsTrue(
          Date2DWY(TimeSheetHeader."Starting Date", 1) = ResourcesSetup."Time Sheet First Weekday" + 1,
          'Time Sheet first weekday differs from Resources Setup');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimesheetChangeFWeekDayError()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        AccountingPeriod: Record "Accounting Period";
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        ResourcesSetup: Record "Resources Setup";
        TempInt1: Integer;
        TempInt2: Integer;
    begin
        // Test case checks error appears when trying to change Time Sheet First Weekday with already created Time Sheets
        Initialize();

        // 1. Create user setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, false);
        // 2. Create new Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        // 3. Setup Time Sheet functionality for Resource
        SetupTSResourceUserID(Resource, UserSetup);
        TempInt1 := LibraryRandom.RandInt(6);
        // 4. Set Time Sheet First Weekday = any day of week in Resources Setup
        ResourcesSetup.FindFirst();
        ResourcesSetup."Time Sheet First Weekday" := TempInt1;
        ResourcesSetup.Modify();
        // 5. Find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        // 6. Find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);
        // 7. Create 1 Time Sheet
        TimeSheetCreate(Date."Period Start", 1, Resource, TimeSheetHeader);
        // 8. Verify time sheet was created
        ValidateTimeSheetCreated(TimeSheetHeader, Resource);
        // 9. Select another random day of week that differs from defined in setup
        repeat
            TempInt2 := LibraryRandom.RandInt(6);
        until TempInt2 <> TempInt1;
        // 10. Try to change Time Sheet First Weekday
        asserterror ResourcesSetup.Validate("Time Sheet First Weekday", TempInt2);
        // 11. check that correct error message appears
        Assert.IsTrue(StrPos(GetLastErrorText, FirstWeekDayCannotBeChangedErr) > 0, ErrorGeneratedIncorrectErr);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimesheetJobTaskforResource()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Date: Record Date;
        Job: Record Job;
        JobTask: Record "Job Task";
        LibraryJob: Codeunit "Library - Job";
    begin
        // Verify that Time Sheet fields Job No./Job Task No. cannot be filled for line of Resource type
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Create Job
        LibraryJob.CreateJob(Job);
        // 3. Set Person Responsible = created Resource
        Job.Validate("Person Responsible", Resource."No.");
        Job.Modify();
        // 4. Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);
        // 5. Set custom Job Task Description
        JobTask.Validate(Description, 'Job Task Description Test');
        JobTask.Modify();
        // 6. Open Time Sheet and add line with type Resource but fill Job No.
        TimeSheetLine.Init();
        TimeSheetLine."Time Sheet No." := TimeSheetHeader."No.";
        asserterror TimeSheetLine.Validate("Job No.", Job."No.");
        // 7. Validate correct error message appeared
        Assert.ExpectedTestFieldError(TimeSheetLine.FieldCaption(Type), Format(TimeSheetLine.Type::Job));

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimesheetJobPosting()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        Job1: Record Job;
        JobTask1: Record "Job Task";
        Job2: Record Job;
        JobTask2: Record "Job Task";
        JobJnlLine: Record "Job Journal Line";
        TempDec1: Decimal;
        TempDec2: Decimal;
    begin
        // Verify that approved Job Time Sheet lines are correctly suggested for Multiple Jobs

        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Create Job, Job Task, Job Planning Lines
        CreateJobPlanning(Resource, Job1, JobTask1, Date);
        CreateJobPlanning(Resource, Job2, JobTask2, Date);

        // 3. create and approve 2 Job type lines
        TempDec1 := GetRandomDecimal();
        CreateJobTSLineApprove(TimeSheetHeader, Job1."No.", JobTask1."Job Task No.", TimeSheetHeader."Starting Date", TempDec1);

        TempDec2 := GetRandomDecimal();
        CreateJobTSLineApprove(TimeSheetHeader, Job2."No.", JobTask2."Job Task No.", TimeSheetHeader."Starting Date", TempDec2);

        // 5. Open Job Journal and suggest lines from Time Sheet
        SuggestJobJournalLines(JobJnlLine, TimeSheetHeader, StrSubstNo('%1|%2', Job1."No.", Job2."No."),
          StrSubstNo('%1|%2', JobTask1."Job Task No.", JobTask2."Job Task No."));
        // 6. Validate Lines for Job 1
        ValidateJobJournal(TimeSheetHeader, JobTask1, TempDec1);
        ValidateJobJournal(TimeSheetHeader, JobTask2, TempDec2);
        TearDown();
    end;

    [Test]
    procedure TimesheetJobPostingWithDateInDescription()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        Job1, Job2 : Record Job;
        JobTask1, JobTask2 : Record "Job Task";
        JobJnlLine: Record "Job Journal Line";
        RandomDec1, RandomDec2 : Decimal;
    begin
        // Verify that approved Job Time Sheet lines are correctly suggested for Multiple Jobs
        Initialize();

        // [GIVEN] User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);

        // [GIVEN] System is configured to include time sheets date in generated journal lines
        SetIncludeTimeSheetDateInJournal();

        // [GIVEN] Job, Job Task, Job Planning Lines exists
        CreateJobPlanning(Resource, Job1, JobTask1, Date);
        CreateJobPlanning(Resource, Job2, JobTask2, Date);

        // [GIVEN] 2 Job type lines exist and are approved
        RandomDec1 := GetRandomDecimal();
        CreateJobTSLineApprove(TimeSheetHeader, Job1."No.", JobTask1."Job Task No.", TimeSheetHeader."Starting Date", RandomDec1);
        RandomDec2 := GetRandomDecimal();
        CreateJobTSLineApprove(TimeSheetHeader, Job2."No.", JobTask2."Job Task No.", TimeSheetHeader."Starting Date", RandomDec2);

        // [WHEN] Open Job Journal and suggest lines from Time Sheet
        SuggestJobJournalLines(JobJnlLine, TimeSheetHeader, StrSubstNo('%1|%2', Job1."No.", Job2."No."), StrSubstNo('%1|%2', JobTask1."Job Task No.", JobTask2."Job Task No."));

        // [THEN] Lines are valid and have date in description
        ValidateJobJournalWithDateInDescription(TimeSheetHeader, JobTask1, RandomDec1);
        ValidateJobJournalWithDateInDescription(TimeSheetHeader, JobTask2, RandomDec2);
        TearDown();
    end;

    local procedure SetIncludeTimeSheetDateInJournal()
    var
        ResourcesSetup: Record "Resources Setup";
    begin
        ResourcesSetup.Get();
        ResourcesSetup."Incl. Time Sheet Date in Jnl." := true;
        ResourcesSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimesheetAbsenceWOutEmployee()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        AccountingPeriod: Record "Accounting Period";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Date: Record Date;
        ResourcesSetup: Record "Resources Setup";
        CauseOfAbsence: Record "Cause of Absence";
    begin
        // Verify that Time Sheet line with Type Absence cannot be created when no Employee is linked with Resource
        Initialize();

        // 1. Create user setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        // 2. Create new Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);
        // 3. Find random Cause of Absence
        LibraryTimeSheet.FindCauseOfAbsence(CauseOfAbsence);
        // 4. Find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        // 5. Find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);
        // 6. Create 1 Time Sheet
        TimeSheetCreate(Date."Period Start", 1, Resource, TimeSheetHeader);
        // 7. Try to create line with Cause of Absence Code
        asserterror
          LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Absence, '', '', '', CauseOfAbsence.Code);
        Assert.ExpectedError(StrSubstNo(ThereIsNoEmployeeLinkedWithResErr, TimeSheetHeader."Resource No."));

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimesheetJobPlanningReport()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        AccountingPeriod: Record "Accounting Period";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Date: Record Date;
        Job: Record Job;
        JobTask: Record "Job Task";
        ResourcesSetup: Record "Resources Setup";
        CreateTimeSheets: Report "Create Time Sheets";
    begin
        // Verify that Time Sheet fields Job No./Job Task No. are suggested by report if option Create lines from Job Planning is On
        Initialize();

        // 1. Create user setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        // 2. Create Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);
        // 3. find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        // 4. find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);
        // 5. Create Job, Job Task and Job Planning lines
        CreateJobPlanning(Resource, Job, JobTask, Date);
        // 6. Create time sheet
        CreateTimeSheets.InitParameters(Date."Period Start", 1, Resource."No.", true, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run();
        // 7. Validate Time Sheet was created
        ValidateTimeSheetCreated(TimeSheetHeader, Resource);
        // 8. Validate that lines were successfully suggested by report with correct Job No./Job Task No.
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.FindLast();
        TimeSheetLine.TestField(Type, TimeSheetLine.Type::Job);
        TimeSheetLine.TestField("Job No.", Job."No.");
        TimeSheetLine.TestField("Job Task No.", JobTask."Job Task No.");

        TearDown();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TimesheetPostedStatus()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Date: Record Date;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJnlLine: Record "Job Journal Line";
        ResJnlLine: Record "Res. Journal Line";
        DayTimeAllocation1: array[7] of Decimal;
        DayTimeAllocation2: array[7] of Decimal;
    begin
        // Test case to check that Time Sheet line after posting has Posted = True value
        Initialize();

        // 1. Create Resource and 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Create Job, Job Task, Job Planning lines
        CreateJobPlanning(Resource, Job, JobTask, Date);
        // 3. Add Time Sheet line with Type = Resource
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
        TimeSheetLine.Description := Format(CreateGuid());
        TimeSheetLine.Modify();
        GenerateTimeAllocation2(DayTimeAllocation1, TimeSheetHeader, TimeSheetLine);
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);

        // 4. Add Time Sheet line with Type = Job
        LibraryTimeSheet.CreateTimeSheetLine(
          TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Job, Job."No.", JobTask."Job Task No.", '', '');
        GenerateTimeAllocation2(DayTimeAllocation2, TimeSheetHeader, TimeSheetLine);
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);
        // 5. Suggest Job Journal Lines
        SuggestJobJournalLines(JobJnlLine, TimeSheetHeader, Job."No.", JobTask."Job Task No.");
        // 6. Post Job Journal Lines
        PostJobJournal(JobJnlLine, TimeSheetHeader);
        // 7. Suggest Resource Journal Lines
        SuggestResourceJnlLines(ResJnlLine, TimeSheetHeader, TimeSheetHeader."Ending Date");
        // 8. Post Resource Journal lines
        PostResourceJournal(ResJnlLine, TimeSheetHeader);
        // 9. Validate both Time Sheet lines have Posted = True
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.FindSet();
        repeat
            TimeSheetLine.TestField(Posted, true);
        until TimeSheetLine.Next() = 0;

        TearDown();
    end;

    [Test]
    [HandlerFunctions('TimeSheetPostingEntryHandler')]
    [Scope('OnPrem')]
    procedure TimesheetPostingEntriesValidate()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ResJnlLine: Record "Res. Journal Line";
        ManagerTimeSheet: TestPage "Manager Time Sheet";
    begin
        // Test case to validate Posting Entries page values
        Initialize();

        Clear(GlobalTimeSheetNo);
        // 1. Create Time Sheet with Resource Type Line
        LibraryTimeSheet.InitResourceScenario(TimeSheetHeader, TimeSheetLine, true);
        Resource.Get(TimeSheetHeader."Resource No.");
        GlobalTimeSheetNo := TimeSheetHeader."No.";
        // 6. Suggest Resource Journal Lines
        SuggestResourceJnlLines(ResJnlLine, TimeSheetHeader, TimeSheetHeader."Ending Date");
        // 7. Post Resource Journal lines
        PostResourceJournal(ResJnlLine, TimeSheetHeader);
        // 8. Open Posting Entries page from Manager Time Sheet and validate values
        ManagerTimeSheet.OpenEdit();
        ManagerTimeSheet.CurrTimeSheetNo.Value := GlobalTimeSheetNo;
        ManagerTimeSheet."Posting E&ntries".Invoke();

        TearDown();
    end;

    [Test]
    [HandlerFunctions('TSArchiveHandlMSG,TimeSheetPostingEntryHandler')]
    [Scope('OnPrem')]
    procedure TimesheetManagerArchivePage()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ResJnlLine: Record "Res. Journal Line";
        MoveTimeSheetsToArchive: Report "Move Time Sheets to Archive";
        ManagerTimeSheetArchive: TestPage "Manager Time Sheet Archive";
        ManagerTSArchiveList: TestPage "Manager Time Sheet Arc. List";
        TimeSheet2No: Code[20];
        Counter: Integer;
    begin
        // Test case to check that Manager can overview archived Time Sheets
        Initialize();

        // 1. Create Resource and 2 Time Sheets, Submit, Approve, Suggest and post Resource Lines
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 2);
        GlobalTimeSheetNo := TimeSheetHeader."No.";
        for Counter := 1 to 2 do begin
            LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
            GenerateTimeAllocation2(DayTimeAllocation, TimeSheetHeader, TimeSheetLine);
            TimeSheetApprovalMgt.Submit(TimeSheetLine);
            TimeSheetApprovalMgt.Approve(TimeSheetLine);
            ResJnlLine.Reset();
            SuggestResourceJnlLines(ResJnlLine, TimeSheetHeader, TimeSheetHeader."Ending Date");
            PostResourceJournal(ResJnlLine, TimeSheetHeader);
            TimeSheetHeader.Next();
        end;
        TimeSheet2No := TimeSheetHeader."No.";
        // 2. Move Time Sheets to Archive
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
        MoveTimeSheetsToArchive.SetTableView(TimeSheetHeader);
        MoveTimeSheetsToArchive.UseRequestPage(false);
        MoveTimeSheetsToArchive.Run();
        // 3. Open Manager Time Sheet Archive List, then open Manager Time Sheet and validate No.
        ManagerTSArchiveList.OpenView();
        ManagerTSArchiveList.FILTER.SetFilter("No.", GlobalTimeSheetNo);
        ManagerTimeSheetArchive.Trap();
        ManagerTSArchiveList."&View Time Sheet".Invoke();
        Assert.AreEqual(ManagerTimeSheetArchive.CurrTimeSheetNo.Value, GlobalTimeSheetNo, IncorrectTSArchiveNoOpenedErr);
        // 4. Validate Previous/Next Period works correctly
        ManagerTimeSheetArchive.CurrTimeSheetNo.Value := GlobalTimeSheetNo;
        ManagerTimeSheetArchive."&Next Period".Invoke();

        Assert.AreEqual(ManagerTimeSheetArchive.CurrTimeSheetNo.Value, TimeSheet2No, IncorrectTSArchiveNoOpenedErr);
        ManagerTimeSheetArchive."&Previous Period".Invoke();
        Assert.AreEqual(ManagerTimeSheetArchive.CurrTimeSheetNo.Value, GlobalTimeSheetNo, IncorrectTSArchiveNoOpenedErr);
        // 5. Open Posting Entries and validate
        ManagerTimeSheetArchive."Posting E&ntries".Invoke();
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetVerifyMyTimeSheetsCurrentUserTSOwner()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        InitialRecordCount: Integer;
        PostRecordCount: Integer;
    begin
        // Verify that Time Sheet fields Job No./Job Task No. can be filled in lines
        Initialize();


        // [GIVEN] Get a record count of My Time Sheets for current user before creating a timesheet
        InitialRecordCount := GetMyTimeSheetRecordCount();

        // [WHEN] User setup, Resource, and 1 Time Sheet created with current user
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        Commit();
        PostRecordCount := GetMyTimeSheetRecordCount();

        // [THEN] Record count for current user has increased by 1.
        Assert.AreEqual(PostRecordCount, InitialRecordCount + 1, 'Count of MyTimeSheet records should have increased.');

        // [WHEN] Time Sheet Header is deleted
        TimeSheetHeader.Delete(true);
        Commit();
        PostRecordCount := GetMyTimeSheetRecordCount();

        // [THEN] Number of records is back to what it was when test was started
        Assert.AreEqual(PostRecordCount, InitialRecordCount, 'Count of MyTimeSheet records is incorrect.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetVerifyMyTimeSheetsNoTSOwner()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        InitialRecordCount: Integer;
        PostRecordCount: Integer;
    begin
        // Verify that Time Sheet fields Job No./Job Task No. can be filled in lines
        Initialize();


        // [GIVEN] Get a record count of My Time Sheets for current user before creating a timesheet
        InitialRecordCount := GetMyTimeSheetRecordCount();

        // [WHEN] User setup, Resource, and 1 Time Sheet created with non-current user
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, false);
        Commit();
        PostRecordCount := GetMyTimeSheetRecordCount();

        // [THEN] Same number of records exist for current user after creating the timesheet
        Assert.AreEqual(PostRecordCount, InitialRecordCount, 'Count of MyTimeSheet records should still be the same.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_AssignHumanResourceUOMForCauseOfAbsence()
    var
        CauseOfAbsence: Record "Cause of Absence";
        HumanResourceUnitOfMeasure: Record "Human Resource Unit of Measure";
    begin
        // [FEATURE] [UT] [Employee] [Unit of Measure]
        // [SCENARIO 382310] Stan can assign "Human Resource Unit of Measure" in "Cause of Absense"

        Initialize();
        LibraryTimeSheet.CreateHRUnitOfMeasure(HumanResourceUnitOfMeasure, 1);
        CauseOfAbsence.Init();
        CauseOfAbsence.Validate("Unit of Measure Code", HumanResourceUnitOfMeasure.Code);

        CauseOfAbsence.TestField("Unit of Measure Code", HumanResourceUnitOfMeasure.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ErrorWhenAssignNormalUOMForCauseOfAbsence()
    var
        CauseOfAbsence: Record "Cause of Absence";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [UT] [Employee] [Unit of Measure]
        // [SCENARIO 382310] Stan cannot assign normal "Unit of Measure" in "Cause of Absense"

        Initialize();
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        CauseOfAbsence.Init();
        asserterror CauseOfAbsence.Validate("Unit of Measure Code", UnitOfMeasure.Code);

        Assert.ExpectedError(StrSubstNo(IncorrectHRUnitOfMeasureTableRelationErr, UnitOfMeasure.Code));
    end;

    local procedure FindResourceJournalBatch(var ResJournalBatch: Record "Res. Journal Batch")
    var
        ResJournalTemplate: Record "Res. Journal Template";
    begin
        ResJournalTemplate.SetRange(Recurring, false);
        LibraryResource.FindResJournalTemplate(ResJournalTemplate);
        LibraryResource.FindResJournalBatch(ResJournalBatch, ResJournalTemplate.Name);
        ResJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        ResJournalBatch.Modify(true);
    end;

    local procedure SetupTSResourceUserID(var Resource: Record Resource; UserSetup: Record "User Setup")
    begin
        Resource.Validate("Time Sheet Owner User ID", UserSetup."User ID");
        Resource.Validate("Time Sheet Approver User ID", UserSetup."User ID");
        Resource.Modify();
    end;

    local procedure TimeSheetCreate(Date: Date; NoOfPeriods: Integer; var Resource: Record Resource; var TimeSheetHeader: Record "Time Sheet Header")
    var
        CreateTimeSheets: Report "Create Time Sheets";
    begin
        // Create time sheet
        CreateTimeSheets.InitParameters(Date, NoOfPeriods, Resource."No.", false, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run();
        // Validate Time Sheet was created
        ValidateTimeSheetCreated(TimeSheetHeader, Resource);
    end;

    [Normal]
    local procedure ValidateTimeSheetCreated(var TimeSheetHeader: Record "Time Sheet Header"; Resource: Record Resource)
    begin
        TimeSheetHeader.Reset();
        TimeSheetHeader.SetFilter("Resource No.", Resource."No.");
        Assert.IsTrue(TimeSheetHeader.FindFirst(), 'Time Sheet is not created');
    end;

    local procedure FindFirstDOW(AccountingPeriod: Record "Accounting Period"; var Date: Record Date; var ResourcesSetup: Record "Resources Setup")
    begin
        // find first DOW after accounting period starting date
        Date.SetRange("Period Type", Date."Period Type"::Date);
        Date.SetFilter("Period Start", '%1..', AccountingPeriod."Starting Date");
        Date.SetRange("Period No.", ResourcesSetup."Time Sheet First Weekday" + 1);
        Date.FindFirst();
    end;

    local procedure FindJobJournalBatch(var JobJournalBatch: Record "Job Journal Batch")
    var
        JobJournalTemplate: Record "Job Journal Template";
    begin
        JobJournalTemplate.SetRange(Recurring, false);
        LibraryTimeSheet.FindJobJournalTemplate(JobJournalTemplate);
        LibraryTimeSheet.FindJobJournalBatch(JobJournalBatch, JobJournalTemplate.Name);
    end;

    local procedure GenerateTimeAllocation2(var DayTimeAllocation: array[7] of Decimal; TimeSheetHeader: Record "Time Sheet Header"; TimeSheetLine: Record "Time Sheet Line")
    var
        Counter: Integer;
    begin
        for Counter := 1 to 7 do begin
            DayTimeAllocation[Counter] := GetRandomDecimal();
            LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetHeader."Starting Date" + Counter - 1, DayTimeAllocation[Counter]);
        end;
    end;

    local procedure GenerateResourceTimeSheet(var Resource: Record Resource; var Date: Record Date; var TimeSheetHeader: Record "Time Sheet Header"; CurrentUser: Boolean)
    var
        UserSetup: Record "User Setup";
        AccountingPeriod: Record "Accounting Period";
        ResourcesSetup: Record "Resources Setup";
    begin
        // create user setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, CurrentUser);
        // Create Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);

        // find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);

        // find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);

        // create time sheet
        TimeSheetCreate(Date."Period Start", 1, Resource, TimeSheetHeader);
    end;

    local procedure SuggestResourceJnlLines(var ResJnlLine: Record "Res. Journal Line"; TimeSheetHeader: Record "Time Sheet Header"; EndDate: Date)
    var
        SuggestResJnlLines: Report "Suggest Res. Jnl. Lines";
    begin
        PrepareResourceJournal(ResJnlLine);
        SuggestResJnlLines.InitParameters(
          ResJnlLine,
          TimeSheetHeader."Resource No.",
          TimeSheetHeader."Starting Date",
          EndDate);
        SuggestResJnlLines.UseRequestPage(false);
        SuggestResJnlLines.Run();
    end;

    local procedure PrepareResourceJournal(var ResJnlLine: Record "Res. Journal Line")
    var
        ResJnlBatch: Record "Res. Journal Batch";
    begin
        // Empty Resource Journal Line table
        FindResourceJournalBatch(ResJnlBatch);
        ResJnlLine.Reset();
        ResJnlLine.DeleteAll();

        ResJnlLine."Journal Template Name" := ResJnlBatch."Journal Template Name";
        ResJnlLine."Journal Batch Name" := ResJnlBatch.Name;
    end;

    local procedure PostResourceJournal(ResJnlLine: Record "Res. Journal Line"; TimeSheetHeader: Record "Time Sheet Header")
    var
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
    begin
        // find and post created journal lines
        ResJnlLine.Reset();
        ResJnlLine.SetRange("Journal Template Name", ResJnlLine."Journal Template Name");
        ResJnlLine.SetRange("Journal Batch Name", ResJnlLine."Journal Batch Name");
        ResJnlLine.SetRange("Resource No.", TimeSheetHeader."Resource No.");
        Assert.IsTrue(ResJnlLine.FindSet(), 'Resource journal lines have not been found');
        Clear(ResJnlPostLine);
        repeat
            ResJnlPostLine.Run(ResJnlLine);
        until ResJnlLine.Next() = 0;
    end;

    local procedure CreateJobPlanning(Resource: Record Resource; var Job: Record Job; var JobTask: Record "Job Task"; Date: Record Date)
    var
        JobPlanningLine: Record "Job Planning Line";
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Person Responsible", Resource."No.");
        Job.Modify();
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate(Description, 'Job Task Description Test');
        JobTask.Modify();

        JobPlanningLine.Init();
        JobPlanningLine."Job No." := Job."No.";
        JobPlanningLine."Job Task No." := JobTask."Job Task No.";
        JobPlanningLine."Planning Date" := Date."Period Start";
        JobPlanningLine."No." := Resource."No.";
        JobPlanningLine.Quantity := GetRandomDecimal();
        JobPlanningLine."Unit Cost" := GetRandomDecimal();
        JobPlanningLine.Insert();
    end;

    local procedure SuggestJobJournalLines(var JobJnlLine: Record "Job Journal Line"; TimeSheetHeader: Record "Time Sheet Header"; JobNo: Text[30]; JobTaskNo: Text[30])
    var
        SuggestJobJnlLines: Report "Suggest Job Jnl. Lines";
    begin
        PrepareJobJournal(JobJnlLine);
        SuggestJobJnlLines.InitParameters(
          JobJnlLine,
          TimeSheetHeader."Resource No.",
          JobNo,
          JobTaskNo,
          TimeSheetHeader."Starting Date",
          TimeSheetHeader."Ending Date");
        SuggestJobJnlLines.UseRequestPage(false);
        SuggestJobJnlLines.Run();
    end;

    local procedure PrepareJobJournal(var JobJnlLine: Record "Job Journal Line")
    var
        JobJnlBatch: Record "Job Journal Batch";
    begin
        JobJnlLine.Reset();
        JobJnlLine.DeleteAll();

        FindJobJournalBatch(JobJnlBatch);
        JobJnlLine."Journal Template Name" := JobJnlBatch."Journal Template Name";
        JobJnlLine."Journal Batch Name" := JobJnlBatch.Name;
    end;

    local procedure ValidateJobJournalWithDateInDescription(TimeSheetHeader: Record "Time Sheet Header"; JobTask: Record "Job Task"; Qty: Decimal)
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        ValidateJobJournal(JobJournalLine, TimeSheetHeader, JobTask, Qty);
        Assert.IsTrue(JobJournalLine.Description.StartsWith(Format(JobJournalLine."Time Sheet Date")), 'Description does not start with Time Sheet Date');
    end;

    local procedure ValidateJobJournal(TimeSheetHeader: Record "Time Sheet Header"; JobTask: Record "Job Task"; Qty: Decimal)
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        ValidateJobJournal(JobJournalLine, TimeSheetHeader, JobTask, Qty);
    end;

    local procedure ValidateJobJournal(var JobJournalLine: Record "Job Journal Line"; TimeSheetHeader: Record "Time Sheet Header"; JobTask: Record "Job Task"; Qty: Decimal)
    begin
        JobJournalLine.Reset();
        JobJournalLine.SetFilter("Time Sheet No.", TimeSheetHeader."No.");
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        JobJournalLine.SetRange(Type, JobJournalLine.Type::Resource);
        JobJournalLine.SetRange("No.", TimeSheetHeader."Resource No.");
        JobJournalLine.SetRange("Job Task No.", JobTask."Job Task No.");
        Assert.IsTrue(JobJournalLine.FindFirst(), StrSubstNo('Job journal line %1 is not found', JobJournalLine.GetFilters));
        Assert.AreEqual(Qty, JobJournalLine.Quantity, 'Incorrect Quantity field value');
    end;

    local procedure PostJobJournal(JobJnlLine: Record "Job Journal Line"; TimeSheetHeader: Record "Time Sheet Header")
    var
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
    begin
        // find and post created journal lines
        JobJnlLine.SetRange("Journal Template Name", JobJnlLine."Journal Template Name");
        JobJnlLine.SetRange("Journal Batch Name", JobJnlLine."Journal Batch Name");
        JobJnlLine.SetRange(Type, JobJnlLine.Type::Resource);
        JobJnlLine.SetRange("No.", TimeSheetHeader."Resource No.");
        Assert.IsTrue(JobJnlLine.FindSet(), 'Job journal lines have not been found');
        Clear(JobJnlPostLine);
        repeat
            JobJnlPostLine.Run(JobJnlLine);
        until JobJnlLine.Next() = 0;
    end;

    local procedure GetRandomDecimal(): Decimal
    begin
        exit(LibraryRandom.RandInt(9999) / 100);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TSArchiveHandlMSG(Message: Text[1024])
    begin
        if StrPos(Message, StrSubstNo(TimeSheetsHaveBeenMovedtoArchErr, 1)) < 0 then
            Assert.Fail(CopyStr('Incorrect message: ' + Message, 1, MaxStrLen(Message)));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure JobDimHandlMSG(Message: Text[1024]; var Reply: Boolean)
    begin
        case true of
            StrPos(Message, YouHaveChangedADimensionMsg) > 0,
          StrPos(Message, DoYouWantToUpdateTheLinesQst) > 0:
                Reply := true;
            else
                Assert.Fail(CopyStr('Incorrect confirm question: ' + Message, 1, MaxStrLen(Message)));
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetLineJobDetailHandler(var TimeSheetLineJobDetail: TestPage "Time Sheet Line Job Detail")
    begin
        TimeSheetLineJobDetail."Job No.".Value := GlobalJobNo;
        TimeSheetLineJobDetail."Job Task No.".Value := GlobalJobTaskNo;
        TimeSheetLineJobDetail.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ValidateTimeSheetLineJobDetailHandler(var TimeSheetLineJobDetail: TestPage "Time Sheet Line Job Detail")
    begin
        asserterror TimeSheetLineJobDetail."Job No.".Value := GlobalJobNo;
        TimeSheetLineJobDetail.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetAllocationHandler(var TimeSheetAllocation: TestPage "Time Sheet Allocation")
    begin
        // Handles Time Sheet Allocation page and fills Global values for verification
        Evaluate(GlobalTSAllocationValues[1], TimeSheetAllocation.TotalQty.Value);
        Evaluate(GlobalTSAllocationValues[2], TimeSheetAllocation.AllocatedQty.Value);
        Evaluate(GlobalTSAllocationValues[3], TimeSheetAllocation.DateQuantity1.Value);
        Evaluate(GlobalTSAllocationValues[4], TimeSheetAllocation.DateQuantity2.Value);
        Evaluate(GlobalTSAllocationValues[5], TimeSheetAllocation.DateQuantity3.Value);
        Evaluate(GlobalTSAllocationValues[6], TimeSheetAllocation.DateQuantity4.Value);
        Evaluate(GlobalTSAllocationValues[7], TimeSheetAllocation.DateQuantity5.Value);
        Evaluate(GlobalTSAllocationValues[8], TimeSheetAllocation.DateQuantity6.Value);
        Evaluate(GlobalTSAllocationValues[9], TimeSheetAllocation.DateQuantity7.Value);
        TimeSheetAllocation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetPostingEntryHandler(var TSPostingEntriesPage: TestPage "Time Sheet Posting Entries")
    var
        TimeSheetPostingEntry: Record "Time Sheet Posting Entry";
        Navigate: TestPage Navigate;
        TempDecimal: Decimal;
    begin
        // Handles Time Sheet Allocation page and validates
        TimeSheetPostingEntry.Reset();
        TimeSheetPostingEntry.SetRange("Time Sheet No.", GlobalTimeSheetNo);
        TimeSheetPostingEntry.FindFirst();
        Evaluate(TempDecimal, TSPostingEntriesPage.Quantity.Value);
        Assert.AreEqual(GlobalTimeSheetNo, Format(TSPostingEntriesPage."Time Sheet No.".Value), IncorrectPostingEntryOpenedErr);
        Assert.AreEqual(TimeSheetPostingEntry.Quantity, TempDecimal, IncorrectPostingEntryQuantityErr);
        // Validate Navigate can be opened from the page
        Navigate.Trap();
        TSPostingEntriesPage."&Navigate".Invoke();
        Navigate.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetLineResDetailHndl(var TimeSheetLineResDetail: TestPage "Time Sheet Line Res. Detail")
    begin
        TimeSheetLineResDetail.Description.Value := GlobalTextVariable;
        TimeSheetLineResDetail.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetLineAbsDetailHndl(var TimeSheetLineAbsDetail: TestPage "Time Sheet Line Absence Detail")
    begin
        TimeSheetLineAbsDetail.Description.Value := GlobalTextVariable;
        TimeSheetLineAbsDetail.OK().Invoke();
    end;

    local procedure CreateJobTSLineApprove(TimeSheetHeader: Record "Time Sheet Header"; JobNo: Code[20]; JobTaskNo: Code[20]; Date: Date; Qty: Decimal)
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Job, JobNo, JobTaskNo, '', '');
        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, Date, Qty);
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);
    end;

    local procedure CreateMultipleTimeSheet(var Resource: Record Resource; var TimeSheetHeader: Record "Time Sheet Header"; NoOfTimeSheets: Integer)
    var
        UserSetup: Record "User Setup";
        AccountingPeriod: Record "Accounting Period";
        Date: Record Date;
        ResourcesSetup: Record "Resources Setup";
    begin
        // 1. Create user setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        // 2. Create Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);
        // 3. Find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        // 4. Find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);
        // 5. Create 2 Time Sheets
        TimeSheetCreate(Date."Period Start", NoOfTimeSheets, Resource, TimeSheetHeader);
        TimeSheetHeader.Reset();
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [HandlerFunctions('NavigateHandler')]
    [Scope('OnPrem')]
    procedure NavigateHandler(var Navigate: TestPage Navigate)
    begin
        // Handles Navigate Page
        Navigate.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    local procedure GetMyTimeSheetRecordCount(): Integer
    var
        MyTimeSheets: Record "My Time Sheets";
    begin
        MyTimeSheets.SetRange("User ID", UserId);
        exit(MyTimeSheets.Count);
    end;
}
