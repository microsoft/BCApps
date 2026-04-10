codeunit 136506 "New Time Sheet Experience"
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
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJob: Codeunit "Library - Job";
        LibraryResource: Codeunit "Library - Resource";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        DescriptionTxt: Label 'Week %1', Comment = '%1 - week number';
        PageDataCaptionTxt: Label '%1 (%2)', Comment = '%1 - start date, %2 - Description,';
        UserSetupStatusTxt: Label 'User Setup (%1 users in User Setup)', Comment = '%1 - number';
        ResourcesStatusTxt: Label 'Resources (%1 resources)', Comment = '%1 - number';
        EmployeesStatusTxt: Label 'Employees (%1 employees)', Comment = '%1 - number';
        CauseofAbsenceStatusTxt: Label 'Causes of Absence (%1 causes of absence)', Comment = '%1 - number';
        navUserEmailTxt: Label 'navuser@email.com', Locked = true;
        TimeSheetCardOwnerUserIDFilter: Text;
        TimeSheetArchiveCardOwnerUserIDFilter: Text;
        UnexpectedTxt: Label 'Unexpected message.';
        ReopenDisabledTxt: Label 'Reopen must be disabled';

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTimeSheetDescription()
    var
        ResourcesSetup: Record "Resources Setup";
        AccountingPeriod: Record "Accounting Period";
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
    begin
        // [FEATURE] [Create Time Sheet]
        // [SCENARIO 390634] Create Time Sheet report makes time sheet default description
        Initialize();

        // [GIVEN] Prepare time sheet resource
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);

        // [WHEN] Create Time Sheet report is being run for "Starting Date" = 25.01.2021
        ResourcesSetup.Get();
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        FindFirstDOW(LibraryRandom.RandDateFrom(AccountingPeriod."Starting Date", 30), Date, ResourcesSetup);
        TimeSheetCreate(Date."Period Start", 1, Resource."No.", TimeSheetHeader);

        // [THEN] Created Time Sheet Header has Description = "Week 5"
        Date.Reset();
        Date.SetRange("Period Type", Date."Period Type"::Week);
        Date.SetFilter("Period Start", '%1..', TimeSheetHeader."Starting Date");
        Date.FindFirst();
        TimeSheetHeader.TestField(Description, StrSubstNo(DescriptionTxt, Date."Period No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenActiveTimeSheet()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TeamMemberActivities: TestPage "Team Member Activities";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action "Open Active Time Sheet" opens time sheet for work date period
        Initialize();

        // [GIVEN] Create 3 time sheets "1", "2" and "3"
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 3);

        // [GIVEN] Set WorkDate within period of time sheet "2" 
        TimeSheetHeader.SetRange("Starting Date", TimeSheetHeader."Starting Date" + 7);
        TimeSheetHeader.FindFirst();
        WorkDate(TimeSheetHeader."Starting Date" + 3);

        // [WHEN] Run action "Open Active Time Sheet" from Team Memeber Activities 
        TimeSheetCard.Trap();
        TeamMemberActivities.OpenView();
        TeamMemberActivities.OpenCurrentTimeSheet.Invoke();

        // [THEN] Time Sheet "2" is opened
        TimeSheetCard."No.".AssertEquals(TimeSheetHeader."No.");

        TimeSheetCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TimeSheetCardSubmit()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        xTimeSheetLineType: Text;
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action Submit on Time Sheet Card page does submit lines
        // [SCENARIO 448247] Copy Type from the previous line.
        // [SCENARIO 448247] Action Approve in subform not available for blank Type.
        Initialize();

        // [GIVEN] Create time sheet with 5 open lines
        CreateTimeSheetWithLines(TimeSheetHeader, false, false, false);
        // [GIVEN] Open time sheet card
        TimeSheetCard.OpenEdit();
        TimeSheetCard.Filter.SetFilter("No.", TimeSheetHeader."No.");

        // [THEN] Action "Reopen" is disabled
        Assert.IsFalse(TimeSheetCard.ReopenSubmitted.Enabled(), 'Reopen must be disabled');
        // [WHEN] Run action "Submit"
        TimeSheetCard.Submit.Invoke();

        // [THEN] All 5 lines are submitted
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Submitted);

        // [THEN] Action "Reopen" is enabled
        Assert.IsTrue(TimeSheetCard.ReopenSubmitted.Enabled(), 'Reopen must be enabled');
        // [THEN] Action "Submit" is disabled
        Assert.IsFalse(TimeSheetCard.Submit.Enabled(), 'Submit must be disabled');

        // [WHEN] Add new line
        TimeSheetCard.TimeSheetLines.Last();
        xTimeSheetLineType := TimeSheetCard.TimeSheetLines.Type.Value();
        TimeSheetCard.TimeSheetLines.New();

        // [THEN] Type is copied from the previous line
        Assert.AreEqual(xTimeSheetLineType, TimeSheetCard.TimeSheetLines.Type.Value(), 'Type must be the same as in the previous line');

        // [WHEN] Change Type to blank
        TimeSheetCard.TimeSheetLines.Type.SetValue("Time Sheet Line Type"::" ");

        // [THEN] Action Approve in subform not available for blank Type
        Assert.IsFalse(TimeSheetCard.TimeSheetLines.Submit.Enabled(), 'Submit must be disabled');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeSheetCardSubmitAllFromSubform()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action Submit on Time Sheet Subform page does submit lines
        Initialize();

        // [GIVEN] Create time sheet with 5 open lines
        CreateTimeSheetWithLines(TimeSheetHeader, false, false, false);
        // [GIVEN] Open time sheet card
        TimeSheetCard.OpenEdit();
        TimeSheetCard.Filter.SetFilter("No.", TimeSheetHeader."No.");

        // [THEN] Action "Reopen" is disabled
        Assert.IsFalse(TimeSheetCard.TimeSheetLines.ReopenSubmitted.Enabled(), 'Reopen must be disabled');
        // [WHEN] Run action "Submit"
        TimeSheetCard.TimeSheetLines.Submit.Invoke();

        // [THEN] All 5 lines are submitted
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Submitted);

        // [THEN] Action "Reopen" is enabled
        Assert.IsTrue(TimeSheetCard.TimeSheetLines.ReopenSubmitted.Enabled(), 'Reopen must be enabled');
        // [THEN] Action "Submit" is disabled
        Assert.IsFalse(TimeSheetCard.TimeSheetLines.Submit.Enabled(), 'Submit must be disabled');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TimeSheetCardReopen()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action Submit on Time Sheet Card page does submit lines
        Initialize();

        // [GIVEN] Create time sheet with 5 submitted lines
        CreateTimeSheetWithLines(TimeSheetHeader, true, false, false);
        // [GIVEN] Open time sheet card
        TimeSheetCard.OpenEdit();
        TimeSheetCard.Filter.SetFilter("No.", TimeSheetHeader."No.");

        // [THEN] Action "Submit" is disabled
        Assert.IsFalse(TimeSheetCard.Submit.Enabled(), 'Submit must be disabled');
        // [WHEN] Run action "Reopen"
        TimeSheetCard.ReopenSubmitted.Invoke();

        // [THEN] All 5 lines are reopened
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Open);

        // [THEN] Action "Submit" is enabled
        Assert.IsTrue(TimeSheetCard.Submit.Enabled(), 'Submit must be enabled');
        // [THEN] Action "Reopen" is disabled
        Assert.IsFalse(TimeSheetCard.ReopenSubmitted.Enabled(), 'Reopen must be disabled');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeSheetCardReopenAllFromSubform()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action Submit on Time Sheet Subform page does submit lines
        Initialize();

        // [GIVEN] Create time sheet with 5 submitted lines
        CreateTimeSheetWithLines(TimeSheetHeader, true, false, false);
        // [GIVEN] Open time sheet card
        TimeSheetCard.OpenEdit();
        TimeSheetCard.Filter.SetFilter("No.", TimeSheetHeader."No.");

        // [THEN] Action "Submit" is disabled
        Assert.IsFalse(TimeSheetCard.TimeSheetLines.Submit.Enabled(), 'Submit must be disabled');
        // [WHEN] Run action "Reopen"
        TimeSheetCard.TimeSheetLines.ReopenSubmitted.Invoke();

        // [THEN] All 5 lines are reopened
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Open);

        // [THEN] Action "Submit" is enabled
        Assert.IsTrue(TimeSheetCard.TimeSheetLines.Submit.Enabled(), 'Submit must be enabled');
        // [THEN] Action "Reopen" is disabled
        Assert.IsFalse(TimeSheetCard.TimeSheetLines.ReopenSubmitted.Enabled(), 'Reopen must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenTimeSheetArchiveCard()
    var
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        TimeSheetArchiveList: TestPage "Time Sheet Archive List";
        TimeSheetArchiveCard: TestPage "Time Sheet Archive Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action "View Time Sheet" of "Time Sheet Archive List" page opens "Time Sheet Archive Card" page
        Initialize();

        // [GIVEN] Create archived time sheet "TS01"
        MockArchivedTimeSheet(TimeSheetHeaderArchive);

        // [GIVEN] Open Time Sheet Archives page
        TimeSheetArchiveList.OpenView();
        TimeSheetArchiveList.Filter.SetFilter("No.", TimeSheetHeaderArchive."No.");

        // [WHEN] Run action "View Time Sheet" 
        TimeSheetArchiveCard.Trap();
        TimeSheetArchiveList."&View Time Sheet".Invoke();

        // [THEN] Archived Time Sheet "TS01" is opened
        TimeSheetArchiveCard."No.".AssertEquals(TimeSheetHeaderArchive."No.");

        TimeSheetArchiveCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenTimeSheetArchiveManagerCard()
    var
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        ManagerTimeSheetArcList: TestPage "Manager Time Sheet Arc. List";
        TimeSheetArchiveCard: TestPage "Time Sheet Archive Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action "View Time Sheet" of "Manager Time Sheet Arc. List" page opens "Time Sheet Archive Card" page
        Initialize();

        // [GIVEN] Create archived time sheet "TS01"
        MockArchivedTimeSheet(TimeSheetHeaderArchive);

        // [GIVEN] Open Time Sheet Archives page
        ManagerTimeSheetArcList.OpenView();
        ManagerTimeSheetArcList.Filter.SetFilter("No.", TimeSheetHeaderArchive."No.");

        // [WHEN] Run action "View Time Sheet" 
        TimeSheetArchiveCard.Trap();
        ManagerTimeSheetArcList."&View Time Sheet".Invoke();

        // [THEN] Archived Time Sheet "TS01" is opened
        TimeSheetArchiveCard."No.".AssertEquals(TimeSheetHeaderArchive."No.");

        TimeSheetArchiveCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenTimeSheetArchiveInTimeSheetLines()
    var
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        TimeSheetLines: TestPage "Time Sheet Lines";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 496952] Time Sheet Archive should be part of Time Sheet Lines list
        Initialize();

        // [GIVEN] Create archived time sheet "TS01"
        MockArchivedTimeSheet(TimeSheetHeaderArchive);

        // [WHEN] Open Time Sheet Lines to check that archived time sheet is visible
        TimeSheetLines.OpenView();
        TimeSheetLines.Filter.SetFilter("Time Sheet No.", TimeSheetHeaderArchive."No.");

        // [THEN] Archived Time Sheet "TS01" is in the list
        TimeSheetLines."Time Sheet No.".AssertEquals(TimeSheetHeaderArchive."No.");

        TimeSheetLines.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateJobStatusWhenExistOnTimeSheetLine()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetLineExistsForJobErr: Label 'One or more unposted Time Sheet lines exists for the project %1.\\You must post or delete the time sheet lines before you can change the project status.', Comment = '%1 = Project No.';
    begin
        // [FEATURE] [Time Sheet], [Job] [Project]
        // [SCENARIO 497260] Job status can`t be updated when time sheet lines exists for the job
        Initialize();

        // [GIVEN] Create job
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        Job.TestField(Status, Job.Status::Open);

        // [GIVEN] Create time sheets, with  job line
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, true);
        CreateTimeSheetLineWithTimeAllocaiton(TimeSheetLine, TimeSheetHeader, "Time Sheet Line Type"::Job, Job."No.", JobTask."Job Task No.");

        // [WHEN] Update job status
        asserterror Job.Validate(Status, Job.Status::Quote);

        // [THEN] Error message is shown
        Assert.ExpectedError(StrSubstNo(TimeSheetLineExistsForJobErr, Job."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetLinesDoesNotContainsEntriesFromOtherUsers()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Resource: Record Resource;
        UserSetup: Record "User Setup";
        TimeSheetLines: TestPage "Time Sheet Lines";
        UpdateUserSetup: Boolean;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 496952] Time Sheet from different owner/approver should not be part of Time Sheet Lines list
        Initialize();

        // [GIVEN] Create time sheet "TS01"
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 1);
        CreateTimeSheetLineWithTimeAllocaiton(TimeSheetHeader, TimeSheetLine);
        TimeSheetLine.Validate(Status, TimeSheetLine.Status::Approved);
        TimeSheetLine.Validate(Posted, true);

        // [GIVEN] with different owner/approver
        TimeSheetLine."Approver ID" := LibraryRandom.RandText(20);
        TimeSheetLine.Modify(true);

        TimeSheetHeader."Owner User ID" := TimeSheetLine."Approver ID";
        TimeSheetHeader."Approver User ID" := TimeSheetLine."Approver ID";
        TimeSheetHeader.Modify();

        // [GIVEN] User is not time sheet admin
        if UserSetup.Get(UserId) then
            if UserSetup."Time Sheet Admin." then begin
                UserSetup."Time Sheet Admin." := false;
                UserSetup.Modify();
                UpdateUserSetup := true;
            end;

        // [WHEN] Open Time Sheet Lines to check is TS01 visible
        TimeSheetLines.OpenView();
        TimeSheetLines.Filter.SetFilter("Time Sheet No.", TimeSheetHeader."No.");

        // [THEN] Time Sheet "TS01" is not in the list
        if TimeSheetLines.Last() then
            Error('Time Sheet Lines must be empty');

        TimeSheetLines.Close();

        if UpdateUserSetup then begin
            UserSetup."Time Sheet Admin." := true;
            UserSetup.Modify();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyTimeSheetLinesNoLinesToCopy()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetCard: TestPage "Time Sheet Card";
        NoLinesToCopyErr: Label 'There are no time sheet lines to show.';
    begin
        // [FEATURE] [Time Sheet], [Copy Time Sheet Lines]
        // [SCENARIO 448248] TS improvement - Copy Lines from Previous TS
        Initialize();

        // [GIVEN] Create X time sheets, but no lines
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Open time sheet card for the last entry
        TimeSheetCard.OpenEdit();
        TimeSheetCard.Filter.SetFilter("Resource No.", Resource."No.");
        TimeSheetCard.Last();

        // [WHEN] Run action "Select and Copy Lines from TS"
        asserterror TimeSheetCard.SelectAndCopyLinesFromTS_Promoted.Invoke();

        // [THEN] Error message is shown
        Assert.IsTrue(StrPos(GetLastErrorText(), NoLinesToCopyErr) > 0, '');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('TimeSheetLinesModalHandler')]
    procedure CopyTimeSheetLinesCopyOneLineFromTS()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        CopiedTimeSheetLine: Record "Time Sheet Line";
        TimeSheetManagement: Codeunit "Time Sheet Management";
    begin
        // [FEATURE] [Time Sheet], [Copy Time Sheet Lines]
        // [SCENARIO 448248] TS improvement - Copy Lines from Previous TS
        Initialize();

        // [GIVEN] Create 2 time sheets, but no lines
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 2);

        // [GIVEN] Added lines into first one
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
        TimeSheetHeader.FindFirst();

        CreateTimeSheetLineWithTimeAllocaiton(TimeSheetHeader, TimeSheetLine);
        TimeSheetLine.Description := LibraryRandom.RandText(20);
        TimeSheetLine.Modify();
        CreateTimeSheetLineWithTimeAllocaiton(TimeSheetHeader, TimeSheetLine);
        TimeSheetLine.Description := LibraryRandom.RandText(20);
        TimeSheetLine.Modify();

        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.FindFirst();

        // [WHEN] Run action "Select and Copy Lines from TS"
        LibraryVariableStorage.Enqueue('CopyTimeSheetLinesCopyOneLineFromTS');
        TimeSheetHeader.FindLast();
        TimeSheetManagement.SelectAndCopyTimeSheetLines(TimeSheetHeader, false);

        // [THEN] Only one line is copied
        CopiedTimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        CopiedTimeSheetLine.FindLast();

        CopiedTimeSheetLine.TestField(Type, TimeSheetLine.Type);
        CopiedTimeSheetLine.TestField(Description, TimeSheetLine.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('TimeSheetLinesModalHandler,CopyTSLinesStrMenuHandler')]
    procedure CopyTimeSheetLinesCopyAllLinesFromTS()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetManagement: Codeunit "Time Sheet Management";
    begin
        // [FEATURE] [Time Sheet], [Copy Time Sheet Lines]
        // [SCENARIO 448248] TS improvement - Copy Lines from Previous TS
        Initialize();

        // [GIVEN] Create 2 time sheets, but no lines
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 2);

        // [GIVEN] Added lines into first one
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
        TimeSheetHeader.FindFirst();

        CreateTimeSheetLineWithTimeAllocaiton(TimeSheetHeader, TimeSheetLine);
        TimeSheetLine.Description := LibraryRandom.RandText(20);
        TimeSheetLine.Modify();
        CreateTimeSheetLineWithTimeAllocaiton(TimeSheetHeader, TimeSheetLine);
        TimeSheetLine.Description := LibraryRandom.RandText(20);
        TimeSheetLine.Modify();

        // [WHEN] Run action "Select and Copy Lines from TS"
        LibraryVariableStorage.Enqueue('CopyTimeSheetLinesCopyAllLinesFromTS');
        TimeSheetHeader.FindLast();
        TimeSheetManagement.SelectAndCopyTimeSheetLines(TimeSheetHeader, false);

        // [THEN] All lines are copied
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        Assert.AreEqual(2, TimeSheetLine.Count, 'Invalid number of lines copied');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetLinesModalHandler(var TimeSheetLines: TestPage "Time Sheet Lines")
    var
        DequeuedText: Text;
    begin
        DequeuedText := LibraryVariableStorage.DequeueText();
        case DequeuedText of
            'CopyTimeSheetLinesCopyOneLineFromTS':
                TimeSheetLines.Last();
            'CopyTimeSheetLinesCopyAllLinesFromTS':
                TimeSheetLines.First();
        end;

        TimeSheetLines.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CopyTSLinesStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetEnterDayValues()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        NewTimeSheetExperience: Codeunit "New Time Sheet Experience";
        TimeSheetCard: TestPage "Time Sheet Card";
        DayQty: array[7] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Data entered into Day1 - Day7 fields recorded correctly
        Initialize();

        // [GIVEN] Create time sheet
        CreateTimeSheet(TimeSheetHeader);

        // [GIVEN] Open time sheet card
        TimeSheetCard.OpenEdit();
        TimeSheetCard.Filter.SetFilter("Resource No.", TimeSheetHeader."Resource No.");

        // [WHEN] Fill in fields Day1 - Day7
        for i := 1 to 7 do
            DayQty[i] := LibraryRandom.RandDec(10, 2);
        TimeSheetCard.TimeSheetLines.Type.SetValue("Time Sheet Line Type"::Resource);
        TimeSheetCard.TimeSheetLines.Field1.SetValue(DayQty[1]);
        TimeSheetCard.TimeSheetLines.Field2.SetValue(DayQty[2]);
        TimeSheetCard.TimeSheetLines.Field3.SetValue(DayQty[3]);
        TimeSheetCard.TimeSheetLines.Field4.SetValue(DayQty[4]);
        TimeSheetCard.TimeSheetLines.Field5.SetValue(DayQty[5]);
        TimeSheetCard.TimeSheetLines.Field6.SetValue(DayQty[6]);
        TimeSheetCard.TimeSheetLines.Field7.SetValue(DayQty[7]);

        // [THEN] Time Sheet details recorded correctly
        VerifyTimeSheetDetailsQty(TimeSheetHeader."No.", DayQty);

        UnbindSubscription(NewTimeSheetExperience);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetGetDataCaptionFull()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetManagement: Codeunit "Time Sheet Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 390634] Function GetTimeSheetDataCaption returns "%1 - %2 (%3)" when time sheet description is not empty
        Initialize();

        // [GIVEN] Create time sheet with "Starting Date" = "04.01.2021", Ending Date = "10.01.2021", Description = "Week 1"
        CreateTimeSheet(TimeSheetHeader);
        TimeSheetHeader.TestField(Description);

        // [THEN] Function GetTimeSheetDataCaption returns 
        Assert.AreEqual(
            StrSubstNo(
                PageDataCaptionTxt,
                Format(TimeSheetHeader."Starting Date", 0, 4),
                TimeSheetHeader.Description),
            TimeSheetManagement.GetTimeSheetDataCaption(TimeSheetHeader),
            'Invalid DataCaption');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetGetDataCaptionShort()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetManagement: Codeunit "Time Sheet Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 390634] Function GetTimeSheetDataCaption returns "%1 - %2 (%3)" when time sheet description is empty
        Initialize();

        // [GIVEN] Create time sheet with "Starting Date" = "04.01.2021", Ending Date = "10.01.2021", Description = ""
        CreateTimeSheet(TimeSheetHeader);
        TimeSheetHeader.Description := '';
        TimeSheetHeader.Modify();

        // [THEN] Function GetTimeSheetDataCaption returns 
        Assert.AreEqual(
                Format(TimeSheetHeader."Starting Date", 0, 4),
            TimeSheetManagement.GetTimeSheetDataCaption(TimeSheetHeader),
            'Invalid DataCaption');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep1Controls()
    var
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard step 1 controls
        Initialize();

        // [WHEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [THEN] Action "Back" is disabled
        Assert.IsFalse(TimeSheetSetupWizard.BackAction.Enabled(), 'Action Back must be disabled');
        // [THEN] Action "Next" is enabled
        Assert.IsTrue(TimeSheetSetupWizard.NextAction.Enabled(), 'Action Next must be enabled');
        // [THEN] Action "Finish" is disabled
        Assert.IsFalse(TimeSheetSetupWizard.FinishAction.Enabled(), 'Action Finish must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep2Controls()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        Employee: Record Employee;
        CauseOfAbsence: Record "Cause of Absence";
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Wizard step 2 actions
        Initialize();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [WHEN] Goto the step 2 "Participants"
        TimeSheetSetupWizard.NextAction.Invoke();

        // [THEN] User Setup Status = User Setup (1 users in User Setup)
        TimeSheetSetupWizard.UserSetupStatus.AssertEquals(StrSubstNo(UserSetupStatusTxt, UserSetup.Count()));
        // [THEN] Resources Setup Status = Resources (5 resources)
        TimeSheetSetupWizard.ResourcesStatus.AssertEquals(StrSubstNo(ResourcesStatusTxt, Resource.Count()));
        // [THEN] Employees Setup Status = Employees (8 employees)
        TimeSheetSetupWizard.EmployeesStatus.AssertEquals(StrSubstNo(EmployeesStatusTxt, Employee.Count()));
        // [THEN] Cause of Absence Status = Causes of Absence (3 causes of absence)
        TimeSheetSetupWizard.CauseOfAbsenceStatus.AssertEquals(StrSubstNo(CauseofAbsenceStatusTxt, CauseOfAbsence.Count()));

        // [THEN] Action "Back" is disabled
        Assert.IsTrue(TimeSheetSetupWizard.BackAction.Enabled(), 'Action Back must be enabled');
        // [THEN] Action "Next" is enabled
        Assert.IsTrue(TimeSheetSetupWizard.NextAction.Enabled(), 'Action Next must be enabled');
        // [THEN] Action "Finish" is disabled
        Assert.IsFalse(TimeSheetSetupWizard.FinishAction.Enabled(), 'Action Finish must be disabled');
    end;

    [Test]
    [HandlerFunctions('UserSetupModalHandler,ResourceListModalHandler,EmployeeListModalHandler,CausesOfAbsenceModalHandler')]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep2Actions()
    var
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Wizard step 2 actions
        Initialize();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();
        // [GIVEN] Goto the step 2 "Participants"
        TimeSheetSetupWizard.NextAction.Invoke();

        // [WHEN] Run drilldown for User Setup Status
        // [THEN] "User Setup" page opened
        TimeSheetSetupWizard.UserSetupStatus.Drilldown();

        // [WHEN] Run drilldown for Resources Status
        // [THEN] "Resource List" page opened
        TimeSheetSetupWizard.ResourcesStatus.Drilldown();

        // [WHEN] Run drilldown for Employee Status
        // [THEN] "Employee List" page opened
        TimeSheetSetupWizard.EmployeesStatus.Drilldown();

        // [WHEN] Run drilldown for Causes of Absence Status
        // [THEN] "Causes of Absence" page opened
        TimeSheetSetupWizard.CauseOfAbsenceStatus.Drilldown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep3Controls()
    var
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard step 3 controls
        Initialize();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [WHEN] Goto the step 3 "General"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [THEN] Action "Back" is disabled
        Assert.IsTrue(TimeSheetSetupWizard.BackAction.Enabled(), 'Action Back must be enabled');
        // [THEN] Action "Next" is enabled
        Assert.IsTrue(TimeSheetSetupWizard.NextAction.Enabled(), 'Action Next must be enabled');
        // [THEN] Action "Finish" is disabled
        Assert.IsFalse(TimeSheetSetupWizard.FinishAction.Enabled(), 'Action Finish must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep3FirstWeekday()
    var
        ResourcesSetup: Record "Resources Setup";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard First Weekday
        Initialize();

        // [GIVEN] Set Resource Setup "Time Sheet First Weekday" = Monday
        TimeSheetHeader.DeleteAll();
        ResourcesSetup.Get();
        ResourcesSetup."Time Sheet First Weekday" := ResourcesSetup."Time Sheet First Weekday"::Monday;
        ResourcesSetup.Modify();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [GIVEN] Goto the step 3 "General"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [WHEN] Change First Day of Week to Saturday
        TimeSheetSetupWizard.FirstDayOfWeek.SetValue(ResourcesSetup."Time Sheet First Weekday"::Saturday);

        // [THEN] Resource Setup has "Time Sheet First Weekday" = Saturday
        ResourcesSetup.Get();
        ResourcesSetup.TestField("Time Sheet First Weekday", ResourcesSetup."Time Sheet First Weekday"::Saturday);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep3TimeSheetAdmin()
    var
        UserSetup: Record "User Setup";
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard First Weekday
        Initialize();

        // [GIVEN] Create user setup with Time Sheet Admin = No
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Time Sheet Admin.", false);
        UserSetup.Modify();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [GIVEN] Goto the step 3 "General"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [WHEN] Set Time Sheet Admin = current user
        TimeSheetSetupWizard.TimeSheetAdmin.SetValue(UserId);

        // [THEN] User Setup has "Time Sheet Admin" = true
        UserSetup.Get(UserId);
        UserSetup.TestField("Time Sheet Admin.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep4Controls()
    var
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard step 4 controls
        Initialize();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [WHEN] Goto the step 4 "Resources"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [THEN] Action "Back" is disabled
        Assert.IsTrue(TimeSheetSetupWizard.BackAction.Enabled(), 'Action Back must be enabled');
        // [THEN] Action "Next" is enabled
        Assert.IsTrue(TimeSheetSetupWizard.NextAction.Enabled(), 'Action Next must be enabled');
        // [THEN] Action "Finish" is disabled
        Assert.IsFalse(TimeSheetSetupWizard.FinishAction.Enabled(), 'Action Finish must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep4TimeSheetByJobApproval()
    var
        ResourcesSetup: Record "Resources Setup";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard "Time Sheet by Job Approval"
        Initialize();

        // [GIVEN] Set Resource Setup "Time Sheet by Job Approval" = Never
        TimeSheetHeader.DeleteAll();
        ResourcesSetup.Get();
        ResourcesSetup."Time Sheet by Job Approval" := ResourcesSetup."Time Sheet by Job Approval"::Never;
        ResourcesSetup.Modify();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [GIVEN] Goto the step 4 "General"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [WHEN] Change "Time Sheet by Job Approval" to Always
        TimeSheetSetupWizard.TimeSheetByJobApproval.SetValue(ResourcesSetup."Time Sheet by Job Approval"::Always);

        // [THEN] Resource Setup has "Time Sheet by Job Approval" = Always
        ResourcesSetup.Get();
        ResourcesSetup.TestField("Time Sheet by Job Approval", ResourcesSetup."Time Sheet by Job Approval"::Always);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep5Controls()
    var
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard step 5 controls
        Initialize();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [WHEN] Goto the step 5 "Employees"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [THEN] Action "Back" is disabled
        Assert.IsTrue(TimeSheetSetupWizard.BackAction.Enabled(), 'Action Back must be enabled');
        // [THEN] Action "Next" is enabled
        Assert.IsTrue(TimeSheetSetupWizard.NextAction.Enabled(), 'Action Next must be enabled');
        // [THEN] Action "Finish" is disabled
        Assert.IsFalse(TimeSheetSetupWizard.FinishAction.Enabled(), 'Action Finish must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TimeSheetWizardSkipStep5NoEmployees()
    var
        Employee: Record Employee;
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard step 5 skipped if no employees
        Initialize();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [GIVEN] Delete all employees
        Employee.DeleteAll();

        // [WHEN] Goto the step 5 
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [THEN] Step "Finish" opened
        Assert.IsTrue(TimeSheetSetupWizard.RunCreateTimeSheets.Visible(), 'Step Finish must be opened');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep6Controls()
    var
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard step 6 controls
        Initialize();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [WHEN] Goto the step 6 "Finish"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [THEN] Action "Back" is disabled
        Assert.IsTrue(TimeSheetSetupWizard.BackAction.Enabled(), 'Action Back must be enabled');
        // [THEN] Action "Next" is disabled
        Assert.IsFalse(TimeSheetSetupWizard.NextAction.Enabled(), 'Action Next must be disabled');
        // [THEN] Action "Finish" is enabled
        Assert.IsTrue(TimeSheetSetupWizard.FinishAction.Enabled(), 'Action Finish must be enabled');
    end;

    [Test]
    [HandlerFunctions('CreateTimeSheetsHandler')]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep6CreateTimeSheets()
    var
        UserSetup: Record "User Setup";
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard step 6 "Create Time Sheets"
        Initialize();

        // [GIVEN] Create user setup with Time Sheet Admin = Yes
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        Commit();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [GIVEN] Goto the step 6 "Finish"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [GIVEN] Set "Create Time Sheets" = Yes
        TimeSheetSetupWizard.RunCreateTimeSheets.SetValue(true);

        // [WHEN] Press "Finish"
        TimeSheetSetupWizard.FinishAction.Invoke();

        // [THEN] Report "Create Time Sheets" opened
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetHeaderResourceName()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        Resource: Record Resource;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 404750] Time Sheet header has Resource Name field
        Initialize();

        // [GIVEN] Create time sheet for resource "R"
        CreateTimeSheet(TimeSheetHeader);
        // [GIVEN] Set name = "NNN" for resource "R"
        Resource.Get(TimeSheetHeader."Resource No.");
        Resource.Name := CopyStr(LibraryRandom.RandText(MaxStrLen(Resource.Name)), 1, MaxStrLen(Resource.Name));
        Resource.Modify();

        // [THEN] Time sheet "Resource Name" = "NNN"
        TimeSheetHeader.CalcFields("Resource Name");
        TimeSheetHeader.TestField("Resource Name", Resource.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardMatchEmployeeVsResource()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        Employee: Record Employee;
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 404725] Time Sheet Setup Wizard matches Employee with Resource by email
        Initialize();

        // [GIVEN] Create time sheet resource "R" for current user
        Resource.ModifyAll("Time Sheet Owner User ID", '');
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);
        // [GIVEN] Set current user email = navuser@email.com
        UserSetup."E-Mail" := navUserEmailTxt;
        UserSetup.Modify();

        // [GIVEN] Create employee "E" with "Company email" = navuser@email.com
        LibraryHumanResource.CreateEmployee(Employee);
        Employee."Company E-Mail" := navUserEmailTxt;
        Employee.Modify();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [WHEN] Goto the step 5 "Employees"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [THEN] Employee "E" matched with resource "R"
        Employee.Find();
        Employee.TestField("Resource No.", Resource."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardMatchEmployeeVsResourceSaaS()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        Employee: Record Employee;
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 404725] Time Sheet Setup Wizard matches Employee with Resource by user Authentication Email
        Initialize();

        // [GIVEN] Create time sheet resource "R" for current user
        Resource.ModifyAll("Time Sheet Owner User ID", '');
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);
        // [GIVEN] Set current user "Authentication Email" = navuser@email.com
        SetCurrentUserAuthenticationEmail(navUserEmailTxt);

        // [GIVEN] Create employee "E" with "Company email" = navuser@email.com
        LibraryHumanResource.CreateEmployee(Employee);
        Employee."Company E-Mail" := navUserEmailTxt;
        Employee.Modify();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [WHEN] Goto the step 5 "Employees"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [THEN] Employee "E" matched with resource "R"
        Employee.Find();
        Employee.TestField("Resource No.", Resource."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyTimeSheetLinesWithDetails()
    var
        FromTimeSheetHeader: Record "Time Sheet Header";
        FromTimeSheetLine: Record "Time Sheet Line";
        ToTimeSheetHeader: Record "Time Sheet Header";
        TimeSheetManagement: Codeunit "Time Sheet Management";
        TimeSheetApprovalManagement: Codeunit "Time Sheet Approval Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 407324] "Copy lines from previous time sheet" copies time sheet details if TimeSheetV2Enabled
        Initialize();

        // [GIVEN] Create time sheet "1" with data
        LibraryTimeSheet.CreateTimeSheet(FromTimeSheetHeader, true);
        CreateTimeSheetLineWithTimeAllocaiton(FromTimeSheetHeader, FromTimeSheetLine);
        // [GIVEN] Submit line
        TimeSheetApprovalManagement.Submit(FromTimeSheetLine);

        // [GIVEN] Create time sheet "2" without data
        TimeSheetCreate(FromTimeSheetHeader."Ending Date" + 1, 1, FromTimeSheetHeader."Resource No.", ToTimeSheetHeader);
        ToTimeSheetHeader.FindLast();

        // [WHEN] Run function "Copy lines from previous time sheet" for time sheet "2"
        TimeSheetManagement.CopyPrevTimeSheetLines(ToTimeSheetHeader);

        // [THEN] Time sheet details copied from "1" to "2"
        VerifyCopiedTimeSheetDetails(FromTimeSheetHeader, FromTimeSheetLine, ToTimeSheetHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubmitEmptyTimeSheetLines()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ResourceSetup: Record "Resources Setup";
        TimeSheetApprovalManagement: Codeunit "Time Sheet Approval Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 448249] Allow submitting empty time sheet lines
        Initialize();

        // [GIVEN] Set "Time Sheet Submission Policy" = "Stop and Show Empty Line Error"
        ResourceSetup.Get();
        ResourceSetup."Time Sheet Submission Policy" := ResourceSetup."Time Sheet Submission Policy"::"Stop and Show Empty Line Error";
        ResourceSetup.Modify();

        // [GIVEN] Create time sheet with data
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, true);
        CreateTimeSheetLineWithTimeAllocaiton(TimeSheetHeader, TimeSheetLine);

        // [GIVEN] and line without quantities
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');

        // [WHEN THEN] Submit line, system throw an error
        TimeSheetLine.Reset();
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        asserterror TimeSheetApprovalManagement.Submit(TimeSheetLine);

        // [WHEN THEN] Set "Time Sheet Submission Policy" = "Empty Lines Not Submitted", submitting will be done successfully
        ResourceSetup."Time Sheet Submission Policy" := ResourceSetup."Time Sheet Submission Policy"::"Empty Lines Not Submitted";
        ResourceSetup.Modify();
        Commit();
        Clear(TimeSheetApprovalManagement);
        TimeSheetApprovalManagement.Submit(TimeSheetLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyTimeSheetLinesWithDetails_ThreeWeeksApart()
    var
        FromTimeSheetHeader: Record "Time Sheet Header";
        FromTimeSheetLine: Record "Time Sheet Line";
        ToTimeSheetHeader: Record "Time Sheet Header";
        TimeSheetManagement: Codeunit "Time Sheet Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 454717] "Copy lines from previous time sheet" copies time sheet details if TimeSheetV2Enabled.
        // [SCENARIO 454717] Create 4 time sheets (4 weeks) and delete 2 in the middle. Then copy lines from time sheet "1" to time sheet "4".
        Initialize();

        // [GIVEN] Create time sheet "1" with data
        LibraryTimeSheet.CreateTimeSheet(FromTimeSheetHeader, true);
        CreateTimeSheetLineWithTimeAllocaiton(FromTimeSheetHeader, FromTimeSheetLine);

        // [GIVEN] Create time sheets "2", "3", "4" without data
        TimeSheetCreate(FromTimeSheetHeader."Ending Date" + 1, 3, FromTimeSheetHeader."Resource No.", ToTimeSheetHeader);

        // [GIVEN] Delete time sheets "2"
        ToTimeSheetHeader.SetRange("Resource No.", FromTimeSheetHeader."Resource No.");
        ToTimeSheetHeader.FindFirst();
        ToTimeSheetHeader.Next();
        ToTimeSheetHeader.Delete(true);

        // [GIVEN] Delete time sheets "3"
        ToTimeSheetHeader.SetRange("Resource No.", FromTimeSheetHeader."Resource No.");
        ToTimeSheetHeader.FindFirst();
        ToTimeSheetHeader.Next();
        ToTimeSheetHeader.Delete(true);

        // [GIVEN] Find the last, time sheets "4"
        ToTimeSheetHeader.SetRange("Resource No.", FromTimeSheetHeader."Resource No.");
        ToTimeSheetHeader.FindLast();

        // [WHEN] Run function "Copy lines from previous time sheet" for time sheet "4"
        TimeSheetManagement.CopyPrevTimeSheetLines(ToTimeSheetHeader);

        // [THEN] Time sheet details copied from "1" to "4"
        VerifyCopiedTimeSheetDetails(FromTimeSheetHeader, FromTimeSheetLine, ToTimeSheetHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetCardDefaultFilterNotAdmin()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        UserSetup: Record "User Setup";
        NewTimeSheetExperience: Codeunit "New Time Sheet Experience";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 421062] Time Sheet Card page has defult filter by owner id if current user is not time sheet admin
        Initialize();

        BindSubscription(NewTimeSheetExperience);

        // [GIVEN] Create time sheet 
        CreateTimeSheetWithLines(TimeSheetHeader, false, false, false);

        // [GIVEN] Current user is not time sheet admin
        UserSetup.Get(UserId);
        UserSetup.Validate("Time Sheet Admin.", false);
        UserSetup.Modify();

        // [WHEN] Time Sheet card page is opened
        TimeSheetCard.OpenEdit();

        // [THEN] Page filtered by Owner User Id
        Assert.AreEqual(UserId(), NewTimeSheetExperience.GetTimeSheetCardOwnerUserIDFilter(), 'Invalid default owner id filter');
        UserSetup.Delete();
        UnbindSubscription(NewTimeSheetExperience);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetCardDefaultFilterAdmin()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        UserSetup: Record "User Setup";
        NewTimeSheetExperience: Codeunit "New Time Sheet Experience";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 421062] Time Sheet Card page has no defult filter by owner id if current user is time sheet admin
        Initialize();

        BindSubscription(NewTimeSheetExperience);

        // [GIVEN] Create time sheet 
        CreateTimeSheetWithLines(TimeSheetHeader, false, false, false);

        // [GIVEN] Current user is time sheet admin
        UserSetup.Get(UserId);
        UserSetup.TestField("Time Sheet Admin.", true);

        // [WHEN] Time Sheet card page is opened
        TimeSheetCard.OpenEdit();

        // [THEN] Page is not filtered by Owner User Id
        Assert.AreEqual('', NewTimeSheetExperience.GetTimeSheetCardOwnerUserIDFilter(), 'Invalid default owner id filter');
        UnbindSubscription(NewTimeSheetExperience);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetCardDefaultFilterNoUserSetup()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        UserSetup: Record "User Setup";
        NewTimeSheetExperience: Codeunit "New Time Sheet Experience";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 421062] Time Sheet Card page has defult filter by owner id if current user does not have user setup
        Initialize();

        BindSubscription(NewTimeSheetExperience);

        // [GIVEN] Create time sheet 
        CreateTimeSheetWithLines(TimeSheetHeader, false, false, false);

        // [GIVEN] Mock no user setup for current user
        UserSetup.Get(UserId);
        UserSetup.Delete();

        // [WHEN] Time Sheet card page is opened
        TimeSheetCard.OpenEdit();

        // [THEN] Page filtered by Owner User Id
        Assert.AreEqual(UserId(), NewTimeSheetExperience.GetTimeSheetCardOwnerUserIDFilter(), 'Invalid default owner id filter');
        UnbindSubscription(NewTimeSheetExperience);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetArchiveCardDefaultFilterNotAdmin()
    var
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        UserSetup: Record "User Setup";
        NewTimeSheetExperience: Codeunit "New Time Sheet Experience";
        TimeSheetArchiveCard: TestPage "Time Sheet Archive Card";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 421062] Time Sheet Archive Card page has defult filter by owner id if current user is not time sheet admin
        Initialize();

        BindSubscription(NewTimeSheetExperience);

        // [GIVEN] Mock time sheet archive
        MockArchivedTimeSheet(TimeSheetHeaderArchive);

        // [GIVEN] Current user is not time sheet admin
        UserSetup.Get(UserId);
        UserSetup.Validate("Time Sheet Admin.", false);
        UserSetup.Modify();

        // [WHEN] Time Sheet Archive card page is opened
        TimeSheetArchiveCard.OpenEdit();

        // [THEN] Page filtered by Owner User Id
        Assert.AreEqual(UserId(), NewTimeSheetExperience.GetTimeSheetArchiveCardOwnerUserIDFilter(), 'Invalid default owner id filter');
        UserSetup.Delete();
        UnbindSubscription(NewTimeSheetExperience);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetArchiveCardDefaultFilterAdmin()
    var
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        UserSetup: Record "User Setup";
        NewTimeSheetExperience: Codeunit "New Time Sheet Experience";
        TimeSheetArchiveCard: TestPage "Time Sheet Archive Card";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 421062] Time Sheet Archive Card page has no defult filter by owner id if current user is time sheet admin
        Initialize();

        BindSubscription(NewTimeSheetExperience);

        // [GIVEN] Mock time sheet archive
        MockArchivedTimeSheet(TimeSheetHeaderArchive);

        // [GIVEN] Current user is time sheet admin
        UserSetup.Get(UserId);
        UserSetup.TestField("Time Sheet Admin.", true);

        // [WHEN] Time Sheet Archive card page is opened
        TimeSheetArchiveCard.OpenEdit();

        // [THEN] Page is not filtered by Owner User Id
        Assert.AreEqual('', NewTimeSheetExperience.GetTimeSheetArchiveCardOwnerUserIDFilter(), 'Invalid default owner id filter');
        UnbindSubscription(NewTimeSheetExperience);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetArchiveCardDefaultFilterNoUserSetup()
    var
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        UserSetup: Record "User Setup";
        NewTimeSheetExperience: Codeunit "New Time Sheet Experience";
        TimeSheetArchiveCard: TestPage "Time Sheet Archive Card";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 421062] Time Sheet Archive Card page has defult filter by owner id if current user is not time sheet admin
        Initialize();

        BindSubscription(NewTimeSheetExperience);

        // [GIVEN] Mock time sheet archive
        MockArchivedTimeSheet(TimeSheetHeaderArchive);

        // [GIVEN] Mock no user setup for current user
        UserSetup.Get(UserId);
        UserSetup.Delete();

        // [WHEN] Time Sheet Archive card page is opened
        TimeSheetArchiveCard.OpenEdit();

        // [THEN] Page filtered by Owner User Id
        Assert.AreEqual(UserId(), NewTimeSheetExperience.GetTimeSheetArchiveCardOwnerUserIDFilter(), 'Invalid default owner id filter');
        UnbindSubscription(NewTimeSheetExperience);
    end;

    [Test]
    [HandlerFunctions('SuggestJobJnlLinesRequestPageHandler,ConfirmHandlerYes,MessageHandler')]
    procedure CopyTimeSheetLinesWithDetailsAfterPosting()
    var
        FromTimeSheetHeader: Record "Time Sheet Header";
        FromTimeSheetLine: Record "Time Sheet Line";
        ToTimeSheetHeader: Record "Time Sheet Header";
        TimeSheetDetail: Record "Time Sheet Detail";
        JobJournalLine: Record "Job Journal Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        TimeSheetManagement: Codeunit "Time Sheet Management";
    begin
        // [SCENARIO 421957] "Copy lines from previous time sheet" for Time Sheet which lines were posted.
        Initialize();

        // [GIVEN] Job "J" with Job Task "T".
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Time Sheet "S1" with one Time Sheet Line that has five Time Sheet Detail.
        // [GIVEN] Time Sheet Line has Job No. "J" and Job Task No. "T".
        LibraryTimeSheet.CreateTimeSheet(FromTimeSheetHeader, true);
        CreateTimeSheetLineWithTimeAllocaiton(FromTimeSheetLine, FromTimeSheetHeader, "Time Sheet Line Type"::Job, Job."No.", JobTask."Job Task No.");

        // [GIVEN] Submitted and approved Time Sheet Line.
        LibraryTimeSheet.SubmitAndApproveTimeSheetLine(FromTimeSheetLine);

        // [GIVEN] Job Journal Lines suggested from Time Sheet "S1" and posted.
        InitJobJournalLine(JobJournalLine);
        LibraryTimeSheet.RunSuggestJobJnlLinesReportForResourceInPeriod(
            JobJournalLine, FromTimeSheetHeader."Resource No.", WorkDate(), CalcDate('<1M>', WorkDate()));
        TimeSheetDetail.SetRange("Time Sheet No.", FromTimeSheetHeader."No.");
        Assert.RecordCount(JobJournalLine, TimeSheetDetail.Count);
        PostJobJournalLine(JobJournalLine);

        // [GIVEN] Create time sheet "S2" without Time Sheet Lines.
        TimeSheetCreate(FromTimeSheetHeader."Ending Date" + 1, 1, FromTimeSheetHeader."Resource No.", ToTimeSheetHeader);
        ToTimeSheetHeader.FindLast();

        // [WHEN] Run function "Copy lines from previous time sheet" for Time Sheet "S2".
        TimeSheetManagement.CopyPrevTimeSheetLines(ToTimeSheetHeader);

        // [THEN] Time Sheet Details were copied from "S1" to "S2" with Posted Quantity = 0.
        VerifyCopiedTimeSheetDetails(FromTimeSheetHeader, FromTimeSheetLine, ToTimeSheetHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTimeSheetListOnTeamMemberActivities()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        FromTimeSheetHeader: Record "Time Sheet Header";
        CreateTimeSheets: Report "Create Time Sheets";
        NewTimeSheetExperience: Codeunit "New Time Sheet Experience";
        TeamMemberActivities: TestPage "Team Member Activities";
        TimeSheetList: TestPage "Time Sheet List";
    begin
        // [SCENARIO 447634] Open Current Time sheet' in the role center through error when timesheet exist for some other dates
        Initialize();
        BindSubscription(NewTimeSheetExperience);

        // [THEN] Deleteall the records created by other test automation for current user. 
        TimeSheetHeader.DeleteAll();

        // [GIVEN] Create resource and update Use time sheet as true.
        LibraryResource.CreateResourceWithUsers(Resource);
        Resource.Validate("Use Time Sheet", true);
        Resource.Modify(true);

        // [WHEN] User tries to run Report Create Time Sheets
        LibraryTimeSheet.CreateTimeSheet(FromTimeSheetHeader, true);
        CreateTimeSheets.InitParameters(FromTimeSheetHeader."Starting Date" + 1, 1, Resource."No.", false, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run();

        // [THEN] Filter creating timesheet.
        WorkDate(FromTimeSheetHeader."Starting Date" - 1);
        TimeSheetHeader.SetFilter("Resource No.", Resource."No.");
        TimeSheetHeader.FindFirst();

        // [GIVEN] Try to open current timesheet and go to created time sheet record.  
        TimeSheetList.Trap();
        TeamMemberActivities.OpenView();
        TeamMemberActivities.OpenCurrentTimeSheet.Invoke();
        TimeSheetList.GoToRecord(TimeSheetHeader);

        // [VERIFY] time sheet list is not empty and it contain the creaeted timesheet record.
        Assert.AreEqual(Resource."No.", TimeSheetList."Resource No.".Value, '');

        UnbindSubscription(NewTimeSheetExperience);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure S458927_CreateLinesFromJobPlanning_SkipInvalidJobPlanningLines()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ResourcesSetup: Record "Resources Setup";
        Resource: Record Resource;
        Job: array[3] of Record Job;
        JobTask: array[3] of Record "Job Task";
        JobPlanningLine: array[3] of Record "Job Planning Line";
        DateRecord: Record Date;
        TimeSheetManagement: Codeunit "Time Sheet Management";
    begin
        // [FEATURE] [UT] [Create lines from job planning]
        // [SCENARIO 458927] "Create lines from job planning" skips "Job Planning Line" if Job.Blocked = All or Job.Status = Completed.
        // [SCENARIO 458927] Create 3 Jobs: J1 with Blocked = All, J2 with default Blocked and Status, J3 in Status = Completed.
        // [SCENARIO 458927] Verify that "Create lines from job planning" only processed J2.
        Initialize();

        // [GIVEN] Set "Time Sheet by Job Approval" in "Resources Setup"
        ResourcesSetup.Get();
        ResourcesSetup."Time Sheet by Job Approval" := ResourcesSetup."Time Sheet by Job Approval"::Never;
        ResourcesSetup.Modify();

        // [GIVEN] Create Time Sheet
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);

        Resource.Get(TimeSheetHeader."Resource No.");

        DateRecord.SetRange("Period Type", DateRecord."Period Type"::Date);
        DateRecord.SetFilter("Period Start", '%1..', TimeSheetHeader."Starting Date");
        DateRecord.SetRange("Period No.", ResourcesSetup."Time Sheet First Weekday" + 1);
        DateRecord.FindFirst();

        // [GIVEN] Create Job "J1" with Blocked = All
        CreateJobWithJobPlanning(Resource, DateRecord, Job[1], JobTask[1], JobPlanningLine[1]);
        Job[1].Validate(Blocked, Job[1].Blocked::All);
        Job[1].Modify();

        // [GIVEN] Create Job "J2" with default Blocked and Status
        CreateJobWithJobPlanning(Resource, DateRecord, Job[2], JobTask[2], JobPlanningLine[2]);

        // [GIVEN] Create Job "J3" in Status = Completed
        CreateJobWithJobPlanning(Resource, DateRecord, Job[3], JobTask[3], JobPlanningLine[3]);
        Job[3].Validate(Status, Job[3].Status::Completed);
        Job[3].Modify();

        // [WHEN] Run action "Create lines from job planning"
        TimeSheetManagement.CreateLinesFromJobPlanning(TimeSheetHeader);

        // [THEN] Verify that only 1 line has been created
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        Assert.RecordCount(TimeSheetLine, 1);

        // [THEN] Verify that line is created for "J2"
        TimeSheetLine.FindFirst();
        TimeSheetLine.TestField(Type, TimeSheetLine.Type::Job);
        TimeSheetLine.TestField("Job No.", Job[2]."No.");
        TimeSheetLine.TestField("Job Task No.", JobTask[2]."Job Task No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerify')]
    [Scope('OnPrem')]
    procedure VerifyEmpoloymentDateWarningTimeSheet()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [SCENARIO 459803] Resources are able to enter time in time sheets prior to the date in their Employment Date field without error
        Initialize();

        // [GIVEN] Create time sheet with 5 open lines
        CreateTimeSheetWithLines(TimeSheetHeader, false, false, false);

        // [GIVEN] Add Employment Date greater thane timesheet creation date
        Resource.Get(TimeSheetHeader."Resource No.");
        Resource.Validate("Employment Date", CalcDate('<+1M>', TimeSheetHeader."Starting Date"));
        Resource.Modify();

        // [GIVEN] Open time sheet card
        TimeSheetCard.OpenEdit();
        TimeSheetCard.Filter.SetFilter("No.", TimeSheetHeader."No.");

        // [THEN] Action "Reopen" is disabled
        Assert.IsFalse(TimeSheetCard.ReopenSubmitted.Enabled(), ReopenDisabledTxt);

        // [WHEN] Run action "Submit"
        // [THEN] Verify Employment Date warning message on handler page.
        TimeSheetCard.Submit.Invoke();

        // [VERIFY] All 5 lines are submitted
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Submitted);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";

    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"New Time Sheet Experience");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"New Time Sheet Experience");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Resources Setup");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"New Time Sheet Experience");
    end;

    local procedure CreateTimeSheetLineWithTimeAllocaiton(TimeSheetHeader: Record "Time Sheet Header"; var TimeSheetLine: Record "Time Sheet Line")
    var
        i: Integer;
    begin
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
        for i := 1 to 5 do
            LibraryTimeSheet.CreateTimeSheetDetail(
                TimeSheetLine, TimeSheetHeader."Starting Date" + i - 1, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateTimeSheetLineWithTimeAllocaiton(var TimeSheetLine: Record "Time Sheet Line"; TimeSheetHeader: Record "Time Sheet Header"; LineType: Enum "Time Sheet Line Type"; JobNo: Code[20]; JobTaskNo: Code[20])
    var
        i: Integer;
    begin
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, LineType, JobNo, JobTaskNo, '', '');
        for i := 1 to 5 do
            LibraryTimeSheet.CreateTimeSheetDetail(
                TimeSheetLine, TimeSheetHeader."Starting Date" + i - 1, LibraryRandom.RandDecInRange(5, 15, 2));
    end;

    local procedure CreateTimeSheetWithLines(var TimeSheetHeader: Record "Time Sheet Header"; Submit: Boolean; Approve: Boolean; Reject: Boolean)
    var
        Resource: Record Resource;
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetApprovalManagement: Codeunit "Time Sheet Approval Management";
        i: Integer;
    begin
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 1);
        for i := 1 to LibraryRandom.RandIntInRange(3, 7) do begin
            CreateTimeSheetLineWithTimeAllocaiton(TimeSheetHeader, TimeSheetLine);
            if Submit then
                TimeSheetApprovalManagement.Submit(TimeSheetLine);
            if Approve then
                TimeSheetApprovalManagement.Approve(TimeSheetLine);
            if Reject then
                TimeSheetApprovalManagement.Reject(TimeSheetLine);
        end;
    end;

    local procedure CreateTimeSheet(var TimeSheetHeader: Record "Time Sheet Header")
    var
        Resource: Record Resource;
    begin
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 1);
    end;

    local procedure MockArchivedTimeSheet(var TimeSheetHeaderArchive: Record "Time Sheet Header Archive")
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Resource: Record Resource;
        TimeSheetManagement: Codeunit "Time Sheet Management";
    begin
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 1);
        CreateTimeSheetLineWithTimeAllocaiton(TimeSheetHeader, TimeSheetLine);
        TimeSheetLine.Validate(Status, TimeSheetLine.Status::Approved);
        TimeSheetLine.Validate(Posted, true);
        TimeSheetLine.Modify(true);

        TimeSheetManagement.MoveTimeSheetToArchive(TimeSheetHeader);
        TimeSheetHeaderArchive.Get(TimeSheetHeader."No.");
    end;

    local procedure CreateMultipleTimeSheet(var Resource: Record Resource; var TimeSheetHeader: Record "Time Sheet Header"; NoOfTimeSheets: Integer)
    var
        UserSetup: Record "User Setup";
        AccountingPeriod: Record "Accounting Period";
        Date: Record Date;
        ResourcesSetup: Record "Resources Setup";
    begin
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);

        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        FindFirstDOW(AccountingPeriod."Starting Date", Date, ResourcesSetup);

        TimeSheetCreate(Date."Period Start", NoOfTimeSheets, Resource."No.", TimeSheetHeader);
        TimeSheetHeader.Reset();
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
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

    local procedure PostJobJournalLine(var JobJournalLine: Record "Job Journal Line")
    begin
        JobJournalLine.ModifyAll("Document No.", LibraryUtility.GenerateGUID());
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure TimeSheetCreate(Date: Date; NoOfPeriods: Integer; ResourceNo: Code[20]; var TimeSheetHeader: Record "Time Sheet Header")
    var
        CreateTimeSheets: Report "Create Time Sheets";
    begin
        CreateTimeSheets.InitParameters(Date, NoOfPeriods, ResourceNo, false, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run();

        TimeSheetHeader.SetRange("Resource No.", ResourceNo);
        TimeSheetHeader.FindFirst();
    end;

    local procedure SetCurrentUserAuthenticationEmail(AuthenticationEmail: Text[250])
    var
        User: Record User;
    begin
        User.SetRange("User Name", UserId());
        if not User.FindFirst() then begin
            User.Init();
            User."User Security ID" := CreateGuid();
            User."User Name" := CopyStr(UserId(), 1, MaxStrLen(User."User Name"));
            User."Authentication Email" := AuthenticationEmail;
            User.Insert();
        end else begin
            User."Authentication Email" := AuthenticationEmail;
            User.Modify();
        end;
    end;

    local procedure FindFirstDOW(StartingDate: Date; var Date: Record Date; var ResourcesSetup: Record "Resources Setup")
    begin
        // find first DOW after accounting period starting date
        Date.SetRange("Period Type", Date."Period Type"::Date);
        Date.SetFilter("Period Start", '%1..', StartingDate);
        Date.SetRange("Period No.", ResourcesSetup."Time Sheet First Weekday" + 1);
        Date.FindFirst();
    end;

    local procedure SetupTSResourceUserID(var Resource: Record Resource; UserSetup: Record "User Setup")
    begin
        Resource.Validate("Time Sheet Owner User ID", UserSetup."User ID");
        Resource.Validate("Time Sheet Approver User ID", UserSetup."User ID");
        Resource.Modify();
    end;

    local procedure VerifyTimeSheetLinesStatus(TimeSheetHeaderNo: Code[20]; ExpectedStatus: Enum "Time Sheet Status")
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeaderNo);
        TimeSheetLine.FindSet();
        repeat
            TimeSheetLine.TestField(Status, ExpectedStatus);
        until TimeSheetLine.Next() = 0;
    end;

    local procedure VerifyTimeSheetDetailsQty(TimeSheetHeaderNo: Code[20]; DayQty: array[7] of Decimal)
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        i: Integer;
    begin
        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetHeaderNo);
        TimeSheetDetail.FindSet();
        repeat
            i := i + 1;
            TimeSheetDetail.TestField(Quantity, DayQty[i]);
        until TimeSheetDetail.Next() = 0;
    end;

    local procedure VerifyCopiedTimeSheetDetails(FromTimeSheetHeader: Record "Time Sheet Header"; FromTimeSheetLine: Record "Time Sheet Line"; ToTimeSheetHeader: Record "Time Sheet Header")
    var
        ToTimeSheetLine: Record "Time Sheet Line";
        FromTimeSheetDetail: Record "Time Sheet Detail";
        ToTimeSheetDetail: Record "Time Sheet Detail";
    begin
        FromTimeSheetDetail.SetRange("Time Sheet No.", FromTimeSheetHeader."No.");
        FromTimeSheetDetail.SetRange("Time Sheet Line No.", FromTimeSheetLine."Line No.");
        FromTimeSheetDetail.FindSet();

        ToTimeSheetLine.SetRange("Time Sheet No.", ToTimeSheetHeader."No.");
        ToTimeSheetLine.FindFirst();
        ToTimeSheetDetail.SetRange("Time Sheet No.", ToTimeSheetHeader."No.");
        ToTimeSheetDetail.SetRange("Time Sheet Line No.", ToTimeSheetLine."Line No.");
        ToTimeSheetDetail.FindSet();

        repeat
            ToTimeSheetDetail.TestField(Posted, false);
            ToTimeSheetDetail.TestField(Status, "Time Sheet Status"::Open);
            ToTimeSheetDetail.TestField(Quantity, FromTimeSheetDetail.Quantity);
            ToTimeSheetDetail.TestField("Posted Quantity", 0);
            ToTimeSheetDetail.TestField(Date, ToTimeSheetLine."Time Sheet Starting Date" + (FromTimeSheetDetail."Date" - FromTimeSheetLine."Time Sheet Starting Date"));

            ToTimeSheetDetail.Next();
        until FromTimeSheetDetail.Next() = 0;
    end;

    local procedure CreateJobWithJobPlanning(Resource: Record Resource; Date: Record Date; var Job: Record Job; var JobTask: Record "Job Task"; var JobPlanningLine: Record "Job Planning Line")
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
        JobPlanningLine.Quantity := LibraryRandom.RandDec(10, 2);
        JobPlanningLine."Unit Cost" := LibraryRandom.RandDec(10, 2);
        JobPlanningLine.Insert();
    end;

    procedure GetTimeSheetCardOwnerUserIDFilter(): Text
    begin
        exit(TimeSheetCardOwnerUserIDFilter);
    end;

    procedure GetTimeSheetArchiveCardOwnerUserIDFilter(): Text
    begin
        exit(TimeSheetArchiveCardOwnerUserIDFilter);
    end;

    [MessageHandler]
    procedure MessageHandler(MessageText: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerVerify(Question: Text; var Reply: Boolean)
    var
        TimeSheetTxt: Label 'Time Sheet';
    begin
        Assert.IsTrue(StrPos(Question, TimeSheetTxt) > 0, UnexpectedTxt); // [VERIFY] Timesheet Employment Date message 
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UserSetupModalHandler(var UserSetup: TestPage "User Setup")
    begin
        UserSetup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceListModalHandler(var ResourceList: TestPage "Resource List")
    begin
        ResourceList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeListModalHandler(var EmployeeList: TestPage "Employee List")
    begin
        EmployeeList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CausesOfAbsenceModalHandler(var CausesOfAbsence: TestPage "Causes of Absence")
    begin
        CausesOfAbsence.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateTimeSheetsHandler(var CreateTimeSheets: TestRequestPage "Create Time Sheets")
    begin
        CreateTimeSheets.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure SuggestJobJnlLinesRequestPageHandler(var SuggestJobJnlLines: TestRequestPage "Suggest Job Jnl. Lines")
    begin
        SuggestJobJnlLines.OK().Invoke();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Time Sheet Card", 'OnAfterOnOpenPage', '', false, false)]
    local procedure OnAfterTimeSheetCardOpened(var TimeSheetHeader: Record "Time Sheet Header")
    begin
        TimeSheetHeader.FilterGroup(2);
        TimeSheetCardOwnerUserIDFilter := TimeSheetHeader.GetFilter("Owner User ID");
        TimeSheetHeader.FilterGroup(2);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Time Sheet Archive Card", 'OnAfterOnOpenPage', '', false, false)]
    local procedure OnAfterTimeSheetArchiveCardOpened(var TimeSheetHeaderArchive: Record "Time Sheet Header Archive")
    begin
        TimeSheetHeaderArchive.FilterGroup(2);
        TimeSheetArchiveCardOwnerUserIDFilter := TimeSheetHeaderArchive.GetFilter("Owner User ID");
        TimeSheetHeaderArchive.FilterGroup(2);
    end;
}