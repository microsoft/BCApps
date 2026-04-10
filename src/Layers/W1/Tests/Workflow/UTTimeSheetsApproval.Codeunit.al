codeunit 136501 "UT Time Sheets Approval"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Time Sheet] [Approval]
    end;

    var
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        Text001: Label 'Rolling back changes...';
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        NoTimeSheetLinesToProcessErr: Label 'There are no time sheet lines to process in %1 action.', Comment = '%1 = Action';

    [Test]
    [Scope('OnPrem')]
    procedure SubmitApprove()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // open -> submitted -> approved
        Initialize();

        DoSubmitApprove(TimeSheetLine);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubmitApproveReopen()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // open -> submitted -> approved -> submitted
        Initialize();

        DoSubmitApprove(TimeSheetLine);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Approved);

        // reopen line
        TimeSheetApprovalMgt.ReopenApproved(TimeSheetLine);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Submitted);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubmitReject()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // open -> submitted -> rejected
        Initialize();

        DoSubmitReject(TimeSheetLine);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubmitReopen()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // open -> submitted -> opened
        Initialize();

        // create time sheet with one line
        CreateTimeSheetWithOneLine(TimeSheetLine);

        // submit line
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Submitted);

        // reopen line
        TimeSheetApprovalMgt.ReopenSubmitted(TimeSheetLine);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Open);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubmitRejectSubmit()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // open -> submitted -> rejected -> submitted
        Initialize();

        DoSubmitReject(TimeSheetLine);

        // submit line again
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Submitted);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubmitRejectReopen()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // rejected line can be reopen
        Initialize();

        DoSubmitReject(TimeSheetLine);

        // try to reopen
        TimeSheetApprovalMgt.ReopenSubmitted(TimeSheetLine);

        // Verify
        Assert.AreEqual(TimeSheetLine.Status, TimeSheetLine.Status::Open, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubmitRejectApprove()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // rejected line cannot be approved
        Initialize();

        DoSubmitReject(TimeSheetLine);

        // try to approve
        asserterror TimeSheetApprovalMgt.Approve(TimeSheetLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Approve()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // open line cannot be approved
        Initialize();

        // create time sheet with one line
        CreateTimeSheetWithOneLine(TimeSheetLine);

        // try to approve
        asserterror TimeSheetApprovalMgt.Approve(TimeSheetLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Reject()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // open line cannot be rejected
        Initialize();

        // create time sheet with one line
        CreateTimeSheetWithOneLine(TimeSheetLine);

        // try to reject
        asserterror TimeSheetApprovalMgt.Reject(TimeSheetLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubmitApproveOpen()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // approved line can be reopened
        Initialize();

        DoSubmitApprove(TimeSheetLine);

        // try to reopen
        TimeSheetApprovalMgt.ReopenSubmitted(TimeSheetLine);

        // Verify
        Assert.AreEqual(TimeSheetLine.Status, TimeSheetLine.Status::Open, ' ');

    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubmitApproveSubmit()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // approved line cannot be submitted
        Initialize();

        DoSubmitApprove(TimeSheetLine);

        // try to submit
        asserterror TimeSheetApprovalMgt.Submit(TimeSheetLine);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubmitApproveReject()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // approved line cannot be rejected
        Initialize();

        DoSubmitApprove(TimeSheetLine);

        // try to reject
        asserterror TimeSheetApprovalMgt.Reject(TimeSheetLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApproveAbsence()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Employee: Record Employee;
        EmployeeAbsence: Record "Employee Absence";
    begin
        // absence approval causes "absence posting"
        Initialize();

        // create time sheet
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);

        // create employee
        LibraryHumanResource.CreateEmployee(Employee);
        Employee."Resource No." := TimeSheetHeader."Resource No.";
        Employee.Modify();

        // create time sheet line with type absence
        LibraryTimeSheet.CreateTimeSheetLine(
          TimeSheetHeader,
          TimeSheetLine,
          TimeSheetLine.Type::Absence,
          '',
          '',
          '',
          GetCauseOfAbsenceCode());

        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetHeader."Starting Date", 1);

        // submit line
        TimeSheetApprovalMgt.Submit(TimeSheetLine);

        // approve line
        TimeSheetApprovalMgt.Approve(TimeSheetLine);

        // verify that employee absence is registered
        EmployeeAbsence.SetRange("Employee No.", Employee."No.");
        EmployeeAbsence.SetRange("From Date", TimeSheetHeader."Starting Date");
        EmployeeAbsence.FindFirst();

        TearDown();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ManagerTimeSheetOnAfterProcessReject()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TempTimeSheetLine: Record "Time Sheet Line" temporary;
        LibraryTimeSheetLocal: Codeunit "Library - Time Sheet";
        ManagerTimeSheet: TestPage "Manager Time Sheet";
        i: Integer;
    begin
        // [FEATURE] [UT] [UI] [Reject]
        // [SCENARIO 271237] Extension has possibility to catch reject of timesheet lines on ManagerTimeSheet page for further processing
        Initialize();

        // [GIVEN] Time sheet with several lines
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);
        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do
            CreateTimeSheetResourceLineWithUniqDescription(TimeSheetHeader);

        // [GIVEN] Submit lines
        SubmitTimeSheet(TimeSheetHeader."No.");

        // [GIVEN] Subscribe to ManagerTimeSheet.OnAfterProcess event
        BindSubscription(LibraryTimeSheetLocal);

        // [GIVEN] Open Manager TimeSheet page
        ManagerTimeSheet.OpenEdit();
        ManagerTimeSheet.CurrTimeSheetNo.Value := TimeSheetHeader."No.";

        // [WHEN] Reject all lines action is being invoked
        ManagerTimeSheet.Reject.Invoke();

        // [THEN] ManagerTimeSheet.OnAfterProcess event provided all processed lines
        LibraryTimeSheetLocal.GetTimeSheetLineBuffer(TempTimeSheetLine);
        VerifyTimeSheetLineBuffer(TempTimeSheetLine, TimeSheetHeader."No.");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ManagerTimeSheetByJobOnAfterProcessReject()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        TimeSheetHeader: Record "Time Sheet Header";
        TempTimeSheetLine: Record "Time Sheet Line" temporary;
        LibraryTimeSheetLocal: Codeunit "Library - Time Sheet";
        ManagerTimeSheetByJob: TestPage "Manager Time Sheet by Job";
        i: Integer;
    begin
        // [FEATURE] [UT] [UI] [Reject]
        // [SCENARIO 271237] Extension has possibility to catch reject of timesheet lines on ManagerTimeSheetByJob page for further processing
        // [SCENARIO 448247] Error when there are no lines to process.
        Initialize();

        LibraryTimeSheet.FindJob(Job);
        LibraryTimeSheet.FindJobTask(Job."No.", JobTask);

        // [GIVEN] Time sheet with several lines
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);
        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do
            CreateTimeSheetJobLineWithUniqDescription(TimeSheetHeader, JobTask);

        // [GIVEN] Submit lines
        SubmitTimeSheet(TimeSheetHeader."No.");

        // [GIVEN] Subscribe to ManagerTimeSheetByJob.OnAfterProcess event
        BindSubscription(LibraryTimeSheetLocal);

        // [GIVEN] Open Manager TimeSheet page
        ManagerTimeSheetByJob.OpenEdit();

        // [WHEN] Reject all lines action is being invoked
        ManagerTimeSheetByJob.Reject.Invoke();

        // [THEN] ManagerTimeSheetbyJob.OnAfterProcess event provided all processed lines
        LibraryTimeSheetLocal.GetTimeSheetLineBuffer(TempTimeSheetLine);
        VerifyTimeSheetLineBuffer(TempTimeSheetLine, TimeSheetHeader."No.");

        // [GIVEN] Open Manager TimeSheet page
        ManagerTimeSheetByJob.Close();
        ManagerTimeSheetByJob.OpenEdit();

        // [WHEN] Try to reject all lines again
        asserterror ManagerTimeSheetByJob.Reject.Invoke();

        // [THEN] Error is thrown that there are no lines to process
        Assert.ExpectedError(StrSubstNo(NoTimeSheetLinesToProcessErr, Enum::"Time Sheet Action"::Reject));
    end;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
    begin
        if IsInitialized then
            exit;

        LibraryTimeSheet.Initialize();

        // create current user id setup for approver
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        IsInitialized := true;
        Commit();
    end;

    local procedure SubmitTimeSheet(TimeSheetNo: Code[20])
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
    begin
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetNo);
        TimeSheetLine.FindSet();
        repeat
            TimeSheetApprovalMgt.Submit(TimeSheetLine);
        until TimeSheetLine.Next() = 0;
    end;

    local procedure CreateTimeSheetWithOneLine(var TimeSheetLine: Record "Time Sheet Line")
    var
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        // create time sheet
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);

        // create simple time sheet line
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');

        // create time sheet detail
        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetHeader."Starting Date", 1);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Open);
    end;

    local procedure CreateTimeSheetResourceLineWithUniqDescription(TimeSheetHeader: Record "Time Sheet Header")
    var
        TimeSheetLine: Record "Time Sheet Line";
        LineNo: Integer;
    begin
        LineNo := TimeSheetHeader.GetLastLineNo() + 10000;

        TimeSheetLine.Init();
        TimeSheetLine."Time Sheet No." := TimeSheetHeader."No.";
        TimeSheetLine."Line No." := LineNo;
        TimeSheetLine.Type := TimeSheetLine.Type::Resource;
        TimeSheetLine.Description := CopyStr(Format(CreateGuid()), 1, MaxStrLen(TimeSheetLine.Description));
        TimeSheetLine."Time Sheet Starting Date" := TimeSheetHeader."Starting Date";
        TimeSheetLine."Approver ID" := UserId;
        TimeSheetLine.Insert();

        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetHeader."Starting Date", 1);
    end;

    local procedure CreateTimeSheetJobLineWithUniqDescription(TimeSheetHeader: Record "Time Sheet Header"; JobTask: Record "Job Task")
    var
        TimeSheetLine: Record "Time Sheet Line";
        LineNo: Integer;
    begin
        LineNo := TimeSheetHeader.GetLastLineNo() + 10000;

        TimeSheetLine.Init();
        TimeSheetLine."Time Sheet No." := TimeSheetHeader."No.";
        TimeSheetLine."Line No." := LineNo;
        TimeSheetLine.Type := TimeSheetLine.Type::Job;
        TimeSheetLine."Job No." := JobTask."Job No.";
        TimeSheetLine."Job Task No." := JobTask."Job Task No.";
        TimeSheetLine.Description := CopyStr(Format(CreateGuid()), 1, MaxStrLen(TimeSheetLine.Description));
        TimeSheetLine."Time Sheet Starting Date" := TimeSheetHeader."Starting Date";
        TimeSheetLine."Approver ID" := UserId;
        TimeSheetLine.Insert();

        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetHeader."Starting Date", 1);
    end;

    local procedure GetCauseOfAbsenceCode(): Code[10]
    var
        CauseOfAbsence: Record "Cause of Absence";
        HumanResourceUnitOfMeasure: Record "Human Resource Unit of Measure";
    begin
        LibraryTimeSheet.FindCauseOfAbsence(CauseOfAbsence);
        if CauseOfAbsence."Unit of Measure Code" = '' then begin
            HumanResourceUnitOfMeasure.FindFirst();
            CauseOfAbsence.Validate("Unit of Measure Code", HumanResourceUnitOfMeasure.Code);
            CauseOfAbsence.Modify(true);
        end;
        exit(CauseOfAbsence.Code);
    end;

    local procedure DoSubmitApprove(var TimeSheetLine: Record "Time Sheet Line")
    begin
        // create time sheet with one line
        CreateTimeSheetWithOneLine(TimeSheetLine);

        // initially status = Open
        // reopen does not affect on open status
        TimeSheetApprovalMgt.ReopenSubmitted(TimeSheetLine);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Open);

        // submit line
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Submitted);

        // approve line
        TimeSheetApprovalMgt.Approve(TimeSheetLine);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Approved);
    end;

    local procedure DoSubmitReject(var TimeSheetLine: Record "Time Sheet Line")
    begin
        // create time sheet with one line
        CreateTimeSheetWithOneLine(TimeSheetLine);

        // submit line
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Submitted);

        // reject line
        TimeSheetApprovalMgt.Reject(TimeSheetLine);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Rejected);
    end;

    local procedure TearDown()
    begin
        asserterror Error(Text001);
    end;

    local procedure VerifyTimeSheetLineBuffer(var TimeSheetLineBuffer: Record "Time Sheet Line"; TimeSheetNo: Code[20])
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetNo);
        Assert.AreEqual(TimeSheetLine.Count, TimeSheetLineBuffer.Count, 'Invalid number of time sheet lines buffer records');
        TimeSheetLineBuffer.FindSet();
        TimeSheetLine.FindSet();
        repeat
            TimeSheetLineBuffer.TestField(Description, TimeSheetLine.Description);
            TimeSheetLineBuffer.Next();
        until TimeSheetLine.Next() = 0;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1; // All lines
    end;
}

