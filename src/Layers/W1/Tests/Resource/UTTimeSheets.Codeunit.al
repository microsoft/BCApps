codeunit 136500 "UT Time Sheets"
{
    Permissions = TableData "Time Sheet Posting Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Time Sheet]
    end;

    var
        ResourcesSetup: Record "Resources Setup";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        TimeSheetMgt: Codeunit "Time Sheet Management";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryJob: Codeunit "Library - Job";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        GlobalWorkTypeCode: Code[10];
        GlobalChargeable: Boolean;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestTimeSheetResourceSetup()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        // simple unit test to verify possibility set up time sheet resource and create one timesheet
        Initialize();

        // resource - person
        CreateTimeSheetResource(Resource, false);

        // create time sheet
        CreateTimeSheets(FindTimeSheetStartDate(), 1, Resource."No.");

        // verify that time sheet is created
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
        Assert.IsTrue(TimeSheetHeader.FindFirst(), 'Time sheet is not created');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestResourceJnlUsage()
    var
        Resource: Record Resource;
        ResJnlLine: Record "Res. Journal Line";
    begin
        // resource marked as Uses Timesheet cannot be used in resource journals
        Initialize();

        // resource - person
        CreateTimeSheetResource(Resource, false);

        // try to use it in resource journal
        ResJnlLine.Init();
        asserterror ResJnlLine.Validate("Resource No.", Resource."No.");
        Assert.IsTrue(StrPos(GetLastErrorText, 'Use Time Sheet must be') > 0, 'Unexpected resource journal validation error.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJobJnlUsage()
    var
        Resource: Record Resource;
        Job: Record Job;
        JobJnlLine: Record "Job Journal Line";
    begin
        // resource marked as Uses Timesheet cannot be used in job journals
        Initialize();

        // create resource and link it to the user
        CreateTimeSheetResource(Resource, false);

        // try to use it in job journal
        Job.FindFirst();
        JobJnlLine.Init();
        JobJnlLine.Validate("Job No.", Job."No.");
        JobJnlLine.Type := JobJnlLine.Type::Resource;
        asserterror JobJnlLine.Validate("No.", Resource."No.");
        Assert.IsTrue(StrPos(GetLastErrorText, 'Use Time Sheet must be') > 0, 'Unexpected job journal validation error.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyLines()
    var
        FromTimeSheetHeader: Record "Time Sheet Header";
        FromTimeSheetLine: Record "Time Sheet Line";
        ToTimeSheetHeader: Record "Time Sheet Header";
        ToTimeSheetLine: Record "Time Sheet Line";
    begin
        // test for function "Copy lines from previous time sheet"
        Initialize();

        // create source time sheet
        LibraryTimeSheet.CreateTimeSheet(FromTimeSheetHeader, false);

        // create time sheet lines with different types
        AddRowsWithDifferentTypes(FromTimeSheetHeader, FromTimeSheetLine);

        // create destanation time sheet
        CreateTimeSheets(FromTimeSheetHeader."Ending Date" + 1, 1, FromTimeSheetHeader."Resource No.");

        ToTimeSheetHeader.SetRange("Resource No.", FromTimeSheetHeader."Resource No.");
        ToTimeSheetHeader.FindLast();

        // run Copy lines function
        TimeSheetMgt.CopyPrevTimeSheetLines(ToTimeSheetHeader);

        // verify that lines are copied
        ToTimeSheetLine.SetRange("Time Sheet No.", ToTimeSheetHeader."No.");
        Assert.IsTrue(ToTimeSheetLine.FindSet(), 'Lines have not been copied.');

        FromTimeSheetLine.SetRange("Time Sheet No.", FromTimeSheetHeader."No.");
        FromTimeSheetLine.FindSet();

        // verify that all needed fields were copied
        repeat
            ToTimeSheetLine.TestField(Type, FromTimeSheetLine.Type);
            ToTimeSheetLine.TestField("Job No.", FromTimeSheetLine."Job No.");
            ToTimeSheetLine.TestField("Job Task No.", FromTimeSheetLine."Job Task No.");
            ToTimeSheetLine.TestField("Cause of Absence Code", FromTimeSheetLine."Cause of Absence Code");
            ToTimeSheetLine.TestField(Description, FromTimeSheetLine.Description);
            ToTimeSheetLine.TestField(Chargeable, FromTimeSheetLine.Chargeable);
            FromTimeSheetLine.Next();
        until ToTimeSheetLine.Next() = 0;

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateLinesFromJobPlanning()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Date: Date;
    begin
        // test for function "Create lines from job planning"
        InitCreateFromJobPlanningSetup();

        // create time sheet
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);

        // find job and task
        LibraryTimeSheet.FindJob(Job);
        LibraryTimeSheet.FindJobTask(Job."No.", JobTask);
        // creat job planning for 2 first time sheet days
        for Date := TimeSheetHeader."Starting Date" to TimeSheetHeader."Starting Date" + 1 do
            LibraryTimeSheet.CreateJobPlanningLine(
              JobPlanningLine,
              Job."No.",
              JobTask."Job Task No.",
              TimeSheetHeader."Resource No.",
              Date);

        // run function Create lines from job planning
        TimeSheetMgt.CreateLinesFromJobPlanning(TimeSheetHeader);

        // verify that only 1 line has been created
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Job);
        TimeSheetLine.SetRange("Job No.", Job."No.");
        TimeSheetLine.SetRange("Job Task No.", JobTask."Job Task No.");
        Assert.IsTrue(TimeSheetLine.Count = 1, 'Incorrect number of lines has been created.');

        // TFS ID 351459: An additional time sheet line would not be created from the same Job Planning Line
        TimeSheetMgt.CreateLinesFromJobPlanning(TimeSheetHeader);
        Assert.IsTrue(TimeSheetLine.Count() = 1, 'Incorrect number of lines has been created.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcLinesFromJobPlanning()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        JobPlanningLine: Record "Job Planning Line";
        NumberOfLines: Integer;
    begin
        // test to verify the number of lines which are going to be created
        // with function Create lines from job planning

        // SETUP
        InitCreateFromJobPlanningSetup();

        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);
        NumberOfLines := CreateSeveralJobPlanningLines(TimeSheetHeader, JobPlanningLine);

        // EXERCISE & VERIFYF
        Assert.AreEqual(
          NumberOfLines,
          TimeSheetMgt.CalcLinesFromJobPlanning(TimeSheetHeader),
          'Incorrect number of lines is counted.');
    end;

    [Test]
    [HandlerFunctions('TimeSheetLineJobDetailHandler,StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TestWorkTypeChargChangingForJobApprove()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Resource: Record Resource;
        WorkType: Record "Work Type";
        ManagerTSbyJob: TestPage "Manager Time Sheet by Job";
    begin
        Initialize();
        LibraryTimeSheet.InitScenarioWTForJob(TimeSheetHeader);

        // create work type
        Resource.Get(TimeSheetHeader."Resource No.");
        LibraryTimeSheet.CreateWorkType(WorkType, Resource."Base Unit of Measure");

        // find time sheet
        WorkDate := TimeSheetHeader."Starting Date";
        ManagerTSbyJob.OpenEdit();

        // change chargeable and work type on the manager page by job
        ManagerTSbyJob.FILTER.SetFilter("Time Sheet No.", TimeSheetHeader."No.");
        ManagerTSbyJob.FILTER.SetFilter(Status, 'Submitted');
        GlobalWorkTypeCode := WorkType.Code;
        GlobalChargeable := false;
        ManagerTSbyJob.Description.AssistEdit();
        ManagerTSbyJob.Approve.Invoke();

        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.FindFirst();
        TimeSheetLine.TestField("Work Type Code", GlobalWorkTypeCode);
        TimeSheetLine.TestField(Chargeable, GlobalChargeable);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestManagerTimeSheetByJobChangePeriod()
    var
        ManagerTSbyJob: TestPage "Manager Time Sheet by Job";
        StartingDate: Date;
    begin
        // [SCENARIO 434102] Next, Previous Period actions shift starting date by one week.
        Initialize();
        ManagerTSbyJob.OpenEdit();
        StartingDate := ManagerTSbyJob.StartingDate.AsDate();

        ManagerTSbyJob."&Previous Period".Invoke();
        Assert.AreEqual(CalcDate('<-1W>', StartingDate), ManagerTSbyJob.StartingDate.AsDate(), 'Prev Period Starting Date');

        ManagerTSbyJob."&Next Period".Invoke();
        Assert.AreEqual(StartingDate, ManagerTSbyJob.StartingDate.AsDate(), 'Next Period Starting Date');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitTestAllStatusesInDifferentLines()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetPostingEntry: Record "Time Sheet Posting Entry";
    begin
        // create an empty time sheet
        Initialize();
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);
        VerifyTimeSheetStatuses(TimeSheetHeader, false, false, false, false, false);

        // add a new line
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
        VerifyTimeSheetStatuses(TimeSheetHeader, true, false, false, false, false);

        // add a new line, submit it
        AddTimeSheetLineWithStatus(TimeSheetHeader, TimeSheetLine.Status::Submitted);
        VerifyTimeSheetStatuses(TimeSheetHeader, true, true, false, false, false);

        // add a new line, reject it
        AddTimeSheetLineWithStatus(TimeSheetHeader, TimeSheetLine.Status::Rejected);
        VerifyTimeSheetStatuses(TimeSheetHeader, true, true, true, false, false);

        // add a new line, approve it
        AddTimeSheetLineWithStatus(TimeSheetHeader, TimeSheetLine.Status::Approved);
        VerifyTimeSheetStatuses(TimeSheetHeader, true, true, true, true, false);

        // add a new line, posted = TRUE
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
        TimeSheetLine.Posted := true;
        TimeSheetLine.Modify();

        // add posting entry
        TimeSheetPostingEntry.Init();
        TimeSheetPostingEntry."Time Sheet No." := TimeSheetLine."Time Sheet No.";
        TimeSheetPostingEntry."Time Sheet Line No." := TimeSheetLine."Line No.";
        TimeSheetPostingEntry."Time Sheet Date" := TimeSheetLine."Time Sheet Starting Date";
        TimeSheetPostingEntry.Quantity := 1;
        TimeSheetPostingEntry.Insert();

        VerifyTimeSheetStatuses(TimeSheetHeader, true, true, true, true, true);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFlowChartCalculation()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        MeasureType: Option Open,Submitted,Rejected,Approved,Scheduled,Posted,"Not posted";
        OpenQty: Decimal;
        SubmittedQty: Decimal;
        RejectedQty: Decimal;
        ApprovedQty: Decimal;
        ScheduledQty: Decimal;
        PostedQty: Decimal;
    begin
        // test for time sheet flow chart calculation procedure
        Initialize();

        // create time sheet
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);

        SetupTimeSheetChart(TimeSheetChartSetup, UserId, TimeSheetHeader."Starting Date");

        // init quiantities
        OpenQty := LibraryTimeSheet.GetRandomDecimal();
        SubmittedQty := LibraryTimeSheet.GetRandomDecimal();
        RejectedQty := LibraryTimeSheet.GetRandomDecimal();
        ApprovedQty := LibraryTimeSheet.GetRandomDecimal();
        ScheduledQty := LibraryTimeSheet.GetRandomDecimal();
        PostedQty := Round(ApprovedQty / 3);

        // create capacity for resource
        CreateResCapacity(TimeSheetHeader."Resource No.", TimeSheetHeader."Starting Date", ScheduledQty);

        // open line
        CreateTSResLineWithDetail(TimeSheetHeader, TimeSheetLine, OpenQty);

        // submitted line
        CreateTSResLineWithDetail(TimeSheetHeader, TimeSheetLine, SubmittedQty);
        TimeSheetApprovalMgt.Submit(TimeSheetLine);

        // rejected line
        CreateTSResLineWithDetail(TimeSheetHeader, TimeSheetLine, RejectedQty);
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Reject(TimeSheetLine);

        // approved line
        CreateTSResLineWithDetail(TimeSheetHeader, TimeSheetLine, ApprovedQty);
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);

        // emulate posting
        TimeSheetDetail.Get(TimeSheetLine."Time Sheet No.", TimeSheetLine."Line No.", TimeSheetLine."Time Sheet Starting Date");
        TimeSheetMgt.CreateTSPostingEntry(TimeSheetDetail, PostedQty, TimeSheetDetail.Date, '', '');

        TimeSheetHeader.CalcFields(Quantity);

        // verify numbers for Show by Status
        TimeSheetChartSetup."Show by" := TimeSheetChartSetup."Show by"::Status;
        VerifyFlowChartCalcAmount(OpenQty, TimeSheetChartSetup, TimeSheetHeader."Resource No.", MeasureType::Open);
        VerifyFlowChartCalcAmount(SubmittedQty, TimeSheetChartSetup, TimeSheetHeader."Resource No.", MeasureType::Submitted);
        VerifyFlowChartCalcAmount(RejectedQty, TimeSheetChartSetup, TimeSheetHeader."Resource No.", MeasureType::Rejected);
        VerifyFlowChartCalcAmount(ApprovedQty, TimeSheetChartSetup, TimeSheetHeader."Resource No.", MeasureType::Approved);
        VerifyFlowChartCalcAmount(ScheduledQty, TimeSheetChartSetup, TimeSheetHeader."Resource No.", MeasureType::Scheduled);
        // verify numbers for Show by Posted
        TimeSheetChartSetup."Show by" := TimeSheetChartSetup."Show by"::Posted;
        VerifyFlowChartCalcAmount(PostedQty, TimeSheetChartSetup, TimeSheetHeader."Resource No.", MeasureType::Posted);
        VerifyFlowChartCalcAmount(
          TimeSheetHeader.Quantity - PostedQty, TimeSheetChartSetup, TimeSheetHeader."Resource No.", MeasureType::"Not posted");

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFlowChartAddColumnsTimeSheetApprover()
    begin
        // test verifies the resource list for manager-approver, not time sheet admin
        InitTimeSheetChartApprover(false);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFlowChartAddColumnsTimeSheetAdmin()
    begin
        // test verifies the resource list for manager-approver, time sheet admin
        InitTimeSheetChartApprover(true);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMeasureIndex2MeasureType_Status()
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
    begin
        VerifyMeasureIndex2MeasureTypeTransformation(TimeSheetChartSetup."Show by"::Status);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMeasureIndex2MeasureType_Type()
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
    begin
        VerifyMeasureIndex2MeasureTypeTransformation(TimeSheetChartSetup."Show by"::Type);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMeasureIndex2MeasureType_Posted()
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
    begin
        VerifyMeasureIndex2MeasureTypeTransformation(TimeSheetChartSetup."Show by"::Posted);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFlowChartMeasuresName_Status()
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
        TimeSheetChartMgt: Codeunit "Time Sheet Chart Mgt.";
    begin
        TimeSheetChartMgt.OnOpenPage(TimeSheetChartSetup);
        VerifyFlowChartMeasures(TimeSheetChartSetup."Show by"::Status);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFlowChartMeasuresName_Type()
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
        TimeSheetChartMgt: Codeunit "Time Sheet Chart Mgt.";
    begin
        TimeSheetChartMgt.OnOpenPage(TimeSheetChartSetup);
        VerifyFlowChartMeasures(TimeSheetChartSetup."Show by"::Type);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFlowChartMeasuresName_Posted()
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
        TimeSheetChartMgt: Codeunit "Time Sheet Chart Mgt.";
    begin
        TimeSheetChartMgt.OnOpenPage(TimeSheetChartSetup);
        VerifyFlowChartMeasures(TimeSheetChartSetup."Show by"::Posted);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTeamMemberTimeSheetCues()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // [FEATURE] [Teammember Role Center]
        // [SCENARIO 174526] Stan can initiate Time Sheets tiles

        // [GIVEN] Create an empty time sheet
        Initialize();
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);
        VerifyTeamMemberTimeSheetStatuses(0, 0, 0, 0, 0);

        // [WHEN] Add a new line
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');

        // [THEN] Verify Open tile has been updated
        VerifyTeamMemberTimeSheetStatuses(1, 0, 0, 0, 0);

        // [THEN] Add a new line, submit it and verify Submitted tile is updated
        AddTimeSheetLineWithStatus(TimeSheetHeader, TimeSheetLine.Status::Submitted);
        VerifyTeamMemberTimeSheetStatuses(1, 1, 1, 0, 0);

        // [THEN] Add a new line, reject it and verify Rejected tile is updated
        AddTimeSheetLineWithStatus(TimeSheetHeader, TimeSheetLine.Status::Rejected);
        VerifyTeamMemberTimeSheetStatuses(1, 1, 1, 1, 0);

        // [THEN] Add a new line, approve it and verify Approved tile is updated
        AddTimeSheetLineWithStatus(TimeSheetHeader, TimeSheetLine.Status::Approved);
        VerifyTeamMemberTimeSheetStatuses(1, 1, 1, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTimeSheetListFilters()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetList: TestPage "Time Sheet List";
    begin
        // [FEATURE] [TimeCard filters]
        // [SCENARIO TFS 201246] Self activity area lacking views

        TimeSheetHeader.DeleteAll();
        TimeSheetLine.DeleteAll();

        // [GIVEN] Time Sheets with different Status.

        CreateTimeSheetHeaderSimple(TimeSheetHeader, 'Open');
        CreateTimeSheetLineSimple(TimeSheetHeader, TimeSheetLine.Status::Open);

        CreateTimeSheetHeaderSimple(TimeSheetHeader, 'Submitted');
        CreateTimeSheetLineSimple(TimeSheetHeader, TimeSheetLine.Status::Submitted);

        CreateTimeSheetHeaderSimple(TimeSheetHeader, 'Rejected');
        CreateTimeSheetLineSimple(TimeSheetHeader, TimeSheetLine.Status::Rejected);

        CreateTimeSheetHeaderSimple(TimeSheetHeader, 'Approved');
        CreateTimeSheetLineSimple(TimeSheetHeader, TimeSheetLine.Status::Approved);

        // [WHEN] The Time Sheet List is opened with filter set to nothing
        TimeSheetList.Trap();
        TimeSheetList.OpenEdit();

        // [THEN] The correct Time Sheet Header will be display.
        Assert.IsTrue(TimeSheetList.Next(), 'Expected record in repeater for Open Time Sheet');
        Assert.IsTrue(TimeSheetList.Next(), 'Expected record in repeater for Open Time Sheet');
        Assert.IsTrue(TimeSheetList.Next(), 'Expected record in repeater for Open Time Sheet');
        Assert.IsFalse(TimeSheetList.Next(), 'UnExpected record in repeater for Open Time Sheet');
        TimeSheetList.Close();

        // [WHEN] The Time Sheet List is opened with filter set to Open
        // [THEN] The correct Time Sheet Header will be display.
        VerifyTimeSheetListFilters(TimeSheetLine.Status::Open);

        // [WHEN] The Time Sheet List is opened with filter set to Submitted
        // [THEN] The correct Time Sheet Header will be display.
        VerifyTimeSheetListFilters(TimeSheetLine.Status::Submitted);

        // [WHEN] The Time Sheet List is opened with filter set to Rejected
        // [THEN] The correct Time Sheet Header will be display.
        VerifyTimeSheetListFilters(TimeSheetLine.Status::Rejected);

        // [WHEN] The Time Sheet List is opened with filter set to Approved
        // [THEN] The correct Time Sheet Header will be display.
        VerifyTimeSheetListFilters(TimeSheetLine.Status::Approved);
    end;

    local procedure CreateTimeSheets(StartDate: Date; TimeSheetsQty: Integer; ResourceNo: Code[20])
    var
        CreateTimeSheets: Report "Create Time Sheets";
    begin
        CreateTimeSheets.InitParameters(StartDate, TimeSheetsQty, ResourceNo, false, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run();
    end;

    local procedure CreateTimeSheetResource(var Resource: Record Resource; CurrUserID: Boolean)
    var
        UserSetup: Record "User Setup";
    begin
        // create user setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, CurrUserID);

        // resource - person
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        Resource.Validate("Time Sheet Owner User ID", UserSetup."User ID");
        Resource.Validate("Time Sheet Approver User ID", UserSetup."User ID");
        Resource.Modify();
    end;

    local procedure CreateSeveralJobPlanningLines(TimeSheetHeader: Record "Time Sheet Header"; var JobPlanningLine: Record "Job Planning Line") NumberOfLines: Integer
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        i: Integer;
    begin
        LibraryTimeSheet.FindJob(Job);

        NumberOfLines := LibraryRandom.RandIntInRange(2, 5);
        for i := 1 to NumberOfLines do begin
            LibraryJob.CreateJobTask(Job, JobTask);
            LibraryTimeSheet.CreateJobPlanningLine(JobPlanningLine, Job."No.", JobTask."Job Task No.",
              TimeSheetHeader."Resource No.", TimeSheetHeader."Starting Date");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateTimeAllocation_modify()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        DateQuantity: array[7] of Decimal;
        UpdateType: Option Modify,Insert,Delete;
    begin
        // UT for TimeSheetMgt.UpdateTimeAllocation
        // all weekday values should be modified

        // setup
        InitUTScenarioUpdTimeAlloc(TimeSheetHeader, TimeSheetLine, DateQuantity, UpdateType::Modify);

        // exercise
        TimeSheetMgt.UpdateTimeAllocation(TimeSheetLine, DateQuantity);

        // verify
        VerifyTimeSheetAllocation(TimeSheetHeader, TimeSheetLine, DateQuantity);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateTimeAllocation_insert()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        DateQuantity: array[7] of Decimal;
        UpdateType: Option Modify,Insert,Delete;
    begin
        // UT for TimeSheetMgt.UpdateTimeAllocation
        // all weekday values should be inserted

        // setup
        InitUTScenarioUpdTimeAlloc(TimeSheetHeader, TimeSheetLine, DateQuantity, UpdateType::Insert);

        // exercise
        TimeSheetMgt.UpdateTimeAllocation(TimeSheetLine, DateQuantity);

        // verify
        VerifyTimeSheetAllocation(TimeSheetHeader, TimeSheetLine, DateQuantity);
        VerifyTimeSheetAllocationInserted(TimeSheetHeader."Starting Date", TimeSheetLine);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateTimeAllocation_delete()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        DateQuantity: array[7] of Decimal;
        UpdateType: Option Modify,Insert,Delete;
    begin
        // UT for TimeSheetMgt.UpdateTimeAllocation
        // all weekday values should be deleted

        // setup
        InitUTScenarioUpdTimeAlloc(TimeSheetHeader, TimeSheetLine, DateQuantity, UpdateType::Delete);

        // exercise
        TimeSheetMgt.UpdateTimeAllocation(TimeSheetLine, DateQuantity);

        // verify
        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        Assert.IsTrue(TimeSheetDetail.IsEmpty, 'All time sheet detail records must be deleted');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateTSLinesFromAssemblyLine()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Date: Date;
    begin
        // UT for TimeSheetMgt.CreateTSLineFromAssemblyLine

        // setup
        Date := WorkDate();
        InitUTScenario(Resource, TimeSheetHeader, Date);
        InitAssemblyOrder(AssemblyHeader, AssemblyLine, Resource."No.", Date);

        // exercise
        TimeSheetMgt.CreateTSLineFromAssemblyLine(AssemblyHeader, AssemblyLine, AssemblyLine."Quantity to Consume (Base)");

        // verify
        VerifyCreatedTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetDetail, Date);

        TimeSheetLine.TestField(Type, TimeSheetLine.Type::"Assembly Order");
        TimeSheetLine.TestField(Description, AssemblyLine.Description);
        TimeSheetLine.TestField("Assembly Order No.", AssemblyLine."Document No.");
        TimeSheetLine.TestField("Assembly Order Line No.", AssemblyLine."Line No.");

        TimeSheetDetail.TestField(Type, TimeSheetLine.Type::"Assembly Order");
        TimeSheetDetail.TestField("Assembly Order No.", AssemblyLine."Document No.");
        TimeSheetDetail.TestField("Assembly Order Line No.", AssemblyLine."Line No.");
        TimeSheetDetail.TestField(Quantity, AssemblyLine."Quantity to Consume (Base)");

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTimeSheetAssemblyLineNotCreatedManually()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        Initialize();

        // create time sheet
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);

        // add a new time sheet line
        TimeSheetLine.Init();
        TimeSheetLine.Validate("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.Validate("Line No.", 10000);
        TimeSheetLine.Insert();

        // try to set the Assembly type of the line
        asserterror TimeSheetLine.Validate(Type, TimeSheetLine.Type::"Assembly Order");
        Assert.IsTrue(StrPos(GetLastErrorText, 'Type must not be Assembly') > 0, 'Unexpected time sheet searching error.');

        TearDown();
    end;

    [Test]
    [HandlerFunctions('TimeSheetListHandler')]
    [Scope('OnPrem')]
    procedure TestLookupOwnerTimeSheet()
    begin
        // verify function LookupOwnerTimeSheet - select time sheet using lookup from the time sheet card page
        LookupTimeSheetScenario(0);
    end;

    [Test]
    [HandlerFunctions('ManagerTimeSheetListHandler')]
    [Scope('OnPrem')]
    procedure TestLookupApproverTimeSheet()
    begin
        // verify function LookupApproverTimeSheet - select manager time sheet using lookup from the time sheet card page
        LookupTimeSheetScenario(1);
    end;

    [Test]
    [HandlerFunctions('TimeSheetArchiveListHandler')]
    [Scope('OnPrem')]
    procedure TestLookupOwnerTimeSheetArchive()
    begin
        // verify function LookupOwnerTimeSheet - select time sheet archive using lookup from the time sheet card page
        LookupTimeSheetArchScenario(0);
    end;

    [Test]
    [HandlerFunctions('ManagerTimeSheetArchiveListHandler')]
    [Scope('OnPrem')]
    procedure TestLookupApproverTimeSheetArchive()
    begin
        // verify function LookupApproverTimeSheet - select manager time sheet archive using lookup from the time sheet card page
        LookupTimeSheetArchScenario(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobWithBlockedAllCannotBeValidatedInTimeSheetUT()
    var
        Job: Record Job;
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // [FEATURE] [Job] [UT]
        // [SCENARIO 216452] Job having Blocked = "All" cannot be validated in Time Sheet Line

        CreateJobWithBlocked(Job, Job.Blocked::All);
        TimeSheetLine.Type := TimeSheetLine.Type::Job;
        asserterror TimeSheetLine.Validate("Job No.", Job."No.");

        Assert.ExpectedError(StrSubstNo('Project %1 must not be blocked with type All.', Job."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobWithBlockedPostingCanBeValidatedInTimeSheetUT()
    var
        Job: Record Job;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // [FEATURE] [Job] [UT]
        // [SCENARIO 216452] Job having Blocked = "Posting" can be validated in Time Sheet Line

        CreateJobWithBlocked(Job, Job.Blocked::Posting);
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);
        TimeSheetLine."Time Sheet No." := TimeSheetHeader."No.";
        TimeSheetLine.Type := TimeSheetLine.Type::Job;
        TimeSheetLine.Validate("Job No.", Job."No.");

        TimeSheetLine.TestField("Job No.", Job."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobWithBlockedBlankCanBeValidatedInTimeSheetUT()
    var
        Job: Record Job;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // [FEATURE] [Job] [UT]
        // [SCENARIO 216452] Job having Blocked = " " can be validated in Time Sheet Line

        CreateJobWithBlocked(Job, Job.Blocked::" ");
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);
        TimeSheetLine."Time Sheet No." := TimeSheetHeader."No.";
        TimeSheetLine.Type := TimeSheetLine.Type::Job;
        TimeSheetLine.Validate("Job No.", Job."No.");

        TimeSheetLine.TestField("Job No.", Job."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobTaskNoClearsOutWhenJobChangesInTimesheetLine()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // [FEATURE] [Job] [UT]
        // [SCENARIO 271148] "Job Task No." clears out when "Job No." changes in "Time Sheet line"

        Initialize();

        // [GIVEN] Job "A" with Job task "A1"
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);

        // [GIVEN] Time Sheet Line of type "Job" with "Job No." = "A" and "Job Task No." = "A1"
        TimeSheetLine.Init();
        TimeSheetLine."Time Sheet No." := TimeSheetHeader."No.";
        TimeSheetLine.Validate(Type, TimeSheetLine.Type::Job);
        TimeSheetLine.Validate("Job No.", JobTask."Job No.");
        TimeSheetLine.Validate("Job Task No.", JobTask."Job Task No.");

        // [GIVEN] Job "B"
        LibraryJob.CreateJob(Job);

        // [WHEN] Assign "B" for "Job No." of Time Sheet Line
        TimeSheetLine.Validate("Job No.", Job."No.");

        // [THEN] "Job Task No." of Time Sheet Line is blank
        TimeSheetLine.TestField("Job Task No.", '');
    end;

    [Test]
    procedure ResourceNameIsNotShowingUpOnTheManagerTimeSheetsByProjectPage()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        ResourceSetup: Record "Resources Setup";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        UserSetup: Record "User Setup";
        TimeSheetApprovalManagement: Codeunit "Time Sheet Approval Management";
    begin
        // [SCENARIO 571456] Resource Name is not showing up on the "Manager Time Sheets by Project" page when the "Resource Name" field is added via Personalization
        Initialize();

        // [GIVEN] Set "Time Sheet Submission Policy" = "Empty Lines Not Submitted"
        ResourceSetup.Get();
        ResourceSetup."Time Sheet Submission Policy" := ResourceSetup."Time Sheet Submission Policy"::"Empty Lines Not Submitted";
        ResourceSetup.Modify();

        // [GIVEN] Create UserSetup
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup."Allow Posting From" := WorkDate();
        UserSetup."Allow Posting To" := WorkDate();
        UserSetup."Time Sheet Admin." := true;
        UserSetup.Modify();

        // [GIVEN] Create Job with Job task
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create Time Sheet with Lines of type Project
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, true);
        TimeSheetHeader.CalcFields("Resource Name");
        CreateTimeSheetLineWithTimeAllocaiton(TimeSheetLine, TimeSheetHeader, "Time Sheet Line Type"::Job, Job."No.", JobTask."Job Task No.");

        // [GIVEN] Submit Time Sheet Line
        TimeSheetLine.Reset();
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetApprovalManagement.Submit(TimeSheetLine);

        //[THEN] Check Resource Name is not blank
        TimeSheetHeader.TestField("Resource Name");
    end;

    [Test]
    procedure TimeSheetStatusFactboxIsNotUpdatedWhenACommentIsAdded()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetCommentSheet: TestPage "Time Sheet Comment Sheet";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [SCENARIO 591266] Times Sheet Status Factbox Is Not Updated When A Comment Is Added
        Initialize();

        // [GIVEN] Create Resource
        CreateTimeSheetResource(Resource, true);

        // [GIVEN] Create Time Sheet
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, true);

        // [GIVEN] Open Time Sheet card 
        TimeSheetCard.OpenEdit();
        TimeSheetCard.Filter.SetFilter("No.", TimeSheetHeader."No.");
        TimeSheetCard.TimeSheetComments.Invoke();
        TimeSheetHeader.CalcFields(Comment);

        //[WHEN] Add Comment on Time sheet Comment sheet Page
        TimeSheetCommentSheet.OpenEdit();
        TimeSheetCommentSheet.Filter.SetFilter("No.", TimeSheetHeader."No.");
        TimeSheetCommentSheet.New();
        TimeSheetCommentSheet.Comment.SetValue('Test');
        TimeSheetCommentSheet.Close();

        // [THEN] Check Comment Should be updated on the Factbox without refresh the page after adding comment
    end;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"UT Time Sheets");

        if IsInitialized then
            exit;

        IsInitialized := true;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"UT Time Sheets");

        LibraryTimeSheet.Initialize();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        ResourcesSetup.Get();
        // create current user id setup for approver
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"UT Time Sheets");
    end;

    local procedure TearDown()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        Resource: Record Resource;
    begin
        TimeSheetHeader.DeleteAll();
        TimeSheetLine.DeleteAll();

        TimeSheetDetail.DeleteAll();
        Resource.ModifyAll("Use Time Sheet", false);
        Resource.ModifyAll("Time Sheet Owner User ID", '');
        Resource.ModifyAll("Time Sheet Approver User ID", '');
    end;

    local procedure InitUTScenario(var Resource: Record Resource; var TimeSheetHeader: Record "Time Sheet Header"; Date: Date)
    begin
        Resource.Init();
        Resource."No." :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(Resource.FieldNo("No."), DATABASE::Resource), 1, MaxStrLen(Resource."No."));
        Resource."Use Time Sheet" := true;
        Resource.Insert();

        TimeSheetHeader.Init();
        TimeSheetHeader."No." :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(TimeSheetHeader.FieldNo("No."), DATABASE::"Time Sheet Header"), 1,
            MaxStrLen(TimeSheetHeader."No."));
        TimeSheetHeader."Resource No." := Resource."No.";
        TimeSheetHeader."Starting Date" := CalcDate('<-CW>', Date);
        TimeSheetHeader."Ending Date" := CalcDate('<CW>', Date);
        TimeSheetHeader."Approver User ID" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(TimeSheetHeader."Approver User ID"));
        TimeSheetHeader.Insert();
    end;

    local procedure InitUTScenarioUpdTimeAlloc(var TimeSheetHeader: Record "Time Sheet Header"; var TimeSheetLine: Record "Time Sheet Line"; var DateQuantity: array[7] of Decimal; UpdateType: Option Modify,Insert,Delete)
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        i: Integer;
    begin
        TimeSheetHeader."No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(TimeSheetHeader."No."));
        TimeSheetHeader."Starting Date" := CalcDate('<-CW>', WorkDate());
        TimeSheetHeader."Ending Date" := CalcDate('<CW>', WorkDate());
        TimeSheetHeader.Insert();

        TimeSheetLine."Time Sheet No." := TimeSheetHeader."No.";
        TimeSheetLine."Line No." := 10000;
        TimeSheetLine."Job No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(TimeSheetLine."Job No."));
        TimeSheetLine."Job Task No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(TimeSheetLine."Job Task No."));
        TimeSheetLine."Assembly Order No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(TimeSheetLine."Assembly Order No."));
        TimeSheetLine."Cause of Absence Code" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(TimeSheetLine."Cause of Absence Code"));
        TimeSheetLine.Insert();

        for i := 1 to 7 do begin
            if UpdateType in [UpdateType::Modify, UpdateType::Delete] then begin
                // insert data to modify or delete
                TimeSheetDetail.Init();
                TimeSheetDetail."Time Sheet No." := TimeSheetLine."Time Sheet No.";
                TimeSheetDetail."Time Sheet Line No." := TimeSheetLine."Line No.";
                TimeSheetDetail.Date := TimeSheetHeader."Starting Date" + i - 1;
                TimeSheetDetail.Quantity := LibraryTimeSheet.GetRandomDecimal();
                TimeSheetDetail.Posted := true;
                TimeSheetDetail.Insert();
            end;

            // prepare time allocation to modify or insert
            if UpdateType in [UpdateType::Modify, UpdateType::Insert] then
                DateQuantity[i] := LibraryTimeSheet.GetRandomDecimal();
        end;
    end;

    local procedure InitAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; ResourceNo: Code[20]; Date: Date)
    begin
        AssemblyHeader.Init();
        AssemblyHeader."No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(AssemblyHeader."No."));
        AssemblyHeader."Posting No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(AssemblyHeader."Posting No."));
        AssemblyHeader."Posting Date" := Date;

        AssemblyLine.Init();
        AssemblyLine.Type := AssemblyLine.Type::Resource;
        AssemblyLine."Document No." := AssemblyHeader."No.";
        AssemblyLine."Line No." := Round(LibraryUtility.GenerateRandomFraction() * 10000, 1);
        AssemblyLine."No." := ResourceNo;
        AssemblyLine.Description := Format(CreateGuid());
        AssemblyLine."Quantity to Consume (Base)" := LibraryUtility.GenerateRandomFraction() * 10;
    end;

    local procedure InitTimeSheetChartApprover(IsAdmin: Boolean)
    var
        UserSetup: Record "User Setup";
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
        Resource: Record Resource;
        BusChartBuf: Record "Business Chart Buffer";
        BusChartMapColumn: Record "Business Chart Map";
    begin
        // setup for managers with different roles testing
        Initialize();

        // resource - person
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        Resource.Validate("Time Sheet Owner User ID", UserSetup."User ID");
        if IsAdmin then
            Resource.Validate("Time Sheet Approver User ID", UserSetup."User ID")
        else
            Resource.Validate("Time Sheet Approver User ID", UserId);
        Resource.Modify();

        SetupTimeSheetChart(TimeSheetChartSetup, UserId, WorkDate());

        if IsAdmin then begin
            UserSetup.Get(UserId);
            UserSetup.Validate("Time Sheet Admin.", true);
            UserSetup.Modify();
        end;

        if not IsAdmin then
            Resource.SetRange("Time Sheet Approver User ID", UserId);
        Resource.SetRange("Use Time Sheet", true);

        ChangeTimeSheetChartShowBy(TimeSheetChartSetup, BusChartBuf, TimeSheetChartSetup."Show by"::Status);

        if BusChartBuf.FindFirstColumn(BusChartMapColumn) and Resource.FindSet() then
            repeat
                Assert.AreEqual(Resource."No.", BusChartMapColumn.Name, 'Incorrect time sheet chart column name.');
            until not BusChartBuf.NextColumn(BusChartMapColumn) and (Resource.Next() = 0);
    end;

    local procedure SetupTimeSheetChart(var TimeSheetChartSetup: Record "Time Sheet Chart Setup"; UID: Text; Date: Date)
    begin
        if not TimeSheetChartSetup.Get(UID) then begin
            TimeSheetChartSetup."User ID" := UID;
            TimeSheetChartSetup.Insert();
        end;
        TimeSheetChartSetup."Starting Date" := Date;
        TimeSheetChartSetup.Modify();
    end;

    local procedure VerifyCreatedTimeSheetLine(TimeSheetHeader: Record "Time Sheet Header"; var TimeSheetLine: Record "Time Sheet Line"; var TimeSheetDetail: Record "Time Sheet Detail"; Date: Date)
    begin
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        Assert.IsTrue(TimeSheetLine.FindFirst(), 'Time sheet line is not created.');
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Approved);
        TimeSheetLine.TestField(Posted, true);
        TimeSheetLine.TestField("Approver ID", TimeSheetHeader."Approver User ID");
        TimeSheetLine.TestField("Approved By", UserId);
        TimeSheetLine.TestField("Approval Date", Today);

        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        Assert.IsTrue(TimeSheetDetail.FindFirst(), 'Time sheet detail is not found.');
        TimeSheetDetail.TestField(Date, Date);
    end;

    local procedure VerifyTimeSheetAllocation(TimeSheetHeader: Record "Time Sheet Header"; TimeSheetLine: Record "Time Sheet Line"; DateQuantity: array[7] of Decimal)
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        i: Integer;
    begin
        for i := 1 to 7 do begin
            TimeSheetDetail.Get(TimeSheetLine."Time Sheet No.", TimeSheetLine."Line No.", TimeSheetHeader."Starting Date" + i - 1);
            TimeSheetDetail.TestField(Quantity, DateQuantity[i]);
            TimeSheetDetail.TestField("Posted Quantity", DateQuantity[i]);
            TimeSheetDetail.TestField(Posted, true);
        end;
    end;

    local procedure VerifyTimeSheetAllocationInserted(TimeSheetStartDate: Date; TimeSheetLine: Record "Time Sheet Line")
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        i: Integer;
    begin
        for i := 1 to 7 do begin
            TimeSheetDetail.Get(TimeSheetLine."Time Sheet No.", TimeSheetLine."Line No.", TimeSheetStartDate + i - 1);
            TimeSheetDetail.TestField("Job No.", TimeSheetLine."Job No.");
            TimeSheetDetail.TestField("Job Task No.", TimeSheetLine."Job Task No.");
            TimeSheetDetail.TestField("Cause of Absence Code", TimeSheetLine."Cause of Absence Code");
            TimeSheetDetail.TestField("Assembly Order No.", TimeSheetLine."Assembly Order No.");
        end;
    end;

    local procedure VerifyFlowChartCalcAmount(ReferenceQty: Decimal; TimeSheetChartSetup: Record "Time Sheet Chart Setup"; ResourceNo: Code[20]; MeasureType: Option)
    var
        TimeSheetChartMgt: Codeunit "Time Sheet Chart Mgt.";
    begin
        Assert.AreEqual(
          ReferenceQty,
          TimeSheetChartMgt.CalcAmount(
            TimeSheetChartSetup,
            ResourceNo,
            MeasureType),
          'Incorrect time sheet chart amount.');
    end;

    local procedure AddRowsWithDifferentTypes(var TimeSheetHeader: Record "Time Sheet Header"; var TimeSheetLine: Record "Time Sheet Line")
    var
        CauseOfAbsence: Record "Cause of Absence";
        Job: Record Job;
        JobTask: Record "Job Task";
        Employee: Record Employee;
        Resource: Record Resource;
    begin
        // create time sheet line with type Resource
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
        TimeSheetLine.Description := 'simple resource line';
        TimeSheetLine.Modify();

        // create time sheet line with type Job
        // find job and task
        LibraryTimeSheet.FindJob(Job);
        LibraryTimeSheet.FindJobTask(Job."No.", JobTask);
        // job's responsible person (resource) must have Owner ID filled in
        Resource.Get(Job."Person Responsible");
        Resource."Time Sheet Owner User ID" := UserId;
        Resource.Modify();
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Job, Job."No.",
          JobTask."Job Task No.", '', '');

        // create time sheet line with type Absence
        LibraryHumanResource.CreateEmployee(Employee);
        Employee."Resource No." := TimeSheetHeader."Resource No.";
        Employee.Modify();

        LibraryTimeSheet.FindCauseOfAbsence(CauseOfAbsence);
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Absence, '', '', '',
          CauseOfAbsence.Code);
        TimeSheetLine.Chargeable := false;
        TimeSheetLine.Modify();
    end;

    local procedure VerifyTimeSheetStatuses(TimeSheetHeader: Record "Time Sheet Header"; OpenExists: Boolean; SubmittedExists: Boolean; RejectedExists: Boolean; ApprovedExists: Boolean; PostedExists: Boolean)
    begin
        TimeSheetHeader.CalcFields("Open Exists", "Submitted Exists", "Rejected Exists", "Approved Exists", "Posted Exists");

        Assert.AreEqual(OpenExists, TimeSheetHeader."Open Exists",
          StrSubstNo('Time Sheet field %1 value is incorrect.', TimeSheetHeader.FieldCaption("Open Exists")));
        Assert.AreEqual(SubmittedExists, TimeSheetHeader."Submitted Exists",
          StrSubstNo('Time Sheet field %1 value is incorrect.', TimeSheetHeader.FieldCaption("Submitted Exists")));
        Assert.AreEqual(RejectedExists, TimeSheetHeader."Rejected Exists",
          StrSubstNo('Time Sheet field %1 value is incorrect.', TimeSheetHeader.FieldCaption("Rejected Exists")));
        Assert.AreEqual(ApprovedExists, TimeSheetHeader."Approved Exists",
          StrSubstNo('Time Sheet field %1 value is incorrect.', TimeSheetHeader.FieldCaption("Approved Exists")));
        Assert.AreEqual(PostedExists, TimeSheetHeader."Posted Exists",
          StrSubstNo('Time Sheet field %1 value is incorrect.', TimeSheetHeader.FieldCaption("Posted Exists")));
    end;

    local procedure CreateJobWithBlocked(var Job: Record Job; BlockedOption: Enum "Job Blocked")
    begin
        Job.Init();
        Job."No." := LibraryUtility.GenerateGUID();
        Job.Blocked := BlockedOption;
        Job.Insert();
    end;

    local procedure CreateResCapacity(ResourceNo: Code[20]; Date: Date; Capacity: Decimal)
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        EntryNo: Integer;
    begin
        if ResCapacityEntry.FindLast() then;
        EntryNo := ResCapacityEntry."Entry No." + 1;
        ResCapacityEntry.Init();
        ResCapacityEntry."Entry No." := EntryNo;
        ResCapacityEntry."Resource No." := ResourceNo;
        ResCapacityEntry.Date := Date;
        ResCapacityEntry.Capacity := Capacity;
        ResCapacityEntry.Insert();
    end;

    local procedure CreateTSResLineWithDetail(TimeSheetHeader: Record "Time Sheet Header"; var TimeSheetLine: Record "Time Sheet Line"; Qty: Decimal)
    begin
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetLine."Time Sheet Starting Date", Qty);
    end;

    local procedure AddTimeSheetLineWithStatus(TimeSheetHeader: Record "Time Sheet Header"; TimeSheetLineStatus: Enum "Time Sheet Status")
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
        TimeSheetLine.Status := TimeSheetLineStatus;
        TimeSheetLine.Modify();
    end;

    local procedure ChangeTimeSheetChartShowBy(var TimeSheetChartSetup: Record "Time Sheet Chart Setup"; var BusChartBuf: Record "Business Chart Buffer"; ShowBy: Option)
    var
        TimeSheetChartMgt: Codeunit "Time Sheet Chart Mgt.";
    begin
        TimeSheetChartSetup."Show by" := ShowBy;
        TimeSheetChartSetup.Modify();
        TimeSheetChartMgt.UpdateData(BusChartBuf);
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetLineJobDetailHandler(var TimeSheetLineJobDetail: TestPage "Time Sheet Line Job Detail")
    begin
        TimeSheetLineJobDetail."Work Type Code".Value := GlobalWorkTypeCode;
        TimeSheetLineJobDetail.Chargeable.Value := Format(GlobalChargeable);
        TimeSheetLineJobDetail.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetListHandler(var TimeSheetList: TestPage "Time Sheet List")
    var
        TimeSheetNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(TimeSheetNo);
        TimeSheetList.FILTER.SetFilter("No.", TimeSheetNo);
        TimeSheetList.First();
        TimeSheetList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ManagerTimeSheetListHandler(var ManagerTimeSheetList: TestPage "Manager Time Sheet List")
    var
        TimeSheetNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(TimeSheetNo);
        ManagerTimeSheetList.FILTER.SetFilter("No.", TimeSheetNo);
        ManagerTimeSheetList.First();
        ManagerTimeSheetList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetArchiveListHandler(var TimeSheetArchiveList: TestPage "Time Sheet Archive List")
    var
        TimeSheetNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(TimeSheetNo);
        TimeSheetArchiveList.FILTER.SetFilter("No.", TimeSheetNo);
        TimeSheetArchiveList.First();
        TimeSheetArchiveList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ManagerTimeSheetArchiveListHandler(var ManagerTimeSheetArcList: TestPage "Manager Time Sheet Arc. List")
    var
        TimeSheetNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(TimeSheetNo);
        ManagerTimeSheetArcList.FILTER.SetFilter("No.", TimeSheetNo);
        ManagerTimeSheetArcList.First();
        ManagerTimeSheetArcList.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 2;
    end;

    local procedure VerifyMeasureIndex2MeasureTypeTransformation(ShowBy: Option Status,Type,Posted)
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
    begin
        TimeSheetChartSetup."Show by" := ShowBy;
        case ShowBy of
            ShowBy::Status:
                begin
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Open, TimeSheetChartSetup.MeasureIndex2MeasureType(0), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Submitted, TimeSheetChartSetup.MeasureIndex2MeasureType(1), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Rejected, TimeSheetChartSetup.MeasureIndex2MeasureType(2), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Approved, TimeSheetChartSetup.MeasureIndex2MeasureType(3), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Scheduled, TimeSheetChartSetup.MeasureIndex2MeasureType(4), '');
                end;
            ShowBy::Type:
                begin
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Resource, TimeSheetChartSetup.MeasureIndex2MeasureType(0), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Job, TimeSheetChartSetup.MeasureIndex2MeasureType(1), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Absence, TimeSheetChartSetup.MeasureIndex2MeasureType(3), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::"Assembly Order", TimeSheetChartSetup.MeasureIndex2MeasureType(4), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Scheduled, TimeSheetChartSetup.MeasureIndex2MeasureType(5), '');
                end;
        end;
    end;

    local procedure GetMeasureTypeName(TimeSheetChartSetup: Record "Time Sheet Chart Setup"; i: Integer): Text[50]
    begin
        TimeSheetChartSetup."Measure Type" := TimeSheetChartSetup.MeasureIndex2MeasureType(i);
        exit(Format(TimeSheetChartSetup."Measure Type"));
    end;

    local procedure VerifyFlowChartMeasures(ShowBy: Option Status,Type,Posted)
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
        BusChartBuf: Record "Business Chart Buffer";
        BusChartMapMeasure: Record "Business Chart Map";
        TimeSheetChartMgt: Codeunit "Time Sheet Chart Mgt.";
        Index: Integer;
    begin
        Index := 0;
        TimeSheetChartSetup.Get(UserId);
        TimeSheetChartSetup."Show by" := ShowBy;
        TimeSheetChartSetup.Modify();
        TimeSheetChartMgt.UpdateData(BusChartBuf);
        if BusChartBuf.FindFirstMeasure(BusChartMapMeasure) then
            repeat
                Assert.AreEqual(
                  GetMeasureTypeName(TimeSheetChartSetup, Index), BusChartMapMeasure.Name, 'Incorrect time sheet chart measure name.');
                Index := Index + 1;
            until not BusChartBuf.NextMeasure(BusChartMapMeasure);
    end;

    local procedure InitLookupTimeSheetScenario(var TimeSheetHeader: Record "Time Sheet Header"; var TimeSheetNo: Code[20]; var TargetTimeSheetNo: Code[20])
    var
        Resource: Record Resource;
        TimeSheetQty: Integer;
    begin
        Initialize();
        LibraryVariableStorage.Clear();

        // create resource and link it to the user
        CreateTimeSheetResource(Resource, true);

        // create time sheets
        TimeSheetQty := LibraryRandom.RandIntInRange(5, 10);
        CreateTimeSheets(FindTimeSheetStartDate(), TimeSheetQty, Resource."No.");

        // find numbers of initial and target time sheets
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
        TimeSheetHeader.FindFirst();
        TimeSheetNo := TimeSheetHeader."No.";
        TimeSheetHeader.FindLast();
        TargetTimeSheetNo := TimeSheetHeader."No.";
        LibraryVariableStorage.Enqueue(TargetTimeSheetNo);
    end;

    local procedure InitCreateFromJobPlanningSetup()
    begin
        Initialize();
        ResourcesSetup."Time Sheet by Job Approval" := ResourcesSetup."Time Sheet by Job Approval"::Never;
        ResourcesSetup.Modify();
    end;

    local procedure LookupTimeSheetScenario(Role: Option Owner,Approver)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetNo: Code[20];
        TargetTimeSheetNo: Code[20];
    begin
        // SETUP
        InitLookupTimeSheetScenario(TimeSheetHeader, TimeSheetNo, TargetTimeSheetNo);

        // EXERCISE
        case Role of
            Role::Owner:
                TimeSheetMgt.LookupOwnerTimeSheet(TimeSheetNo, TimeSheetLine, TimeSheetHeader);
            Role::Approver:
                TimeSheetMgt.LookupApproverTimeSheet(TimeSheetNo, TimeSheetLine, TimeSheetHeader);
        end;

        // VERIFY
        VerifyTargetTimeSheetNo(TimeSheetNo, TargetTimeSheetNo);

        TearDown();
    end;

    local procedure LookupTimeSheetArchScenario(Role: Option Owner,Approver)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        TimeSheetLineArchive: Record "Time Sheet Line Archive";
        TimeSheetNo: Code[20];
        TargetTimeSheetNo: Code[20];
    begin
        // SETUP
        InitLookupTimeSheetScenario(TimeSheetHeader, TimeSheetNo, TargetTimeSheetNo);

        // copy time sheets to archive
        TimeSheetHeader.FindFirst();
        repeat
            TimeSheetHeaderArchive.TransferFields(TimeSheetHeader);
            TimeSheetHeaderArchive.Insert();
        until TimeSheetHeader.Next() = 0;

        // EXERCISE
        case Role of
            Role::Owner:
                TimeSheetMgt.LookupOwnerTimeSheetArchive(TimeSheetNo, TimeSheetLineArchive, TimeSheetHeaderArchive);
            Role::Approver:
                TimeSheetMgt.LookupApproverTimeSheetArchive(TimeSheetNo, TimeSheetLineArchive, TimeSheetHeaderArchive);
        end;

        // VERIFY
        VerifyTargetTimeSheetNo(TimeSheetNo, TargetTimeSheetNo);

        TearDown();
    end;

    local procedure VerifyTargetTimeSheetNo(TimeSheetNo: Code[20]; TargetTimeSheetNo: Code[20])
    begin
        Assert.AreEqual(TargetTimeSheetNo, TimeSheetNo, 'Incorrect time sheet number.');
    end;

    local procedure FindTimeSheetStartDate(): Date
    var
        AccountingPeriod: Record "Accounting Period";
        Date: Record Date;
    begin
        // find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);

        // find first DOW after accounting period starting date
        Date.SetRange("Period Type", Date."Period Type"::Date);
        Date.SetFilter("Period Start", '%1..', AccountingPeriod."Starting Date");
        Date.SetRange("Period No.", ResourcesSetup."Time Sheet First Weekday" + 1);
        Date.FindFirst();

        exit(Date."Period Start");
    end;

    local procedure VerifyTeamMemberTimeSheetStatuses(OpenExists: Integer; SubmittedExists: Integer; TimesheetsToApproveExists: Integer; RejectedExists: Integer; ApprovedExists: Integer)
    var
        TeamMemberCue: Record "Team Member Cue";
        UserFilterOption: Option Owner,Approver;
    begin
        TeamMemberCue."User ID Filter" := UserId();

        Assert.AreEqual(OpenExists, TeamMemberCue.CountTimeSheetsInStatus(UserFilterOption::Owner, "Time Sheet Status"::Open),
          StrSubstNo('Time Sheet field %1 value is incorrect.', 'Time Sheets In progress'));
        Assert.AreEqual(SubmittedExists, TeamMemberCue.CountTimeSheetsInStatus(UserFilterOption::Owner, "Time Sheet Status"::Submitted),
          StrSubstNo('Time Sheet field %1 value is incorrect.', 'Submitted Time Sheets'));
        Assert.AreEqual(TimesheetsToApproveExists, TeamMemberCue.CountTimeSheetsInStatus(UserFilterOption::Approver, "Time Sheet Status"::Submitted),
          StrSubstNo('Time Sheet field %1 value is incorrect.', 'Time Sheets to Approve'));
        Assert.AreEqual(RejectedExists, TeamMemberCue.CountTimeSheetsInStatus(UserFilterOption::Owner, "Time Sheet Status"::Rejected),
          StrSubstNo('Time Sheet field %1 value is incorrect.', 'Rejected Time Sheets'));
        Assert.AreEqual(ApprovedExists, TeamMemberCue.CountTimeSheetsInStatus(UserFilterOption::Owner, "Time Sheet Status"::Approved),
          StrSubstNo('Time Sheet field %1 value is incorrect.', 'Approved Time Sheets'));
    end;

    local procedure CreateTimeSheetHeaderSimple(var TimeSheetHeader: Record "Time Sheet Header"; No: Code[20])
    begin
        TimeSheetHeader.Init();
        TimeSheetHeader."No." := No;
        TimeSheetHeader."Owner User ID" := UserId;
        TimeSheetHeader.Insert();
    end;

    local procedure CreateTimeSheetLineSimple(var TimeSheetHeader: Record "Time Sheet Header"; Status: Enum "Time Sheet Status")
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        TimeSheetLine.Init();
        TimeSheetLine."Time Sheet No." := TimeSheetHeader."No.";
        TimeSheetLine.Status := Status;
        TimeSheetLine.Insert();
    end;

    local procedure VerifyTimeSheetListFilters(Status: Enum "Time Sheet Status")
    var
        TimeSheetList: TestPage "Time Sheet List";
    begin
        // [WHEN] The Time Sheet List is opened with filter set to various values
        TimeSheetList.Trap();
        TimeSheetList.OpenEdit();
        case Status of
            Status::Open:
                TimeSheetList.FILTER.SetFilter("Open Exists", 'Yes');
            Status::Submitted:
                TimeSheetList.FILTER.SetFilter("Submitted Exists", 'Yes');
            Status::Rejected:
                TimeSheetList.FILTER.SetFilter("Rejected Exists", 'Yes');
            Status::Approved:
                TimeSheetList.FILTER.SetFilter("Approved Exists", 'Yes');
        end;
        TimeSheetList.First();

        // [THEN] The correct Time Sheet Header will be display.
        case Status of
            Status::Open:
                Assert.AreEqual('OPEN', TimeSheetList."No.".Value, 'Unexpected record for Open Time Sheet');
            Status::Submitted:
                Assert.AreEqual('SUBMITTED', TimeSheetList."No.".Value, 'Unexpected record for Submitted Time Sheet');
            Status::Rejected:
                Assert.AreEqual('REJECTED', TimeSheetList."No.".Value, 'Unexpected record for Rejected Time Sheet');
            Status::Approved:
                Assert.AreEqual('APPROVED', TimeSheetList."No.".Value, 'Unexpected record for Approved Time Sheet');
        end;
        Assert.IsFalse(TimeSheetList.Next(), 'Unexpected record in repeater for filtered Time Sheet');
        TimeSheetList.Close();
    end;
}
