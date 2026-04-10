codeunit 136504 "RES Time Sheet"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Time Sheet] [Resource]
        IsInitialized := false;
    end;

    var
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJob: Codeunit "Library - Job";
        IsInitialized: Boolean;
        PageVerify: Label 'The TestPage is already open.';
        TimeSheetNo: Code[20];
        TimeSheetLineExist: Label 'Time Sheet Line has not be deleted';

    [Test]
    [Scope('OnPrem')]
    procedure OpenTimeSheetListPage()
    var
        TimeSheetList: TestPage "Time Sheet List";
    begin
        // Verify that Time Sheet List page is opened and not allowed to reopen.

        // Setup: Open Time Sheet List page.
        Initialize();
        TimeSheetList.OpenView();

        // Exercise.
        asserterror TimeSheetList.OpenView();

        // Verify: Verify error message on Time Sheet List page.
        Assert.ExpectedError(PageVerify);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManagerTimeSheetListPage()
    var
        Assert: Codeunit Assert;
        ManagerTimeSheetList: TestPage "Manager Time Sheet List";
    begin
        // Verify that Manager Time Sheet List page is opened and not allowed to reopen.

        // Setup: Open Manager Time Sheet List page.
        Initialize();
        ManagerTimeSheetList.OpenView();

        // Exercise.
        asserterror ManagerTimeSheetList.OpenView();

        // Verify: Verify error message on Manager Time Sheet List page.
        Assert.ExpectedError(PageVerify);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateTimeSheetMenu()
    var
        ResourcesSetup: Record "Resources Setup";
        AccountingPeriod: Record "Accounting Period";
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        ResourceNo: Code[20];
    begin
        // [SCENARIO] Creation of Time Sheet menu is working and creating timesheet
        Initialize();
        ResourcesSetup.Get();
        ResourceNo := CreateTimesheetResourceWithUserSetup();

        // [GIVEN] Open Accounting Period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);

        // [GIVEN] Working Date after Accounting Period Starting Date
        Date.SetRange("Period Type", Date."Period Type"::Date);
        Date.SetFilter("Period Start", '%1..', AccountingPeriod."Starting Date");
        Date.SetRange("Period No.", ResourcesSetup."Time Sheet First Weekday" + 1);  // Here 1 is taken to get first working day of weekday.
        Date.FindFirst();

        // [WHEN] Run Create time sheet
        LibraryTimeSheet.RunCreateTimeSheetsReport(Date."Period Start", 1, ResourceNo);

        // [THEN] Time sheet is created
        TimeSheetHeader.SetRange("Resource No.", ResourceNo);
        Assert.RecordIsNotEmpty(TimeSheetHeader);

        // Tear Down
        DeleteResource(ResourceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetArchivesPage()
    var
        Assert: Codeunit Assert;
        TimeSheetArchiveList: TestPage "Time Sheet Archive List";
    begin
        // Verify that Time Sheet Archive List page is opened and not allowed to reopen.

        // Setup: Open Time Sheet Archive List page.
        Initialize();
        TimeSheetArchiveList.OpenView();

        // Exercise.
        asserterror TimeSheetArchiveList.OpenView();

        // Verify: Verify error message on Time Sheet Archive List page.
        Assert.ExpectedError(PageVerify);
    end;

    [Test]
    [HandlerFunctions('MoveTimeSheetHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MoveTimeSheetsToArchiveBatch()
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        MoveTimeSheetsToArchive: Report "Move Time Sheets to Archive";
    begin
        // Check that Move Time Sheets to Archive Report is working.

        // Setup.
        Initialize();
        TimeSheetNo := CreateTimeSheet(TimeSheetLine);
        TimeSheetLine.Validate(Status, TimeSheetLine.Status::Approved);
        TimeSheetLine.Validate(Posted, true);
        TimeSheetLine.Modify(true);
        Commit();

        // Exercise: Run Move Time Sheets to Archive Report.
        Clear(MoveTimeSheetsToArchive);
        MoveTimeSheetsToArchive.Run();

        // Verify: Verify that Move Time Sheets To Archives report archives created Time Sheet.
        TimeSheetHeaderArchive.Get(TimeSheetNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManagerTimeSheetArchivesPage()
    var
        Assert: Codeunit Assert;
        ManagerTimeSheetArcList: TestPage "Manager Time Sheet Arc. List";
    begin
        // Verify that Manager Time Sheet Archives List page is opened and not allowed to reopen.

        // Setup: Open Manager Time Sheet Archive List page.
        Initialize();
        ManagerTimeSheetArcList.OpenView();

        // Exercise:
        asserterror ManagerTimeSheetArcList.OpenView();

        // Verify: Verify error message on Manager Time Sheet Archive List page.
        Assert.ExpectedError(PageVerify);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceCard()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
    begin
        // Check fields on Resource Card.

        // Setup.
        Initialize();
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        CreateTimesheetResource(Resource, UserSetup);

        // Exercise.
        Resource.Get(Resource."No.");

        // Verify.
        Resource.TestField("Use Time Sheet", true);
        Resource.TestField("Time Sheet Owner User ID", UserSetup."User ID");
        Resource.TestField("Time Sheet Approver User ID", UserSetup."User ID");

        // Tear Down.
        Resource.Delete(true);
    end;

    [Test]
    [HandlerFunctions('TimeSheetHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateTimeSheetsForResource()
    var
        ResourceCard: TestPage "Resource Card";
        ResourceNo: Code[20];
    begin
        // [SCENARIO] Creation of Time Sheet Menu is exists on Resource page
        Initialize();
        ResourceNo := CreateTimesheetResourceWithUserSetup();
        Commit();

        // [GIVEN] Resource card
        ResourceCard.OpenEdit();
        ResourceCard.FILTER.SetFilter("No.", ResourceNo);

        // [WHEN] Perform "Create Time Sheets" action
        ResourceCard.CreateTimeSheets.Invoke();

        // [THEN] REP 950 "Create Time Sheets" has been invoked
        // TimeSheetHandler handler

        // Tear Down.
        DeleteResource(ResourceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceJournalLine()
    var
        Resource: Record Resource;
        ResJournalLine: Record "Res. Journal Line";
        TempResJournalLine: Record "Res. Journal Line" temporary;
        ResJournalTemplate: Record "Res. Journal Template";
        ResJournalBatch: Record "Res. Journal Batch";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // Check fields on the Resource Journal Line.Verification is done through record rather than page because verified fields are not available on the page without Show Column.

        // Setup: Create Resource Journal Template, Resource Batch and Time Sheet.
        Initialize();
        CreateResourceJournalTemplate(ResJournalTemplate);
        LibraryResource.CreateResourceJournalBatch(ResJournalBatch, ResJournalTemplate.Name);
        Resource.SetRange("Use Time Sheet", false);
        Resource.FindFirst();
        CreateTimeSheet(TimeSheetLine);

        // Exercise: Create Resource Journal Line.
        CreateAndModifyResourceJournalLine(ResJournalLine, ResJournalBatch, TimeSheetLine, Resource."No.");
        TempResJournalLine := ResJournalLine;
        Commit();

        // Verify.
        ResJournalLine.TestField("Time Sheet No.", TempResJournalLine."Time Sheet No.");
        ResJournalLine.TestField("Time Sheet Line No.", TempResJournalLine."Time Sheet Line No.");
        ResJournalLine.TestField("Time Sheet Date", TempResJournalLine."Time Sheet Date");
    end;

    [Test]
    [HandlerFunctions('ResourceJournalLineHandler,ResourceJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure MenuSuggestlLinesFromTimeSheetOnResourceJournal()
    var
        TimeSheetLine: Record "Time Sheet Line";
        ResJournalTemplate: Record "Res. Journal Template";
        ResourceJournal: TestPage "Resource Journal";
    begin
        // Check that Suggest Lines from Time Sheets link is exists on Resource Journal.

        // Setup: Create Time Sheet.
        Initialize();
        CreateResourceJournalTemplate(ResJournalTemplate);
        CreateTimeSheet(TimeSheetLine);
        Commit();

        // Exercise.
        ResourceJournal.OpenEdit();
        ResourceJournal.SuggestLinesFromTimeSheets.Invoke();

        // Verify: Verification done in ResourceJournalLineHandler handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldsOnJobJournalLine()
    var
        TempJobJournalLine: Record "Job Journal Line" temporary;
        TimeSheetLine: Record "Time Sheet Line";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
    begin
        // Check fields on the Job Journal Line.Verification is done through record rather than page because verified fields are not available on the page without Show Column.

        // Setup: Create Time Sheet and Job Task.
        Initialize();
        CreateTimeSheet(TimeSheetLine);
        CreateJobAndJobTask(JobTask);

        // Exercise.
        LibraryJob.CreateJobJournalLineForType(LibraryJob.UsageLineTypeBoth(), JobJournalLine.Type::Item, JobTask, JobJournalLine);
        JobJournalLine.Validate("Time Sheet No.", TimeSheetLine."Time Sheet No.");
        JobJournalLine.Validate("Time Sheet Line No.", TimeSheetLine."Line No.");
        JobJournalLine.Validate("Time Sheet Date", TimeSheetLine."Time Sheet Starting Date");
        JobJournalLine.Modify(true);
        TempJobJournalLine := JobJournalLine;

        // Verify.
        JobJournalLine.TestField("Time Sheet No.", TempJobJournalLine."Time Sheet No.");
        JobJournalLine.TestField("Time Sheet Line No.", TempJobJournalLine."Time Sheet Line No.");
        JobJournalLine.TestField("Time Sheet Date", TempJobJournalLine."Time Sheet Date");
    end;

    [Test]
    [HandlerFunctions('JobJournalLineHandler,JobJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure MenuSuggestlLinesFromTimeSheetOnJobJournal()
    var
        TimeSheetLine: Record "Time Sheet Line";
        JobTask: Record "Job Task";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournal: TestPage "Job Journal";
    begin
        // Check that Suggest Lines from Time Sheets exists menu of Job Journal Line.

        // Setup: Create Time Sheet and Job Task.
        Initialize();
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        TimeSheetNo := CreateTimeSheet(TimeSheetLine);
        CreateJobAndJobTask(JobTask);
        Commit();

        // Exercise.
        JobJournal.OpenEdit();
        JobJournal.SuggestLinesFromTimeSheets.Invoke();

        // Verify: Verification done in JobJournalLineHandler handler.
    end;

    [Test]
    [HandlerFunctions('JobJournalLineHandler,JobJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure MenuSuggestlLinesFromTimeSheetOnJobJournalWhereDocumentNoEqualJobNo()
    var
        JobTask: Record "Job Task";
        JobJournalTemplate: Record "Job Journal Template";
        JobsSetup: Record "Jobs Setup";
        JobJournal: TestPage "Job Journal";
        JobsSetupUpdated: Boolean;
    begin
        // Check that Suggest Lines from Time Sheets include copying Job No. to Document No. on Job Journal Line.
        Initialize();

        //[GIVEN] Update Jobs Setup.
        JobsSetup.Get();
        if not JobsSetup."Document No. Is Job No." then begin
            JobsSetup."Document No. Is Job No." := true;
            JobsSetup.Modify(true);
            JobsSetupUpdated := true;
        end;

        //[GIVEN] Create Time Sheet and Job Task.
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        CreateJobAndJobTask(JobTask);
        TimeSheetNo := CreateJobTimeSheet(JobTask."Job No.", JobTask."Job Task No.");
        Commit();

        //[WHEN]Run Suggest Lines from Time Sheets.
        JobJournal.OpenEdit();
        JobJournal.SuggestLinesFromTimeSheets.Invoke();

        //[THEN] Job Journal Line has Document No. equal to Job No.
        JobJournal.Last();
        Assert.AreEqual(JobJournal."Job No.".Value, JobTask."Job No.", 'Job Jnl Line is not created');
        Assert.AreEqual(JobJournal."Job No.".Value, JobJournal."Document No.".Value, 'Document No. is not equal to Job No.');

        if JobsSetupUpdated then begin
            JobsSetup."Document No. Is Job No." := false;
            JobsSetup.Modify(true);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceSetupValidate()
    var
        ResourcesSetup: Record "Resources Setup";
        TimeSheetNos: Code[20];
    begin
        // Check fields on Resources Setup Record.

        // Setup.
        Initialize();
        ResourcesSetup.Get();
        TimeSheetNos := LibraryUtility.GetGlobalNoSeriesCode();

        // Exercise.
        ResourcesSetup.Validate("Time Sheet Nos.", TimeSheetNos);
        ResourcesSetup.Validate("Time Sheet First Weekday", ResourcesSetup."Time Sheet First Weekday"::Monday);
        ResourcesSetup.Validate("Time Sheet by Job Approval", ResourcesSetup."Time Sheet by Job Approval"::Always);
        ResourcesSetup.Modify(true);

        // Verify.
        ResourcesSetup.Get();
        ResourcesSetup.TestField("Time Sheet Nos.", TimeSheetNos);
        ResourcesSetup.TestField("Time Sheet First Weekday", ResourcesSetup."Time Sheet First Weekday"::Monday);
        ResourcesSetup.TestField("Time Sheet by Job Approval", ResourcesSetup."Time Sheet by Job Approval"::Always);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetAdminOnUserSetup()
    var
        UserSetup: Record "User Setup";
    begin
        // Check that User Id has been granted Time Sheet Administrator permissions successfully or not.

        // Setup: Create User Setup.
        Initialize();
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);

        // Exercise.
        UserSetup.Validate("Time Sheet Admin.", true);
        UserSetup.Modify(true);

        // Verify: Verify User Id has been granted Administrator permissions or not.
        UserSetup.Get(UserSetup."User ID");
        UserSetup.TestField("Time Sheet Admin.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteTimeSheetLine()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // Check that Time Sheet Line has been deleted or not.

        // Setup: Create Time Sheet Header and Time Sheet Line.
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');

        // Exercise: Delete Time Sheet Line.
        TimeSheetLine.Delete(true);

        // Verify: Verify that the Time Sheet Line is deleted.
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        Assert.IsFalse(TimeSheetLine.FindFirst(), TimeSheetLineExist);
    end;

    [Test]
    [HandlerFunctions('JobJournalLineHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure EqualSourceCodesPriorityJob()
    var
        JobTask: Record "Job Task";
        SourceCode: Code[10];
        ResourceNo: Code[20];
        PriorityGlobalDimValue: Code[20];
    begin
        // [FEATURE] [Job Journal] [Dimension] [Suggest Job Jnl. Lines]
        // [SCENARIO 380110] Inherit Job's dimension if Template, Job and Resource have the same Source Code and Job priority higher then Resource
        Initialize();

        // [GIVEN] Dimension "DD1" where "Source Code" = "SC", Priority = 1
        // [GIVEN] Dimension "DD2" where "Source Code" = "SC", Priority = 2
        // [GIVEN] Job "J" with Default Dimension "DD1"
        CreateJobTaskResourceAndSourceCode(JobTask, ResourceNo, SourceCode);

        PriorityGlobalDimValue := CreateDimensionWithPriority(SourceCode, DATABASE::Job, JobTask."Job No.", 1);

        // [GIVEN] Resource "R" with Default Dimension "DD2"
        CreateDimensionWithPriority(SourceCode, DATABASE::Resource, ResourceNo, 2);

        // [WHEN] Run "Suggest Job journal lines" in Job Journal Template, where Source Code = "SC"
        RunSuggestJobJnlLinesReport(SourceCode);

        // [THEN] Job Journal Line for "R" created with Dimension "DD1"
        VerifyDimensionOfJobJournalLine(JobTask."Job No.", ResourceNo, PriorityGlobalDimValue);
    end;

    [Test]
    [HandlerFunctions('JobJournalLineHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure EqualSourceCodesPriorityResource()
    var
        JobTask: Record "Job Task";
        ResourceNo: Code[20];
        SourceCode: Code[10];
        PriorityGlobalDimValue: Code[20];
    begin
        // [FEATURE] [Job Journal] [Dimension] [Suggest Job Jnl. Lines]
        // [SCENARIO 380110] Inherit Resource's dimension if Template, Job and Resource have the same Source Code and Resource priority higher then Job
        Initialize();

        // [GIVEN] Dimension "DD1" where "Source Code" = "SC", Priority = 2
        // [GIVEN] Dimension "DD2" where "Source Code" = "SC", Priority = 1
        CreateJobTaskResourceAndSourceCode(JobTask, ResourceNo, SourceCode);

        // [GIVEN] Job "J" with Default Dimension "DD1"
        CreateDimensionWithPriority(SourceCode, DATABASE::Job, JobTask."Job No.", 2);

        // [GIVEN] Resource "R" with Default Dimension "DD2"
        PriorityGlobalDimValue := CreateDimensionWithPriority(SourceCode, DATABASE::Resource, ResourceNo, 1);

        // [WHEN] Run "Suggest Job journal lines" in Job Journal Template, where Source Code = "SC"
        RunSuggestJobJnlLinesReport(SourceCode);

        // [THEN] Job Journal Line for "R" created with Dimension "DD2"
        VerifyDimensionOfJobJournalLine(JobTask."Job No.", ResourceNo, PriorityGlobalDimValue);
    end;

    [Test]
    [HandlerFunctions('JobJournalLineHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure EqualSourceCodesNoDimPriorities()
    var
        JobTask: Record "Job Task";
        SourceCode: Code[10];
        ResourceNo: Code[20];
        PriorityGlobalDimValue: Code[20];
    begin
        // [FEATURE] [Job Journal] [Dimension] [Suggest Job Jnl. Lines]
        // [SCENARIO 380110] Inherit Resource's dimension if Template, Job and Resource have the same Source Code and Resource and Job have equal priorities
        Initialize();

        // [GIVEN] Dimension "DD1" where "Source Code" = "SC", Priority = 1
        // [GIVEN] Dimension "DD2" where "Source Code" = "SC", Priority = 1
        CreateJobTaskResourceAndSourceCode(JobTask, ResourceNo, SourceCode);

        // [GIVEN] Job "J" with Default Dimension "DD1"
        CreateDimensionWithPriority(SourceCode, DATABASE::Job, JobTask."Job No.", 1);

        // [GIVEN] Resource "R" with Default Dimension "DD2"
        PriorityGlobalDimValue := CreateDimensionWithPriority(SourceCode, DATABASE::Resource, ResourceNo, 1);

        // [WHEN] Run "Suggest Job journal lines" in Job Journal Template, where Source Code = "SC"
        RunSuggestJobJnlLinesReport(SourceCode);

        // [THEN] Job Journal Line for "R" created with Dimension "DD2"
        VerifyDimensionOfJobJournalLine(JobTask."Job No.", ResourceNo, PriorityGlobalDimValue);
    end;

    [Test]
    [HandlerFunctions('JobJournalLineHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SourceCodeJoblDimPriorityJob()
    var
        JobTask: Record "Job Task";
        SourceCodeJob: Code[10];
        SourceCodeResource: Code[10];
        ResourceNo: Code[20];
        PriorityGlobalDimValue: Code[20];
    begin
        // [FEATURE] [Job Journal] [Dimension] [Suggest Job Jnl. Lines]
        // [SCENARIO 380110] Inherit Job's dimension if Template and Job have Source Code differs from Resource one and Job priority higher then Resource
        Initialize();

        // [GIVEN] Default Dimension "DD1" where "Source Code" = "SC1", Priority = 1
        // [GIVEN] Default Dimension "DD2" where "Source Code" = "SC2", Priority = 2
        CreateJobTaskResourceAndSourceCode(JobTask, ResourceNo, SourceCodeJob);
        SourceCodeResource := CreateSourceCode();

        // [GIVEN] Job "J" with Default Dimension "DD1"
        PriorityGlobalDimValue := CreateDimensionWithPriority(SourceCodeJob, DATABASE::Job, JobTask."Job No.", 1);

        // [GIVEN] Resource "R" with Default Dimension "DD2"
        CreateDimensionWithPriority(SourceCodeResource, DATABASE::Resource, ResourceNo, 2);

        // [WHEN] Run "Suggest Job journal lines" in Job Journal Template, where Source Code = "SC1"
        RunSuggestJobJnlLinesReport(SourceCodeJob);

        // [THEN] Job Journal Line for "R" created with Dimension "DD1"
        VerifyDimensionOfJobJournalLine(JobTask."Job No.", ResourceNo, PriorityGlobalDimValue);
    end;

    [Test]
    [HandlerFunctions('JobJournalLineHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SourceCodeJobDimPriorityResource()
    var
        JobTask: Record "Job Task";
        SourceCodeJob: Code[10];
        SourceCodeResource: Code[10];
        ResourceNo: Code[20];
        PriorityGlobalDimValue: Code[20];
    begin
        // [FEATURE] [Job Journal] [Dimension] [Suggest Job Jnl. Lines]
        // [SCENARIO 380110] Inherit Job's dimension if Template and Job have Source Code differs from Resource one and Resource priority higher then Job
        Initialize();

        // [GIVEN] Default Dimension "DD1" where "Source Code" = "SC1", Priority = 2
        // [GIVEN] Default Dimension "DD2" where "Source Code" = "SC2", Priority = 1
        CreateJobTaskResourceAndSourceCode(JobTask, ResourceNo, SourceCodeJob);
        SourceCodeResource := CreateSourceCode();

        // [GIVEN] Job "J" with Default Dimension "DD1"
        PriorityGlobalDimValue := CreateDimensionWithPriority(SourceCodeJob, DATABASE::Job, JobTask."Job No.", 2);

        // [GIVEN] Resource "R" with Default Dimension "DD2"
        CreateDimensionWithPriority(SourceCodeResource, DATABASE::Resource, ResourceNo, 1);

        // [WHEN] Run "Suggest Job journal lines" in Job Journal Template, where Source Code = "SC1"
        RunSuggestJobJnlLinesReport(SourceCodeJob);

        // [THEN] Job Journal Line for "R" created with Dimension "DD1"
        VerifyDimensionOfJobJournalLine(JobTask."Job No.", ResourceNo, PriorityGlobalDimValue);
    end;

    [Test]
    [HandlerFunctions('JobJournalLineHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SourceCodeJobNoDimPriorities()
    var
        JobTask: Record "Job Task";
        SourceCodeJob: Code[10];
        SourceCodeResource: Code[10];
        ResourceNo: Code[20];
        PriorityGlobalDimValue: Code[20];
    begin
        // [FEATURE] [Job Journal] [Dimension] [Suggest Job Jnl. Lines]
        // [SCENARIO 380110] Inherit Job's dimension if Template and Job have Source Code differs from Resource one and Resource and Job have equal priorities
        Initialize();

        // [GIVEN] Default Dimension "DD1" where "Source Code" = "SC1", Priority = 1
        // [GIVEN] Default Dimension "DD2" where "Source Code" = "SC2", Priority = 1
        CreateJobTaskResourceAndSourceCode(JobTask, ResourceNo, SourceCodeJob);
        SourceCodeResource := CreateSourceCode();

        // [GIVEN] Job "J" with Default Dimension "DD1"
        PriorityGlobalDimValue := CreateDimensionWithPriority(SourceCodeJob, DATABASE::Job, JobTask."Job No.", 1);

        // [GIVEN] Resource "R" with Default Dimension "DD2"
        CreateDimensionWithPriority(SourceCodeResource, DATABASE::Resource, ResourceNo, 1);

        // [WHEN] Run "Suggest Job journal lines" in Job Journal Template, where Source Code = "SC1"
        RunSuggestJobJnlLinesReport(SourceCodeJob);

        // [THEN] Job Journal Line for "R" created with Dimension "DD1"
        VerifyDimensionOfJobJournalLine(JobTask."Job No.", ResourceNo, PriorityGlobalDimValue);
    end;

    [Test]
    [HandlerFunctions('JobJournalLineHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SourceCodeResourceDimPriorityJob()
    var
        JobTask: Record "Job Task";
        SourceCodeJob: Code[10];
        SourceCodeResource: Code[10];
        ResourceNo: Code[20];
        PriorityGlobalDimValue: Code[20];
    begin
        // [FEATURE] [Job Journal] [Dimension] [Suggest Job Jnl. Lines]
        // [SCENARIO 380110] Inherit Resource's dimension if Template and Resource have Source Code differs from Job one and Job priority higher then Resource
        Initialize();

        // [GIVEN] Default Dim. "DD1" where "Source Code" = "SC1", Priority = 1
        // [GIVEN] Default Dim. "DD2" where "Source Code" = "SC2", Priority = 2
        CreateJobTaskResourceAndSourceCode(JobTask, ResourceNo, SourceCodeJob);
        SourceCodeResource := CreateSourceCode();

        // [GIVEN] Job "J" with Default Dimension "DD1"
        CreateDimensionWithPriority(SourceCodeJob, DATABASE::Job, JobTask."Job No.", 1);

        // [GIVEN] Resource "R" with Default Dimension "DD2"
        PriorityGlobalDimValue := CreateDimensionWithPriority(SourceCodeResource, DATABASE::Resource, ResourceNo, 2);

        // [WHEN] Run "Suggest Job journal lines" in Job Journal Template, where Source Code = "SC2"
        RunSuggestJobJnlLinesReport(SourceCodeResource);

        // [THEN] Job Journal Line for "R" created with Dimension "DD2"
        VerifyDimensionOfJobJournalLine(JobTask."Job No.", ResourceNo, PriorityGlobalDimValue);
    end;

    [Test]
    [HandlerFunctions('JobJournalLineHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SourceCodeResourceDimPriorityResource()
    var
        JobTask: Record "Job Task";
        SourceCodeJob: Code[10];
        SourceCodeResource: Code[10];
        ResourceNo: Code[20];
        PriorityGlobalDimValue: Code[20];
    begin
        // [FEATURE] [Job Journal] [Dimension] [Suggest Job Jnl. Lines]
        // [SCENARIO 380110] Inherit Resource's dimension if Template and Resource have Source Code differs from Job one and Resource priority higher then Job
        Initialize();

        // [GIVEN] Default Dim. "DD1" where "Source Code" = "SC1", Priority = 2
        // [GIVEN] Default Dim. "DD2" where "Source Code" = "SC2", Priority = 1
        CreateJobTaskResourceAndSourceCode(JobTask, ResourceNo, SourceCodeJob);
        SourceCodeResource := CreateSourceCode();

        // [GIVEN] Job "J" with Default Dimension "DD1"
        CreateDimensionWithPriority(SourceCodeJob, DATABASE::Job, JobTask."Job No.", 2);

        // [GIVEN] Resource "R" with Default Dimension "DD2"
        PriorityGlobalDimValue := CreateDimensionWithPriority(SourceCodeResource, DATABASE::Resource, ResourceNo, 1);

        // [WHEN] Run "Suggest Job journal lines" in Job Journal Template, where Source Code = "SC2"
        RunSuggestJobJnlLinesReport(SourceCodeResource);

        // [THEN] Job Journal Line for "R" created with Dimension "DD2"
        VerifyDimensionOfJobJournalLine(JobTask."Job No.", ResourceNo, PriorityGlobalDimValue);
    end;

    [Test]
    [HandlerFunctions('JobJournalLineHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SourceCodeResourceNoDimPriorities()
    var
        JobTask: Record "Job Task";
        SourceCodeJob: Code[10];
        SourceCodeResource: Code[10];
        ResourceNo: Code[20];
        PriorityGlobalDimValue: Code[20];
    begin
        // [FEATURE] [Job Journal] [Dimension] [Suggest Job Jnl. Lines]
        // [SCENARIO 380110] Inherit Resource's dimension if Template and Resource have Source Code differs from Job one and Resource and Job have equal priorities
        Initialize();

        // [GIVEN] Default Dim. "DD1" where "Source Code" = "SC1", Priority = 1
        // [GIVEN] Default Dim. "DD2" where "Source Code" = "SC2", Priority = 1
        CreateJobTaskResourceAndSourceCode(JobTask, ResourceNo, SourceCodeJob);
        SourceCodeResource := CreateSourceCode();

        // [GIVEN] Job "J" with Default Dimension "DD1"
        CreateDimensionWithPriority(SourceCodeJob, DATABASE::Job, JobTask."Job No.", 1);

        // [GIVEN] Resource "R" with Default Dimension "DD2"
        PriorityGlobalDimValue := CreateDimensionWithPriority(SourceCodeResource, DATABASE::Resource, ResourceNo, 1);

        // [WHEN] Run "Suggest Job journal lines" in Job Journal Template, where Source Code = "SC2"
        RunSuggestJobJnlLinesReport(SourceCodeResource);

        // [THEN] Job Journal Line for "R" created with Dimension "DD2"
        VerifyDimensionOfJobJournalLine(JobTask."Job No.", ResourceNo, PriorityGlobalDimValue);
    end;

    [Test]
    [HandlerFunctions('JobJournalLineHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestResTimeSheetJobLinesForTwoMonths()
    var
        JobJournalLine: Record "Job Journal Line";
        ResourceNo: Code[20];
        StartingDate: Date;
        NoOfRemDays: Integer;
    begin
        // [SCENARIO 221547] Suggest lines from time sheet for a resource with job time sheet detail lines
        // [SCENARIO 221547] in case of one week period with month change
        Initialize();

        // [GIVEN] Resource with "Use Time Sheet" = TRUE
        ResourceNo := CreateTimesheetResourceWithUserSetup();
        // [GIVEN] One week time sheet for the resource using Start Date = 28-05-2018 (monday)
        StartingDate := FindWorkingWeekWithMonthChange();
        NoOfRemDays := CalcDate('<CM>', StartingDate) - StartingDate + 1;
        LibraryTimeSheet.RunCreateTimeSheetsReport(StartingDate, 1, ResourceNo);
        // [GIVEN] Five time sheet detail lines using Type = "Job", from 28-05-2018 (monday) to 01-06-2018 (friday)
        CreateWeekTimeSheetDetailsUsingJobForResource(ResourceNo, StartingDate);

        // [GIVEN] From job journal perform "Suggest Lines From Time Sheet" for the resource using "Starting Date" = 01-05-2018, "Ending Date" = 31-05-2018
        InitJobJournalLine(JobJournalLine);
        LibraryTimeSheet.RunSuggestJobJnlLinesReportForResourceInPeriod(
          JobJournalLine, ResourceNo, CalcDate('<-CM>', StartingDate), CalcDate('<CM>', StartingDate));
        // [GIVEN] Four lines have been suggested
        Assert.RecordCount(JobJournalLine, NoOfRemDays);
        // [GIVEN] Post the journal
        PostJobJournalLine(JobJournalLine);

        // [GIVEN] From job journal perform "Suggest Lines From Time Sheet" for the resource using "Starting Date" = 01-06-2018, "Ending Date" = 30-06-2018
        IncrementJobJournalLineBatch(JobJournalLine);
        LibraryTimeSheet.RunSuggestJobJnlLinesReportForResourceInPeriod(
          JobJournalLine, ResourceNo, CalcDate('<1M-CM>', StartingDate), CalcDate('<1M+CM>', StartingDate));
        // [GIVEN] One line has been suggested
        Assert.RecordCount(JobJournalLine, 5 - NoOfRemDays);

        // [WHEN] Post the journal
        PostJobJournalLine(JobJournalLine);

        // [THEN] All resource's time sheet lines (5 pcs) have "Posted" = TRUE
        VerifyTimeSheetLineCountAndPostedStatus(ResourceNo, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertTimeSheetHeaderBlockedResource()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223058] Cassie cannot create time sheet header refered to blocked resource
        LibraryResource.CreateResourceWithUsers(Resource);

        LibraryResource.SetResourceBlocked(Resource);

        TimeSheetHeader.Init();
        TimeSheetHeader."Resource No." := Resource."No.";
        asserterror TimeSheetHeader.Insert(true);

        Assert.ExpectedTestFieldError(Resource.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTimeSheetHeaderBlockedResource()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223058] Cassie cannot set blocked resource in time sheet header
        LibraryResource.CreateResourceWithUsers(Resource);

        TimeSheetHeader.Init();
        TimeSheetHeader.Insert(true);

        LibraryResource.SetResourceBlocked(Resource);

        asserterror TimeSheetHeader.Validate("Resource No.", Resource."No.");

        Assert.ExpectedTestFieldError(Resource.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyTimeSheetHeaderBlockedResource()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223058] Cassie cannot modify resource header refered to blocked resource
        LibraryResource.CreateResourceWithUsers(Resource);

        MockTimeSheetHeader(TimeSheetHeader, Resource."No.");

        LibraryResource.SetResourceBlocked(Resource);

        TimeSheetHeader.Validate("Starting Date", WorkDate());
        asserterror TimeSheetHeader.Modify(true);

        Assert.ExpectedTestFieldError(Resource.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameTimeSheetHeaderBlockedResource()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223058] Cassie cannot rename resource header refered to blocked resource
        LibraryResource.CreateResourceWithUsers(Resource);

        MockTimeSheetHeader(TimeSheetHeader, Resource."No.");

        LibraryResource.SetResourceBlocked(Resource);

        asserterror TimeSheetHeader.Rename(LibraryUtility.GenerateGUID());

        Assert.ExpectedTestFieldError(Resource.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteTimeSheetHeaderBlockedResource()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223058] Cassie cannot delete resource header refered to blocked resource
        LibraryResource.CreateResourceWithUsers(Resource);

        MockTimeSheetHeader(TimeSheetHeader, Resource."No.");

        LibraryResource.SetResourceBlocked(Resource);

        asserterror TimeSheetHeader.Delete(true);

        Assert.ExpectedTestFieldError(Resource.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertTimeSheetLineBlockedResource()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223058] Cassie cannot insert time sheet line into header refered to blocked resource
        LibraryResource.CreateResourceWithUsers(Resource);

        MockTimeSheetHeader(TimeSheetHeader, Resource."No.");

        LibraryResource.SetResourceBlocked(Resource);

        TimeSheetLine.Init();
        TimeSheetLine."Time Sheet No." := TimeSheetHeader."No.";
        asserterror TimeSheetLine.Insert(true);

        Assert.ExpectedTestFieldError(Resource.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyTimeSheetLineBlockedResource()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223058] Cassie cannot modify time sheet line in header refered to blocked resource
        LibraryResource.CreateResourceWithUsers(Resource);

        MockTimeSheetHeader(TimeSheetHeader, Resource."No.");
        MockTimeSheetLine(TimeSheetLine, TimeSheetHeader."No.");

        LibraryResource.SetResourceBlocked(Resource);

        TimeSheetLine.Validate(Description, LibraryUtility.GenerateGUID());
        asserterror TimeSheetLine.Modify(true);

        Assert.ExpectedTestFieldError(Resource.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteTimeSheetLineBlockedResource()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223058] Cassie cannot delete time sheet line from header refered to blocked resource
        LibraryResource.CreateResourceWithUsers(Resource);

        MockTimeSheetHeader(TimeSheetHeader, Resource."No.");
        MockTimeSheetLine(TimeSheetLine, TimeSheetHeader."No.");

        LibraryResource.SetResourceBlocked(Resource);

        asserterror TimeSheetLine.Delete(true);

        Assert.ExpectedTestFieldError(Resource.FieldCaption(Blocked), Format(false));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"RES Time Sheet");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"RES Time Sheet");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Resources Setup");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"RES Time Sheet");
    end;

    local procedure CreateWeekTimeSheetDetailsUsingJobForResource(ResourceNo: Code[20]; StartingDate: Date)
    var
        JobTask: Record "Job Task";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        i: Integer;
    begin
        CreateJobAndJobTask(JobTask);
        FindTimeSheetHeader(TimeSheetHeader, ResourceNo);
        for i := 1 to 5 do begin
            LibraryTimeSheet.CreateTimeSheetLine(
              TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Job, JobTask."Job No.", JobTask."Job Task No.", '', '');
            LibraryTimeSheet.CreateTimeSheetDetail(
              TimeSheetLine, StartingDate + i - 1, LibraryRandom.RandDec(100, 2));
            LibraryTimeSheet.SubmitAndApproveTimeSheetLine(TimeSheetLine);
        end;
    end;

    local procedure CreateTimesheetResourceWithUserSetup(): Code[20]
    var
        Resource: Record Resource;
        UserSetup: Record "User Setup";
    begin
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        CreateTimesheetResource(Resource, UserSetup);
        exit(Resource."No.");
    end;

    local procedure CreateTimesheetResource(var Resource: Record Resource; var UserSetup: Record "User Setup")
    begin
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        Resource.Validate("Time Sheet Owner User ID", UserSetup."User ID");
        Resource.Validate("Time Sheet Approver User ID", UserSetup."User ID");
        Resource.Modify(true);
    end;

    local procedure CreateTimeSheet(var TimeSheetLine: Record "Time Sheet Line"): Code[20]
    var
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
        LibraryTimeSheet.CreateTimeSheetDetail(
          TimeSheetLine, TimeSheetLine."Time Sheet Starting Date", LibraryRandom.RandDec(100, 2));  // Random values taken for Time Sheet Starting Date.
        exit(TimeSheetHeader."No.");
    end;

    local procedure CreateJobTimeSheet(JobNo: Code[20]; JobTaskNo: Code[20]): Code[20]
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        UserSetup: Record "User Setup";
    begin
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Job, JobNo, JobTaskNo, '', '');
        TimeSheetLine.Validate(Status, TimeSheetLine.Status::Approved);
        TimeSheetLine.Modify(true);
        LibraryTimeSheet.CreateTimeSheetDetail(
          TimeSheetLine, TimeSheetLine."Time Sheet Starting Date", LibraryRandom.RandDec(100, 2));  // Random values taken for Time Sheet Starting Date.
        exit(TimeSheetHeader."Resource No.");
    end;

    local procedure CreateResourceJournalTemplate(var ResJournalTemplate: Record "Res. Journal Template")
    begin
        LibraryResource.CreateResourceJournalTemplate(ResJournalTemplate);
        ResJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ResJournalTemplate.Modify(true);
    end;

    local procedure CreateAndModifyResourceJournalLine(var ResJournalLine: Record "Res. Journal Line"; ResJournalBatch: Record "Res. Journal Batch"; TimeSheetLine: Record "Time Sheet Line"; ResourceNo: Code[20])
    begin
        LibraryResource.CreateResJournalLine(ResJournalLine, ResJournalBatch."Journal Template Name", ResJournalBatch.Name);
        ResJournalLine.Validate("Resource No.", ResourceNo);
        ResJournalLine.Validate("Posting Date", WorkDate());
        ResJournalLine.Validate("Document No.", ResourceNo);
        ResJournalLine.Validate("Time Sheet No.", TimeSheetLine."Time Sheet No.");
        ResJournalLine.Validate("Time Sheet Line No.", TimeSheetLine."Line No.");
        ResJournalLine.Validate("Time Sheet Date", TimeSheetLine."Time Sheet Starting Date");
        ResJournalLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));  // Use Random Quantity because value is not important.
        ResJournalLine.Modify(true);
    end;

    local procedure CreateJobAndJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobJournalLine(var JobJournalLine: Record "Job Journal Line"; SourceCode: Code[10])
    var
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalTemplate: Record "Job Journal Template";
    begin
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        JobJournalTemplate.Validate("Source Code", SourceCode);
        JobJournalTemplate.Modify(true);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);
        JobJournalLine.Init();
        JobJournalLine.Validate("Journal Template Name", JobJournalTemplate.Name);
        JobJournalLine.Validate("Journal Batch Name", JobJournalBatch.Name);
        JobJournalLine.Validate("Source Code", SourceCode);
        JobJournalLine.Insert(true);
    end;

    local procedure CreateSourceCode(): Code[10]
    var
        SourceCode: Record "Source Code";
    begin
        LibraryERM.CreateSourceCode(SourceCode);
        exit(SourceCode.Code);
    end;

    local procedure CreateDefaultDimension(TableID: Integer; RecordCode: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, TableID, RecordCode,
          DimensionValue."Dimension Code", DimensionValue.Code);
        exit(DimensionValue.Code);
    end;

    local procedure CreateDimensionWithPriority(SourceCode: Code[10]; TableID: Integer; RecordCode: Code[20]; Priority: Integer) DimValue: Code[20]
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        DimValue := CreateDefaultDimension(TableID, RecordCode);
        LibraryDimension.CreateDefaultDimensionPriority(DefaultDimensionPriority, SourceCode, TableID);
        DefaultDimensionPriority.Validate(Priority, Priority);
        DefaultDimensionPriority.Modify(true);
    end;

    local procedure CreateJobTaskResourceAndSourceCode(var JobTask: Record "Job Task"; var ResourceNo: Code[20]; var SourceCodeJob: Code[10])
    begin
        SourceCodeJob := CreateSourceCode();
        CreateJobAndJobTask(JobTask);
        ResourceNo := CreateJobTimeSheet(JobTask."Job No.", JobTask."Job Task No.");
    end;

    local procedure PostJobJournalLine(var JobJournalLine: Record "Job Journal Line")
    begin
        JobJournalLine.ModifyAll("Document No.", LibraryUtility.GenerateGUID());
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure InitJobJournalLine(var JobJournalLine: Record "Job Journal Line")
    var
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
    begin
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        JobJournalTemplate."Increment Batch Name" := true;
        JobJournalTemplate.Modify();

        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);
        JobJournalLine.Init();
        JobJournalLine.Validate("Journal Template Name", JobJournalTemplate.Name);
        JobJournalLine.Validate("Journal Batch Name", JobJournalBatch.Name);
        JobJournalLine.SetRange("Journal Template Name", JobJournalLine."Journal Template Name");
        JobJournalLine.SetRange("Journal Batch Name", JobJournalLine."Journal Batch Name");
    end;

    local procedure RunSuggestJobJnlLinesReport(SourceCode: Code[10])
    var
        JobJournalLine: Record "Job Journal Line";
        SuggestJobJnlLines: Report "Suggest Job Jnl. Lines";
    begin
        CreateJobJournalLine(JobJournalLine, SourceCode);
        Commit();
        SuggestJobJnlLines.SetJobJnlLine(JobJournalLine);
        SuggestJobJnlLines.Run();
    end;

    local procedure FindWorkingWeekWithMonthChange(): Date
    var
        ResourcesSetup: Record "Resources Setup";
        AccountingPeriod: Record "Accounting Period";
        Date: Record Date;
    begin
        ResourcesSetup.Get();
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        Date.SetRange("Period Type", Date."Period Type"::Date);
        Date.SetFilter("Period Start", '%1..', AccountingPeriod."Starting Date");
        Date.SetRange("Period No.", ResourcesSetup."Time Sheet First Weekday" + 1);
        Date.FindSet();
        while Date2DMY(Date."Period Start", 1) < 28 do
            Date.Next();
        exit(Date."Period Start");
    end;

    local procedure FindTimeSheetHeader(var TimeSheetHeader: Record "Time Sheet Header"; ResourceNo: Code[20])
    begin
        TimeSheetHeader.SetRange("Resource No.", ResourceNo);
        TimeSheetHeader.FindFirst();
    end;

    local procedure MockTimeSheetHeader(var TimeSheetHeader: Record "Time Sheet Header"; ResourceNo: Code[20])
    begin
        TimeSheetHeader.Init();
        TimeSheetHeader."Resource No." := ResourceNo;
        TimeSheetHeader.Insert();
    end;

    local procedure MockTimeSheetLine(var TimeSheetLine: Record "Time Sheet Line"; TimeSheetNo: Code[20])
    begin
        TimeSheetLine.Init();
        TimeSheetLine."Time Sheet No." := TimeSheetNo;
        TimeSheetLine."Line No." := LibraryUtility.GetNewRecNo(TimeSheetLine, TimeSheetLine.FieldNo("Line No."));
        TimeSheetLine.Insert();
    end;

    local procedure IncrementJobJournalLineBatch(var JobJournalLine: Record "Job Journal Line")
    begin
        JobJournalLine."Journal Batch Name" := CopyStr(IncStr(JobJournalLine."Journal Batch Name"), 1, MaxStrLen(JobJournalLine."Journal Batch Name"));
        JobJournalLine.SetRange("Journal Batch Name", JobJournalLine."Journal Batch Name");
        JobJournalLine.DeleteAll(true);
    end;

    local procedure DeleteResource(ResourceNo: Code[20])
    var
        Resource: Record Resource;
    begin
        Resource.Get(ResourceNo);
        Resource.Delete(true);
    end;

    local procedure VerifyDimensionOfJobJournalLine(JobNo: Code[20]; ResourceNo: Code[20]; ExpectedDimValue: Code[20])
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        JobJournalLine.SetRange("Job No.", JobNo);
        JobJournalLine.FindFirst();
        JobJournalLine.TestField(Type, JobJournalLine.Type::Resource);
        JobJournalLine.TestField("No.", ResourceNo);
        JobJournalLine.TestField("Shortcut Dimension 1 Code", ExpectedDimValue);
    end;

    local procedure VerifyTimeSheetLineCountAndPostedStatus(ResourceNo: Code[20]; ExpectedCount: Integer)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        FindTimeSheetHeader(TimeSheetHeader, ResourceNo);
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.SetRange(Posted, true);
        Assert.RecordCount(TimeSheetLine, ExpectedCount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetHandler(var CreateTimeSheets: TestRequestPage "Create Time Sheets")
    begin
        CreateTimeSheets.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ResourceJournalLineHandler(var SuggestResJnlLines: TestRequestPage "Suggest Res. Jnl. Lines")
    begin
        SuggestResJnlLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceJournalTemplateListHandler(var ResJournalTemplateList: TestPage "Res. Journal Template List")
    begin
        ResJournalTemplateList.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobJournalLineHandler(var SuggestJobJnlLines: TestRequestPage "Suggest Job Jnl. Lines")
    begin
        SuggestJobJnlLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobJournalTemplateListHandler(var JobJournalTemplateList: TestPage "Job Journal Template List")
    begin
        JobJournalTemplateList.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MoveTimeSheetHandler(var MoveTimeSheetsToArchive: TestRequestPage "Move Time Sheets to Archive")
    begin
        MoveTimeSheetsToArchive."Time Sheet Header".SetFilter("No.", TimeSheetNo);
        MoveTimeSheetsToArchive.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
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
}
