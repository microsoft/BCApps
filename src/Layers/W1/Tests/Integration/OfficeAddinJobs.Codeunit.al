codeunit 139060 "Office Add-in Jobs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Outlook Add-in] [Jobs]
    end;

    var
        Assert: Codeunit Assert;
        LibraryOfficeHostProvider: Codeunit "Library - Office Host Provider";
        LibraryJob: Codeunit "Library - Job";
        LibraryRandom: Codeunit "Library - Random";
        TestJobNoTxt: Label 'TestProjectNo287178';
        TestJobTaskNoTxt: Label 'TestProjectTaskNo82917';
        OfficeHostType: DotNet OfficeHostType;

    [Test]
    [Scope('OnPrem')]
    procedure GetJobInfoFromAppointment()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeJobsHandler: Codeunit "Office Jobs Handler";
        RandomLineNo: Integer;
        JobNo: Text;
        JobTaskNo: Text;
        JobPlanningLineNo: Integer;
    begin
        // [SCENARIO] Test the parsing logic for the calendar appointment information

        // Setup
        Initialize();

        // [GIVEN] Calendar appointment, where Subject is JobNo:JobTaskNo:PlanningLineNo
        OfficeAddinContext.Init();
        RandomLineNo := LibraryRandom.RandInt(9999);
        OfficeAddinContext.Subject := CreateAppointmentSubject(TestJobNoTxt, TestJobTaskNoTxt, RandomLineNo);
        OfficeAddinContext."Item Type" := OfficeAddinContext."Item Type"::Appointment;

        // [WHEN] Run GetJobProperties
        OfficeJobsHandler.GetJobProperties(OfficeAddinContext, JobNo, JobTaskNo, JobPlanningLineNo);

        // [THEN] Returned three values 'ProjectNo', ProjectTaskNo', 'PlanningLineNo'
        Assert.AreEqual(TestJobNoTxt, JobNo, 'Project No. not parsed correctly');
        Assert.AreEqual(TestJobTaskNoTxt, JobTaskNo, 'Project Task No. not parsed correctly');
        Assert.AreEqual(RandomLineNo, JobPlanningLineNo, 'Project Planning Line No. not parsed correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OfficeJobJournalOpens()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        JobPlanningLine: Record "Job Planning Line";
        OfficeJobJournal: TestPage "Office Job Journal";
        Quantity: Integer;
    begin
        // [SCENARIO] Resource completes the job from the calendar appointment
        // [FEATURE] [UI]

        // Setup
        Initialize();

        // [GIVEN] A job planning line exists for a resource.
        CreateJobPlanningLine(JobPlanningLine);

        // [GIVEN] Calendar appoinment with Job information
        OfficeAddinContext.SetRange(
          Subject, CreateAppointmentSubject(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."));
        OfficeAddinContext.SetRange("Item Type", OfficeAddinContext."Item Type"::Appointment);

        // [GIVEN] Add-in opens the Office Job Journal page opens
        OfficeJobJournal.Trap();
        RunMailEngine(OfficeAddinContext);

        // [GIVEN] User sets the quantity
        Quantity := GenerateRandomQuantity();
        OfficeJobJournal.DisplayQuantity.Value(Format(Quantity));

        // [THEN] Office Job Complete page opens with correct values
        VerifyPage(JobPlanningLine, OfficeJobJournal, Quantity, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserCompletesJob()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        OfficeJobJournal: TestPage "Office Job Journal";
        OfficeJobJournalComplete: TestPage "Office Job Journal";
        Quantity: Integer;
    begin
        // [SCENARIO] Resource completes the job from the calendar appointment
        // [FEATURE] [UI]

        // Setup
        Initialize();

        // [GIVEN] Job Information
        CreateJobPlanningLine(JobPlanningLine);

        // [GIVEN] Calendar appoinment with Job information
        OfficeAddinContext.SetRange(
          Subject, CreateAppointmentSubject(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."));
        OfficeAddinContext.SetRange("Item Type", OfficeAddinContext."Item Type"::Appointment);

        // [GIVEN] Add-in opens the Office Job Journal page opens
        OfficeJobJournal.Trap();
        RunMailEngine(OfficeAddinContext);

        // [GIVEN] Job Journal Template and Job Batch Template
        JobJournalTemplate.SetRange("Page ID", PAGE::"Job Journal");
        JobJournalTemplate.SetRange(Recurring, false);
        JobJournalTemplate.FindFirst();
        JobJournalBatch.SetRange("Journal Template Name", JobJournalTemplate.Name);
        JobJournalBatch.FindFirst();

        // [GIVEN] User sets the journal template, journal batch and quantity
        OfficeJobJournal.JobJournalTemplate.Value(JobJournalTemplate.Name);
        OfficeJobJournal.JobJournalBatch.Value(JobJournalBatch.Name);
        Quantity := GenerateRandomQuantity();
        OfficeJobJournal.DisplayQuantity.Value(Format(Quantity));

        // [WHEN] User clicks submit to complete job and Office Job Complete page opens
        OfficeJobJournalComplete.Trap();
        OfficeJobJournal.Submit.Invoke();

        // [THEN] Office Job Complete page opens with correct values
        VerifyPage(JobPlanningLine, OfficeJobJournalComplete, Quantity, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleTemplatesMultipleBatches()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch1: Record "Job Journal Batch";
        JobJournalBatch2: Record "Job Journal Batch";
        OfficeJobJournal: TestPage "Office Job Journal";
    begin
        // [SCENARIO] Multiple Job Journal Templates exist with multiple Job Journal Batches
        // [FEATURE] [UI]

        // Setup
        Initialize();

        // [GIVEN] Job Information
        CreateJobPlanningLine(JobPlanningLine);

        // [GIVEN] Multiple Job Journal Templates exist with multiple Journal Batches
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch1);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch2);

        // [GIVEN] Calendar appoinment with Job information
        OfficeAddinContext.SetRange(
          Subject, CreateAppointmentSubject(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."));
        OfficeAddinContext.SetRange("Item Type", OfficeAddinContext."Item Type"::Appointment);

        // [GIVEN] Add-in opens the Office Job Journal page opens
        OfficeJobJournal.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] Job Journal Template is editable and Job Journal Batch is editable
        Assert.IsTrue(OfficeJobJournal.JobJournalTemplate.Editable(), 'Job journal template');
        OfficeJobJournal.JobJournalTemplate.Value(JobJournalTemplate.Name);
        OfficeJobJournal.JobJournalTemplate.AssertEquals(JobJournalTemplate.Name);
        Assert.IsTrue(OfficeJobJournal.JobJournalBatch.Editable(), 'Job journal batch');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MulitpleTemplatesAndOneBatch()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        OfficeJobJournal: TestPage "Office Job Journal";
    begin
        // [SCENARIO] Multiple Job Journal Templates exists with one Job Journal Batch
        // [FEATURE] [UI]

        // Setup
        Initialize();

        // [GIVEN] Job Information
        CreateJobPlanningLine(JobPlanningLine);

        // [GIVEN] A Job Journal Template with one Journal Batch
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);

        // [GIVEN] Calendar appoinment with Job information
        OfficeAddinContext.SetRange(
          Subject, CreateAppointmentSubject(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."));
        OfficeAddinContext.SetRange("Item Type", OfficeAddinContext."Item Type"::Appointment);

        // [GIVEN] Add-in opens the Office Job Journal page opens
        OfficeJobJournal.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] Job Journal Template is editable and Job Journal Batch is not editable
        Assert.IsTrue(OfficeJobJournal.JobJournalTemplate.Editable(), 'Job journal template');
        OfficeJobJournal.JobJournalTemplate.Value(JobJournalTemplate.Name);
        Assert.IsFalse(OfficeJobJournal.JobJournalBatch.Editable(), 'Job journal batch');
        OfficeJobJournal.JobJournalBatch.AssertEquals(JobJournalBatch.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoBatchesExist()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalTemplate: Record "Job Journal Template";
        OfficeJobJournal: TestPage "Office Job Journal";
    begin
        // [SCENARIO] A Job Journal Template exists with no Job Journal Batches
        // [FEATURE] [UI]

        // Setup
        Initialize();

        // [GIVEN] Job Information
        CreateJobPlanningLine(JobPlanningLine);

        // [GIVEN] A Job Journal Template exists with no Journal Batch
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);

        // [GIVEN] Calendar appoinment with Job information
        OfficeAddinContext.SetRange(
          Subject, CreateAppointmentSubject(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."));
        OfficeAddinContext.SetRange("Item Type", OfficeAddinContext."Item Type"::Appointment);

        // [GIVEN] Add-in opens the Office Job Journal page opens
        OfficeJobJournal.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] An error is displayed that no batches exist for this template
        Assert.IsTrue(OfficeJobJournal.JobJournalTemplate.Editable(), 'Job journal template');
        asserterror OfficeJobJournal.JobJournalTemplate.Value(JobJournalTemplate.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonJobJournalPageTemplate()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalTemplate: Record "Job Journal Template";
        OfficeJobJournal: TestPage "Office Job Journal";
    begin
        // [SCENARIO] User tries to enter a Job Journal Template with a non Job Journal Page Id

        // Setup
        Initialize();

        // [GIVEN] Job Information
        CreateJobPlanningLine(JobPlanningLine);

        // [GIVEN] A Job Journal Template exists with a non Job Journal Page Id
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        JobJournalTemplate."Page ID" := PAGE::"Office Job Journal";

        // [GIVEN] Calendar appoinment with Job information
        OfficeAddinContext.SetRange(
          Subject, CreateAppointmentSubject(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."));
        OfficeAddinContext.SetRange("Item Type", OfficeAddinContext."Item Type"::Appointment);

        // [GIVEN] Add-in opens the Office Job Journal page opens
        OfficeJobJournal.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] An error is displayed when the user enters an the invalid Job Journal Template Name
        asserterror OfficeJobJournal.JobJournalTemplate.Value(JobJournalTemplate.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJournalTemplateRecurring()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalTemplate: Record "Job Journal Template";
        OfficeJobJournal: TestPage "Office Job Journal";
    begin
        // [SCENARIO] User tries to enter a Job Journal Template that is Recurring

        // Setup
        Initialize();

        // [GIVEN] Job Information
        CreateJobPlanningLine(JobPlanningLine);

        // [GIVEN] A Job Journal Template exists that is Recurring
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        JobJournalTemplate.Recurring := true;

        // [GIVEN] Calendar appoinment with Job information
        OfficeAddinContext.SetRange(
          Subject, CreateAppointmentSubject(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."));
        OfficeAddinContext.SetRange("Item Type", OfficeAddinContext."Item Type"::Appointment);

        // [GIVEN] Add-in opens the Office Job Journal page opens
        OfficeJobJournal.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] An error is displayed when the user enters an the invalid Job Journal Template Name
        asserterror OfficeJobJournal.JobJournalTemplate.Value(JobJournalTemplate.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BatchNotBelongingToTemplate()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch1: Record "Job Journal Batch";
        JobJournalBatch2: Record "Job Journal Batch";
        OfficeJobJournal: TestPage "Office Job Journal";
    begin
        // [SCENARIO] User tries to enter a Batch Template that doesn't belong to the Journal Template

        // Setup
        Initialize();

        // [GIVEN] Job Information
        CreateJobPlanningLine(JobPlanningLine);

        // [GIVEN] Job Journal Templates with multiple Journal Batches
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch1);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch2);

        // [GIVEN] Calendar appoinment with Job information
        OfficeAddinContext.SetRange(
          Subject, CreateAppointmentSubject(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."));
        OfficeAddinContext.SetRange("Item Type", OfficeAddinContext."Item Type"::Appointment);

        // [GIVEN] Add-in opens the Office Job Journal page opens
        OfficeJobJournal.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] An error is displayed when the user enters an the invalid Job Journal Batch Name
        OfficeJobJournal.JobJournalTemplate.Value(JobJournalTemplate.Name);
        asserterror OfficeJobJournal.JobJournalBatch.Value('INVALID');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorIsDisplayed()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeErrorDlg: TestPage "Office Error Dlg";
    begin
        // [SCENARIO] Resource has modified the calendar appointment and job can't be found

        // Setup
        Initialize();

        // [GIVEN] Calendar appoinment with Job information
        OfficeAddinContext.SetRange(Subject, CreateAppointmentSubject('123', '456', 789));
        OfficeAddinContext.SetRange("Item Type", OfficeAddinContext."Item Type"::Appointment);

        // [WHEN] Add-in opens the Office Error Dialog page opens
        OfficeErrorDlg.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] Error dialog has correct message
        OfficeErrorDlg.ErrorText.AssertEquals('Cannot find project number 123, project task number 456, line number 789.');
    end;

    local procedure Initialize()
    var
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        OfficeAddin: Record "Office Add-in";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
    begin
        AddinManifestManagement.CreateDefaultAddins(OfficeAddin);
        JobJournalTemplate.SetRange("Page ID", PAGE::"Job Journal");
        JobJournalTemplate.SetRange(Recurring, false);
        if not JobJournalTemplate.FindFirst() then
            LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);

        JobJournalBatch.SetRange("Journal Template Name", JobJournalTemplate.Name);
        if not JobJournalBatch.FindFirst() then
            LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);

        Clear(LibraryOfficeHostProvider);
        BindSubscription(LibraryOfficeHostProvider);
        InitializeOfficeHostProvider(OfficeHostType.OutlookItemEdit);
    end;

    local procedure InitializeOfficeHostProvider(HostType: Text)
    var
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeManagement: Codeunit "Office Management";
        OfficeHost: DotNet OfficeHost;
    begin
        OfficeAddinContext.DeleteAll();
        SetOfficeHostUnAvailable();

        SetOfficeHostProvider(CODEUNIT::"Library - Office Host Provider");

        OfficeManagement.InitializeHost(OfficeHost, HostType);
    end;

    local procedure SetOfficeHostUnAvailable()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        // Test Providers checks whether we have registered Host in NameValueBuffer or not
        if NameValueBuffer.Get(SessionId()) then begin
            NameValueBuffer.Delete();
            Commit();
        end;
    end;

    local procedure SetOfficeHostProvider(ProviderId: Integer)
    var
        OfficeAddinSetup: Record "Office Add-in Setup";
    begin
        OfficeAddinSetup.Get();
        OfficeAddinSetup."Office Host Codeunit ID" := ProviderId;
        OfficeAddinSetup.Modify();
    end;

    local procedure RunMailEngine(var OfficeAddinContext: Record "Office Add-in Context")
    var
        OfficeAddin: Record "Office Add-in";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        OutlookMailEngine: TestPage "Outlook Mail Engine";
    begin
        AddinManifestManagement.GetAddinByHostType(OfficeAddin, OfficeHostType.OutlookItemRead);
        OfficeAddinContext.SetRange(Version, OfficeAddin.Version);

        OutlookMailEngine.Trap();
        PAGE.Run(PAGE::"Outlook Mail Engine", OfficeAddinContext);
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
    end;

    local procedure CreateAppointmentSubject(JobNo: Text; JobTaskNo: Text; JobPlanningLineNo: Integer) AppointmentSubject: Text[250]
    begin
        AppointmentSubject := StrSubstNo('%1:%2:%3', JobNo, JobTaskNo, JobPlanningLineNo);
    end;

    local procedure GenerateRandomQuantity(): Integer
    begin
        exit(LibraryRandom.RandIntInRange(1, 10));
    end;

    local procedure VerifyPage(JobPlanningLine: Record "Job Planning Line"; OfficeJobJournal: TestPage "Office Job Journal"; Quantity: Integer; IsComplete: Boolean)
    begin
        OfficeJobJournal."Job No.".AssertEquals(JobPlanningLine."Job No.");
        OfficeJobJournal."Job Task No.".AssertEquals(JobPlanningLine."Job Task No.");
        OfficeJobJournal.DisplayQuantity.AssertEquals(Quantity);

        Assert.AreEqual(not IsComplete, OfficeJobJournal.DisplayQuantity.Editable(), 'DisplayQuantity Editable');
        Assert.AreEqual(not IsComplete, OfficeJobJournal.Date.Editable(), 'Planning Date Editable');
        Assert.AreEqual(not IsComplete, OfficeJobJournal.Submit.Visible(), 'Submit Visible');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler
    end;
}

