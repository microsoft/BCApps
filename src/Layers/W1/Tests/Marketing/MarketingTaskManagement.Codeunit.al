codeunit 136203 "Marketing Task Management"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Marketing] [Task]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryMarketing: Codeunit "Library - Marketing";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTablesUT: Codeunit "Library - Tables UT";
        IsInitialized: Boolean;
        UnknownError: Label 'Unexpected Error.';
        EMailError: Label 'You cannot set %1 as organizer because he/she does not have email address.';
        TaskExistErr: Label '%1 %2 must not exist.';
        TaskCountErr: Label 'Total %1 must be %2.';
        OrganizerErr: Label 'You must specify the Task organizer.';
        DateFormula2: Label '<2D>', Locked = true;
        DateFormula3: Label '<1W - 2D>', Locked = true;
        TeamCode: Code[10];
        SegmentNo: Code[20];
        SalespersonCode2: Code[20];
        TaskType2: Enum "Task Type";
        ActivityCode: Code[10];
        ContactNo: Code[20];
        AllDayEvent2: Boolean;
        Recurring: Boolean;
        WrongSalespersonCodeErr: Label 'Wrong Salesperson Code';
        CannotDeleteSalespersonDueToActiveOpportunitiesErr: Label 'You cannot delete the salesperson/purchaser with code %1 because it has open opportunities.';
        MeetingSaaSNotSupportedErr: Label 'You cannot create a task of type Meeting because you''re not using an on-premises deployment.';

    [Test]
    [HandlerFunctions('ModalFormHandlerForTeamTask')]
    [Scope('OnPrem')]
    procedure TaskWithoutEMailTeam()
    var
        Team: Record Team;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        TeamSalesperson: Record "Team Salesperson";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // Covers document number TC0002 - refer to TFS ID 21732.
        // Test error occurs on Creating Task for Team with Salespeople without E-mail address.

        // 1. Setup: Create Team, Salespeople and attach Salespeople to Team.
        Initialize();
        LibraryMarketing.CreateTeam(Team);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryMarketing.CreateTeamSalesperson(TeamSalesperson, Team.Code, SalespersonPurchaser.Code);
        Commit();

        // Set global variable for Form Handler.
        InitializeGlobalVariable();
        TeamCode := Team.Code;

        // 2. Exercise: Create Task for Team.
        asserterror TempTask.CreateTaskFromTask(Task);

        // 3. Verify: Verify error occurs on Creating Task for Team with Salespeople without E-mail address.
        Assert.AreEqual(StrSubstNo(EMailError, SalespersonPurchaser.Code), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerForTeamTask')]
    [Scope('OnPrem')]
    procedure TaskTeamTypeBlank()
    var
        Team: Record Team;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
        Contact: Record Contact;
    begin
        // Covers document number TC0002 - refer to TFS ID 21732.
        // Test Task for Team, Contact and Salespeople after create Task for Team with Type Blank.

        // 1. Setup: Create Team, Salespeople with E-Mail address and attach Salespeople to Team.
        CreateTeamWithSalesperson(Team, SalespersonPurchaser);

        // Set global variable for Form Handler.
        InitializeGlobalVariable();
        TeamCode := Team.Code;

        // 2. Exercise: Create Task for Team and attach Contact to Created Task.
        TempTask.CreateTaskFromTask(Task);
        Contact.FindFirst();
        UpdateTask(Task, Team.Code, Contact."No.");

        // 3. Verify: Verify Task attach on Team, Contact and Salespeople.
        VerifyTaskForTeam(Team.Code);
        VerifyTaskForContact(Team.Code, Contact."No.");
        VerifyTaskForSalesperson(Team.Code, SalespersonPurchaser.Code);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerForTeamTask')]
    [Scope('OnPrem')]
    procedure DeleteTaskTeamTypeBlank()
    var
        Team: Record Team;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
        Contact: Record Contact;
        DeleteTasks: Report "Delete Tasks";
    begin
        // Covers document number TC0002 - refer to TFS ID 21732.
        // Test Task for Team, Contact and Salespeople deleted after delete Task for Team with Type Blank.

        // 1. Setup: Create Team, Salespeople with E-Mail address, attach Salespeople to Team, Create Task for Team and attach Contact
        // to Created Task.
        CreateTeamWithSalesperson(Team, SalespersonPurchaser);

        // Set global variable for Form Handler.
        InitializeGlobalVariable();
        TeamCode := Team.Code;
        TempTask.CreateTaskFromTask(Task);
        Contact.FindFirst();
        UpdateTask(Task, Team.Code, Contact."No.");

        // 2. Exercise: Canceled the Created Task and run Delete Tasks Batch Report.
        Task.Validate(Canceled, true);
        Task.Modify(true);
        Task.SetRange("No.", Task."No.");
        DeleteTasks.SetTableView(Task);
        DeleteTasks.UseRequestPage(false);
        DeleteTasks.Run();

        // 3. Verify: Verify Task deleted attach on Team, Contact and Salespeople.
        Task.Reset();
        Task.SetRange("Team Code", Team.Code);
        Assert.IsFalse(Task.FindFirst(), StrSubstNo(TaskExistErr, Task.TableCaption(), Task."No."));

        Task.Reset();
        Task.SetRange("Contact No.", Contact."No.");
        Task.SetRange("Team Code", Team.Code);
        Assert.IsFalse(Task.FindFirst(), StrSubstNo(TaskExistErr, Task.TableCaption(), Task."No."));

        Task.Reset();
        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        Assert.IsFalse(Task.FindFirst(), StrSubstNo(TaskExistErr, Task.TableCaption(), Task."No."));
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerForSegmentTask')]
    [Scope('OnPrem')]
    procedure TaskSegmentTypeBlank()
    var
        Task: Record "To-do";
    begin
        // Covers document number TC0004 - refer to TFS ID 21732.
        // Test Task for Segment, Contact and Salespeople after create Task for Segment with Type Blank.

        TaskSegment(Task.Type::" ");
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerForSegmentTask')]
    [Scope('OnPrem')]
    procedure TaskSegmentTypePhoneCall()
    var
        Task: Record "To-do";
    begin
        // Covers document number TC0004 - refer to TFS ID 21732.
        // Test Task for Segment, Contact and Salespeople after create Task for Segment with Type Phone Call.

        TaskSegment(Task.Type::"Phone Call");
    end;

    local procedure TaskSegment(Type: Enum "Task Type")
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // 1. Setup: Create Salesperson, Segment Header and Segment Line for Contact.
        Initialize();
        CreateSalespersonWithEmail(SalespersonPurchaser);
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentHeader.Validate("Salesperson Code", SalespersonPurchaser.Code);
        SegmentHeader.Modify(true);
        CreateSegmentLine(SegmentHeader."No.");

        // Set global variable for Form Handler.
        InitializeGlobalVariable();
        TaskType2 := Type;
        SegmentNo := SegmentHeader."No.";
        SalespersonCode2 := SalespersonPurchaser.Code;

        // 2. Exercise: Create Task for Segment.
        TempTask.CreateTaskFromTask(Task);

        // 3. Verify: Verify Task for Segment, Contact equal total lines on Segment Line and Salespeople.
        SegmentLine.SetRange("Segment No.", SegmentHeader."No.");
        Task.SetRange("Segment No.", SegmentHeader."No.");
        Task.SetRange("System To-do Type", Task."System To-do Type"::Organizer);
        Assert.AreEqual(Task.Count, SegmentLine.Count, StrSubstNo(TaskCountErr, Task.TableCaption(), SegmentLine.Count));

        Task.Reset();
        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        Task.SetRange("Segment No.", SegmentHeader."No.");
        Task.SetRange("System To-do Type", Task."System To-do Type"::Organizer);
        Assert.AreEqual(Task.Count, SegmentLine.Count, StrSubstNo(TaskCountErr, Task.TableCaption(), SegmentLine.Count));

        VerifyTaskForSegment(SegmentHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerTeamSegment')]
    [Scope('OnPrem')]
    procedure TeamTaskSegmentTypeBlank()
    var
        Task: Record "To-do";
    begin
        // Covers document number TC0005 - refer to TFS ID 21732.
        // Test Task for Segment, Contact and Salespeople after create Task for Segment with Type Blank having Team Code.

        TeamTaskSegment(Task.Type::" ");
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerTeamSegment')]
    [Scope('OnPrem')]
    procedure TeamTaskSegmentTypePhoneCall()
    var
        Task: Record "To-do";
    begin
        // Covers document number TC0005 - refer to TFS ID 21732.
        // Test Task for Segment, Contact and Salespeople after create Task for Segment with Type Phone Call having Team Code.

        TeamTaskSegment(Task.Type::"Phone Call");
    end;

    local procedure TeamTaskSegment(Type: Enum "Task Type")
    var
        Team: Record Team;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // 1. Setup: Create Team, Salespeople with E-Mail address, attach Salespeople to Team, Create Segment Header and Segment Line.
        CreateTeamWithSalesperson(Team, SalespersonPurchaser);
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        CreateSegmentLine(SegmentHeader."No.");

        // Set global variable for Form Handler.
        InitializeGlobalVariable();
        TeamCode := Team.Code;
        SegmentNo := SegmentHeader."No.";
        TaskType2 := Type;

        // 2. Exercise: Create Task for Segment.
        TempTask.CreateTaskFromTask(Task);

        // 3. Verify: Verify Task for Segment, Contact equal total lines on Segment Line and Salespeople.
        SegmentLine.SetRange("Segment No.", SegmentHeader."No.");
        Task.SetRange("Segment No.", SegmentHeader."No.");
        Task.SetRange("System To-do Type", Task."System To-do Type"::Organizer);
        Assert.AreEqual(Task.Count, SegmentLine.Count, StrSubstNo(TaskCountErr, Task.TableCaption(), SegmentLine.Count));

        Task.Reset();
        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        Task.SetRange("Segment No.", SegmentHeader."No.");
        Assert.AreEqual(Task.Count, SegmentLine.Count, StrSubstNo(TaskCountErr, Task.TableCaption(), SegmentLine.Count));

        VerifyTaskForSegment(SegmentHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerSegmentMeeting')]
    [Scope('OnPrem')]
    procedure TeamTaskSegmentWOOrganizer()
    var
        Team: Record Team;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SegmentHeader: Record "Segment Header";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // Covers document number TC0005 - refer to TFS ID 21732.
        // Test error occurs on creating Task for Segment with Type Meeting without Task Organizer.

        // 1. Setup: Create Team, Salespeople with E-Mail address, attach Salespeople to Team, Create Segment Header and Segment Line.
        CreateTeamWithSalesperson(Team, SalespersonPurchaser);
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        CreateSegmentLine(SegmentHeader."No.");

        // Set global variable for Form Handler.
        InitializeGlobalVariable();
        TeamCode := Team.Code;
        SegmentNo := SegmentHeader."No.";
        TaskType2 := Task.Type::Meeting;

        // 2. Exercise: Create Task for Segment.
        asserterror TempTask.CreateTaskFromTask(Task);

        // 3. Verify: Verify error occurs on creating Task for Segment with Type Meeting without Task Organizer.
        Assert.AreEqual(StrSubstNo(OrganizerErr), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerSegmentMeeting')]
    [Scope('OnPrem')]
    procedure TeamTaskSegmentTypeMeeting()
    var
        Team: Record Team;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SegmentHeader: Record "Segment Header";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // Covers document number TC0005 - refer to TFS ID 21732.
        // Test Task for Segment, Contact and Salespeople after create Task for Segment with Type Meeting having Team Code.

        // 1. Setup: Create Team, Salespeople with E-Mail address, attach Salespeople to Team, Create Segment Header and Segment Line.
        CreateTeamWithSalesperson(Team, SalespersonPurchaser);
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        CreateSegmentLine(SegmentHeader."No.");

        // Set global variable for Form Handler.
        InitializeGlobalVariable();
        TeamCode := Team.Code;
        SegmentNo := SegmentHeader."No.";
        TaskType2 := Task.Type::Meeting;
        SalespersonCode2 := SalespersonPurchaser.Code;

        // 2. Exercise: Create Task for Segment.
        TempTask.CreateTaskFromTask(Task);

        // 3. Verify: Verify Task for Segment, Contact and Salespeople.
        Task.SetRange("Segment No.", SegmentHeader."No.");
        Task.SetRange("System To-do Type", Task."System To-do Type"::Organizer);
        Task.FindFirst();

        Task.Reset();
        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        Task.SetRange("Segment No.", SegmentHeader."No.");
        Task.FindFirst();

        VerifyTaskForSegment(SegmentHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TeamSalespersonTeamNameField()
    var
        Team: Record Team;
        TeamSalesperson: Record "Team Salesperson";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 214904] Field length TeamSalesperson."Team Name" = Team.Name
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          Team, Team.FieldNo(Name),
          TeamSalesperson, TeamSalesperson.FieldNo("Team Name"));
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerAssignActivity')]
    [Scope('OnPrem')]
    procedure AssignActivityOnContact()
    var
        Team: Record Team;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Activity: Record Activity;
        ActivityStep: Record "Activity Step";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
        Contact: Record Contact;
    begin
        // Covers document number TC0006 - refer to TFS ID 21732.
        // Test Task for Contact, Salesperson and Team after Assign activity through Assign Activity wizard for Contact.

        // 1. Setup: Create Team, Salesperson, attach Salesperson to Team and Create Activity.
        CreateTeamWithSalesperson(Team, SalespersonPurchaser);
        LibraryMarketing.CreateActivity(Activity);
        CreateActivityStep(Activity.Code, ActivityStep.Type::" ", ActivityStep.Priority::Low, '');
        CreateActivityStep(Activity.Code, ActivityStep.Type::"Phone Call", ActivityStep.Priority::Normal, DateFormula2);
        CreateActivityStep(Activity.Code, ActivityStep.Type::Meeting, ActivityStep.Priority::High, DateFormula3);

        // Set global variable for Form Handler.
        InitializeGlobalVariable();
        ActivityCode := Activity.Code;
        SalespersonCode2 := SalespersonPurchaser.Code;
        TeamCode := Team.Code;

        // 2. Exercise: Select Contact with type Company and assign Activity to Contact.
        Contact.SetRange(Type, Contact.Type::Company);
        Contact.FindFirst();
        ContactNo := Contact."No.";
        TempTask.AssignActivityFromTask(Task);

        // 3. Verify: Verify Task for Contact, Salesperson and Team after Assign activity.
        VerifyContactActivity(Contact."No.", Activity.Code, Team.Code);
        VerifyTeamActivity(Activity.Code, Team.Code);
        VerifySalespersonActivity(SalespersonPurchaser.Code, Activity.Code, Team.Code);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerRecurringTask')]
    [Scope('OnPrem')]
    procedure RecurringTaskTypeBlank()
    var
        Task: Record "To-do";
    begin
        // Covers document number TC0007 - refer to TFS ID 21732.
        // Test Task for Salespeople after create Task for Salespeople with Type Blank having Recurring True.

        RecurringTask(Task.Type::" ", false);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerRecurringTask')]
    [Scope('OnPrem')]
    procedure RecurringTaskTypePhoneCall()
    var
        Task: Record "To-do";
    begin
        // Covers document number TC0007 - refer to TFS ID 21732.
        // Test Task for Salespeople after create Task for Salespeople with Type Phone Call having Recurring True.

        RecurringTask(Task.Type::"Phone Call", false);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerRecurringTask')]
    [Scope('OnPrem')]
    procedure RecurringTaskTypeMeeting()
    var
        Task: Record "To-do";
    begin
        // Covers document number TC0007 - refer to TFS ID 21732.
        // Test Task for Salespeople after create Task for Salespeople with Type Meeting having Recurring True.

        RecurringTask(Task.Type::Meeting, true);
    end;

    local procedure RecurringTask(Type: Enum "Task Type"; AllDayEvent: Boolean)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // 1. Setup: Create Salesperson with E-mail.
        Initialize();
        CreateSalespersonWithEmail(SalespersonPurchaser);

        // Set global variable for Form Handler.
        InitializeGlobalVariable();
        SalespersonCode2 := SalespersonPurchaser.Code;
        TaskType2 := Type;
        AllDayEvent2 := AllDayEvent;
        Recurring := true;

        // 2. Exercise: Create Recurring Task for Salesperson.
        TempTask.CreateTaskFromTask(Task);

        // 3. Verify: Verify Task for Salesperson.
        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        Task.FindFirst();
        Task.TestField(Recurring, true);
        Task.TestField(Description, SalespersonPurchaser.Code);
        Task.TestField(Type, Type);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerRecurringTask,MessageHandler')]
    [Scope('OnPrem')]
    procedure ClosedRecurringTask()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // Covers document number TC0007 - refer to TFS ID 21732.
        // Test Task for Salespeople after closed Recurring Task for Salespeople.

        // 1. Setup: Create Salesperson with E-mail Id.
        Initialize();
        CreateSalespersonWithEmail(SalespersonPurchaser);

        // Set global variable for Form Handler.
        InitializeGlobalVariable();
        SalespersonCode2 := SalespersonPurchaser.Code;
        Recurring := true;

        // 2. Exercise: Create Recurring Task for Salesperson and Closed the Created Task.
        TempTask.CreateTaskFromTask(Task);

        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        Task.FindFirst();
        Task.Validate(Closed, true);
        Task.Modify(true);

        // 3. Verify: Verify Task Closed and New Recurring Task created for Salesperson.
        FindClosedTask(Task, SalespersonPurchaser.Code, true);
        Task.FindFirst();
        Task.TestField(Status, Task.Status::Completed);

        FindClosedTask(Task, SalespersonPurchaser.Code, false);
        Task.TestField(Recurring, true);
        Task.TestField(Description, SalespersonPurchaser.Code);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerRecurringTask,MessageHandler')]
    [Scope('OnPrem')]
    procedure CanceledRecurringTask()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // Covers document number TC0007 - refer to TFS ID 21732.
        // Test Task for Salespeople after canceled Recurring Task for Salespeople.

        // 1. Setup: Create Salesperson with E-mail Id.
        Initialize();
        CreateSalespersonWithEmail(SalespersonPurchaser);

        // Set global variable for Form Handler.
        InitializeGlobalVariable();
        SalespersonCode2 := SalespersonPurchaser.Code;
        Recurring := true;

        // 2. Exercise: Create Recurring Task for Salesperson and Canceled the Created Task.
        TempTask.CreateTaskFromTask(Task);

        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        Task.FindFirst();
        Task.Validate(Canceled, true);
        Task.Modify(true);

        // 3. Verify: Verify Task Canceled and New Recurring Task created for Salesperson.
        FindCanceledTask(Task, SalespersonPurchaser.Code, true);
        Task.FindFirst();
        Task.TestField(Status, Task.Status::Completed);

        FindCanceledTask(Task, SalespersonPurchaser.Code, false);
        Task.FindFirst();
        Task.TestField(Recurring, true);
        Task.TestField(Description, SalespersonPurchaser.Code);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerRecurringTask')]
    [Scope('OnPrem')]
    procedure ClosedTaskRecurringFalse()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // Covers document number TC0007 - refer to TFS ID 21732.
        // Test Task for Salespeople after closed Task for Salespeople.

        // 1. Setup: Create Salesperson with E-mail Id.
        Initialize();
        CreateSalespersonWithEmail(SalespersonPurchaser);

        // Set global variable for Form Handler.
        InitializeGlobalVariable();
        SalespersonCode2 := SalespersonPurchaser.Code;
        Recurring := true;

        // 2. Exercise: Create Recurring Task for Salesperson, set Recurring True and Closed the Created Task.
        TempTask.CreateTaskFromTask(Task);

        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        Task.FindFirst();
        Task.Validate(Recurring, false);
        Task.Validate(Closed, true);
        Task.Modify(true);

        // 3. Verify: Verify Task Closed and No New Task created for Salesperson.
        FindClosedTask(Task, SalespersonPurchaser.Code, true);
        Task.FindFirst();
        Task.TestField(Status, Task.Status::Completed);

        FindClosedTask(Task, SalespersonPurchaser.Code, false);
        Assert.IsFalse(Task.FindFirst(), StrSubstNo(TaskExistErr, Task.TableCaption(), Task."No."));
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerRecurringTask')]
    [Scope('OnPrem')]
    procedure CanceledTaskRecurringFalse()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // Covers document number TC0007 - refer to TFS ID 21732.
        // Test Task for Salespeople after canceled Task for Salespeople.

        // 1. Setup: Create Salesperson with E-mail Id.
        Initialize();
        CreateSalespersonWithEmail(SalespersonPurchaser);

        // Set global variable for Form Handler.
        InitializeGlobalVariable();
        SalespersonCode2 := SalespersonPurchaser.Code;
        Recurring := true;

        // 2. Exercise: Create Recurring Task for Salesperson, set Recurring True and Canceled the Created Task.
        TempTask.CreateTaskFromTask(Task);

        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        Task.FindFirst();
        Task.Validate(Recurring, false);
        Task.Validate(Canceled, true);
        Task.Modify(true);

        // 3. Verify: Verify Task Canceled and No New Task created for Salesperson.
        FindCanceledTask(Task, SalespersonPurchaser.Code, true);
        Task.FindFirst();
        Task.TestField(Status, Task.Status::Completed);

        FindCanceledTask(Task, SalespersonPurchaser.Code, false);
        Assert.IsFalse(Task.FindFirst(), StrSubstNo(TaskExistErr, Task.TableCaption(), Task."No."));
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerRecurringTask')]
    [Scope('OnPrem')]
    procedure NonRecurringTaskTypeBlank()
    var
        Task: Record "To-do";
    begin
        // Covers document number TC0007 - refer to TFS ID 21732.
        // Test Task for Salespeople after create Task for Salespeople with Type Blank having Recurring False.

        NonRecurringTask(Task.Type::" ", false);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerRecurringTask')]
    [Scope('OnPrem')]
    procedure NonRecurringTaskTypePhoneCall()
    var
        Task: Record "To-do";
    begin
        // Covers document number TC0007 - refer to TFS ID 21732.
        // Test Task for Salespeople after create Task for Salespeople with Type Phone Call having Recurring False.

        NonRecurringTask(Task.Type::"Phone Call", false);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerRecurringTask')]
    [Scope('OnPrem')]
    procedure NonRecurringTaskTypeMeeting()
    var
        Task: Record "To-do";
    begin
        // Covers document number TC0007 - refer to TFS ID 21732.
        // Test Task for Salespeople after create Task for Salespeople with Type Meeting having Recurring False.

        NonRecurringTask(Task.Type::Meeting, true);
    end;

    local procedure NonRecurringTask(Type: Enum "Task Type"; AllDayEvent: Boolean)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // 1. Setup: Create Salesperson with E-mail Id.
        Initialize();
        CreateSalespersonWithEmail(SalespersonPurchaser);

        // Set global variable for Form Handler.
        InitializeGlobalVariable();
        SalespersonCode2 := SalespersonPurchaser.Code;
        TaskType2 := Type;
        AllDayEvent2 := AllDayEvent;

        // 2. Exercise: Create Task for Salesperson and set Recurring True the Created Task.
        TempTask.CreateTaskFromTask(Task);

        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        Task.FindFirst();
        Task.Validate(Recurring, true);
        Evaluate(Task."Recurring Date Interval", DateFormula2);
        Task.Validate("Calc. Due Date From", Task."Calc. Due Date From"::"Closing Date");
        Task.Modify(true);

        // 3. Verify: Verify Task for Salesperson.
        Task.Reset();
        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        Task.FindFirst();
        Task.TestField(Recurring, true);
        Task.TestField(Description, SalespersonPurchaser.Code);
        Task.TestField(Type, Type);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerForTeamTask,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ReassignTeamTaskTypeBlank()
    var
        Task: Record "To-do";
    begin
        // Covers document number TC0008 - refer to TFS ID 21732.
        // Test Task for Salespeople after Reassign Salespeople to Task with Type Blank for Team.

        ReassignTeamTask(Task.Type::" ", false);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerForTeamTask,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ReassignTeamTaskTypePhoneCall()
    var
        Task: Record "To-do";
    begin
        // Covers document number TC0008 - refer to TFS ID 21732.
        // Test Task for Salespeople after Reassign Salespeople to Task with Type Phone Call for Team.

        ReassignTeamTask(Task.Type::"Phone Call", false);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerForTeamTask,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ReassignTeamTaskTypeMeeting()
    var
        Task: Record "To-do";
    begin
        // Covers document number TC0008 - refer to TFS ID 21732.
        // Test Task for Salespeople after Reassign Salespeople to Task with Type Meeting for Team.

        ReassignTeamTask(Task.Type::Meeting, true);
    end;

    local procedure ReassignTeamTask(Type: Enum "Task Type"; AllDayEvent: Boolean)
    var
        Team: Record Team;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // 1. Setup: Create Team, Salespeople with E-Mail address and attach Salespeople to Team.
        CreateTeamWithSalesperson(Team, SalespersonPurchaser);
        InitializeGlobalVariable();
        SalespersonCode2 := SalespersonPurchaser.Code;
        CreateSalespersonWithEmail(SalespersonPurchaser);

        // Set global variable for Form Handler.
        TeamCode := Team.Code;
        TaskType2 := Type;
        AllDayEvent2 := AllDayEvent;

        // 2. Exercise: Create Task for Team and Updated Salesperson code on Created Task.
        TempTask.CreateTaskFromTask(Task);

        Task.SetRange("Team Code", Team.Code);
        Task.SetRange("System To-do Type", Task."System To-do Type"::Team);
        Task.FindFirst();
        Task.SetRunFromForm();
        Task.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Task.Modify(true);

        // 3. Verify: Verify Task attach on Salesperson and Task for Team Deleted.
        Task.Reset();
        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        Task.FindFirst();

        Task.Reset();
        Task.SetRange("Team Code", Team.Code);
        Task.SetRange("System To-do Type", Task."System To-do Type"::Team);
        Assert.IsFalse(Task.FindFirst(), StrSubstNo(TaskExistErr, Task.TableCaption(), Task."No."));
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerRecurringTask')]
    [Scope('OnPrem')]
    procedure ReassignTaskTypeBlank()
    var
        Task: Record "To-do";
    begin
        // Covers document number TC0010 - refer to TFS ID 21732.
        // Test Task for Team after Reassign Salespeople to Task with Type Blank for Salespeople.

        ReassignTask(Task.Type::" ", false);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerRecurringTask')]
    [Scope('OnPrem')]
    procedure ReassignTaskTypePhoneCall()
    var
        Task: Record "To-do";
    begin
        // Covers document number TC0010 - refer to TFS ID 21732.
        // Test Task for Team after Reassign Salespeople to Task with Type Phone Call for Salespeople.

        ReassignTask(Task.Type::"Phone Call", false);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerRecurringTask')]
    [Scope('OnPrem')]
    procedure ReassignTaskTypeMeeting()
    var
        Task: Record "To-do";
    begin
        // Covers document number TC0010 - refer to TFS ID 21732.
        // Test Task for Team Salespeople after Reassign Salespeople to Task with Type Meeting for Salespeople.

        ReassignTask(Task.Type::Meeting, true);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure AllDayEventEndDateOnCreateTaskPage()
    begin
        // [FEATURE] [Task]
        // [SCENARIO 173844] The "Ending Date" in the Task with "All Day Event" checked remains as it set by the user as current day.

        // [GIVEN] Task with "All Day Event" checked
        // [WHEN] User sets "Ending Date" to Date
        // [THEN] "Ending Date" is equal to Date
        AllDayEventMoveEndDate('<CD>');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllDayEventLateEndDateOnCreateTaskPage()
    begin
        // [FEATURE] [Task]
        // [SCENARIO 173844] The "Ending Date" in the Task with "All Day Event" checked remains as it set by the user.

        // [GIVEN] Task with "All Day Event" checked
        // [WHEN] User sets "Ending Date" to Date + X days
        // [THEN] Ending Date is equal to Date + X days
        AllDayEventMoveEndDate('<+2D>');
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerRecurringTask,ModalFormHandlerMakePhoneCall')]
    [Scope('OnPrem')]
    procedure TaskMakePhoneCallFromCardSalesPerson()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TaskCard: TestPage "Task Card";
    begin
        // [FEATURE] [Task]
        // [SCENARIO 207176] SalesPerson Code is filled when user runs Make Phone Call from Task Card
        Initialize();

        // [GIVEN] Task of Phone Call type with SalesPerson Code = "SPC"
        CreateSalespersonWithEmail(SalespersonPurchaser);
        InitializeGlobalVariable();
        SalespersonCode2 := SalespersonPurchaser.Code;
        CreatePhoneCallTask(Task, SalespersonPurchaser.Code);

        // [GIVEN] Task Card page opened
        TaskCard.OpenEdit();
        TaskCard.GotoRecord(Task);

        // [WHEN] Make Phone Call action is called
        TaskCard.MakePhoneCall.Invoke();

        // [THEN] Make Phone Call page is opened and SalesPerson Code = "SPC"
        Assert.AreEqual(SalespersonPurchaser.Code, LibraryVariableStorage.DequeueText(), WrongSalespersonCodeErr);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerRecurringTask,ModalFormHandlerMakePhoneCall')]
    [Scope('OnPrem')]
    procedure TaskMakePhoneCallFromListSalesPerson()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TaskList: TestPage "Task List";
    begin
        // [FEATURE] [Task]
        // [SCENARIO 207176] SalesPerson Code is filled when user runs Make Phone Call from Task List
        Initialize();

        // [GIVEN] Task of Phone Call type with SalesPerson Code = "SPC"
        CreateSalespersonWithEmail(SalespersonPurchaser);
        InitializeGlobalVariable();
        SalespersonCode2 := SalespersonPurchaser.Code;
        CreatePhoneCallTask(Task, SalespersonPurchaser.Code);

        // [GIVEN] Task List page is opened and focused on created Task
        TaskList.OpenEdit();
        TaskList.GotoRecord(Task);

        // [WHEN] Make Phone Call action is called
        TaskList.MakePhoneCall.Invoke();

        // [THEN] Make Phone Call page is opened and SalesPerson Code = "SPC"
        Assert.AreEqual(SalespersonPurchaser.Code, LibraryVariableStorage.DequeueText(), WrongSalespersonCodeErr);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerRecurringTask,ModalFormHandlerMakePhoneCall,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure TaskPhoneCallCompleteSalesPerson()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TaskCard: TestPage "Task Card";
    begin
        // [FEATURE] [Task]
        // [SCENARIO 207176] SalesPerson Code is filled when user completes Task of Phone Call type and agrees to create Interaction
        Initialize();

        // [GIVEN] Task of Phone Call type with SalesPerson Code = "SPC"
        CreateSalespersonWithEmail(SalespersonPurchaser);
        InitializeGlobalVariable();
        SalespersonCode2 := SalespersonPurchaser.Code;
        CreatePhoneCallTask(Task, SalespersonPurchaser.Code);

        // [GIVEN] Task Card page opened
        TaskCard.OpenEdit();
        TaskCard.GotoRecord(Task);

        // [WHEN] Status is set to Complete
        TaskCard.Status.SetValue(Task.Status::Completed);

        // [THEN] Make Phone Call page is opened and SalesPerson Code = "SPC"
        Assert.AreEqual(SalespersonPurchaser.Code, LibraryVariableStorage.DequeueText(), WrongSalespersonCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLenghtOfTeamNameToDo()
    var
        ToDo: Record "To-do";
        Team: Record Team;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 228568] Lenght of "To-do"."Team Name" shoud be equal to lenght of "Team"."Name"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(ToDo, ToDo.FieldNo("Team Name"), Team, Team.FieldNo(Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactNameAndContactCompanyNameVisibleOnTaskMeeting()
    var
        Task: Record "To-do";
        Contact: Record Contact;
        TaskCardPage: TestPage "Task Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 284068] Contact Name and Contact Company Name values are visible on Task Card, when Task.Type = Meeting
        Initialize();

        // [GIVEN] A contact
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Task with Type = Meeting
        CreateMeetingTask(Task);

        // [GIVEN] Task has Contact Name and Contact Company Name
        Task.Validate("Contact No.", Contact."No.");
        Task.Modify();

        // [WHEN] Task Card is open for viewing of this Task
        TaskCardPage.OpenView();
        TaskCardPage.GotoRecord(Task);

        // [THEN] Contact Name value is visible and equals Contact.Name
        Assert.IsFalse(TaskCardPage."Contact Name".HideValue(), 'Contact Name value is hidden for Task.Type = Meeting');
        TaskCardPage."Contact Name".AssertEquals(Contact.Name);

        // [THEN] Contact Company Name value is visible and equals Contact."Company Name"
        Assert.IsFalse(TaskCardPage."Contact Company Name".HideValue(), 'Contact Company Name value is hidden for Task.Type = Meeting');
        TaskCardPage."Contact Company Name".AssertEquals(Contact."Company Name");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ModalFormHandlerCreateInteraction')]
    [Scope('OnPrem')]
    procedure InteractionLogWizardOnClosedMeeting()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        Task: Record "To-do";
        TaskCard: TestPage "Task Card";
    begin
        // [FEATURE] [Interaction]
        // [SCENARIO 284727] Interaction Log Entry can be created after changing Task Status to 'Complete'
        Initialize();

        // [GIVEN] Task with Type 'Meeting'
        LibraryMarketing.CreateCompanyContactTask(Task, Task.Type::Meeting.AsInteger());

        // [GIVEN] Task Card page opened
        TaskCard.OpenEdit();
        TaskCard.FILTER.SetFilter("No.", Task."No.");

        // [WHEN] Task Status is set to Complete
        TaskCard.Status.SetValue(Task.Status::Completed);

        // [THEN] Interaction log entry is created
        InteractionLogEntry.SetFilter("Contact No.", Task."Contact No.");
        Assert.RecordIsNotEmpty(InteractionLogEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalespersonWithOpenTask()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
    begin
        // [FEATURE] [Salesperson] [UT]
        // [SCENARIO 323540] Salesperson/Purchaser cannot be deleted if it has open tasks.
        Initialize();

        // [GIVEN] Created Salesperson and Task assigned to them
        CreateSalespersonWithTask(SalespersonPurchaser, Task);

        // [WHEN] Attempt to delete Salesperson
        asserterror SalespersonPurchaser.Delete(true);

        // [THEN] Error "You cannot delete Salesperson/Purchaser.." is thrown
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
          StrSubstNo('You cannot delete the salesperson/purchaser with code %1 because it has open tasks.', SalespersonPurchaser.Code));
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteSalespersonWithClosedTask()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
    begin
        // [FEATURE] [Salesperson] [UT]
        // [SCENARIO 323540] Salesperson/Purchaser is deleted if it has closed tasks.
        Initialize();

        // [GIVEN] Created Salesperson and Task assigned to them, then close it
        CreateSalespersonWithTask(SalespersonPurchaser, Task);
        CloseSalepersonsTask(SalespersonPurchaser.Code);

        // [WHEN] Attempt to delete Salesperson
        SalespersonPurchaser.Delete(true);

        // [THEN] Salesperson is deleted successfuly
        VerifySalespersonDeleted(SalespersonPurchaser.Code);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerMakePhoneCallChangeDateTime,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure PageMakePhoneCallCanChangeDateTimeOfInteraction()
    var
        Contact: Record Contact;
        InteractionLogEntry: Record "Interaction Log Entry";
        ContactList: TestPage "Contact List";
    begin
        // [SCENARIO 326506] Date and Time of Interaction should be visible and editable on Make Phone Call page
        Initialize();

        // [GIVEN] Contact "X" with filled "Phone No."
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Phone No.", Format(LibraryRandom.RandInt(100)));
        Contact.Modify(FALSE);

        // [GIVEN] Make Phone Call page opened by Make Phone Call action on Contact List positioned on Contact "X"        
        ContactList.OpenView();
        ContactList.GoToRecord(Contact);

        // [WHEN] Make Phone Call page is opened
        ContactList.MakePhoneCall.Invoke();

        // [THEN] Date and "Time of Interaction" fields are editable and filled with "D1" and "TI1" values
        // checked on ModalFormHandlerMakePhoneCallChangeDateTime handler
        // [THEN] Date = "D1", Time of Interaction" = "TI1" in created Interaction Log Entry
        InteractionLogEntry.SetRange("Contact No.", Contact."No.");
        InteractionLogEntry.FindFirst();
        InteractionLogEntry.TestField("Time of Interaction", LibraryVariableStorage.DequeueTime());
        InteractionLogEntry.TestField(Date, LibraryVariableStorage.DequeueDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalespersonWithOpenOpportunity()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Opportunity: Record Opportunity;
    begin
        // [FEATURE] [Salesperson] [UT]
        // [SCENARIO 338127] Salesperson/Purchaser cannot be deleted if it has open opportunity.
        Initialize();

        // [GIVEN] Created Salesperson "S" and Opportunity assigned to it
        CreateSalespersonWithOpportunity(SalespersonPurchaser, Opportunity);

        // [WHEN] Attempt to delete Salesperson
        asserterror SalespersonPurchaser.Delete(true);

        // [THEN] Error "You cannot delete the salesperson/purchaser with code A because it has open opportunities" has been thrown
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(CannotDeleteSalespersonDueToActiveOpportunitiesErr, SalespersonPurchaser.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalespersonWithClosedOpportunity()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Opportunity: Record Opportunity;
    begin
        // [FEATURE] [Salesperson] [UT]
        // [SCENARIO 338127] Salesperson/Purchaser is deleted if it hasn't open opportunity.
        Initialize();

        // [GIVEN] Created Salesperson and Opportunity assigned to it, then close it
        CreateSalespersonWithOpportunity(SalespersonPurchaser, Opportunity);
        Opportunity.Validate(Closed, true);
        Opportunity.Modify(true);

        // [WHEN] Attempt to delete Salesperson
        SalespersonPurchaser.Delete(true);

        // [THEN] Salesperson is deleted successfuly
        VerifySalespersonDeleted(SalespersonPurchaser.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateTaskPhoneCallSetStartEndTimeUI()
    var
        Todo: Record "To-do";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CreateTask: TestPage "Create Task";
    begin
        // [SCEANRIO 420421] Make "Start Time" and "Ending Time" fields available to edit for "Phone Call" task on the "Create Task" page
        Initialize();

        // [GIVEN] "Phone Call" task
        LibraryMarketing.CreateTask(Todo);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Todo.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Todo.Validate(Type, Todo.Type::"Phone Call");
        Todo.Validate(Date, WorkDate());
        Todo.Modify(true);

        // [WHEN] Set "Start Time" = "T1" and "Ending Time" = "T2" on the "Create Task" page
        CreateTask.OpenEdit();
        CreateTask.GoToRecord(Todo);
        CreateTask."Start Time".SetValue(120100T);
        CreateTask."Ending Time".SetValue(125959T);
        CreateTask.OK().Invoke();

        // [THEN] "Start Time" = "T1", "Ending Time" = "T2", "Duration" = "T2" - "T1"
        Todo.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        Todo.FindFirst();
        Todo.TestField("Start Time", 120100T);
        Todo.TestField("Ending Time", 125959T);
        Todo.TestField(Duration, 125959T - 120100T);
    end;

    [Test]
    [HandlerFunctions('ModalFormCreateTaskCheckEditable')]
    [Scope('OnPrem')]
    procedure CreateTaskFromSalespersonPage()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Team: Record Team;
        SalespersonPurchaserCard: TestPage "Salesperson/Purchaser Card";
        TaskList: TestPage "Task List";
    begin
        // [FEATURE] [Salesperson] [UT]
        // [SCENARIO 420888] Salesperson and Team are editable when Create Task opened from salesperson
        Initialize();

        // [GIVEN] Created Salesperson and Team
        CreateTeamWithSalesperson(Team, SalespersonPurchaser);
        SalespersonPurchaserCard.OpenEdit();
        SalespersonPurchaserCard.Filter.SetFilter(Code, SalespersonPurchaser.Code);
        TaskList.Trap();
        SalespersonPurchaserCard."T&asks".Invoke();

        // [WHEN] Action "Create Task"
        TaskList."&Create Task".Invoke();

        // [THEN] Salesperson Code and Team Task are editable
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Invalid editable state for Salesperson Code');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Invalid editable state for Team Task');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateTaskSalesPersonEnablePhoneCallTeamTodo()
    var
        Todo: Array[2] of Record "To-do";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Team: Record Team;
        CreateTask: TestPage "Create Task";
    begin
        // [SCENARIO 430127] Salesperson should be enabled on Create Task page when "Team To-do" = false
        Initialize();

        // [GIVEN] Task "T1" with "Team To-do" = false
        CreateTeamWithSalesperson(Team, SalespersonPurchaser);
        LibraryMarketing.CreateTask(Todo[1]);
        Todo[1].Validate(Date, WorkDate());
        Todo[1].Validate("Team To-do", False);
        Todo[1].Validate("Salesperson Code", SalespersonPurchaser.Code);
        Todo[1].Modify(true);

        // [GIVEN] Task "T2" with "Team To-do" = true
        LibraryMarketing.CreateTask(Todo[2]);
        Todo[2].Validate(Date, WorkDate());
        Todo[2].Validate("Team To-do", true);
        Todo[2].Validate("Team Code", Team.Code);
        Todo[2].Modify(true);

        // [WHEN] "Create Task" page opened for Task "T1" and Type set to "Phone Call"
        CreateTask.OpenEdit();
        CreateTask.GoToRecord(Todo[1]);
        CreateTask.TypeOnPrem.SetValue(Todo[1].Type::"Phone Call");
        // [THEN] "Salesperson Code" is enabled 
        Assert.IsTrue(CreateTask."Salesperson Code".Enabled(), 'Salesperson Code is not enabled');
        CreateTask.Close();

        // [WHEN] "Create Task" page opened for Task "T2" and Type set to "Phone Call"
        CreateTask.OpenEdit();
        CreateTask.GoToRecord(Todo[2]);
        CreateTask.TypeOnPrem.SetValue(Todo[2].Type::"Phone Call");
        // [THEN] "Salesperson Code" is not enabled 
        Assert.IsFalse(CreateTask."Salesperson Code".Enabled(), 'Salesperson Code should not be enabled');
        CreateTask.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaskEmptyTypeEndingDateChange()
    var
        Todo: Record "To-do";
        EndingDate: Date;
    begin
        // [SCEANRIO 437183] Ending Date for Task with Type = " " should not be changed after setting value
        Initialize();

        // [GIVEN] Task with type " ", "Ending Date" = D1
        LibraryMarketing.CreateTask(Todo);
        Todo.Validate(Type, Todo.Type::" ");
        Todo.Validate(Date, WorkDate());
        EndingDate := Todo."Ending Date";
        Todo.Modify(true);

        // [WHEN] Set "Ending Date" = D1 + 1 day
        Todo.Validate("Ending Date", EndingDate + 1);
        Todo.Modify();

        // [THEN] "Ending Date" = D1 + 1 day
        Todo.TestField("Ending Date", EndingDate + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MeetingTaskTypeSaaSNotAllowed()
    var
        Todo: Record "To-do";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [SCEANRIO 435531] Task with Type = Meeting should be allowed in SaaS
        Initialize();

        // [GIVEN] SaaS Environment
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Task 
        LibraryMarketing.CreateTask(Todo);

        // [WHEN] Task Type is set to Meeting
        // [THEN] Error message 'Task Type Meeting is not supported in online environments.' appears
        asserterror Todo.Validate(Type, Todo.Type::Meeting);
        Assert.ExpectedError(MeetingSaaSNotSupportedErr);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        LibrarySales.SetCreditWarningsToNoWarnings();

        IsInitialized := true;
        Commit();
    end;

    local procedure AllDayEventMoveEndDate(EndingDateFormula: Text)
    var
        Task: Record "To-do";
        EndingDate: Date;
        DateFormula: DateFormula;
    begin
        Evaluate(DateFormula, EndingDateFormula);
        Task.Validate(Type, Task.Type::Meeting);
        Task.Validate(Date, WorkDate());
        Task.Validate(Duration, 1440 * 60 * 1000);
        Task.Validate("All Day Event", true);

        EndingDate := CalcDate(DateFormula, WorkDate());
        Task.Validate("Ending Date", EndingDate);

        Task.TestField("Ending Date", EndingDate);
        Task.TestField("Ending Time", 0T);
    end;

    local procedure CloseSalepersonsTask(CompletedBy: Code[20])
    var
        Task: Record "To-do";
    begin
        Task.SetRange("Salesperson Code", CompletedBy);
        Task.FindFirst();
        Task.Validate("Completed By", CompletedBy);
        Task.Validate(Closed, true);
        Task.Modify(true);
    end;

    local procedure ReassignTask(Type: Enum "Task Type"; AllDayEvent: Boolean)
    var
        Team: Record Team;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // 1. Setup: Create Salesperson with E-Mail address and Team.
        Initialize();
        CreateSalespersonWithEmail(SalespersonPurchaser);
        LibraryMarketing.CreateTeam(Team);

        // Set global variable for Form Handler.
        InitializeGlobalVariable();
        TaskType2 := Type;
        AllDayEvent2 := AllDayEvent;
        SalespersonCode2 := SalespersonPurchaser.Code;

        // 2. Exercise: Create Task for Salesperson and Update Team Code on Created Task.
        TempTask.CreateTaskFromTask(Task);

        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        Task.FindFirst();
        Task.SetRunFromForm();
        Task.Validate("Team Code", Team.Code);
        Task.Modify(true);

        // 3. Verify: Verify Task attach on Team and Task for Salesperson Deleted.
        Task.Reset();
        Task.SetRange("Team Code", Team.Code);
        Task.FindFirst();

        Task.Reset();
        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        if Type = Task.Type::Meeting then begin
            Task.FindFirst();
            Task.TestField("Team Code", Team.Code);
        end else
            Assert.IsFalse(Task.FindFirst(), StrSubstNo(TaskExistErr, Task.TableCaption(), Task."No."));
    end;

    local procedure InitializeGlobalVariable()
    begin
        TeamCode := '';
        SalespersonCode2 := '';
        SegmentNo := '';
        Clear(TaskType2);
        ActivityCode := '';
        ContactNo := '';
        AllDayEvent2 := false;
        Recurring := false;
    end;

    local procedure CreateActivityStep(ActivityCode: Code[10]; TaskType: Enum "Task Type"; Priority: Option; DateFormula: Text[30])
    var
        ActivityStep: Record "Activity Step";
    begin
        LibraryMarketing.CreateActivityStep(ActivityStep, ActivityCode);
        ActivityStep.Validate(Type, TaskType);
        ActivityStep.Validate(Priority, Priority);
        Evaluate(ActivityStep."Date Formula", DateFormula);
        ActivityStep.Modify(true);
    end;

    local procedure CreateAttendee(var TempAttendee: Record Attendee temporary; AttendanceType: Option; AttendeeType: Option; AttendeeNo: Code[20])
    begin
        TempAttendee.Init();
        TempAttendee.Validate("Attendance Type", AttendanceType);
        TempAttendee.Validate("Attendee Type", AttendeeType);
        TempAttendee.Validate("Line No.", TempAttendee."Line No." + 10000);  // Use 10000 to Increase the Line No.
        TempAttendee.Validate("Attendee No.", AttendeeNo);
        TempAttendee.Insert();
    end;

    local procedure CreatePhoneCallTask(var Task: Record "To-do"; SalesPersonCode: Code[20])
    begin
        Task.CreateTaskFromTask(Task);
        Task.Validate(Type, Task.Type::"Phone Call");
        Task.Validate("Contact No.", LibraryMarketing.CreateCompanyContactNo());
        Task.Validate("Salesperson Code", SalesPersonCode);
        Task.Modify();
    end;

    local procedure CreateMeetingTask(var Task: Record "To-do")
    begin
        Task.Init();
        Task.Type := Task.Type::Meeting;
        Task."Start Time" := Time;
        Task.Date := WorkDate();
        Task.Insert(true);
    end;

    local procedure CreateSalespersonWithEmail(var SalespersonPurchaser: Record "Salesperson/Purchaser")
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        SalespersonPurchaser.Modify(true);
        Commit();
    end;

    local procedure CreateSalespersonWithTask(var SalespersonPurchaser: Record "Salesperson/Purchaser"; var Task: Record "To-do")
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryMarketing.CreateTask(Task);
        Task.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Task.Modify(true);
    end;

    local procedure CreateSalespersonWithOpportunity(var SalespersonPurchaser: Record "Salesperson/Purchaser"; var Opportunity: Record Opportunity)
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryMarketing.CreateOpportunity(Opportunity, LibraryMarketing.CreateCompanyContactNo());
        Opportunity.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Opportunity.Modify(true);
    end;

    local procedure CreateSegmentLine(SegmentHeaderNo: Code[20])
    var
        SegmentLine: Record "Segment Line";
        Contact: Record Contact;
        Counter: Integer;
    begin
        Contact.FindSet();
        // Create 2 to 10 Segment Line - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(8) do begin
            LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeaderNo);
            SegmentLine.Validate("Contact No.", Contact."No.");
            SegmentLine.Modify(true);
            Contact.Next();
        end;
    end;

    local procedure CreateSegmentTask(var TempTask: Record "To-do" temporary; SegmentNo3: Code[20]; TaskType: Enum "Task Type")
    begin
        TempTask.Validate("Segment No.", SegmentNo3);
        TempTask.Validate(Type, TaskType);
        TempTask.Validate(Description, SegmentNo3);
        TempTask.Validate(Date, WorkDate());
    end;

    local procedure CreateTeamWithSalesperson(var Team: Record Team; var SalespersonPurchaser: Record "Salesperson/Purchaser")
    var
        TeamSalesperson: Record "Team Salesperson";
    begin
        Initialize();
        LibraryMarketing.CreateTeam(Team);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        SalespersonPurchaser.Modify(true);
        LibraryMarketing.CreateTeamSalesperson(TeamSalesperson, Team.Code, SalespersonPurchaser.Code);
        Commit();
    end;

    local procedure FindCanceledTask(var Task: Record "To-do"; SalespersonCode: Code[20]; Canceled: Boolean)
    begin
        Task.Reset();
        Task.SetRange("Salesperson Code", SalespersonCode);
        Task.SetRange(Canceled, Canceled);
    end;

    local procedure FindClosedTask(var Task: Record "To-do"; SalespersonCode: Code[20]; Closed: Boolean)
    begin
        Task.Reset();
        Task.SetRange("Salesperson Code", SalespersonCode);
        Task.SetRange(Closed, Closed);
    end;

    local procedure FinishStepTaskWizard(var TempTask: Record "To-do" temporary)
    begin
        TempTask.Modify();
        TempTask.CheckStatus();
        TempTask.FinishWizard(false);
    end;

    local procedure UpdateTask(var Task: Record "To-do"; TeamCode: Code[10]; ContactNo: Code[20])
    begin
        Task.SetRange("Team Code", TeamCode);
        Task.FindFirst();
        Task.Validate("Contact No.", ContactNo);
        Task.Modify(true);
    end;

    local procedure VerifyContactActivity(ContactNo: Code[20]; ActivityCode: Code[10]; TeamCode: Code[10])
    var
        Task: Record "To-do";
        ActivityStep: Record "Activity Step";
    begin
        ActivityStep.SetRange("Activity Code", ActivityCode);
        ActivityStep.FindSet();
        repeat
            Task.SetRange("Contact Company No.", ContactNo);
            Task.SetRange("System To-do Type", Task."System To-do Type"::"Contact Attendee");
            Task.SetRange("Activity Code", ActivityCode);
            Task.SetRange(Type, ActivityStep.Type);
            Task.FindFirst();
            Task.TestField(Priority, ActivityStep.Priority);
            Task.TestField("Team Code", TeamCode);
            Task.TestField(Date, CalcDate(ActivityStep."Date Formula", WorkDate()));
        until ActivityStep.Next() = 0;
    end;

    local procedure VerifySalespersonActivity(SalespersonCode: Code[20]; ActivityCode: Code[10]; TeamCode: Code[10])
    var
        Task: Record "To-do";
        ActivityStep: Record "Activity Step";
    begin
        ActivityStep.SetRange("Activity Code", ActivityCode);
        ActivityStep.FindSet();
        repeat
            Task.SetRange("Salesperson Code", SalespersonCode);
            Task.SetRange("Activity Code", ActivityCode);
            Task.SetRange(Type, ActivityStep.Type);
            Task.FindFirst();
            Task.TestField(Priority, ActivityStep.Priority);
            Task.TestField("Team Code", TeamCode);
            Task.TestField(Date, CalcDate(ActivityStep."Date Formula", WorkDate()));
        until ActivityStep.Next() = 0;
    end;

    local procedure VerifyTeamActivity(ActivityCode: Code[10]; TeamCode: Code[10])
    var
        Task: Record "To-do";
        ActivityStep: Record "Activity Step";
    begin
        ActivityStep.SetRange("Activity Code", ActivityCode);
        ActivityStep.FindSet();
        repeat
            Task.SetRange("Team Code", TeamCode);
            Task.SetRange("System To-do Type", Task."System To-do Type"::Team);
            Task.SetRange(Type, ActivityStep.Type);
            Task.FindFirst();
            Task.TestField(Priority, ActivityStep.Priority);
            Task.TestField(Date, CalcDate(ActivityStep."Date Formula", WorkDate()));
        until ActivityStep.Next() = 0;
    end;

    local procedure VerifyTaskForTeam(TeamCode: Code[10])
    var
        Task: Record "To-do";
    begin
        Task.SetRange("Team Code", TeamCode);
        Task.FindFirst();
        Task.TestField(Type, Task.Type::" ");
        Task.TestField(Description, TeamCode);
    end;

    local procedure VerifyTaskForContact(TeamCode: Code[10]; ContactNo: Code[20])
    var
        Task: Record "To-do";
    begin
        Task.SetRange("Contact No.", ContactNo);
        Task.SetRange("Team Code", TeamCode);
        Task.FindFirst();
        Task.TestField(Type, Task.Type::" ");
        Task.TestField(Description, TeamCode);
    end;

    local procedure VerifyTaskForSalesperson(TeamCode: Code[10]; SalespersonCode: Code[20])
    var
        Task: Record "To-do";
    begin
        Task.SetRange("Salesperson Code", SalespersonCode);
        Task.FindFirst();
        Task.TestField("Team Code", TeamCode);
        Task.TestField(Type, Task.Type::" ");
        Task.TestField(Description, TeamCode);
    end;

    local procedure VerifyTaskForSegment(SegmentNo: Code[20])
    var
        SegmentLine: Record "Segment Line";
        Task: Record "To-do";
    begin
        SegmentLine.SetRange("Segment No.", SegmentNo);
        SegmentLine.FindSet();
        repeat
            Task.SetRange("Contact No.", SegmentLine."Contact No.");
            Task.SetRange("Segment No.", SegmentLine."Segment No.");
            Task.FindFirst();
            Task.TestField("Contact Company No.", SegmentLine."Contact Company No.");
            Task.TestField(Date, SegmentLine.Date);
        until SegmentLine.Next() = 0;
    end;

    local procedure VerifySalespersonDeleted(SalespersonPurchaserCode: Code[20])
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        SalespersonPurchaser.SetRange(Code, SalespersonPurchaserCode);
        Assert.RecordIsEmpty(SalespersonPurchaser);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Question: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerForTeamTask(var CreateTask: Page "Create Task"; var Response: Action)
    var
        TempTask: Record "To-do" temporary;
        TempAttendee: Record Attendee temporary;
    begin
        TempTask.Init();
        CreateTask.GetRecord(TempTask);
        TempTask.Insert();
        TempTask.Validate("Team Code", TeamCode);
        TempTask.Validate(Type, TaskType2);
        TempTask.Validate(Description, TeamCode);
        TempTask.Validate("Team To-do", true);
        TempTask.Validate(Date, WorkDate());
        TempTask.Validate("All Day Event", AllDayEvent2);

        if SalespersonCode2 <> '' then
            CreateAttendee(
              TempAttendee, TempAttendee."Attendance Type"::"To-do Organizer", TempAttendee."Attendee Type"::Salesperson, SalespersonCode2);

        TempTask.SetAttendee(TempAttendee);
        TempTask.GetAttendee(TempAttendee);

        FinishStepTaskWizard(TempTask);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerForSegmentTask(var CreateTask: Page "Create Task"; var Response: Action)
    var
        TempTask: Record "To-do" temporary;
    begin
        TempTask.Init();
        CreateTask.GetRecord(TempTask);
        TempTask.Insert();
        CreateSegmentTask(TempTask, SegmentNo, TaskType2);
        TempTask.Validate("Salesperson Code", SalespersonCode2);
        FinishStepTaskWizard(TempTask);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormCreateTaskCheckEditable(var CreateTask: TestPage "Create Task")
    begin
        LibraryVariableStorage.Enqueue(CreateTask."Salesperson Code".Editable());
        LibraryVariableStorage.Enqueue(CreateTask.TeamTask.Editable());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerTeamSegment(var CreateTask: Page "Create Task"; var Response: Action)
    var
        TempTask: Record "To-do" temporary;
    begin
        TempTask.Init();
        CreateTask.GetRecord(TempTask);
        TempTask.Insert();
        CreateSegmentTask(TempTask, SegmentNo, TaskType2);
        TempTask.Validate("Team To-do", true);
        TempTask.Validate("Team Code", TeamCode);
        FinishStepTaskWizard(TempTask);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerSegmentMeeting(var CreateTask: Page "Create Task"; var Response: Action)
    var
        TempTask: Record "To-do" temporary;
        SegmentLine: Record "Segment Line";
        TempAttendee: Record Attendee temporary;
    begin
        TempTask.Init();
        CreateTask.GetRecord(TempTask);
        TempTask.Insert();
        CreateSegmentTask(TempTask, SegmentNo, TaskType2);
        TempTask.Validate("Start Time", Time);
        TempTask.Validate("All Day Event", true);
        TempTask.Validate("Team To-do", true);
        TempTask.Validate("Team Code", TeamCode);

        if SalespersonCode2 <> '' then
            CreateAttendee(
              TempAttendee, TempAttendee."Attendance Type"::"To-do Organizer", TempAttendee."Attendee Type"::Salesperson, SalespersonCode2);

        SegmentLine.SetRange("Segment No.", SegmentNo);
        SegmentLine.FindSet();
        repeat
            CreateAttendee(
              TempAttendee, TempAttendee."Attendance Type"::Required, TempAttendee."Attendee Type"::Contact, SegmentLine."Contact No.");
            TempTask.SetAttendee(TempAttendee);
        until SegmentLine.Next() = 0;
        TempTask.SetAttendee(TempAttendee);
        TempTask.GetAttendee(TempAttendee);

        FinishStepTaskWizard(TempTask);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerAssignActivity(var AssignActivity: Page "Assign Activity"; var Response: Action)
    var
        TempTask: Record "To-do" temporary;
    begin
        TempTask.Init();
        AssignActivity.GetRecord(TempTask);
        TempTask.Insert();
        TempTask.Validate("Contact No.", ContactNo);
        TempTask.Validate("Activity Code", ActivityCode);
        TempTask.Validate(Description, ActivityCode);
        TempTask.Validate(Date, WorkDate());
        TempTask.Validate("Team Code", TeamCode);
        TempTask.Validate("Team Meeting Organizer", SalespersonCode2);
        TempTask.Modify();
        TempTask.CheckAssignActivityStatus();
        TempTask.FinishAssignActivity();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerRecurringTask(var CreateTask: Page "Create Task"; var Response: Action)
    var
        TempTask: Record "To-do" temporary;
        TempAttendee: Record Attendee temporary;
    begin
        TempTask.Init();
        CreateTask.GetRecord(TempTask);
        TempTask.Insert();
        TempTask.Validate("Salesperson Code", SalespersonCode2);
        TempTask.Validate(Type, TaskType2);
        TempTask.Validate(Description, SalespersonCode2);
        TempTask.Validate("All Day Event", AllDayEvent2);

        if AllDayEvent2 then
            CreateAttendee(
              TempAttendee, TempAttendee."Attendance Type"::"To-do Organizer", TempAttendee."Attendee Type"::Salesperson, SalespersonCode2);

        TempTask.SetAttendee(TempAttendee);
        TempTask.GetAttendee(TempAttendee);

        TempTask.Validate(Recurring, Recurring);
        Evaluate(TempTask."Recurring Date Interval", DateFormula2);
        TempTask.Validate("Calc. Due Date From", TempTask."Calc. Due Date From"::"Closing Date");
        FinishStepTaskWizard(TempTask);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerMakePhoneCall(var MakePhoneCall: TestPage "Make Phone Call")
    begin
        LibraryVariableStorage.Enqueue(MakePhoneCall."Salesperson Code".Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerCreateInteraction(var CreateInteraction: TestPage "Create Interaction")
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        CreateInteraction."Interaction Template Code".SetValue(InteractionTemplate.Code);
        CreateInteraction.Description.SetValue(InteractionTemplate.Code);
        CreateInteraction.NextInteraction.Invoke();
        CreateInteraction.NextInteraction.Invoke();
        CreateInteraction.FinishInteraction.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerMakePhoneCallChangeDateTime(var MakePhoneCall: TestPage "Make Phone Call")
    begin
        // Modifying the "Time of Interaction" and Date we check mentioned fields on the page are editable
        Assert.IsFalse(MakePhoneCall.Finish.Visible(), 'MakePhoneCall.Finish.Visible #1');
        Assert.IsFalse(MakePhoneCall.Date.Visible(), 'MakePhoneCall.Date.Visible');
        Assert.IsFalse(MakePhoneCall."Time of Interaction".Visible(), 'MakePhoneCall."Time of Interaction".Visible');
        MakePhoneCall.ShowMoreLess1.Drilldown(); // to show additional controls
        Assert.IsTrue(MakePhoneCall.Date.Visible(), 'MakePhoneCall.Date. not Visible');
        Assert.IsTrue(MakePhoneCall."Time of Interaction".Visible(), 'MakePhoneCall."Time of Interaction". not Visible');

        MakePhoneCall.Date.AssertEquals(Today);
        MakePhoneCall."Time of Interaction".SetValue(Time);
        MakePhoneCall.Date.SetValue(Today - 1);
        LibraryVariableStorage.Enqueue(MakePhoneCall."Time of Interaction".AsTime());
        LibraryVariableStorage.Enqueue(Today - 1);

        MakePhoneCall.Next.Invoke(); // step 2
        Assert.IsFalse(MakePhoneCall.Finish.Visible(), 'MakePhoneCall.Finish.Visible #2');
        Assert.IsFalse(MakePhoneCall."Interaction Successful".Visible(), 'MakePhoneCall."Interaction Successful".Visible #2');
        MakePhoneCall.ShowMoreLess2.Drilldown(); // to show additional controls
        Assert.IsTrue(MakePhoneCall."Interaction Successful".Visible(), 'MakePhoneCall."Interaction Successful".not Visible #2');

        MakePhoneCall.Next.Invoke(); // step 3
        Assert.IsTrue(MakePhoneCall.Finish.Visible(), 'MakePhoneCall.Finish.not Visible #3');
        MakePhoneCall.Finish.Invoke();
    end;
}

