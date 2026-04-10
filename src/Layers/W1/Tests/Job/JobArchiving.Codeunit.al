codeunit 136321 "Job Archiving"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Project] [Archive]
        Initialized := false
    end;

    var
        Assert: Codeunit Assert;
        JobArchiveManagement: Codeunit "Job Archive Management";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJob: Codeunit "Library - Job";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ArchiveConfirmMsg: Label 'Archive %1 no.: %2?';
        JobArchiveMsg: Label 'Project %1 has been archived.', Comment = '%1 = Project No.';
        JobRestoredMsg: Label '%1 %2 has been restored.', Comment = '%1 = Project Table Caption %2 = Project No.';
        RestoreConfirmMsg: Label 'Do you want to Restore Project %1 Version %2?', Comment = '%1 = Project No. %2 = Version No.';
        MissingJobErr: Label 'Project %1 does not exist anymore.\It is not possible to restore the Project.', Comment = '%1 = Project No.';
        CompletedJobStatusErr: Label 'Status must not be Completed in order to restore the Project: No. = %1', Comment = '%1 = Project No.';
        EndingDateChangedMsg: Label '%1 is set to %2.', Comment = '%1 = The name of the Ending Date field; %2 = This project''s Ending Date value';
        JobLedgerEntryExistErr: Label 'Project Ledger Entries exist for Project No. %1.\It is not possible to restore the Project.', Comment = '%1 = Project No.';
        SalesInvoiceExistErr: Label 'Outstanding Sales Invoice exists for Project No. %1.\It is not possible to restore the Project.', Comment = '%1 = Project No.';
        LinesTransferedToInvoiceMsg: Label 'The lines were successfully transferred to an invoice.';
        Initialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure VerifyJobIsArchivedManually()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify that a job can be archived manually
        Initialize();

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, Job.TableCaption(), Job."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(JobArchiveMsg, Job."No."));

        // [WHEN] Archive Job
        JobArchiveManagement.ArchiveJob(Job);

        // [THEN] Verify results
        CheckIfTableIsArchived(Job, true);
        CheckIfTableIsArchived(JobTask, true);
        CheckIfTableIsArchived(JobPlanningLine, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure VerifyJobIsArchivedOnDeleteWithAlwaysArchive()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify that a job can be archived on delete with Always Archive
        Initialize();

        // [GIVEN] Set Always Archive
        SetArchiveOption('Always');

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);

        // [WHEN] Delete Job
        Job.Delete(true);

        // [THEN] Verify results
        CheckIfTableIsArchived(Job, true);
        CheckIfTableIsArchived(JobTask, true);
        CheckIfTableIsArchived(JobPlanningLine, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure VerifyJobIsArchivedOnDeleteWithArchiveQuestionOption()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify that a job can be archived on delete with Archive with Question option
        Initialize();

        // [GIVEN] Set Archive with Question
        SetArchiveOption('Question');

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, Job.TableCaption(), Job."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(JobArchiveMsg, Job."No."));

        // [WHEN] Delete Job
        Job.Delete(true);

        // [THEN] Verify results
        CheckIfTableIsArchived(Job, true);
        CheckIfTableIsArchived(JobTask, true);
        CheckIfTableIsArchived(JobPlanningLine, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure VerifyJobIsNotArchivedOnDeleteWithNeverArchive()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify that a job is not archived on delete with Never Archive
        Initialize();

        // [GIVEN] Set Never Archive
        SetArchiveOption('Never');

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);

        // [WHEN] Delete Job
        Job.Delete(true);

        // [THEN] Verify results
        CheckIfTableIsArchived(Job, false);
        CheckIfTableIsArchived(JobTask, false);
        CheckIfTableIsArchived(JobPlanningLine, false);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure VerifyJobIsArchivedOnChangeJobStatusWithAlwaysArchive()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify that a job can be archived on change job status with Always Archive
        Initialize();

        // [GIVEN] Set Always Archive
        SetArchiveOption('Always');

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);

        // [WHEN] Change Job Status
        Job.Validate("Status", Job."Status"::Planning);
        Job.Modify(true);

        // [THEN] Verify results
        CheckIfTableIsArchived(Job, true);
        CheckIfTableIsArchived(JobTask, true);
        CheckIfTableIsArchived(JobPlanningLine, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure VerifyRestoreJobIsNotPossibleIfJobNotExist()
    var
        Job: Record Job;
        JobArchive: Record "Job Archive";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify restore job is not possible if job does not exist
        Initialize();

        // [GIVEN] Set Never Archive
        SetArchiveOption('Never');

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, Job.TableCaption(), Job."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(JobArchiveMsg, Job."No."));

        // [GIVEN] Archive Job
        JobArchiveManagement.ArchiveJob(Job);

        // [GIVEN] Find Job Archive
        FindJobArchive(JobArchive, Job, 1);

        // [GIVEN] Delete Job
        Job.Delete(true);

        // [WHEN]  Restore Job 
        asserterror JobArchiveManagement.RestoreJob(JobArchive);

        // [THEN] Verify results
        Assert.ExpectedError(StrSubstNo(MissingJobErr, JobArchive."No."));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure VerifyRestoreJobIsNotPossibleForCompletedJob()
    var
        Job: Record Job;
        JobArchive: Record "Job Archive";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify restore job is not possible for completed job
        Initialize();

        // [GIVEN] Set Never Archive
        SetArchiveOption('Never');

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Set Ending Date
        Job.Validate("Ending Date", WorkDate());
        Job.Modify(true);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, Job.TableCaption(), Job."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(JobArchiveMsg, Job."No."));
        LibraryVariableStorage.Enqueue(StrSubstNo(EndingDateChangedMsg, Job.FieldCaption("Ending Date"), Job."Ending Date"));

        // [GIVEN] Archive Job
        JobArchiveManagement.ArchiveJob(Job);

        // [GIVEN] Find Job Archive
        FindJobArchive(JobArchive, Job, 1);

        // [GIVEN] Change Job Status to Completed        
        Job.Validate("Status", Job."Status"::Completed);
        Job.Modify(true);

        // [WHEN]  Restore Job 
        asserterror JobArchiveManagement.RestoreJob(JobArchive);

        // [THEN] Verify results
        Assert.ExpectedError(StrSubstNo(CompletedJobStatusErr, JobArchive."No."));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,JobTransferToSalesInvoiceRequestPageHandler')]
    procedure VerifyRestoreJobIsNotPossibleIfJobHasJobLedgerEntry()
    var
        Job: Record Job;
        JobArchive: Record "Job Archive";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify restore job is not possible if job has job ledger entry
        Initialize();

        // [GIVEN] Set Never Archive
        SetArchiveOption('Never');

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, Job.TableCaption(), Job."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(JobArchiveMsg, Job."No."));
        LibraryVariableStorage.Enqueue(LinesTransferedToInvoiceMsg);

        // [GIVEN] Archive Job
        JobArchiveManagement.ArchiveJob(Job);

        // [GIVEN] Create Job Planning Line and Post Sales Invoice created from Job Planning Line.
        Commit();
        CreateAndPostSalesInvoiceFromJobPlanningLine(JobPlanningLine);

        // [GIVEN] Find Job Archive
        FindJobArchive(JobArchive, Job, 1);

        // [WHEN]  Restore Job 
        asserterror JobArchiveManagement.RestoreJob(JobArchive);

        // [THEN] Verify results
        Assert.ExpectedError(StrSubstNo(JobLedgerEntryExistErr, JobArchive."No."));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure VerifyArchiveJobVersionOneIsRestoredAfterJobIsChanged()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobArchive: Record "Job Archive";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify that a job version 1 can be restored after job is changed
        Initialize();

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, Job.TableCaption(), Job."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(JobArchiveMsg, Job."No."));

        // [GIVEN] Archive Job
        JobArchiveManagement.ArchiveJob(Job);

        // [GIVEN] Find Job Archive
        FindJobArchive(JobArchive, Job, 1);

        // [GIVEN] Create one more Job Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create two more Job Planning Lines
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);

        // [GIVEN] Enqueue data        
        LibraryVariableStorage.Enqueue(StrSubstNo(RestoreConfirmMsg, Job."No.", 1));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(JobRestoredMsg, Job.TableCaption(), Job."No."));

        // [WHEN] Restore Job version 1
        JobArchiveManagement.RestoreJob(JobArchive);

        // [GIVEN] Find Job Tables
        FindJobTables(Job, JobTask, JobPlanningLine);

        // [THEN] Verify results
        Assert.RecordCount(JobTask, 1);
        Assert.RecordCount(JobPlanningLine, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure JobTaskDimensionsAreDeletedOnRestoreJob()
    var
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobArchive: Record "Job Archive";
    begin
        // [SCENARIO 495223] Job Task Dimensions are deleted on Restore Job
        Initialize();

        // [GIVEN] Create Customer with Default Dimension
        CreateCustomerWithDefaultGlobalDimValue(Customer, DimensionValue);

        // [GIVEN] Create Job
        LibraryJob.CreateJob(Job, Customer."No.");

        // [GIVEN] Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, Job.TableCaption(), Job."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(JobArchiveMsg, Job."No."));

        // [GIVEN] Archive Job
        JobArchiveManagement.ArchiveJob(Job);

        // [GIVEN] Find Job Archive
        FindJobArchive(JobArchive, Job, 1);

        // [GIVEN] Create one more Job Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(RestoreConfirmMsg, Job."No.", 1));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(JobRestoredMsg, Job.TableCaption(), Job."No."));

        // [WHEN] Restore Job version 1
        JobArchiveManagement.RestoreJob(JobArchive);

        // [THEN] Create Job Task with same Task Id
        JobTask.Insert();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure VerifyNoOfArchivedVersionsOnProjectCard()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobCard: TestPage "Job Card";
    begin
        // [SCENARIO 502839] Verify No. of Archived Versions on Project Card
        Initialize();

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, Job.TableCaption(), Job."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(JobArchiveMsg, Job."No."));

        // [GIVEN] Archive Job
        JobArchiveManagement.ArchiveJob(Job);

        // [WHEN] Open Job Card
        JobCard.OpenView();
        JobCard.GoToRecord(Job);

        // [THEN] Verify results
        Assert.AreEqual('1', JobCard."No. of Archived Versions".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,JobTransferToSalesInvoiceRequestPageHandler')]
    procedure RestoreJobIsNotPossibleIfJobHasOutstandingSalesInvoice()
    var
        Job: Record Job;
        JobArchive: Record "Job Archive";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify restore job is not possible if job has outstanding sales invoice
        Initialize();

        // [GIVEN] Set Never Archive
        SetArchiveOption('Never');

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, Job.TableCaption(), Job."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(JobArchiveMsg, Job."No."));
        LibraryVariableStorage.Enqueue(LinesTransferedToInvoiceMsg);

        // [GIVEN] Archive Job
        JobArchiveManagement.ArchiveJob(Job);

        // [GIVEN] Create Job Planning Line
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);

        // [GIVEN] Create Sales Invoice from Job Planning Line.
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [GIVEN] Find Job Archive
        FindJobArchive(JobArchive, Job, 1);

        // [WHEN]  Restore Job 
        asserterror JobArchiveManagement.RestoreJob(JobArchive);

        // [THEN] Verify results
        Assert.ExpectedError(StrSubstNo(SalesInvoiceExistErr, JobArchive."No."));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure VerifyJobArchiveIsRenamedWhenJobNoIsChanged()
    var
        Job: Record Job;
        JobArchive: Record "Job Archive";
        JobCommentLine: Record "Comment Line";
        JobCommentLineArchive: Record "Comment Line";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineArchive: Record "Job Planning Line Archive";
        JobTask: Record "Job Task";
        JobTaskArchive: Record "Job Task Archive";
        NewJobNo, OldJobNo : Code[20];
    begin
        // [SCENARIO 612600] Verify that Job Archive records are renamed when Job No. is changed manually
        Initialize();

        // [GIVEN] Set Always Archive
        SetArchiveOption('Always');

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Comment Line.
        CreateSimpleJobCommentLine(JobCommentLine, Job);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);

        // [GIVEN] Change Job Status to create archive version 1
        Job.Validate("Status", Job."Status"::Planning);
        Job.Modify(true);

        // [GIVEN] Change Job Status again to create archive version 2
        Job.Validate("Status", Job."Status"::Quote);
        Job.Modify(true);

        // [GIVEN] Store the old Job No.
        OldJobNo := Job."No.";

        // [WHEN] Rename Job No.
        NewJobNo := LibraryRandom.RandText(15);
        Job.Rename(NewJobNo);

        // [THEN] Verify Job Archive records are renamed
        JobArchive.SetRange("No.", NewJobNo);
        Assert.AreEqual(2, JobArchive.Count, 'Job Archive should have 2 versions with new Job No.');

        // [THEN] Verify old Job Archive records no longer exist
        JobArchive.SetRange("No.", OldJobNo);
        Assert.AreEqual(0, JobArchive.Count, 'Job Archive should not have any records with old Job No.');

        // [THEN] Verify Job Task Archive records are renamed
        JobTaskArchive.SetRange("Job No.", NewJobNo);
        Assert.IsTrue(JobTaskArchive.FindFirst(), 'Job Task Archive should have records with new Job No.');

        JobTaskArchive.SetRange("Job No.", OldJobNo);
        Assert.AreEqual(0, JobTaskArchive.Count, 'Job Task Archive should not have any records with old Job No.');

        // [THEN] Verify Job Planning Line Archive records are renamed
        JobPlanningLineArchive.SetRange("Job No.", NewJobNo);
        Assert.IsTrue(JobPlanningLineArchive.FindFirst(), 'Job Planning Line Archive should have records with new Job No.');

        JobPlanningLineArchive.SetRange("Job No.", OldJobNo);
        Assert.AreEqual(0, JobPlanningLineArchive.Count, 'Job Planning Line Archive should not have any records with old Job No.');

        // [THEN] Verify Job Comment Line Archive records are renamed
        JobCommentLineArchive.SetRange("No.", NewJobNo);
        Assert.IsTrue(JobCommentLineArchive.FindFirst(), 'Job Comment Line Archive should have records with new Job No.');

        JobCommentLineArchive.SetRange("No.", OldJobNo);
        Assert.AreEqual(0, JobCommentLineArchive.Count, 'Job Comment Line Archive should not have any records with old Job No.');

        // [THEN] Verify No. of Archived Versions is correct
        Job.CalcFields("No. of Archived Versions");
        Assert.AreEqual(2, Job."No. of Archived Versions", 'No. of Archived Versions should be 2 after renumbering');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Archiving");
        LibrarySetupStorage.Restore();

        ClearArchiveTables();

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Archiving");

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Archiving");
    end;

    local procedure ClearArchiveTables()
    var
        JobArchive: Record "Job Archive";
        JobTaskArchive: Record "Job Task Archive";
        JobPlanningLineArchive: Record "Job Planning Line Archive";
    begin
        JobArchive.DeleteAll();
        JobTaskArchive.DeleteAll();
        JobPlanningLineArchive.DeleteAll();
    end;

    local procedure CreateJobAndJobTask(var Job: Record Job; var JobTask: Record "Job Task")
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateSimpleJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task")
    begin
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", JobTask."Job No.");
        JobPlanningLine.Validate("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.Validate("Line No.", LibraryJob.GetNextLineNo(JobPlanningLine));
        JobPlanningLine.Insert(true);
    end;

    local procedure CheckIfTableIsArchived(ArchiveTable: Variant; Archived: Boolean)
    var
        JobArchive: Record "Job Archive";
        JobTaskArchive: Record "Job Task Archive";
        JobPlanningLineArchive: Record "Job Planning Line Archive";
        DataTypeMgt: Codeunit "Data Type Management";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(ArchiveTable);
        case RecRef.Number of
            Database::Job:
                if DataTypeMgt.FindFieldByName(RecRef, FldRef, 'No.') then begin
                    JobArchive.SetRange("No.", FldRef.Value());
                    if Archived then
                        Assert.RecordIsNotEmpty(JobArchive)
                    else
                        Assert.RecordIsEmpty(JobArchive);
                end;
            Database::"Job Task":
                if DataTypeMgt.FindFieldByName(RecRef, FldRef, 'Job No.') then begin
                    JobTaskArchive.SetRange("Job No.", FldRef.Value());
                    if Archived then
                        Assert.RecordIsNotEmpty(JobTaskArchive)
                    else
                        Assert.RecordIsEmpty(JobTaskArchive);
                end;
            Database::"Job Planning Line":
                if DataTypeMgt.FindFieldByName(RecRef, FldRef, 'Job No.') then begin
                    JobPlanningLineArchive.SetRange("Job No.", FldRef.Value());
                    if Archived then
                        Assert.RecordIsNotEmpty(JobPlanningLineArchive)
                    else
                        Assert.RecordIsEmpty(JobPlanningLineArchive);
                end;
        end;
    end;

    local procedure SetArchiveOption(ArchiveOption: Text[10])
    var
        JobsSetup: Record "Jobs Setup";
    begin
        JobsSetup.Get();
        case ArchiveOption of
            'Always':
                JobsSetup."Archive Jobs" := JobsSetup."Archive Jobs"::Always;
            'Question':
                JobsSetup."Archive Jobs" := JobsSetup."Archive Jobs"::Question;
            'Never':
                JobsSetup."Archive Jobs" := JobsSetup."Archive Jobs"::Never;
        end;
        JobsSetup.Modify(true);
    end;

    local procedure FindJobArchive(var JobArchive: Record "Job Archive"; var Job: Record Job; Version: Integer)
    begin
        JobArchive.SetRange("No.", Job."No.");
        JobArchive.SetRange("Version No.", Version);
        JobArchive.FindFirst();
    end;

    local procedure FindJobTables(var Job: Record Job; var JobTask: Record "Job Task"; var JobPlanningLine: Record "Job Planning Line")
    begin
        Job.Get(Job."No.");
        JobTask.SetRange("Job No.", Job."No.");
        JobTask.FindSet();
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.FindSet();
    end;

    local procedure CreateAndPostSalesInvoiceFromJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        FindSalesLine(SalesLine, SalesLine."Document Type"::Invoice, SalesLine.Type::Item, JobPlanningLine."Job No.");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; JobNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange(Type, Type);
        SalesLine.SetRange("Job No.", JobNo);
        SalesLine.FindFirst();
    end;

    local procedure CreateCustomerWithDefaultGlobalDimValue(var Customer: Record Customer; var DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateSimpleJobCommentLine(var JobCommentLine: Record "Comment Line"; Job: Record Job)
    begin
        JobCommentLine.Init();
        JobCommentLine.Validate("Table Name", JobCommentLine."Table Name"::Job);
        JobCommentLine.Validate("No.", Job."No.");
        JobCommentLine.Validate("Line No.", GetNextLineNo(JobCommentLine));
        JobCommentLine.Validate(Date, Today);
        JobCommentLine.Validate(Comment, LibraryRandom.RandText(50));
        JobCommentLine.Insert(true);
    end;

    local procedure GetNextLineNo(JobCommentLine: Record "Comment Line"): Integer
    begin
        JobCommentLine.Reset();
        JobCommentLine.SetRange("Table Name", JobCommentLine."Table Name"::Job);
        JobCommentLine.SetRange("No.", JobCommentLine."No.");
        if JobCommentLine.FindLast() then
            exit(JobCommentLine."Line No." + 10000);

        exit(10000);
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [RequestPageHandler]
    procedure JobTransferToSalesInvoiceRequestPageHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice.OK().Invoke();
    end;
}

