codeunit 134120 "Price Source UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Source]
    end;

    var
        Assert: Codeunit Assert;
        LibraryJob: Codeunit "Library - Job";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ParentErr: Label 'Parent Source No. must be blank for %1 source type.', Comment = '%1 - source type value';

    [Test]
    procedure T000_InsertSourceWithoutValidation()
    var
        TempPriceSource: Record "Price Source" temporary;
    begin
        // [SCENARIO] Insert() without validation keeps "Entry No." unchanged.
        Initialize();
        TempPriceSource."Entry No." := 13;
        TempPriceSource.Insert();
        TempPriceSource.Testfield("Entry No.", 13);
    end;

    [Test]
    procedure T001_InsertFirstSourceWithValidation()
    var
        TempPriceSource: Record "Price Source" temporary;
    begin
        // [SCENARIO] First Insert() sets "Entry No." to 1.
        Initialize();

        TempPriceSource."Entry No." := 13;
        TempPriceSource.Insert(true);
        TempPriceSource.Testfield("Entry No.", 1);
    end;

    [Test]
    procedure T002_InsertSecondSourceWithValidation()
    var
        TempPriceSource: Record "Price Source" temporary;
    begin
        // [SCENARIO] Second Insert() with validation sets "Entry No." to last entry + 1, ignores actual "Entry No.".
        Initialize();

        TempPriceSource."Entry No." := 13;
        TempPriceSource.Insert();

        TempPriceSource."Entry No." := 1;
        TempPriceSource.Insert(true);
        TempPriceSource.Testfield("Entry No.", 14);
    end;

    [Test]
    procedure T005_ChangedSourceTypeValidation()
    var
        PriceSource: Record "Price Source";
    begin
        Initialize();
        // [GIVEN] Price Source, where all fields are filled, "Source Type" = 'Job Task'
        NewSourceJobTask(PriceSource);

        // [WHEN] Validate "Source Type" as 'Vendor'
        PriceSource.Validate("Source Type", PriceSource."Source Type"::Vendor);

        // [THEN] "Source No.", "Parent Source No.", "Source ID" are blank, "Source Type" = 'Vendor'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Vendor);
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T010_JobTask_ChangedSourceIDValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
    begin
        // [FEATURE] [Job Task]
        Initialize();
        // [GIVEN] Price Source, for Job Task #1, where all fields are filled, "Source ID" = 'X', "Source Type" = 'Job Task'
        NewSourceJobTask(PriceSource);
        // [GIVEN] Job Task #2, where "Source No." is A, "Parent Source No." is 'B', "Source ID" is 'Y'
        NewSourceJobTask(NewPriceSource);

        // [WHEN] Validate "Source ID" as 'Y'
        PriceSource.Validate("Source ID", NewPriceSource."Source Id");

        // [THEN] Price Source got values from Job Task #2:
        // [THEN] "Source No." is 'A', "Parent Source No." is 'B', "Source ID" = 'Y', "Source Type" = 'Job Task'
        PriceSource.Testfield("Source ID", NewPriceSource."Source Id");
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::"Job Task");
        PriceSource.Testfield("Parent Source No.", NewPriceSource."Parent Source No.");
        PriceSource.Testfield("Source No.", NewPriceSource."Source No.");
    end;

    [Test]
    procedure T011_JobTask_BlankSourceIDValidation()
    var
        PriceSource: Record "Price Source";
        BlankGuid: Guid;
    begin
        // [FEATURE] [Job Task]
        Initialize();
        // [GIVEN] Price Source, where all fields are filled, "Source ID" = 'X', "Source Type" = 'Job Task'
        NewSourceJobTask(PriceSource);

        // [WHEN] Validate "Source ID" as <blank>
        PriceSource.Validate("Source ID", BlankGuid);

        // [THEN] "Source No.", "Parent Source No." are blank, "Source ID" = <blank>, "Source Type" = 'Job Task'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::"Job Task");
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T012_JobTask_ChangedSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        JobNo: Code[20];
    begin
        // [FEATURE] [Job Task]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Job Task', "Job Task No." is 'JT', Job No." is 'J'
        NewSourceJobTask(PriceSource);
        JobNo := PriceSource."Parent Source No.";

        // [GIVEN] JobTask, where "Job Task No." is 'X', Job No." is 'J', SystemId is 'A'
        NewPriceSource."Parent Source No." := JobNo;
        NewSourceJobTask(NewPriceSource);

        // [WHEN] Validate "Source No." as 'X'
        PriceSource.Validate("Source No.", NewPriceSource."Source No.");

        // [THEN] "Source No." is 'X', "Parent Source No." = 'J', "Source ID" is 'A', "Source Type" = 'Job Task'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::"Job Task");
        PriceSource.Testfield("Parent Source No.", JobNo);
        PriceSource.Testfield("Source No.", NewPriceSource."Source No.");
        PriceSource.Testfield("Source ID", NewPriceSource."Source ID");
    end;

    [Test]
    procedure T013_JobTask_NotExistingSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        JobTask: Record "Job Task";
    begin
        // [FEATURE] [Job Task]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Job Task', "Job Task No." is 'JT', Job No." is 'J'
        NewSourceJobTask(PriceSource);

        // [GIVEN] JobTasks, where "Job Task No." is 'X', do not exist
        JobTask.SetRange("Job Task No.", 'X');
        JobTask.DeleteAll();

        // [WHEN] Validate "Source No." as 'X'
        PriceSource.Validate("Source No.", 'X');

        // [THEN] "Source No.", "Parent Source No.", "Source ID" are blank, "Source Type" = 'Job Task'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::"Job Task");
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T014_JobTask_ChangedParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        BlankGuid: Guid;
    begin
        // [FEATURE] [Job Task]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Job Task', "Job Task No." is 'JT1', Job No." is 'J1'
        NewSourceJobTask(PriceSource);
        // [GIVEN] Job Task, where "Job Task No." is 'JT2', Job No." is 'J2'
        NewSourceJobTask(NewPriceSource);

        // [WHEN] Validate "Parent Source No." as 'J2'
        PriceSource.Validate("Parent Source No.", NewPriceSource."Parent Source No.");

        // [THEN] "Source No." and "Source ID" are blank, "Parent Source No." = 'J2', "Source Type" = 'Job Task'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::"Job Task");
        PriceSource.Testfield("Parent Source No.", NewPriceSource."Parent Source No.");
        PriceSource.Testfield("Source No.", '');
        PriceSource.Testfield("Source ID", BlankGuid);
    end;

    [Test]
    procedure T015_JobTask_BlankParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        JobTask: Record "Job Task";
    begin
        // [FEATURE] [Job Task]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Job Task', "Job Task No." is 'JT', Job No." is 'J'
        NewSourceJobTask(PriceSource);

        // [GIVEN] JobTasks, where "Job Task No." is 'JT', do not exist
        JobTask.SetRange("Job Task No.", PriceSource."Source No.");
        JobTask.DeleteAll();

        // [WHEN] Validate "Parent Source No." as <blank>
        PriceSource.Validate("Parent Source No.", '');

        // [THEN] "Parent Source No.", "Filter Source No." and "Source No." are <blank>
        PriceSource.Testfield("Parent Source No.", '');
        PriceSource.Testfield("Source No.", '');
        PriceSource.Testfield("Filter Source No.", '');
    end;

    [Test]
    procedure T016_JobTask_IsSourceNoAllowed()
    var
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Job Task";
    begin
        // [FEATURE] [Job Task]
        Initialize();
        //IPriceSource := SourceType::"Job Task";
        Assert.IsTrue(IPriceSource.IsSourceNoAllowed(), 'IsSourceNoAllowed');
    end;

    [Test]
    [HandlerFunctions('NewJobTasksMPHandler,JobsMPHandler')]
    procedure T017_JobTask_IsLookupOKNewTask()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Job Task";
    begin
        // [FEATURE] [Job Task]
        Initialize();
        // [GIVEN] Two PriceSources, where "Source Type" = 'Job Task', "Parent Source" = 'J', "Source No." are 'A' and 'B'
        NewSourceJobTask(PriceSource);
        NewPriceSource."Parent Source No." := PriceSource."Parent Source No.";
        NewSourceJobTask(NewPriceSource);

        // [WHEN] Lookup source on Job Task 'A'
        LibraryVariableStorage.Enqueue(NewPriceSource."Source No."); // new Job Task No. for JobTasksMPHandler
        //IPriceSource := PriceSource."Source Type";
        Assert.IsTrue(IPriceSource.IsLookupOK(PriceSource), 'Lookup');

        // [THEN] Open page "Job List" and "Job Task List" and returned Job task 'B'
        PriceSource.TestField("Parent Source No.", NewPriceSource."Parent Source No.");
        PriceSource.TestField("Source No.", NewPriceSource."Source No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('JobTasksMPHandler,NewJobsMPHandler')]
    procedure T018_JobTask_IsLookupOKNewJob()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Job Task";
    begin
        // [FEATURE] [Job Task]
        Initialize();
        // [GIVEN] Two PriceSources, where "Source Type" = 'Job Task', "Parent Source No." = 'J1' and 'J2' "Source No." is 'JT'
        NewSourceJobTask(PriceSource);
        NewSourceJobTask(NewPriceSource);

        // [WHEN] Lookup source on Job Task 'A'
        LibraryVariableStorage.Enqueue(NewPriceSource."Parent Source No."); // new Job No. for JobsMPHandler
        //IPriceSource := PriceSource."Source Type";
        Assert.IsTrue(IPriceSource.IsLookupOK(PriceSource), 'Lookup');

        // [THEN] Open page "Job List" and "Job Task List" and returned Job task, where "Parent Source No." = 'J2' 
        PriceSource.TestField("Parent Source No.", NewPriceSource."Parent Source No.");
        PriceSource.TestField("Source No.", NewPriceSource."Source No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CancelJobsMPHandler')]
    procedure T019_JobTask_IsLookupOKCancelJob()
    var
        PriceSource: Record "Price Source";
        xPriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        IPriceSource: Codeunit "Price Source - Job Task";
    begin
        // [FEATURE] [Job Task]
        Initialize();
        // [GIVEN] Two PriceSources, where "Source Type" = 'Job Task', "Parent Source No." = 'J1' and 'J2' "Source No." is 'JT'
        NewSourceJobTask(PriceSource);
        xPriceSource := PriceSource;
        NewSourceJobTask(NewPriceSource);

        // [WHEN] Lookup source on Job Task 'A', and cancel "Job List"
        Assert.IsFalse(IPriceSource.IsLookupOK(PriceSource), 'Lookup');

        // [THEN] Open page "Job List" and "Job Task List" and returned Job task, where "Parent Source No." = 'J1' 
        PriceSource.TestField("Parent Source No.", xPriceSource."Parent Source No.");
        PriceSource.TestField("Source No.", xPriceSource."Source No.");
        PriceSource.TestField("Filter Source No.", xPriceSource."Parent Source No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T020_Job_ChangedSourceIDValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Price Source, for Job #1, where all fields are filled, "Source ID" = 'X', "Source Type" = 'Job'
        NewSourceJob(PriceSource);
        // [GIVEN] Job #2, where "Source No." is A, "Parent Source No." is 'B', "Source ID" is 'Y'
        NewSourceJob(NewPriceSource);

        // [WHEN] Validate "Source ID" as 'Y'
        PriceSource.Validate("Source ID", NewPriceSource."Source Id");

        // [THEN] Price Source got values from Job #2:
        // [THEN] "Source No." is 'A', "Parent Source No." is <blank>, "Source ID" = 'Y', "Source Type" = 'Job'
        PriceSource.Testfield("Source ID", NewPriceSource."Source Id");
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Job);
        PriceSource.Testfield("Parent Source No.", '');
        PriceSource.Testfield("Source No.", NewPriceSource."Source No.");
        PriceSource.Testfield("Filter Source No.", NewPriceSource."Source No.");
    end;

    [Test]
    procedure T021_Job_BlankSourceIDValidation()
    var
        PriceSource: Record "Price Source";
        BlankGuid: Guid;
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Price Source, where all fields are filled, "Source ID" = 'X', "Source Type" = 'Job'
        NewSourceJob(PriceSource);

        // [WHEN] Validate "Source ID" as <blank>
        PriceSource.Validate("Source ID", BlankGuid);

        // [THEN] "Source No.", "Parent Source No." are blank, "Source ID" = <blank>, "Source Type" = 'Job'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Job);
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T022_Job_ChangedSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        JobNo: Code[20];
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Job', Job No." is 'J1'
        NewSourceJob(PriceSource);
        JobNo := PriceSource."Parent Source No.";

        // [GIVEN] Job, where Job No." is 'J2', SystemId is 'A'
        NewSourceJob(NewPriceSource);

        // [WHEN] Validate "Source No." as 'J2'
        PriceSource.Validate("Source No.", NewPriceSource."Source No.");

        // [THEN] "Source No." is 'X', "Parent Source No." is <blank>, "Source ID" is 'A', "Source Type" = 'Job'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Job);
        PriceSource.Testfield("Parent Source No.", '');
        PriceSource.Testfield("Source No.", NewPriceSource."Source No.");
        PriceSource.Testfield("Source ID", NewPriceSource."Source ID");
        PriceSource.Testfield("Filter Source No.", NewPriceSource."Source No.");
    end;

    [Test]
    procedure T023_Job_NotExistingSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        Job: Record Job;
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Job', Job No." is 'J'
        NewSourceJob(PriceSource);

        // [GIVEN] Job, where "No." is 'X', does not exist
        Job.SetRange("No.", 'X');
        Job.DeleteAll();

        // [WHEN] Validate "Source No." as 'X'
        PriceSource.Validate("Source No.", 'X');

        // [THEN] "Source No.", "Parent Source No.", "Source ID" are blank, "Source Type" = 'Job'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Job);
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T024_Job_ChangedParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Job', Job No." is 'J1'
        NewSourceJob(PriceSource);
        // [GIVEN] Job, where Job No." is 'J2'
        NewSourceJob(NewPriceSource);

        // [WHEN] Validate "Parent Source No." as 'X'
        asserterror PriceSource.Validate("Parent Source No.", 'X');
        // [THEN] Error Message: 'Parent Source No. must be blank for Job source type.'
        Assert.ExpectedError(StrSubstNo(ParentErr, PriceSource."Source Type"::Job));
    end;

    [Test]
    procedure T025_Job_BlankParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Job', Job No." is 'J'
        NewSourceJob(PriceSource);

        // [WHEN] Validate "Parent Source No." as <blank>
        PriceSource.Validate("Parent Source No.", '');

        // [THEN] "Parent Source No." is <blank>
        PriceSource.TestField("Parent Source No.", '');
        PriceSource.TestField("Filter Source No.", '');
    end;

    [Test]
    procedure T026_Job_IsSourceNoAllowed()
    var
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Job";
    begin
        // [FEATURE] [Job]
        Initialize();
        //IPriceSource := SourceType::"Job";
        Assert.IsTrue(IPriceSource.IsSourceNoAllowed(), 'IsSourceNoAllowed');
    end;

    [Test]
    [HandlerFunctions('NewJobsMPHandler')]
    procedure T027_Job_IsLookupOKNewJob()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Job";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Two PriceSources, where "Source Type" = 'Job', "Source No." are 'A' and 'B'
        NewSourceJob(PriceSource);
        NewSourceJob(NewPriceSource);

        // [WHEN] Lookup source on Job 'A'
        LibraryVariableStorage.Enqueue(NewPriceSource."Source No."); // new Job No. for JobsMPHandler
        //IPriceSource := PriceSource."Source Type";
        Assert.IsTrue(IPriceSource.IsLookupOK(PriceSource), 'Lookup');

        // [THEN] Open page "Job List" and "Job Task List" and returned Job 'B'
        assert.AreEqual(NewPriceSource."Source No.", LibraryVariableStorage.DequeueText(), 'picked job no');
        PriceSource.TestField("Source No.", NewPriceSource."Source No.");
        PriceSource.TestField("Filter Source No.", NewPriceSource."Source No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T028_Job_VerifyAmountType()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [Job]
        Initialize();
        PriceSource."Source Type" := PriceSource."Source Type"::"All Jobs";
        AllAmountTypesAllowed(PriceSource);
        PriceSource."Source Type" := PriceSource."Source Type"::Job;
        AllAmountTypesAllowed(PriceSource);
        PriceSource."Source Type" := PriceSource."Source Type"::"Job Task";
        AllAmountTypesAllowed(PriceSource);
    end;

    [Test]
    procedure T030_All_ChangedSourceIDValidation()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [All]
        Initialize();
        // [GIVEN] Price Source, for All, where all fields are <blank>, "Source Type" = 'All Customers'
        PriceSource.Init();
        PriceSource."Source Type" := PriceSource."Source Type"::"All Customers";

        // [WHEN] Validate "Source ID" as 'X'
        PriceSource.Validate("Source ID", CreateGuid());

        // [THEN] "Source ID", "Source No.", "Parent Source No." are <blank>, "Source Type" = 'All Customers'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::"All Customers");
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T032_All_ChangedSourceNoValidation()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [All]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'All Vendors'
        PriceSource.Init();
        PriceSource."Source Type" := PriceSource."Source Type"::"All Vendors";

        // [WHEN] Validate "Source No." as 'X'
        PriceSource.Validate("Source No.", 'X');

        // [THEN] "Source ID", "Source No.", "Parent Source No." are <blank>, "Source Type" = 'All Vendors'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::"All Vendors");
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T034_All_ChangedParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [All]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'All Jobs'
        PriceSource.Init();
        PriceSource."Source Type" := PriceSource."Source Type"::"All Jobs";

        // [WHEN] Validate "Parent Source No." as 'X'
        PriceSource.Validate("Parent Source No.", 'X');

        // [THEN] "Source ID", "Source No.", "Parent Source No." are <blank>, "Source Type" = 'All Jobs'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::"All Jobs");
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T036_All_IsSourceNoAllowed()
    var
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - All";
    begin
        // [FEATURE] [All]
        // [SCENARIO] IsSourceNoAllowed() is false for "Price Source - All"
        Initialize();
        //IPriceSource := SourceType::"All Customers";
        Assert.IsFalse(IPriceSource.IsSourceNoAllowed(), 'IsSourceNoAllowed');
    end;

    [Test]
    procedure T037_All_IsLookupOK_AlwaysFalse()
    var
        PriceSource: Record "Price Source";
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - All";
    begin
        // [FEATURE] [All]
        Initialize();
        // [GIVEN] PriceSource, where "Source Type" = 'All', "Source No." is <blank>
        NewSourceAll(PriceSource);

        // [WHEN] Lookup source on 'All'
        //IPriceSource := PriceSource."Source Type";
        Assert.IsFalse(IPriceSource.IsLookupOK(PriceSource), 'Lookup');
        // [THEN] Lookup is not supported
    end;

    [Test]
    procedure T038_All_VerifyAmountType()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [All]
        Initialize();
        PriceSource."Source Type" := PriceSource."Source Type"::All;
        AllAmountTypesAllowed(PriceSource);
    end;

    [Test]
    procedure T040_Customer_ChangedSourceIDValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
    begin
        // [FEATURE] [Customer]
        Initialize();
        // [GIVEN] Price Source, for Customer #1, where all fields are filled, "Source ID" = 'X', "Source Type" = 'Customer'
        NewSourceCustomer(PriceSource);
        // [GIVEN] Customer #2, where "Source No." is A, "Source ID" is 'Y'
        NewSourceCustomer(NewPriceSource);

        // [WHEN] Validate "Source ID" as 'Y'
        PriceSource.Validate("Source ID", NewPriceSource."Source Id");

        // [THEN] Price Source got values from Customer #2:
        // [THEN] "Source No." is 'A', "Parent Source No." is <blank>, "Source ID" = 'Y', "Source Type" = 'Customer'
        PriceSource.Testfield("Source ID", NewPriceSource."Source Id");
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Customer);
        PriceSource.Testfield("Parent Source No.", '');
        PriceSource.Testfield("Source No.", NewPriceSource."Source No.");
    end;

    [Test]
    procedure T041_Customer_BlankSourceIDValidation()
    var
        PriceSource: Record "Price Source";
        BlankGuid: Guid;
    begin
        // [FEATURE] [Customer]
        Initialize();
        // [GIVEN] Price Source, where all fields are filled, "Source ID" = 'X', "Source Type" = 'Customer'
        NewSourceCustomer(PriceSource);

        // [WHEN] Validate "Source ID" as <blank>
        PriceSource.Validate("Source ID", BlankGuid);

        // [THEN] "Source No.", "Parent Source No." are blank, "Source ID" = <blank>, "Source Type" = 'Customer'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Customer);
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T042_Customer_ChangedSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Customer]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Customer', "Source No." is 'C1'
        NewSourceCustomer(PriceSource);
        CustomerNo := PriceSource."Parent Source No.";

        // [GIVEN] Customer, where "No." is 'C2', SystemId is 'X'
        NewSourceCustomer(NewPriceSource);

        // [WHEN] Validate "Source No." as 'C2'
        PriceSource.Validate("Source No.", NewPriceSource."Source No.");

        // [THEN] "Source No." is 'X', "Parent Source No." is <blank>, "Source ID" is 'X', "Source Type" = 'Customer'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Customer);
        PriceSource.Testfield("Parent Source No.", '');
        PriceSource.Testfield("Source No.", NewPriceSource."Source No.");
        PriceSource.Testfield("Source ID", NewPriceSource."Source ID");
    end;

    [Test]
    procedure T043_Customer_NotExistingSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Customer', "Source No." is 'C'
        NewSourceCustomer(PriceSource);

        // [GIVEN] Customer, where "No." is 'X', does not exist
        Customer.SetRange("No.", 'X');
        Customer.DeleteAll();

        // [WHEN] Validate "Source No." as 'X'
        PriceSource.Validate("Source No.", 'X');

        // [THEN] "Source No.", "Parent Source No.", "Source ID" are blank, "Source Type" = 'Customer'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Customer);
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T044_Customer_ChangedParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
    begin
        // [FEATURE] [Customer]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Customer', Customer No." is 'C1'
        NewSourceCustomer(PriceSource);
        // [GIVEN] Customer, where "No." is 'C2'
        NewSourceCustomer(NewPriceSource);

        // [WHEN] Validate "Parent Source No." as 'X'
        asserterror PriceSource.Validate("Parent Source No.", 'X');
        // [THEN] Error Message: 'Parent Source No. must be blank for Customer source type.'
        Assert.ExpectedError(StrSubstNo(ParentErr, PriceSource."Source Type"::Customer));
    end;

    [Test]
    procedure T045_Customer_BlankParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [Customer]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Customer', Customer No." is 'C'
        NewSourceCustomer(PriceSource);

        // [WHEN] Validate "Parent Source No." as <blank>
        PriceSource.Validate("Parent Source No.", '');

        // [THEN] "Parent Source No." is <blank>
        PriceSource.TestField("Parent Source No.", '');
    end;

    [Test]
    procedure T046_Customer_IsSourceNoAllowed()
    var
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Customer";
    begin
        // [FEATURE] [Customer]
        Initialize();
        //IPriceSource := SourceType::"Customer";
        Assert.IsTrue(IPriceSource.IsSourceNoAllowed(), 'IsSourceNoAllowed');
    end;

    [Test]
    [HandlerFunctions('NewCustomersMPHandler')]
    procedure T047_Customer_IsLookupOKNewCustomer()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Customer";
    begin
        // [FEATURE] [Customer]
        Initialize();
        // [GIVEN] Two PriceSources, where "Source Type" = 'Customer', "Source No." are 'A' and 'B'
        NewSourceCustomer(PriceSource);
        NewSourceCustomer(NewPriceSource);

        // [WHEN] Lookup source on Customer 'A'
        LibraryVariableStorage.Enqueue(NewPriceSource."Source No."); // new Customer No. for CustomersMPHandler
        //IPriceSource := PriceSource."Source Type";
        Assert.IsTrue(IPriceSource.IsLookupOK(PriceSource), 'Lookup');

        // [THEN] Open page "Customer Lookup" and returned Customer 'B'
        PriceSource.TestField("Source No.", NewPriceSource."Source No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T048_Customer_VerifyAmountType()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [Customer]
        Initialize();
        PriceSource."Source Type" := PriceSource."Source Type"::"All Customers";
        AllAmountTypesAllowed(PriceSource);

        PriceSource."Source Type" := PriceSource."Source Type"::Customer;
        AllAmountTypesAllowed(PriceSource);
    end;

    [Test]
    procedure T050_CustomerDiscountGroup_ChangedSourceIDValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
    begin
        // [FEATURE] [Customer Discount Group]
        Initialize();
        // [GIVEN] Price Source, for Customer Discount Group #1, where all fields are filled, "Source ID" = 'X', "Source Type" = 'Customer Discount Group'
        NewSourceCustomerDiscountGroup(PriceSource);
        // [GIVEN] Customer Discount Group #2, where "Source No." is A, "Source ID" is 'Y'
        NewSourceCustomerDiscountGroup(NewPriceSource);

        // [WHEN] Validate "Source ID" as 'Y'
        PriceSource.Validate("Source ID", NewPriceSource."Source Id");

        // [THEN] Price Source got values from Customer Discount Group #2:
        // [THEN] "Source No." is 'A', "Parent Source No." is <blank>, "Source ID" = 'Y', "Source Type" = 'Customer Discount Group'
        PriceSource.Testfield("Source ID", NewPriceSource."Source Id");
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::"Customer Disc. Group");
        PriceSource.Testfield("Parent Source No.", '');
        PriceSource.Testfield("Source No.", NewPriceSource."Source No.");
    end;

    [Test]
    procedure T051_CustomerDiscountGroup_BlankSourceIDValidation()
    var
        PriceSource: Record "Price Source";
        BlankGuid: Guid;
    begin
        // [FEATURE] [Customer Discount Group]
        Initialize();
        // [GIVEN] Price Source, where all fields are filled, "Source ID" = 'X', "Source Type" = 'Customer Discount Group'
        NewSourceCustomerDiscountGroup(PriceSource);

        // [WHEN] Validate "Source ID" as <blank>
        PriceSource.Validate("Source ID", BlankGuid);

        // [THEN] "Source No.", "Parent Source No." are blank, "Source ID" = <blank>, "Source Type" = 'Customer Discount Group'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::"Customer Disc. Group");
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T052_CustomerDiscountGroup_ChangedSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        CustomerDiscountGroupNo: Code[20];
    begin
        // [FEATURE] [Customer Discount Group]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Customer Discount Group', "Source No." is 'C1'
        NewSourceCustomerDiscountGroup(PriceSource);
        CustomerDiscountGroupNo := PriceSource."Parent Source No.";

        // [GIVEN] Customer Discount Group, where "Code" is 'C2', SystemId is 'X'
        NewSourceCustomerDiscountGroup(NewPriceSource);

        // [WHEN] Validate "Source No." as 'C2'
        PriceSource.Validate("Source No.", NewPriceSource."Source No.");

        // [THEN] "Source No." is 'X', "Parent Source No." is <blank>, "Source ID" is 'X', "Source Type" = 'Customer Discount Group'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::"Customer Disc. Group");
        PriceSource.Testfield("Parent Source No.", '');
        PriceSource.Testfield("Source No.", NewPriceSource."Source No.");
        PriceSource.Testfield("Source ID", NewPriceSource."Source ID");
    end;

    [Test]
    procedure T053_CustomerDiscountGroup_NotExistingSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        CustomerDiscountGroup: Record "Customer Discount Group";
    begin
        // [FEATURE] [Customer Discount Group]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Customer Discount Group', "Source No." is 'C'
        NewSourceCustomerDiscountGroup(PriceSource);

        // [GIVEN] Customer Discount Group, where "Code" is 'X', does not exist
        CustomerDiscountGroup.SetRange(Code, 'X');
        CustomerDiscountGroup.DeleteAll();

        // [WHEN] Validate "Source No." as 'X'
        PriceSource.Validate("Source No.", 'X');

        // [THEN] "Source No.", "Parent Source No.", "Source ID" are blank, "Source Type" = 'Customer Discount Group'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::"Customer Disc. Group");
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T054_CustomerDiscountGroup_ChangedParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [Customer Discount Group]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Customer Discount Group', "Source No." is 'C1'
        NewSourceCustomerDiscountGroup(PriceSource);

        // [WHEN] Validate "Parent Source No." as 'X'
        asserterror PriceSource.Validate("Parent Source No.", 'X');
        // [THEN] Error Message: 'Parent Source No. must be blank for Customer Discount Group source type.'
        Assert.ExpectedError(StrSubstNo(ParentErr, PriceSource."Source Type"::"Customer Disc. Group"));
    end;

    [Test]
    procedure T055_CustomerDiscountGroup_BlankParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [Customer Discount Group]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Customer Discount Group', "Source No." is 'C'
        NewSourceCustomerDiscountGroup(PriceSource);

        // [WHEN] Validate "Parent Source No." as <blank>
        PriceSource.Validate("Parent Source No.", '');

        // [THEN] "Parent Source No." is <blank>
        PriceSource.TestField("Parent Source No.", '');
    end;

    [Test]
    procedure T056_CustomerDiscountGroup_IsSourceNoAllowed()
    var
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Cust. Disc. Gr.";
    begin
        // [FEATURE] [Customer Discount Group]
        Initialize();
        //IPriceSource := SourceType::"Customer Disc. Group";
        Assert.IsTrue(IPriceSource.IsSourceNoAllowed(), 'IsSourceNoAllowed');
    end;

    [Test]
    [HandlerFunctions('NewCustomerDiscountGroupMPHandler')]
    procedure T057_CustomerDiscountGroup_IsLookupOKNewGroup()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Cust. Disc. Gr.";
    begin
        // [FEATURE] [Customer Discount Group]
        Initialize();
        // [GIVEN] Two PriceSources, where "Source Type" = 'Customer Disc. Group', "Source No." are 'A' and 'B'
        NewSourceCustomerDiscountGroup(PriceSource);
        NewSourceCustomerDiscountGroup(NewPriceSource);

        // [WHEN] Lookup source on Customer Disc. Group 'A'
        LibraryVariableStorage.Enqueue(NewPriceSource."Source No."); // new Code for MPHandler
        //IPriceSource := PriceSource."Source Type";
        Assert.IsTrue(IPriceSource.IsLookupOK(PriceSource), 'Lookup');

        // [THEN] Open page "Customer Disc. Groups" and returned Customer Disc. Group 'B'
        PriceSource.TestField("Source No.", NewPriceSource."Source No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T058_CustomerDiscountGroup_VerifyAmountTypeDiscountOnly()
    var
        PriceSource: Record "Price Source";
        AmountType: Enum "Price Amount Type";
    begin
        // [FEATURE] [Customer Discount Group]
        Initialize();
        PriceSource."Source Type" := PriceSource."Source Type"::"Customer Disc. Group";

        Assert.AreEqual(AmountType::Discount, PriceSource.GetDefaultAmountType(), 'Wrong default amount type');

        PriceSource.VerifyAmountTypeForSourceType(AmountType::Discount);
        asserterror PriceSource.VerifyAmountTypeForSourceType(AmountType::Any);
        asserterror PriceSource.VerifyAmountTypeForSourceType(AmountType::Price);
    end;

    [Test]
    procedure T059_CustomerDiscountGroup_IsForAmountTypeDiscountOnly()
    var
        PriceSource: Record "Price Source";
        AmountType: Enum "Price Amount Type";
    begin
        // [FEATURE] [Customer Discount Group]
        Initialize();
        PriceSource."Source Type" := PriceSource."Source Type"::"Customer Disc. Group";

        Assert.IsFalse(PriceSource.IsForAmountType(AmountType::Any), 'AmountType::All');
        Assert.IsFalse(PriceSource.IsForAmountType(AmountType::Price), 'AmountType::Price');
        Assert.IsTrue(PriceSource.IsForAmountType(AmountType::Discount), 'AmountType::Discount');
    end;

    [Test]
    procedure T060_CustomerPriceGroup_ChangedSourceIDValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
    begin
        // [FEATURE] [Customer Price Group]
        Initialize();
        // [GIVEN] Price Source, for Customer Price Group #1, where all fields are filled, "Source ID" = 'X', "Source Type" = 'Customer Price Group'
        NewSourceCustomerPriceGroup(PriceSource);
        // [GIVEN] Customer Price Group #2, where "Source No." is A, "Source ID" is 'Y'
        NewSourceCustomerPriceGroup(NewPriceSource);

        // [WHEN] Validate "Source ID" as 'Y'
        PriceSource.Validate("Source ID", NewPriceSource."Source Id");

        // [THEN] Price Source got values from Customer Price Group #2:
        // [THEN] "Source No." is 'A', "Parent Source No." is <blank>, "Source ID" = 'Y', "Source Type" = 'Customer Price Group'
        PriceSource.Testfield("Source ID", NewPriceSource."Source Id");
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::"Customer Price Group");
        PriceSource.Testfield("Parent Source No.", '');
        PriceSource.Testfield("Source No.", NewPriceSource."Source No.");
    end;

    [Test]
    procedure T061_CustomerPriceGroup_BlankSourceIDValidation()
    var
        PriceSource: Record "Price Source";
        BlankGuid: Guid;
    begin
        // [FEATURE] [Customer Price Group]
        Initialize();
        // [GIVEN] Price Source, where all fields are filled, "Source ID" = 'X', "Source Type" = 'Customer Price Group'
        NewSourceCustomerPriceGroup(PriceSource);

        // [WHEN] Validate "Source ID" as <blank>
        PriceSource.Validate("Source ID", BlankGuid);

        // [THEN] "Source No.", "Parent Source No." are blank, "Source ID" = <blank>, "Source Type" = 'Customer Price Group'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::"Customer Price Group");
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T062_CustomerPriceGroup_ChangedSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        CustomerPriceGroupNo: Code[20];
    begin
        // [FEATURE] [Customer Price Group]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Customer Price Group', "Source No." is 'C1'
        NewSourceCustomerPriceGroup(PriceSource);
        CustomerPriceGroupNo := PriceSource."Parent Source No.";

        // [GIVEN] Customer Price Group, where "Code" is 'C2', SystemId is 'X'
        NewSourceCustomerPriceGroup(NewPriceSource);

        // [WHEN] Validate "Source No." as 'C2'
        PriceSource.Validate("Source No.", NewPriceSource."Source No.");

        // [THEN] "Source No." is 'X', "Parent Source No." is <blank>, "Source ID" is 'X', "Source Type" = 'Customer Price Group'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::"Customer Price Group");
        PriceSource.Testfield("Parent Source No.", '');
        PriceSource.Testfield("Source No.", NewPriceSource."Source No.");
        PriceSource.Testfield("Source ID", NewPriceSource."Source ID");
    end;

    [Test]
    procedure T063_CustomerPriceGroup_NotExistingSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        // [FEATURE] [Customer Price Group]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Customer Price Group', "Source No." is 'C'
        NewSourceCustomerPriceGroup(PriceSource);

        // [GIVEN] Customer Price Group, where "Code" is 'X', does not exist
        CustomerPriceGroup.SetRange(Code, 'X');
        CustomerPriceGroup.DeleteAll();

        // [WHEN] Validate "Source No." as 'X'
        PriceSource.Validate("Source No.", 'X');

        // [THEN] "Source No.", "Parent Source No.", "Source ID" are blank, "Source Type" = 'Customer Price Group'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::"Customer Price Group");
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T064_CustomerPriceGroup_ChangedParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [Customer Price Group]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Customer Price Group', "Source No." is 'C1'
        NewSourceCustomerPriceGroup(PriceSource);

        // [WHEN] Validate "Parent Source No." as 'X'
        asserterror PriceSource.Validate("Parent Source No.", 'X');
        // [THEN] Error Message: 'Parent Source No. must be blank for Customer Price Group source type.'
        Assert.ExpectedError(StrSubstNo(ParentErr, PriceSource."Source Type"::"Customer Price Group"));
    end;

    [Test]
    procedure T065_CustomerPriceGroup_BlankParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [Customer Price Group]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Customer Price Group', "Source No." is 'C'
        NewSourceCustomerPriceGroup(PriceSource);

        // [WHEN] Validate "Parent Source No." as <blank>
        PriceSource.Validate("Parent Source No.", '');

        // [THEN] "Parent Source No." is <blank>
        PriceSource.TestField("Parent Source No.", '');
    end;

    [Test]
    procedure T066_CustomerPriceGroup_IsSourceNoAllowed()
    var
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Cust. Disc. Gr.";
    begin
        // [FEATURE] [Customer Price Group]
        Initialize();
        //IPriceSource := SourceType::"Customer Price Group";
        Assert.IsTrue(IPriceSource.IsSourceNoAllowed(), 'IsSourceNoAllowed');
    end;

    [Test]
    [HandlerFunctions('NewCustomerPriceGroupMPHandler')]
    procedure T067_CustomerPriceGroup_IsLookupOKNewGroup()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Cust. Price Gr.";
    begin
        // [FEATURE] [Customer Price Group]
        Initialize();
        // [GIVEN] Two PriceSources, where "Source Type" = 'Customer Price Group', "Source No." are 'A' and 'B'
        NewSourceCustomerPriceGroup(PriceSource);
        NewSourceCustomerPriceGroup(NewPriceSource);

        // [WHEN] Lookup source on Customer Price Group 'A'
        LibraryVariableStorage.Enqueue(NewPriceSource."Source No."); // new Code for MPHandler
        //IPriceSource := PriceSource."Source Type";
        Assert.IsTrue(IPriceSource.IsLookupOK(PriceSource), 'Lookup');

        // [THEN] Open page "Customer Price Groups" and returned Customer Price Group 'B'
        PriceSource.TestField("Source No.", NewPriceSource."Source No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T068_CustomerPriceGroup_VerifyAmountTypePriceOnly()
    var
        PriceSource: Record "Price Source";
        AmountType: Enum "Price Amount Type";
    begin
        // [FEATURE] [Customer Discount Group]
        Initialize();
        PriceSource."Source Type" := PriceSource."Source Type"::"Customer Price Group";

        Assert.AreEqual(AmountType::Price, PriceSource.GetDefaultAmountType(), 'Wrong default amount type');

        PriceSource.VerifyAmountTypeForSourceType(AmountType::Price);
        asserterror PriceSource.VerifyAmountTypeForSourceType(AmountType::Discount);
        asserterror PriceSource.VerifyAmountTypeForSourceType(AmountType::Any);
    end;

    [Test]
    procedure T069_CustomerPriceGroup_IsForAmountTypePriceOnly()
    var
        PriceSource: Record "Price Source";
        AmountType: Enum "Price Amount Type";
    begin
        // [FEATURE] [Customer Price Group]
        Initialize();
        PriceSource."Source Type" := PriceSource."Source Type"::"Customer Price Group";

        Assert.IsFalse(PriceSource.IsForAmountType(AmountType::Any), 'AmountType::All');
        Assert.IsTrue(PriceSource.IsForAmountType(AmountType::Price), 'AmountType::Price');
        Assert.IsFalse(PriceSource.IsForAmountType(AmountType::Discount), 'AmountType::Discount');
    end;

    [Test]
    procedure T070_Vendor_ChangedSourceIDValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
    begin
        // [FEATURE] [Vendor]
        Initialize();
        // [GIVEN] Price Source, for Vendor #1, where all fields are filled, "Source ID" = 'X', "Source Type" = 'Vendor'
        NewSourceVendor(PriceSource);
        // [GIVEN] Vendor #2, where "Source No." is A, "Source ID" is 'Y'
        NewSourceVendor(NewPriceSource);

        // [WHEN] Validate "Source ID" as 'Y'
        PriceSource.Validate("Source ID", NewPriceSource."Source Id");

        // [THEN] Price Source got values from Vendor #2:
        // [THEN] "Source No." is 'A', "Parent Source No." is <blank>, "Source ID" = 'Y', "Source Type" = 'Vendor'
        PriceSource.Testfield("Source ID", NewPriceSource."Source Id");
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Vendor);
        PriceSource.Testfield("Parent Source No.", '');
        PriceSource.Testfield("Source No.", NewPriceSource."Source No.");
    end;

    [Test]
    procedure T071_Vendor_BlankSourceIDValidation()
    var
        PriceSource: Record "Price Source";
        BlankGuid: Guid;
    begin
        // [FEATURE] [Vendor]
        Initialize();
        // [GIVEN] Price Source, where all fields are filled, "Source ID" = 'X', "Source Type" = 'Vendor'
        NewSourceVendor(PriceSource);

        // [WHEN] Validate "Source ID" as <blank>
        PriceSource.Validate("Source ID", BlankGuid);

        // [THEN] "Source No.", "Parent Source No." are blank, "Source ID" = <blank>, "Source Type" = 'Vendor'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Vendor);
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T072_Vendor_ChangedSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Vendor]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Vendor', "Source No." is 'C1'
        NewSourceVendor(PriceSource);
        VendorNo := PriceSource."Parent Source No.";

        // [GIVEN] Vendor, where "No." is 'C2', SystemId is 'X'
        NewSourceVendor(NewPriceSource);

        // [WHEN] Validate "Source No." as 'C2'
        PriceSource.Validate("Source No.", NewPriceSource."Source No.");

        // [THEN] "Source No." is 'X', "Parent Source No." is <blank>, "Source ID" is 'X', "Source Type" = 'Vendor'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Vendor);
        PriceSource.Testfield("Parent Source No.", '');
        PriceSource.Testfield("Source No.", NewPriceSource."Source No.");
        PriceSource.Testfield("Source ID", NewPriceSource."Source ID");
    end;

    [Test]
    procedure T073_Vendor_NotExistingSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Vendor', "Source No." is 'C'
        NewSourceVendor(PriceSource);

        // [GIVEN] Vendor, where "No." is 'X', does not exist
        Vendor.SetRange("No.", 'X');
        Vendor.DeleteAll();

        // [WHEN] Validate "Source No." as 'X'
        PriceSource.Validate("Source No.", 'X');

        // [THEN] "Source No.", "Parent Source No.", "Source ID" are blank, "Source Type" = 'Vendor'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Vendor);
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T074_Vendor_ChangedParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
    begin
        // [FEATURE] [Vendor]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Vendor', Vendor No." is 'C1'
        NewSourceVendor(PriceSource);
        // [GIVEN] Vendor, where "No." is 'C2'
        NewSourceVendor(NewPriceSource);

        // [WHEN] Validate "Parent Source No." as 'X'
        asserterror PriceSource.Validate("Parent Source No.", 'X');
        // [THEN] Error Message: 'Parent Source No. must be blank for Vendor source type.'
        Assert.ExpectedError(StrSubstNo(ParentErr, PriceSource."Source Type"::Vendor));
    end;

    [Test]
    procedure T075_Vendor_BlankParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [Vendor]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Vendor', Vendor No." is 'C'
        NewSourceVendor(PriceSource);

        // [WHEN] Validate "Parent Source No." as <blank>
        PriceSource.Validate("Parent Source No.", '');

        // [THEN] "Parent Source No." is <blank>
        PriceSource.TestField("Parent Source No.", '');
    end;

    [Test]
    procedure T076_Vendor_IsSourceNoAllowed()
    var
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Vendor";
    begin
        // [FEATURE] [Vendor]
        Initialize();
        //IPriceSource := SourceType::"Vendor";
        Assert.IsTrue(IPriceSource.IsSourceNoAllowed(), 'IsSourceNoAllowed');
    end;

    [Test]
    [HandlerFunctions('NewVendorsMPHandler')]
    procedure T077_Vendor_IsLookupOKNewVendor()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Vendor";
    begin
        // [FEATURE] [Vendor]
        Initialize();
        // [GIVEN] Two PriceSources, where "Source Type" = 'Vendor', "Source No." are 'A' and 'B'
        NewSourceVendor(PriceSource);
        NewSourceVendor(NewPriceSource);

        // [WHEN] Lookup source on Vendor 'A'
        LibraryVariableStorage.Enqueue(NewPriceSource."Source No."); // new Vendor No. for VendorsMPHandler
        //IPriceSource := PriceSource."Source Type";
        Assert.IsTrue(IPriceSource.IsLookupOK(PriceSource), 'Lookup');

        // [THEN] Open page "Vendor Lookup" and returned Vendor 'B'
        PriceSource.TestField("Source No.", NewPriceSource."Source No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T068_Vendor_VerifyAmountType()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [Vendor]
        Initialize();
        PriceSource."Source Type" := PriceSource."Source Type"::"All Vendors";
        AllAmountTypesAllowed(PriceSource);

        PriceSource."Source Type" := PriceSource."Source Type"::Vendor;
        AllAmountTypesAllowed(PriceSource);
    end;

    [Test]
    procedure T080_Campaign_ChangedSourceIDValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Price Source, for Campaign #1, where all fields are filled, "Source ID" = 'X', "Source Type" = 'Campaign'
        NewSourceCampaign(PriceSource);
        // [GIVEN] Campaign #2, where "Source No." is A, "Source ID" is 'Y'
        NewSourceCampaign(NewPriceSource);

        // [WHEN] Validate "Source ID" as 'Y'
        PriceSource.Validate("Source ID", NewPriceSource."Source Id");

        // [THEN] Price Source got values from Campaign #2:
        // [THEN] "Source No." is 'A', "Parent Source No." is <blank>, "Source ID" = 'Y', "Source Type" = 'Campaign'
        PriceSource.Testfield("Source ID", NewPriceSource."Source Id");
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Campaign);
        PriceSource.Testfield("Parent Source No.", '');
        PriceSource.Testfield("Source No.", NewPriceSource."Source No.");
    end;

    [Test]
    procedure T081_Campaign_BlankSourceIDValidation()
    var
        PriceSource: Record "Price Source";
        BlankGuid: Guid;
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Price Source, where all fields are filled, "Source ID" = 'X', "Source Type" = 'Campaign'
        NewSourceCampaign(PriceSource);

        // [WHEN] Validate "Source ID" as <blank>
        PriceSource.Validate("Source ID", BlankGuid);

        // [THEN] "Source No.", "Parent Source No." are blank, "Source ID" = <blank>, "Source Type" = 'Campaign'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Campaign);
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T082_Campaign_ChangedSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        CampaignNo: Code[20];
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Campaign', "Source No." is 'C1'
        NewSourceCampaign(PriceSource);
        CampaignNo := PriceSource."Parent Source No.";

        // [GIVEN] Campaign, where "No." is 'C2', SystemId is 'X'
        NewSourceCampaign(NewPriceSource);

        // [WHEN] Validate "Source No." as 'C2'
        PriceSource.Validate("Source No.", NewPriceSource."Source No.");

        // [THEN] "Source No." is 'X', "Parent Source No." is <blank>, "Source ID" is 'X', "Source Type" = 'Campaign'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Campaign);
        PriceSource.Testfield("Parent Source No.", '');
        PriceSource.Testfield("Source No.", NewPriceSource."Source No.");
        PriceSource.Testfield("Source ID", NewPriceSource."Source ID");
    end;

    [Test]
    procedure T083_Campaign_NotExistingSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        Campaign: Record Campaign;
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Campaign', "Source No." is 'C'
        NewSourceCampaign(PriceSource);

        // [GIVEN] Campaign, where "No." is 'X', does not exist
        Campaign.SetRange("No.", 'X');
        Campaign.DeleteAll();

        // [WHEN] Validate "Source No." as 'X'
        PriceSource.Validate("Source No.", 'X');

        // [THEN] "Source No.", "Parent Source No.", "Source ID" are blank, "Source Type" = 'Campaign'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Campaign);
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T084_Campaign_ChangedParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Campaign', Campaign No." is 'C1'
        NewSourceCampaign(PriceSource);
        // [GIVEN] Campaign, where "No." is 'C2'
        NewSourceCampaign(NewPriceSource);

        // [WHEN] Validate "Parent Source No." as 'X'
        asserterror PriceSource.Validate("Parent Source No.", 'X');
        // [THEN] Error Message: 'Parent Source No. must be blank for Campaign source type.'
        Assert.ExpectedError(StrSubstNo(ParentErr, PriceSource."Source Type"::Campaign));
    end;

    [Test]
    procedure T085_Campaign_BlankParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Campaign', Campaign No." is 'C'
        NewSourceCampaign(PriceSource);

        // [WHEN] Validate "Parent Source No." as <blank>
        PriceSource.Validate("Parent Source No.", '');

        // [THEN] "Parent Source No." is <blank>
        PriceSource.TestField("Parent Source No.", '');
    end;

    [Test]
    procedure T086_Campaign_IsSourceNoAllowed()
    var
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Campaign";
    begin
        // [FEATURE] [Campaign]
        Initialize();
        //IPriceSource := SourceType::"Campaign";
        Assert.IsTrue(IPriceSource.IsSourceNoAllowed(), 'IsSourceNoAllowed');
    end;

    [Test]
    [HandlerFunctions('NewCampaignsMPHandler')]
    procedure T087_Campaign_IsLookupOKNewCampaign()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Campaign";
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Two PriceSources, where "Source Type" = 'Campaign', "Source No." are 'A' and 'B'
        NewSourceCampaign(PriceSource);
        NewSourceCampaign(NewPriceSource);

        // [WHEN] Lookup source on Campaign 'A'
        LibraryVariableStorage.Enqueue(NewPriceSource."Source No."); // new Campaign No. for CampaignsMPHandler
        //IPriceSource := PriceSource."Source Type";
        Assert.IsTrue(IPriceSource.IsLookupOK(PriceSource), 'Lookup');

        // [THEN] Open page "Campaign List" and returned Campaign 'B'
        PriceSource.TestField("Source No.", NewPriceSource."Source No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T088_Campaign_VerifyAmountType()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [Campaign]
        Initialize();
        PriceSource."Source Type" := PriceSource."Source Type"::Campaign;
        AllAmountTypesAllowed(PriceSource);
    end;

    [Test]
    procedure T090_Contact_ChangedSourceIDValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
    begin
        // [FEATURE] [Contact]
        Initialize();
        // [GIVEN] Price Source, for Contact #1, where all fields are filled, "Source ID" = 'X', "Source Type" = 'Contact'
        NewSourceContact(PriceSource);
        // [GIVEN] Contact #2, where "Source No." is A, "Source ID" is 'Y'
        NewSourceContact(NewPriceSource);

        // [WHEN] Validate "Source ID" as 'Y'
        PriceSource.Validate("Source ID", NewPriceSource."Source Id");

        // [THEN] Price Source got values from Contact #2:
        // [THEN] "Source No." is 'A', "Parent Source No." is <blank>, "Source ID" = 'Y', "Source Type" = 'Contact'
        PriceSource.Testfield("Source ID", NewPriceSource."Source Id");
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Contact);
        PriceSource.Testfield("Parent Source No.", '');
        PriceSource.Testfield("Source No.", NewPriceSource."Source No.");
    end;

    [Test]
    procedure T091_Contact_BlankSourceIDValidation()
    var
        PriceSource: Record "Price Source";
        BlankGuid: Guid;
    begin
        // [FEATURE] [Contact]
        Initialize();
        // [GIVEN] Price Source, where all fields are filled, "Source ID" = 'X', "Source Type" = 'Contact'
        NewSourceContact(PriceSource);

        // [WHEN] Validate "Source ID" as <blank>
        PriceSource.Validate("Source ID", BlankGuid);

        // [THEN] "Source No.", "Parent Source No." are blank, "Source ID" = <blank>, "Source Type" = 'Contact'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Contact);
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T092_Contact_ChangedSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        ContactNo: Code[20];
    begin
        // [FEATURE] [Contact]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Contact', "Source No." is 'C1'
        NewSourceContact(PriceSource);
        ContactNo := PriceSource."Parent Source No.";

        // [GIVEN] Contact, where "No." is 'C2', SystemId is 'X'
        NewSourceContact(NewPriceSource);

        // [WHEN] Validate "Source No." as 'C2'
        PriceSource.Validate("Source No.", NewPriceSource."Source No.");

        // [THEN] "Source No." is 'X', "Parent Source No." is <blank>, "Source ID" is 'X', "Source Type" = 'Contact'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Contact);
        PriceSource.Testfield("Parent Source No.", '');
        PriceSource.Testfield("Source No.", NewPriceSource."Source No.");
        PriceSource.Testfield("Source ID", NewPriceSource."Source ID");
    end;

    [Test]
    procedure T093_Contact_NotExistingSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        Contact: Record Contact;
    begin
        // [FEATURE] [Contact]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Contact', "Source No." is 'C'
        NewSourceContact(PriceSource);

        // [GIVEN] Contact, where "No." is 'X', does not exist
        Contact.SetRange("No.", 'X');
        Contact.DeleteAll();

        // [WHEN] Validate "Source No." as 'X'
        PriceSource.Validate("Source No.", 'X');

        // [THEN] "Source No.", "Parent Source No.", "Source ID" are blank, "Source Type" = 'Contact'
        PriceSource.Testfield("Source Type", PriceSource."Source Type"::Contact);
        VerifyBlankSource(PriceSource);
    end;

    [Test]
    procedure T094_Contact_ChangedParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
    begin
        // [FEATURE] [Contact]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Contact', Contact No." is 'C1'
        NewSourceContact(PriceSource);
        // [GIVEN] Contact, where "No." is 'C2'
        NewSourceContact(NewPriceSource);

        // [WHEN] Validate "Parent Source No." as 'X'
        asserterror PriceSource.Validate("Parent Source No.", 'X');
        // [THEN] Error Message: 'Parent Source No. must be blank for Contact source type.'
        Assert.ExpectedError(StrSubstNo(ParentErr, PriceSource."Source Type"::Contact));
    end;

    [Test]
    procedure T095_Contact_BlankParentSourceNoValidation()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [Contact]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Contact', Contact No." is 'C'
        NewSourceContact(PriceSource);

        // [WHEN] Validate "Parent Source No." as <blank>
        PriceSource.Validate("Parent Source No.", '');

        // [THEN] "Parent Source No." is <blank>
        PriceSource.TestField("Parent Source No.", '');
    end;

    [Test]
    procedure T096_Contact_IsSourceNoAllowed()
    var
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Contact";
    begin
        // [FEATURE] [Contact]
        Initialize();
        //IPriceSource := SourceType::"Contact";
        Assert.IsTrue(IPriceSource.IsSourceNoAllowed(), 'IsSourceNoAllowed');
    end;

    [Test]
    [HandlerFunctions('NewContactsMPHandler')]
    procedure T097_Contact_IsLookupOKNewContact()
    var
        PriceSource: Record "Price Source";
        NewPriceSource: Record "Price Source";
        //IPriceSource: Interface "Price Source";
        IPriceSource: Codeunit "Price Source - Contact";
    begin
        // [FEATURE] [Contact]
        Initialize();
        // [GIVEN] Two PriceSources, where "Source Type" = 'Contact', "Source No." are 'A' and 'B'
        NewSourceContact(PriceSource);
        NewSourceContact(NewPriceSource);

        // [WHEN] Lookup source on Contact 'A'
        LibraryVariableStorage.Enqueue(NewPriceSource."Source No."); // new Contact No. for ContactsMPHandler
        //IPriceSource := PriceSource."Source Type";
        Assert.IsTrue(IPriceSource.IsLookupOK(PriceSource), 'Lookup');

        // [THEN] Open page "Contact List" and returned Contact 'B'
        PriceSource.TestField("Source No.", NewPriceSource."Source No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T098_Contact_VerifyAmountType()
    var
        PriceSource: Record "Price Source";
    begin
        // [FEATURE] [Contact]
        Initialize();
        PriceSource."Source Type" := PriceSource."Source Type"::Contact;
        AllAmountTypesAllowed(PriceSource);
    end;

    [Test]
    procedure T100_All_NewSourceGetsGroupAll()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] New source of type 'All' gets Group 'All'
        PriceSource.NewEntry(PriceSource."Source Type"::All, 0);
        PriceSource.Testfield("Source Group", PriceSource."Source Group"::All);
    end;

    [Test]
    procedure T101_AllCustomer_NewSourceGetsGroupCustomer()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] New source of type 'All Customers' gets Group 'Customer'
        PriceSource.NewEntry(PriceSource."Source Type"::"All Customers", 0);
        PriceSource.Testfield("Source Group", PriceSource."Source Group"::Customer);
    end;

    [Test]
    procedure T102_Customer_NewSourceGetsGroupCustomer()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] New source of type 'Customer' gets Group 'Customer'
        PriceSource.NewEntry(PriceSource."Source Type"::Customer, 0);
        PriceSource.Testfield("Source Group", PriceSource."Source Group"::Customer);
    end;

    [Test]
    procedure T103_AllVendors_NewSourceGetsGroupVendor()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] New source of type 'All Vendors' gets Group 'Vendor'
        PriceSource.NewEntry(PriceSource."Source Type"::"All Vendors", 0);
        PriceSource.Testfield("Source Group", PriceSource."Source Group"::Vendor);
    end;

    [Test]
    procedure T104_Vendor_NewSourceGetsGroupVendor()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] New source of type 'Vendor' gets Group 'Vendor'
        PriceSource.NewEntry(PriceSource."Source Type"::Vendor, 0);
        PriceSource.Testfield("Source Group", PriceSource."Source Group"::Vendor);
    end;

    [Test]
    procedure T105_AllJobs_NewSourceGetsGroupJob()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] New source of type 'All Jobs' gets Group 'Job'
        PriceSource.NewEntry(PriceSource."Source Type"::"All Jobs", 0);
        PriceSource.Testfield("Source Group", PriceSource."Source Group"::Job);
    end;

    [Test]
    procedure T106_Job_NewSourceGetsGroupJob()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] New source of type 'Job' gets Group 'Job'
        PriceSource.NewEntry(PriceSource."Source Type"::Job, 0);
        PriceSource.Testfield("Source Group", PriceSource."Source Group"::Job);
    end;

    [Test]
    procedure T107_JobTask_NewSourceGetsGroupJob()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] New source of type 'Job Task' gets Group 'Job'
        PriceSource.NewEntry(PriceSource."Source Type"::"Job Task", 0);
        PriceSource.Testfield("Source Group", PriceSource."Source Group"::Job);
    end;

    [Test]
    procedure T108_Campaign_NewSourceGetsGroupAll()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] New source of type 'Campaign' gets Group 'All', gets 'Vendor' for Price Type 'Purchase'
        PriceSource.NewEntry(PriceSource."Source Type"::Campaign, 0);
        PriceSource.Testfield("Source Group", PriceSource."Source Group"::All);

        PriceSource.Validate("Price Type", "Price Type"::Purchase);
        PriceSource.Validate("Source Type");
        PriceSource.Testfield("Source Group", PriceSource."Source Group"::Vendor);
    end;

    [Test]
    procedure T109_Contact_NewSourceGetsGroupAll()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] New source of type 'Contact' gets Group 'All', gets 'Customer' for Price Type 'Sale'
        PriceSource.NewEntry(PriceSource."Source Type"::Contact, 0);
        PriceSource.Testfield("Source Group", PriceSource."Source Group"::All);

        PriceSource.Validate("Price Type", "Price Type"::Sale);
        PriceSource.Validate("Source Type");
        PriceSource.Testfield("Source Group", PriceSource."Source Group"::Customer);
    end;

    [Test]
    procedure T110_CustomerPriceGroup_NewSourceGetsGroupCustomer()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] New source of type 'Customer Price Group' gets Group 'Customer'
        PriceSource.NewEntry(PriceSource."Source Type"::"Customer Price Group", 0);
        PriceSource.Testfield("Source Group", PriceSource."Source Group"::Customer);
    end;

    [Test]
    procedure T111_CustomerDiscGroup_NewSourceGetsGroupCustomer()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] New source of type 'Customer Disc. Group' gets Group 'Customer'
        PriceSource.NewEntry(PriceSource."Source Type"::"Customer Disc. Group", 0);
        PriceSource.Testfield("Source Group", PriceSource."Source Group"::Customer);
    end;

    [Test]
    procedure T115_JobTask_GetParentSourceType()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] Source Type 'Job Task' gives parent source type 'Job'
        PriceSource.Validate("Source Type", "Price Source Type"::"Job Task");
        Assert.AreEqual("Price Source Type"::Job, PriceSource.GetParentSourceType(), 'Wrong parent source type for Job Task');
    end;

    [Test]
    procedure T116_NonJobTask_GetParentSourceType()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] Source Type that is not 'Job Task' gives parent source type 'All'
        PriceSource.Validate("Source Type", "Price Source Type"::All);
        Assert.AreEqual("Price Source Type"::All, PriceSource.GetParentSourceType(), 'Wrong parent source type for All');
        PriceSource.Validate("Source Type", "Price Source Type"::"All Customers");
        Assert.AreEqual("Price Source Type"::All, PriceSource.GetParentSourceType(), 'Wrong parent source type for All Cust');
        PriceSource.Validate("Source Type", "Price Source Type"::"All Vendors");
        Assert.AreEqual("Price Source Type"::All, PriceSource.GetParentSourceType(), 'Wrong parent source type for All Vend');
        PriceSource.Validate("Source Type", "Price Source Type"::"All Jobs");
        Assert.AreEqual("Price Source Type"::All, PriceSource.GetParentSourceType(), 'Wrong parent source type for All Jobs');
        PriceSource.Validate("Source Type", "Price Source Type"::Customer);
        Assert.AreEqual("Price Source Type"::All, PriceSource.GetParentSourceType(), 'Wrong parent source type for Cust');
        PriceSource.Validate("Source Type", "Price Source Type"::Vendor);
        Assert.AreEqual("Price Source Type"::All, PriceSource.GetParentSourceType(), 'Wrong parent source type for Vend');
        PriceSource.Validate("Source Type", "Price Source Type"::Job);
        Assert.AreEqual("Price Source Type"::All, PriceSource.GetParentSourceType(), 'Wrong parent source type for Job');
        PriceSource.Validate("Source Type", "Price Source Type"::Contact);
        Assert.AreEqual("Price Source Type"::All, PriceSource.GetParentSourceType(), 'Wrong parent source type for Contact');
        PriceSource.Validate("Source Type", "Price Source Type"::Campaign);
        Assert.AreEqual("Price Source Type"::All, PriceSource.GetParentSourceType(), 'Wrong parent source type for Campaign');
    end;


    [Test]
    procedure T120_All_GetPriceType()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] Source Type 'All' gives "Price Type" 'Any'
        PriceSource.Validate("Source Type", PriceSource."Source Type"::All);
        PriceSource.TestField("Price Type", PriceSource."Price Type"::Any);
    end;

    [Test]
    procedure T121_AllCustomers_GetPriceType()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] Source Type 'All Customers' gives "Price Type" 'Sale'
        PriceSource.Validate("Source Type", PriceSource."Source Type"::"All Customers");
        PriceSource.TestField("Price Type", PriceSource."Price Type"::Sale);
    end;

    [Test]
    procedure T121_Customer_GetPriceType()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] Source Type 'Customer' gives "Price Type" 'Sale'
        PriceSource.Validate("Source Type", PriceSource."Source Type"::Customer);
        PriceSource.TestField("Price Type", PriceSource."Price Type"::Sale);
    end;

    [Test]
    procedure T122_AllVendors_GetPriceType()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] Source Type 'All Vendors' gives "Price Type" 'Purchase'
        PriceSource.Validate("Source Type", PriceSource."Source Type"::"All Vendors");
        PriceSource.TestField("Price Type", PriceSource."Price Type"::Purchase);
    end;

    [Test]
    procedure T123_Vendor_GetPriceType()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] Source Type 'Vendor' gives "Price Type" 'Purchase'
        PriceSource.Validate("Source Type", PriceSource."Source Type"::Vendor);
        PriceSource.TestField("Price Type", PriceSource."Price Type"::Purchase);
    end;

    [Test]
    procedure T124_AllJobs_GetPriceType()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] Source Type 'All Jobs' gives "Price Type" 'Any'
        PriceSource.Validate("Source Type", PriceSource."Source Type"::"All Jobs");
        PriceSource.TestField("Price Type", PriceSource."Price Type"::Any);
    end;

    [Test]
    procedure T125_Job_GetPriceType()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] Source Type 'Job' gives "Price Type" 'Any'
        PriceSource.Validate("Source Type", PriceSource."Source Type"::Job);
        PriceSource.TestField("Price Type", PriceSource."Price Type"::Any);
    end;

    [Test]
    procedure T126_JobTask_GetPriceType()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] Source Type 'Job Task' gives "Price Type" 'Any'
        PriceSource.Validate("Source Type", PriceSource."Source Type"::"Job Task");
        PriceSource.TestField("Price Type", PriceSource."Price Type"::Any);
    end;

    [Test]
    procedure T127_Campaign_GetPriceType()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] Source Type 'Campaign' gives "Price Type" 'Any'
        PriceSource.Validate("Source Type", PriceSource."Source Type"::Campaign);
        PriceSource.TestField("Price Type", PriceSource."Price Type"::Any);
    end;

    [Test]
    procedure T128_Contact_GetPriceType()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] Source Type 'Contact' gives "Price Type" 'Any'
        PriceSource.Validate("Source Type", PriceSource."Source Type"::Contact);
        PriceSource.TestField("Price Type", PriceSource."Price Type"::Any);
    end;

    [Test]
    procedure T129_CustomerPriceGroup_GetPriceType()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] Source Type 'Customer Price Group' gives "Price Type" 'Sale'
        PriceSource.Validate("Source Type", PriceSource."Source Type"::"Customer Price Group");
        PriceSource.TestField("Price Type", PriceSource."Price Type"::Sale);
    end;

    [Test]
    procedure T130_CustomerDiscGroup_GetPriceType()
    var
        PriceSource: Record "Price Source";
    begin
        // [SCENARIO] Source Type 'Customer Disc. Group' gives "Price Type" 'Sale'
        PriceSource.Validate("Source Type", PriceSource."Source Type"::"Customer Disc. Group");
        PriceSource.TestField("Price Type", PriceSource."Price Type"::Sale);
    end;

    [Test]
    procedure T200_IsSaleAllowedEditingActivePrice()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PriceListManagement: Codeunit "Price List Management";
    begin
        Initialize();

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Allow Editing Active Price" := true;
        SalesReceivablesSetup.Modify();
        Assert.IsTrue(PriceListManagement.IsAllowedEditingActivePrice("Price Type"::Sale), 'Should be allowed');

        SalesReceivablesSetup.Delete();
        Assert.IsFalse(PriceListManagement.IsAllowedEditingActivePrice("Price Type"::Sale), 'Should not be allowed');
        SalesReceivablesSetup.Insert();
    end;

    [Test]
    procedure T200_IsPurchAllowedEditingActivePrice()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PriceListManagement: Codeunit "Price List Management";
    begin
        Initialize();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Allow Editing Active Price" := true;
        PurchasesPayablesSetup.Modify();
        Assert.IsTrue(PriceListManagement.IsAllowedEditingActivePrice("Price Type"::Purchase), 'Should be allowed');

        PurchasesPayablesSetup.Delete();
        Assert.IsFalse(PriceListManagement.IsAllowedEditingActivePrice("Price Type"::Purchase), 'Should not be allowed');
        PurchasesPayablesSetup.Insert();
    end;

    [Test]
    procedure T210_UpgradeSourceGroup()
    var
        PriceListHeader: Record "Price List Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO 400024] Corrected upgrade for setting Source Group in lines.
        Initialize();
        // [GIVEN] "Allow Editing Active Price" is yes for sales
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Allow Editing Active Price" := true;
        SalesReceivablesSetup.Modify();

        // [GIVEN] Active price list with one line
        PriceListHeader.Code := 'SALE';
        PriceListHeader."Price Type" := PriceListHeader."Price Type"::Sale;
        PriceListHeader."Source Type" := PriceListHeader."Source Type"::"All Customers";
        PriceListHeader."Source Group" := PriceListHeader."Source Group"::Customer;
        PriceListHeader.Status := PriceListHeader.Status::Active;
        PriceListHeader.Insert();

        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine."Source Group" := PriceListLine."Source Group"::All;
        PriceListLine."Source Type" := PriceListLine."Source Type"::"All Customers";
        PriceListLine."Price Type" := PriceListLine."Price Type"::Sale;
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Insert();

        // [WHEN] Run upgrade for seeting Price Source group
        PriceSourceGroupUpgrade();

        // [THEN] Price Line, where Status is Active, "Source Group" is Customer
        PriceListLine.Find();
        PriceListLine.TestField(Status, "Price Status"::Active);
        PriceListLine.TestField("Source Group", PriceListLine."Source Group"::Customer);
    end;

    [Test]
    procedure T211_UpgradeSourceGroupWithStatusSync()
    var
        PriceListHeader: Record "Price List Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO 400024] Price line Status correction after Source Group update.
        Initialize();
        // [GIVEN] "Allow Editing Active Price" is yes for purchase
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Allow Editing Active Price" := true;
        PurchasesPayablesSetup.Modify();
        // [GIVEN] Active price list with one line
        PriceListHeader.Code := 'PURCH';
        PriceListHeader."Price Type" := PriceListHeader."Price Type"::Purchase;
        PriceListHeader."Source Type" := PriceListHeader."Source Type"::"All Jobs";
        PriceListHeader."Source Group" := PriceListHeader."Source Group"::Job;
        PriceListHeader.Status := PriceListHeader.Status::Active;
        PriceListHeader.Insert();

        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine."Price Type" := PriceListLine."Price Type"::Purchase;
        PriceListLine."Source Type" := PriceListLine."Source Type"::"All Jobs";
        PriceListLine."Source Group" := PriceListLine."Source Group"::All;
        PriceListLine.Status := "Price Status"::Draft;
        PriceListLine.Insert();

        // [WHEN] Run upgrade for setting Price Source group 
        PriceSourceGroupUpgrade();
        // [THEN] Price Line, where Status is Draft, "Source Group" is Job
        PriceListLine.Find();
        PriceListLine.TestField(Status, "Price Status"::Draft);
        PriceListLine.TestField("Source Group", PriceListLine."Source Group"::Job);

        // [WHEN] Run upgrade for syncing Status in lines with headers
        SyncPriceListLineStatus();
        // [THEN] Price Line, where Status is Active, "Source Group" is Job
        PriceListLine.Find();
        PriceListLine.TestField(Status, "Price Status"::Active);
        PriceListLine.TestField("Source Group", PriceListLine."Source Group"::Job);
    end;

    local procedure Initialize()
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Price Source UT");
        LibraryVariableStorage.Clear();
        PriceCalculationSetup.DeleteAll();
        DtldPriceCalculationSetup.DeleteAll();

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Price Source UT");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Price Source UT");
    end;

    local procedure NewSourceAll(var PriceSource: Record "Price Source")
    begin
        PriceSource.NewEntry(PriceSource."Source Type"::All, 0);
    end;

    local procedure NewSourceCustomer(var PriceSource: Record "Price Source")
    begin
        PriceSource.NewEntry(PriceSource."Source Type"::Customer, 0);
        PriceSource.Validate("Source No.", NewCustomer(PriceSource."Source ID"));
    end;

    local procedure NewCustomer(var SystemID: Guid) CustomerNo: Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        SystemID := Customer.SystemId;
    end;

    local procedure NewSourceCustomerDiscountGroup(var PriceSource: Record "Price Source")
    begin
        PriceSource.NewEntry(PriceSource."Source Type"::"Customer Disc. Group", 0);
        PriceSource.Validate("Source No.", NewCustomerDiscountGroup(PriceSource."Source ID"));
    end;

    local procedure NewCustomerDiscountGroup(var SystemID: Guid) CustomerDiscountGroupCode: Code[20]
    var
        CustomerDiscountGroup: Record "Customer Discount Group";
    begin
        CustomerDiscountGroup.Init();
        CustomerDiscountGroup.Code := LibraryUtility.GenerateGUID();
        CustomerDiscountGroup.Insert(true);
        CustomerDiscountGroupCode := CustomerDiscountGroup.Code;
        SystemID := CustomerDiscountGroup.SystemId;
    end;

    local procedure NewSourceCustomerPriceGroup(var PriceSource: Record "Price Source")
    begin
        PriceSource.NewEntry(PriceSource."Source Type"::"Customer Price Group", 0);
        PriceSource.Validate("Source No.", NewCustomerPriceGroup(PriceSource."Source ID"));
    end;

    local procedure NewCustomerPriceGroup(var SystemID: Guid) CustomerPriceGroupCode: Code[20]
    var
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        CustomerPriceGroup.Init();
        CustomerPriceGroup.Code := LibraryUtility.GenerateGUID();
        CustomerPriceGroup.Insert(true);
        CustomerPriceGroupCode := CustomerPriceGroup.Code;
        SystemID := CustomerPriceGroup.SystemId;
    end;

    local procedure NewSourceJob(var PriceSource: Record "Price Source")
    begin
        PriceSource.NewEntry(PriceSource."Source Type"::Job, 0);
        PriceSource.Validate("Source No.", NewJob(PriceSource."Source ID"));
    end;

    local procedure NewSourceVendor(var PriceSource: Record "Price Source")
    begin
        PriceSource.NewEntry(PriceSource."Source Type"::Vendor, 0);
        PriceSource.Validate("Source No.", NewVendor(PriceSource."Source ID"));
    end;

    local procedure NewVendor(var SystemID: Guid) VendorNo: Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        VendorNo := Vendor."No.";
        SystemID := Vendor.SystemId;
    end;

    local procedure NewSourceCampaign(var PriceSource: Record "Price Source")
    begin
        PriceSource.NewEntry(PriceSource."Source Type"::Campaign, 0);
        PriceSource.Validate("Source No.", NewCampaign(PriceSource."Source ID"));
    end;

    local procedure NewCampaign(var SystemID: Guid) CampaignNo: Code[20]
    var
        Campaign: Record Campaign;
    begin
        LibraryMarketing.CreateCampaign(Campaign);
        CampaignNo := Campaign."No.";
        SystemID := Campaign.SystemId;
    end;

    local procedure NewSourceContact(var PriceSource: Record "Price Source")
    begin
        PriceSource.NewEntry(PriceSource."Source Type"::Contact, 0);
        PriceSource.Validate("Source No.", NewContact(PriceSource."Source ID"));
    end;

    local procedure NewContact(var SystemID: Guid) ContactNo: Code[20]
    var
        Contact: Record Contact;
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        ContactNo := Contact."No.";
        SystemID := Contact.SystemId;
    end;

    local procedure NewJob(var SystemID: Guid) JobNo: Code[20]
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        JobNo := Job."No.";
        SystemID := Job.SystemId;
    end;

    local procedure NewSourceJobTask(var PriceSource: Record "Price Source")
    var
        JobNo: Code[20];
    begin
        JobNo := PriceSource."Parent Source No.";
        PriceSource.NewEntry(PriceSource."Source Type"::"Job Task", 0);
        PriceSource."Parent Source No." := JobNo;
        PriceSource.Validate("Source No.", NewJobTask(PriceSource."Parent Source No.", PriceSource."Source ID"));
    end;

    local procedure NewJobTask(var JobNo: Code[20]; var SystemID: Guid) JobTaskNo: Code[20]
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        if not Job.Get(JobNo) then begin
            LibraryJob.CreateJob(Job);
            JobNo := Job."No.";
        end;
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTaskNo := JobTask."Job Task No.";
        SystemID := JobTask.SystemId;
    end;

    local procedure VerifyBlankSource(PriceSource: Record "Price Source")
    var
        BlankGuid: Guid;
    begin
        PriceSource.Testfield("Parent Source No.", '');
        PriceSource.Testfield("Source No.", '');
        PriceSource.Testfield("Source ID", BlankGuid);
        PriceSource.TestField("Filter Source No.", '');
    end;

    local procedure AllAmountTypesAllowed(var PriceSource: Record "Price Source")
    var
        AmountType: Enum "Price Amount Type";
    begin
        Assert.AreEqual(AmountType::Any, PriceSource.GetDefaultAmountType(), 'Wrong default amount type');

        PriceSource.VerifyAmountTypeForSourceType(AmountType::Price);
        PriceSource.VerifyAmountTypeForSourceType(AmountType::Discount);
        PriceSource.VerifyAmountTypeForSourceType(AmountType::Any);
    end;

    local procedure PriceSourceGroupUpgrade()
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Source Group", "Price Source Group"::All);
        if PriceListLine.FindSet(true) then
            repeat
                if PriceListLine."Source Type" in
                    ["Price Source Type"::"All Jobs",
                    "Price Source Type"::Job,
                    "Price Source Type"::"Job Task"]
                then
                    PriceListLine."Source Group" := "Price Source Group"::Job
                else
                    case PriceListLine."Price Type" of
                        "Price Type"::Purchase:
                            PriceListLine."Source Group" := "Price Source Group"::Vendor;
                        "Price Type"::Sale:
                            PriceListLine."Source Group" := "Price Source Group"::Customer;
                    end;
                if PriceListLine."Source Group" <> "Price Source Group"::All then
                    PriceListLine.Modify();
            until PriceListLine.Next() = 0;
    end;

    local procedure SyncPriceListLineStatus()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        Status: Enum "Price Status";
    begin
        PriceListLine.SetRange(Status, "Price Status"::Draft);
        if PriceListLine.Findset(true) then
            repeat
                if PriceListHeader.Code <> PriceListLine."Price List Code" then
                    if PriceListHeader.Get(PriceListLine."Price List Code") then
                        Status := PriceListHeader.Status
                    else
                        Status := Status::Draft;
                if Status = Status::Active then begin
                    PriceListLine.Status := Status::Active;
                    PriceListLine.Modify();
                end;
            until PriceListLine.Next() = 0;
    end;

    [ModalPageHandler]
    procedure NewCustomersMPHandler(var CustomerLookup: TestPage "Customer Lookup")
    var
        Customer: Record Customer;
        NewCustomerNo: Code[20];
    begin
        NewCustomerNo := LibraryVariableStorage.DequeueText();
        Customer.Get(NewCustomerNo);
        CustomerLookup.GoToRecord(Customer);
        CustomerLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewCustomerDiscountGroupMPHandler(var CustomerDiscGroups: TestPage "Customer Disc. Groups")
    var
        CustomerDiscGroup: Record "Customer Discount Group";
        NewCode: Code[20];
    begin
        NewCode := LibraryVariableStorage.DequeueText();
        CustomerDiscGroup.Get(NewCode);
        CustomerDiscGroups.GoToRecord(CustomerDiscGroup);
        CustomerDiscGroups.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewCustomerPriceGroupMPHandler(var CustomerPriceGroups: TestPage "Customer Price Groups")
    var
        CustomerPriceGroup: Record "Customer Price Group";
        NewCode: Code[20];
    begin
        NewCode := LibraryVariableStorage.DequeueText();
        CustomerPriceGroup.Get(NewCode);
        CustomerPriceGroups.GoToRecord(CustomerPriceGroup);
        CustomerPriceGroups.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewVendorsMPHandler(var VendorLookup: TestPage "Vendor Lookup")
    var
        Vendor: Record Vendor;
        NewVendorNo: Code[20];
    begin
        NewVendorNo := LibraryVariableStorage.DequeueText();
        Vendor.Get(NewVendorNo);
        VendorLookup.GoToRecord(Vendor);
        VendorLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewCampaignsMPHandler(var CampaignList: TestPage "Campaign List")
    var
        Campaign: Record Campaign;
        NewCampaignNo: Code[20];
    begin
        NewCampaignNo := LibraryVariableStorage.DequeueText();
        Campaign.Get(NewCampaignNo);
        CampaignList.GoToRecord(Campaign);
        CampaignList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewContactsMPHandler(var ContactList: TestPage "Contact List")
    var
        Contact: Record Contact;
        NewContactNo: Code[20];
    begin
        NewContactNo := LibraryVariableStorage.DequeueText();
        Contact.Get(NewContactNo);
        ContactList.GoToRecord(Contact);
        ContactList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure JobsMPHandler(var JobList: TestPage "Job List")
    begin
        LibraryVariableStorage.Enqueue(JobList."No.".Value()); // for JobTasksMPHandler
        JobList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelJobsMPHandler(var JobList: TestPage "Job List")
    begin
        JobList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure NewJobsMPHandler(var JobList: TestPage "Job List")
    var
        Job: Record Job;
        NewJobNo: Code[20];
    begin
        NewJobNo := LibraryVariableStorage.DequeueText();
        Job.Get(NewJobNo);
        JobList.GoToRecord(Job);
        LibraryVariableStorage.Enqueue(JobList."No.".Value()); // for JobTasksMPHandler
        JobList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure JobTasksMPHandler(var JobTaskList: TestPage "Job Task List")
    var
        JobNo: Code[20];
    begin
        JobNo := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(JobNo, JobTaskList.Filter.GetFilter("Job No."), 'filter on Job in Job Task List');
        JobTaskList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewJobTasksMPHandler(var JobTaskList: TestPage "Job Task List")
    var
        JobTask: Record "Job Task";
        JobNoFilter: Code[20];
        NewJobTaskNo: Code[20];
    begin
        NewJobTaskNo := LibraryVariableStorage.DequeueText();
        JobNoFilter := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(JobNoFilter, JobTaskList.Filter.GetFilter("Job No."), 'filter on Job in Job Task List');
        JobTask.Get(Format(JobTaskList."Job No.".Value()), NewJobTaskNo);
        JobTaskList.GoToRecord(JobTask);
        JobTaskList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure FreeJobTasksMPHandler(var JobTaskList: TestPage "Job Task List")
    var
        JobTask: Record "Job Task";
        JobNoFilter: Code[20];
        NewJobNo: Code[20];
        NewJobTaskNo: Code[20];
    begin
        NewJobNo := LibraryVariableStorage.DequeueText();
        NewJobTaskNo := LibraryVariableStorage.DequeueText();
        JobNoFilter := LibraryVariableStorage.DequeueText(); // should be blank
        Assert.AreEqual(JobNoFilter, JobTaskList.Filter.GetFilter("Job No."), 'filter on Job in Job Task List');
        JobTask.Get(NewJobNo, NewJobTaskNo);
        JobTaskList.GoToRecord(JobTask);
        JobTaskList.OK().Invoke();
    end;

}
