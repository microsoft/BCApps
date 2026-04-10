codeunit 134401 "ERM KPI Web Service"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Account Schedule] [KPI] [Web Service]
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    var
        Assert: Codeunit Assert;
        ActivitiesTxt: Label 'ACTIVITIEX', Comment = 'Normal translation';
        LiquidityTxt: Label 'LIQUIDITX', Comment = 'Normal translation';
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        GLAccNo1: Code[20];
        GLAccNo2: Code[20];

    [Test]
    [Scope('OnPrem')]
    procedure TestGetLastModifiedBudgetDateNoBudget()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        GLBudgetEntry: Record "G/L Budget Entry";
        TempGLBudgetEntry: Record "G/L Budget Entry" temporary;
    begin
        InitSetupData();
        CopyBudgetEntries(GLBudgetEntry, TempGLBudgetEntry);
        GLBudgetEntry.DeleteAll();
        Assert.AreEqual(0D, AccSchedKPIWebSrvSetup.GetLastBudgetChangedDate(), 'Wrong Last Date Modified for empty budget.');
        CopyBudgetEntries(TempGLBudgetEntry, GLBudgetEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetLastModifiedBudgetDateWithBudget()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        InitSetupData();

        GLBudgetEntry.SetCurrentKey("Last Date Modified", "Budget Name");
        GLBudgetEntry.SetRange("Budget Name", GetBudgetName());
        GLBudgetEntry.FindLast();
        Assert.AreEqual(
          GLBudgetEntry."Last Date Modified", AccSchedKPIWebSrvSetup.GetLastBudgetChangedDate(), 'Wrong Last Date Modified for existing budget.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPeriod()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        AccountingPeriod: Record "Accounting Period";
        NoOfLines: Integer;
        StartDate: Date;
        EndDate: Date;
    begin
        if AccSchedKPIWebSrvSetup.Get() then
            AccSchedKPIWebSrvSetup.Delete(true);
        InitSetupData();
        AccSchedKPIWebSrvSetup.Get();

        AccSchedKPIWebSrvSetup.Period := AccSchedKPIWebSrvSetup.Period::"Fiscal Year - Last Locked Period";
        AccSchedKPIWebSrvSetup."View By" := AccSchedKPIWebSrvSetup."View By"::Day;
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);
        Assert.AreNearlyEqual(365, NoOfLines, 1, 'Wrong number of lines returned');
        AccountingPeriod.Get(StartDate);
        AccountingPeriod.TestField("New Fiscal Year");

        AccSchedKPIWebSrvSetup.Period := AccSchedKPIWebSrvSetup.Period::"Current Fiscal Year";
        AccSchedKPIWebSrvSetup."View By" := AccSchedKPIWebSrvSetup."View By"::Day;
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);
        AccountingPeriod.Get(StartDate);
        AccountingPeriod.TestField("New Fiscal Year");
        Assert.AreNearlyEqual(365, NoOfLines, 1, 'Wrong number of lines returned - curr. fiscal year.');

        AccSchedKPIWebSrvSetup.Period := AccSchedKPIWebSrvSetup.Period::"Current Period";
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);
        AccountingPeriod.Get(StartDate);

        AccSchedKPIWebSrvSetup.Period := AccSchedKPIWebSrvSetup.Period::"Last Locked Period";
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);
        AccountingPeriod.Get(StartDate);

        AccSchedKPIWebSrvSetup.Period := AccSchedKPIWebSrvSetup.Period::"Current Calendar Year";
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);
        Assert.AreEqual(1, Date2DMY(StartDate, 1), 'Wrong day of startdate for current calendar year.');
        Assert.AreEqual(1, Date2DMY(StartDate, 2), 'Wrong month of startdate for current calendar year.');
        Assert.AreEqual(31, Date2DMY(EndDate, 1), 'Wrong day of enddate for current calendar year.');
        Assert.AreEqual(12, Date2DMY(EndDate, 2), 'Wrong month of enddate for current calendar year.');
        Assert.AreNearlyEqual(365, NoOfLines, 1, 'Wrong number of lines returned for current calendar year.');
        AccSchedKPIWebSrvSetup."View By" := AccSchedKPIWebSrvSetup."View By"::Year;
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);
        Assert.AreEqual(1, NoOfLines, 'Wrong number of lines returned for current calendar year / year.');
        AccSchedKPIWebSrvSetup."View By" := AccSchedKPIWebSrvSetup."View By"::Quarter;
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);
        Assert.AreEqual(4, NoOfLines, 'Wrong number of lines returned for current calendar year / quarter.');
        AccSchedKPIWebSrvSetup."View By" := AccSchedKPIWebSrvSetup."View By"::Month;
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);
        Assert.AreEqual(12, NoOfLines, 'Wrong number of lines returned for current calendar year / month.');
        AccSchedKPIWebSrvSetup."View By" := AccSchedKPIWebSrvSetup."View By"::Week;
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);
        Assert.AreNearlyEqual(52, NoOfLines, 2, 'Wrong number of lines returned for current calendar year / week.');

        AccSchedKPIWebSrvSetup."View By" := AccSchedKPIWebSrvSetup."View By"::Day;
        AccSchedKPIWebSrvSetup.Period := AccSchedKPIWebSrvSetup.Period::"Current Calendar Quarter";
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);
        Assert.AreEqual(1, Date2DMY(StartDate, 1), 'Wrong day of startdate for current calendar quarter.');
        Assert.AreEqual(CalcDate('<-CQ>', WorkDate()), StartDate, 'Wrong startdate for current calendar quarter.');
        Assert.AreEqual(CalcDate('<CQ>', WorkDate()), EndDate, 'Wrong enddate for current calendar quarter.');

        AccSchedKPIWebSrvSetup.Period := AccSchedKPIWebSrvSetup.Period::"Current Month";
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);
        Assert.AreEqual(1, Date2DMY(StartDate, 1), 'Wrong day of startdate for current month.');
        Assert.AreEqual(CalcDate('<-CM>', WorkDate()), StartDate, 'Wrong startdate for current month.');
        Assert.AreEqual(CalcDate('<CM>', StartDate), EndDate, 'Wrong enddate for current month.');

        AccSchedKPIWebSrvSetup.Period := AccSchedKPIWebSrvSetup.Period::Today;
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);
        Assert.AreEqual(WorkDate(), StartDate, 'Wrong day of startdate for today.');
        Assert.AreEqual(WorkDate(), EndDate, 'Wrong day of startdate for today.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcNextStartDate()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        NoOfLines: Integer;
        StartDate: Date;
        EndDate: Date;
        Date: Date;
    begin
        InitSetupData();

        AccSchedKPIWebSrvSetup.Get();
        AccSchedKPIWebSrvSetup."View By" := AccSchedKPIWebSrvSetup."View By"::Day;
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);
        Date := AccSchedKPIWebSrvSetup.CalcNextStartDate(StartDate, 1);
        Assert.AreEqual(StartDate + 1, Date, 'Wrong calculation in CalcNextStartDate, 1 day.');
        Date := AccSchedKPIWebSrvSetup.CalcNextStartDate(StartDate, NoOfLines);
        Assert.AreEqual(EndDate + 1, Date, 'Wrong calculation in CalcNextStartDate, 365 days.');

        AccSchedKPIWebSrvSetup."View By" := AccSchedKPIWebSrvSetup."View By"::Month;
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);
        Date := AccSchedKPIWebSrvSetup.CalcNextStartDate(StartDate, 1);
        Assert.AreEqual(CalcDate('<1M>', StartDate), Date, 'Wrong calculation in CalcNextStartDate, 1 month.');
        Date := AccSchedKPIWebSrvSetup.CalcNextStartDate(StartDate, NoOfLines);
        Assert.AreEqual(EndDate + 1, Date, 'Wrong calculation in CalcNextStartDate, 12 months.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLastClosedAccDate()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        LastClosedDate: Date;
    begin
        InitSetupData();
        if LibraryERM.GetAllowPostingFrom() = 0D then
            LastClosedDate := WorkDate()
        else
            LastClosedDate := LibraryERM.GetAllowPostingFrom() - 1;

        AccSchedKPIWebSrvSetup.Get();
        Assert.AreEqual(LastClosedDate, AccSchedKPIWebSrvSetup.GetLastClosedAccDate(), 'Wrong last closed date.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateWebServiceName()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
    begin
        AccSchedKPIWebSrvSetup.Init();
        AccSchedKPIWebSrvSetup.Validate("Web Service Name", 'kpi');
        Assert.AreEqual('kpi', AccSchedKPIWebSrvSetup."Web Service Name", 'web service name was changed.');
        AccSchedKPIWebSrvSetup.Validate("Web Service Name", 'kpi-data1');
        asserterror AccSchedKPIWebSrvSetup.Validate("Web Service Name", 'kpi data');
        asserterror AccSchedKPIWebSrvSetup.Validate("Web Service Name", 'kp¹');
        asserterror AccSchedKPIWebSrvSetup.Validate("Web Service Name", 'kp/12');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPublishWebService()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        WebService: Record "Web Service";
    begin
        InitSetupData();
        AccSchedKPIWebSrvSetup.Get();
        WebService.LockTable();
        WebService.SetRange("Object Type", WebService."Object Type"::Page);
        WebService.SetRange("Object ID", PAGE::"Acc. Sched. KPI Web Service");
        if WebService.FindFirst() then
            WebService.Delete();
        AccSchedKPIWebSrvSetup.PublishWebService();
        WebService.Get(WebService."Object Type"::Page, AccSchedKPIWebSrvSetup."Web Service Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteWebService()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        WebService: Record "Web Service";
    begin
        InitSetupData();
        AccSchedKPIWebSrvSetup.Get();
        AccSchedKPIWebSrvSetup.PublishWebService();
        AccSchedKPIWebSrvSetup.DeleteWebService();
        asserterror WebService.Get(WebService."Object Type"::Page, PAGE::"Acc. Sched. KPI Web Service");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebServicePage()
    begin
        InitSetupData();
        ValidateWebServicePage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebServicePageIncrementalUpdate()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer";
        AccSchedKPIBufferCount: Integer;
    begin
        InitSetupData();
        // Run the web service page once to initiate data
        ValidateWebServicePage();
        AccSchedKPIBufferCount := AccSchedKPIBuffer.Count();
        Assert.AreNotEqual(0, AccSchedKPIBufferCount, 'AccSchedKPIBuffer is not updated');
        // Simulated that some gl entries have been posted and time has passed
        AccSchedKPIWebSrvSetup.Get();
        AccSchedKPIWebSrvSetup."Last G/L Entry Included" := 1000;
        AccSchedKPIWebSrvSetup."Data Last Updated" := CurrentDateTime - 3600000 * 25; // 25hrs ago
        AccSchedKPIWebSrvSetup.Modify();

        // WHEN running the page again, it should be refreshed
        ValidateWebServicePage();

        // THEN the page still produces same data as nothing was really posted
        Assert.AreEqual(AccSchedKPIBufferCount, AccSchedKPIBuffer.Count, 'Not same amount of lines in page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWebServiceDimsPage()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        AccSchedKPIWSDimensions: TestPage "Acc. Sched. KPI WS Dimensions";
        NoOfLines: Integer;
        StartDate: Date;
        EndDate: Date;
        PrevKPIName: Text;
    begin
        InitSetupData();
        AccSchedKPIWebSrvSetup.Get();
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);

        AccSchedKPIWSDimensions.OpenView();
        AccSchedKPIWSDimensions.First();
        Assert.AreEqual(StartDate, AccSchedKPIWSDimensions.Date.AsDate(), 'Wrong StartDate.');
        Assert.AreEqual(
          Format(ActivitiesTxt), AccSchedKPIWSDimensions."Account Schedule Name".Value, 'Wrong Account Schedule Name.');
        Assert.AreEqual(
          GetNetChange(GLAccNo1, AccSchedKPIWSDimensions.Date.AsDate()),
          AccSchedKPIWSDimensions."Net Change Actual".AsDecimal(), 'Wrong Net Change Actual.');
        Assert.AreEqual(
          GetBalance(GLAccNo1, AccSchedKPIWSDimensions.Date.AsDate()),
          AccSchedKPIWSDimensions."Balance at Date Actual".AsDecimal(), 'Wrong Balance at Date Actual.');
        Assert.AreEqual(
          GetNetChangeBudget(GLAccNo1, AccSchedKPIWSDimensions.Date.AsDate()),
          AccSchedKPIWSDimensions."Net Change Budget".AsDecimal(), 'Wrong Net Change Budget.');
        Assert.AreEqual(
          GetBalanceBudget(GLAccNo1, AccSchedKPIWSDimensions.Date.AsDate()),
          AccSchedKPIWSDimensions."Balance at Date Budget".AsDecimal(), 'Wrong Balance at Date Budget.');
        Assert.AreEqual(
          GetNetChange(GLAccNo1, CalcDate('<-1Y>', AccSchedKPIWSDimensions.Date.AsDate())),
          AccSchedKPIWSDimensions."Net Change Actual Last Year".AsDecimal(), 'Wrong Net Change Actual Last Year.');
        Assert.AreEqual(
          GetBalance(GLAccNo1, CalcDate('<-1Y>', AccSchedKPIWSDimensions.Date.AsDate())),
          AccSchedKPIWSDimensions."Balance at Date Actual Last Year".AsDecimal(), 'Wrong Balance at Date Actual Last Year.');
        Assert.AreEqual(
          GetNetChangeBudget(GLAccNo1, CalcDate('<-1Y>', AccSchedKPIWSDimensions.Date.AsDate())),
          AccSchedKPIWSDimensions."Net Change Budget Last Year".AsDecimal(), 'Wrong Net Change Budget Last Year.');
        Assert.AreEqual(
          GetBalanceBudget(GLAccNo1, CalcDate('<-1Y>', AccSchedKPIWSDimensions.Date.AsDate())),
          AccSchedKPIWSDimensions."Balance at Date Budget Last Year".AsDecimal(), 'Wrong Balance at Date Budget Last Year.');

        PrevKPIName := AccSchedKPIWSDimensions."KPI Name".Value();
        Assert.AreNotEqual('', PrevKPIName, 'Missing KPI Name.');
        AccSchedKPIWSDimensions.Next();
        Assert.AreNotEqual(PrevKPIName, AccSchedKPIWSDimensions."KPI Name".Value, 'Expected KPI names to be different.');
        AccSchedKPIWSDimensions.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnModifyGlBudgetEntryKpiBudget()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        // Verify that table 135 is reset when another budget entry is added
        InitSetupData();
        AccSchedKPIWebSrvSetup.Get();
        AccSchedKPIWebSrvSetup."Data Last Updated" := CurrentDateTime;
        AccSchedKPIWebSrvSetup."Last G/L Entry Included" := 1;
        AccSchedKPIWebSrvSetup.Modify();

        // When a G/L Budget Entry is added
        if GLBudgetEntry.FindLast() then;
        GLBudgetEntry."Entry No." += 1;
        GLBudgetEntry."Budget Name" := AccSchedKPIWebSrvSetup."G/L Budget Name";
        GLBudgetEntry.Insert();

        // Then AccSchedKPIWebSrvSetup is reset.
        ValidateAccSchedKpiIsReset();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnModifyGlBudgetEntryOtherBudget()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        // Verify that table 135 is NOT reset when another budget entry is added
        InitSetupData();
        AccSchedKPIWebSrvSetup.Get();
        AccSchedKPIWebSrvSetup."Data Last Updated" := CurrentDateTime;
        AccSchedKPIWebSrvSetup."Last G/L Entry Included" := 1;
        AccSchedKPIWebSrvSetup.Modify();

        // When a G/L Budget Entry is added
        if GLBudgetEntry.FindLast() then;
        GLBudgetEntry."Entry No." += 1;
        GLBudgetEntry."Budget Name" := 'FOO-BAR';
        GLBudgetEntry.Insert();

        // Then AccSchedKPIWebSrvSetup is reset.
        ValidateAccSchedKpiIsNotReset();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnModifyAccSchedKpiLine()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
    begin
        // Verify that single instance codeunit 198 is updated when table 135 is changed.
        InitSetupData();
        AccSchedKPIWebSrvSetup.Get();
        AccSchedKPIWebSrvSetup."Data Last Updated" := CurrentDateTime;
        AccSchedKPIWebSrvSetup."Last G/L Entry Included" := 1;
        AccSchedKPIWebSrvSetup.Modify();

        // When an AccSchedKpiLine is modified
        InsertTestData(LiquidityTxt, 20000, 'FOO', 'Foo', 'FOO');

        // Then AccSchedKPIWebSrvSetup is reset.
        ValidateAccSchedKpiIsReset();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnModifyAccSchedLineUsedAsKpi()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Verify that single instance codeunit 198 is updated when table 135 is changed.
        InitSetupData();
        AccSchedKPIWebSrvSetup.Get();
        AccSchedKPIWebSrvSetup."Data Last Updated" := CurrentDateTime;
        AccSchedKPIWebSrvSetup."Last G/L Entry Included" := 1;
        AccSchedKPIWebSrvSetup.Modify();

        // When an AccSchedLine is modified
        AccScheduleLine.Get(LiquidityTxt, 10000);
        AccScheduleLine.Bold := true;
        AccScheduleLine.Modify();

        // Then AccSchedKPIWebSrvSetup is reset.
        ValidateAccSchedKpiIsReset();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnModifyAccSchedLineNotUsedAsKpi()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Verify that single instance codeunit 198 is updated when table 135 is changed.
        InitSetupData();
        AccSchedKPIWebSrvSetup.Get();
        AccSchedKPIWebSrvSetup."Data Last Updated" := CurrentDateTime;
        AccSchedKPIWebSrvSetup."Last G/L Entry Included" := 1;
        AccSchedKPIWebSrvSetup.Modify();

        // When an AccSchedLine is modified
        AccScheduleLine.Init();
        AccScheduleLine."Schedule Name" := 'FOO';
        AccScheduleLine."Line No." := 10000;
        AccScheduleLine.Insert();

        // Then AccSchedKPIWebSrvSetup not is reset.
        ValidateAccSchedKpiIsNotReset();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPeriodLengthViewByPeriod()
    var
        AccountingPeriod: Record "Accounting Period";
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        NoOfLines: Integer;
        StartDate: Date;
        EndDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 292696] In case of "View By"=Period function GetPeriodLength calculates parameter NoOfLines as a number of accounting periods
        InitSetupData();

        // [GIVEN] Delete all accounting periods
        AccountingPeriod.DeleteAll();
        // [GIVEN] Create a new 12 month fiscal year for WORKDATE
        LibraryFiscalYear.CreateFiscalYear();

        // [GIVEN] Period = "Current Fiscal Year", "View By" = Period
        SetAccSchedKPIWebSrvSetupPeriodAndViewBy(
          AccSchedKPIWebSrvSetup,
          AccSchedKPIWebSrvSetup.Period::"Current Fiscal Year",
          AccSchedKPIWebSrvSetup."View By"::Period);

        // [WHEN] Function GetPeriodLength is being run
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);

        // [THEN] NoOfLines is 12
        Assert.AreEqual(12, NoOfLines, 'Invalid value of NoOfLines');
    end;

    [Test]
    [HandlerFunctions('CreateFiscalYearRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GetPeriodLengthViewByYear()
    var
        AccountingPeriod: Record "Accounting Period";
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        NoOfLines: Integer;
        StartDate: Date;
        EndDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 292696] In case of "View By"=Year function GetPeriodLength calculates parameter NoOfLines as a number of years for more than one year period
        InitSetupData();

        // [GIVEN] Delete all accounting periods
        AccountingPeriod.DeleteAll();

        // [GIVEN] Create 3 privious and current fiscal years
        RunCreateFiscalYear(CalcDate('<-3Y>', WorkDate()));
        RunCreateFiscalYear(CalcDate('<-2Y>', WorkDate()));
        RunCreateFiscalYear(CalcDate('<-1Y>', WorkDate()));
        RunCreateFiscalYear(WorkDate());

        // [GIVEN] Period = "Current Fiscal Year + 3 Previous Years", "View By" = Year
        SetAccSchedKPIWebSrvSetupPeriodAndViewBy(
          AccSchedKPIWebSrvSetup,
          AccSchedKPIWebSrvSetup.Period::"Current Fiscal Year + 3 Previous Years",
          AccSchedKPIWebSrvSetup."View By"::Year);

        // [WHEN] Function GetPeriodLength is being run
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);

        // [THEN] NoOfLines is 4
        Assert.AreEqual(4, NoOfLines, 'Invalid value of NoOfLines');
    end;

    [Test]
    [HandlerFunctions('CreateFiscalYearRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestAccountingPeriodExistsTrue()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // [FEATURE] [UT] [Accounting Period]
        // [SCENARIO 384990] CorrespondingAccountingPeriodExists returns True if Accounting Period record for the date exists
        InitSetupData();

        // [GIVEN] Delete all accounting periods
        AccountingPeriod.DeleteAll();

        // [WHEN] Create current fiscal year
        RunCreateFiscalYear(WorkDate());

        // [THEN] CorrespondingAccountingPeriodExists returns True for current month
        Assert.IsTrue(AccountingPeriod.CorrespondingAccountingPeriodExists(AccountingPeriod, WorkDate()), '');
    end;

    [Test]
    [HandlerFunctions('CreateFiscalYearRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestAccountingPeriodExistsFalse()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // [FEATURE] [UT] [Accounting Period]
        // [SCENARIO 384990] CorrespondingAccountingPeriodExists returns False if Accounting Period record for the date doesn't exist
        InitSetupData();

        // [GIVEN] Delete all accounting periods
        AccountingPeriod.DeleteAll();

        // [WHEN] Create current fiscal year
        RunCreateFiscalYear(WorkDate());

        // [THEN] CorrespondingAccountingPeriodExists returns False for the date next year
        Assert.IsFalse(AccountingPeriod.CorrespondingAccountingPeriodExists(AccountingPeriod, CalcDate('<+1M+1Y>', WorkDate())), '');
    end;

    [Test]
    procedure LastUpdatedEntryResetOnDeletingService()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        LastEntryNoMustBeResetErr: Label 'Last G/L Entry Included must be reset when the web service is unpublished.';
    begin
        // [SCENARIO] "Last G/L Entry Included" is reset when the web service is unpublished

        InitSetupData();

        // [GIVEN] Web service data is updated, "Last G/L Entry Included" is greater than 0
        AccSchedKPIWebSrvSetup."Last G/L Entry Included" := 1000;
        AccSchedKPIWebSrvSetup.Modify();

        // [WHEN] Invoke DeleteWebService
        AccSchedKPIWebSrvSetup.DeleteWebService();

        // [THEN] "Last G/L Entry Included" is reset to 0
        AccSchedKPIWebSrvSetup.Get();
        Assert.AreEqual(0, AccSchedKPIWebSrvSetup."Last G/L Entry Included", LastEntryNoMustBeResetErr);
    end;

    local procedure InitSetupData()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer";
        GLEntry: Record "G/L Entry";
    begin
        if AccSchedKPIWebSrvSetup.Get() then
            AccSchedKPIWebSrvSetup.Delete();
        AccSchedKPIWebSrvSetup.Init();
        AccSchedKPIWebSrvSetup."G/L Budget Name" := GetBudgetName();
        AccSchedKPIWebSrvSetup."Web Service Name" := 'kpi';
        AccSchedKPIWebSrvSetup."View By" := AccSchedKPIWebSrvSetup."View By"::Day;
        AccSchedKPIWebSrvSetup.Insert();

        AccSchedKPIBuffer.DeleteAll();

        GLEntry.FindFirst();
        GLAccNo1 := GLEntry."G/L Account No.";
        GLEntry.SetFilter("G/L Account No.", '<>%1', GLEntry."G/L Account No.");
        GLEntry.FindFirst();
        GLAccNo2 := GLEntry."G/L Account No.";

        InsertTestData(ActivitiesTxt, 10000, 'REV', 'Revenue', GLAccNo1);
        InsertTestData(LiquidityTxt, 10000, 'COST', 'Cost', GLAccNo2);

        LibraryERM.SetAllowPostingFromTo(CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));
        LibraryVariableStorage.Clear();
    end;

    local procedure InsertTestData(Name: Code[10]; LineNo: Integer; RowNo: Code[10]; Description: Text[30]; Totaling: Code[30])
    begin
        InsertAccSchedName(Name);
        InsertAccSchedLine(Name, LineNo, RowNo, Description, Totaling);
        InsertAccSchedWSLine(Name);
    end;

    local procedure InsertAccSchedName(Name2: Code[10])
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        if not AccScheduleName.Get(Name2) then begin
            AccScheduleName.Init();
            AccScheduleName.Name := Name2;
            AccScheduleName.Description := Format(Name2[1]) + CopyStr(LowerCase(Name2), 2);
            AccScheduleName.Insert();
        end;
    end;

    local procedure InsertAccSchedLine(Name2: Code[10]; LineNo: Integer; RowNo: Code[10]; Description2: Text[30]; Totaling2: Code[30])
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        if not AccScheduleLine.Get(Name2, LineNo) then begin
            AccScheduleLine.Init();
            AccScheduleLine."Schedule Name" := Name2;
            AccScheduleLine."Line No." := LineNo;
            AccScheduleLine."Row No." := RowNo;
            AccScheduleLine.Description := Description2;
            AccScheduleLine.Totaling := Totaling2;
            AccScheduleLine."Totaling Type" := AccScheduleLine."Totaling Type"::"Posting Accounts";
            AccScheduleLine.Insert();
        end;
    end;

    local procedure InsertAccSchedWSLine(Name2: Code[10])
    var
        AccSchedKPIWebSrvLine: Record "Acc. Sched. KPI Web Srv. Line";
    begin
        if not AccSchedKPIWebSrvLine.Get(Name2) then begin
            AccSchedKPIWebSrvLine.Init();
            AccSchedKPIWebSrvLine."Acc. Schedule Name" := Name2;
            AccSchedKPIWebSrvLine.Insert();
        end;
    end;

    local procedure GetBudgetName(): Code[10]
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        GLBudgetName.FindLast();
        exit(GLBudgetName.Name);
    end;

    local procedure GetNetChange(AccNo: Code[20]; Date: Date): Decimal
    begin
        exit(GetSum(AccNo, Date, Date));
    end;

    local procedure GetBalance(AccNo: Code[20]; Date: Date): Decimal
    begin
        exit(GetSum(AccNo, 0D, Date));
    end;

    local procedure GetSum(AccNo: Code[20]; FromDate: Date; ToDate: Date): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", AccNo);
        GLEntry.SetRange("Posting Date", FromDate, ToDate);
        GLEntry.CalcSums(Amount);
        exit(GLEntry.Amount);
    end;

    local procedure GetNetChangeBudget(AccNo: Code[20]; Date: Date): Decimal
    begin
        exit(GetSumBudget(AccNo, Date, Date));
    end;

    local procedure GetBalanceBudget(AccNo: Code[20]; Date: Date): Decimal
    begin
        exit(GetSumBudget(AccNo, 0D, Date));
    end;

    local procedure GetSumBudget(AccNo: Code[20]; FromDate: Date; ToDate: Date): Decimal
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry.SetRange("G/L Account No.", AccNo);
        GLBudgetEntry.SetRange(Date, FromDate, ToDate);
        GLBudgetEntry.CalcSums(Amount);
        exit(GLBudgetEntry.Amount);
    end;

    local procedure CopyBudgetEntries(var FromGLBudgetEntry: Record "G/L Budget Entry"; var ToGLBudgetEntry: Record "G/L Budget Entry")
    begin
        if FromGLBudgetEntry.FindSet() then
            repeat
                ToGLBudgetEntry := FromGLBudgetEntry;
                ToGLBudgetEntry.Insert();
            until FromGLBudgetEntry.Next() = 0;
    end;

    local procedure RunCreateFiscalYear(StartingDate: Date)
    var
        CreateFiscalYear: Report "Create Fiscal Year";
        PeriodLength: DateFormula;
    begin
        Commit();
        Evaluate(PeriodLength, '<1M>');
        LibraryVariableStorage.Enqueue(CalcDate('<-CY>', StartingDate));
        LibraryVariableStorage.Enqueue(12);
        LibraryVariableStorage.Enqueue(PeriodLength);
        CreateFiscalYear.HideConfirmationDialog(true);
        CreateFiscalYear.Run();
    end;

    local procedure SetAccSchedKPIWebSrvSetupPeriodAndViewBy(var AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup"; NewPeriod: Option; NewViewBy: Option)
    begin
        AccSchedKPIWebSrvSetup.Period := NewPeriod;
        AccSchedKPIWebSrvSetup."View By" := NewViewBy;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateFiscalYearRequestPageHandler(var CreateFiscalYear: TestRequestPage "Create Fiscal Year")
    begin
        CreateFiscalYear.StartingDate.SetValue(LibraryVariableStorage.DequeueDate());
        CreateFiscalYear.NoOfPeriods.SetValue(LibraryVariableStorage.DequeueInteger());
        CreateFiscalYear.PeriodLength.SetValue(LibraryVariableStorage.DequeueText());
        CreateFiscalYear.OK().Invoke();
    end;

    local procedure ValidateWebServicePage()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        AccSchedKPIWebService: TestPage "Acc. Sched. KPI Web Service";
        NoOfLines: Integer;
        StartDate: Date;
        EndDate: Date;
        PrevKPIName: Text;
    begin
        AccSchedKPIWebSrvSetup.Get();
        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);

        AccSchedKPIWebService.OpenView();
        AccSchedKPIWebService.First();
        Assert.AreEqual(StartDate, AccSchedKPIWebService.Date.AsDate(), 'Wrong StartDate.');
        Assert.AreEqual(
          Format(ActivitiesTxt), AccSchedKPIWebService."Account Schedule Name".Value, 'Wrong Account Schedule Name.');
        Assert.AreEqual(
          GetNetChange(GLAccNo1, AccSchedKPIWebService.Date.AsDate()),
          AccSchedKPIWebService."Net Change Actual".AsDecimal(), 'Wrong Net Change Actual.');
        Assert.AreEqual(
          GetBalance(GLAccNo1, AccSchedKPIWebService.Date.AsDate()),
          AccSchedKPIWebService."Balance at Date Actual".AsDecimal(), 'Wrong Balance at Date Actual.');
        Assert.AreEqual(
          GetNetChangeBudget(GLAccNo1, AccSchedKPIWebService.Date.AsDate()),
          AccSchedKPIWebService."Net Change Budget".AsDecimal(), 'Wrong Net Change Budget.');
        Assert.AreEqual(
          GetBalanceBudget(GLAccNo1, AccSchedKPIWebService.Date.AsDate()),
          AccSchedKPIWebService."Balance at Date Budget".AsDecimal(), 'Wrong Balance at Date Budget.');
        Assert.AreEqual(
          GetNetChange(GLAccNo1, CalcDate('<-1Y>', AccSchedKPIWebService.Date.AsDate())),
          AccSchedKPIWebService."Net Change Actual Last Year".AsDecimal(), 'Wrong Net Change Actual Last Year.');
        Assert.AreEqual(
          GetBalance(GLAccNo1, CalcDate('<-1Y>', AccSchedKPIWebService.Date.AsDate())),
          AccSchedKPIWebService."Balance at Date Actual Last Year".AsDecimal(), 'Wrong Balance at Date Actual Last Year.');
        Assert.AreEqual(
          GetNetChangeBudget(GLAccNo1, CalcDate('<-1Y>', AccSchedKPIWebService.Date.AsDate())),
          AccSchedKPIWebService."Net Change Budget Last Year".AsDecimal(), 'Wrong Net Change Budget Last Year.');
        Assert.AreEqual(
          GetBalanceBudget(GLAccNo1, CalcDate('<-1Y>', AccSchedKPIWebService.Date.AsDate())),
          AccSchedKPIWebService."Balance at Date Budget Last Year".AsDecimal(), 'Wrong Balance at Date Budget Last Year.');

        PrevKPIName := AccSchedKPIWebService."KPI Name".Value();
        Assert.AreNotEqual('', PrevKPIName, 'Missing KPI Name.');
        AccSchedKPIWebService.Next();
        Assert.AreNotEqual(PrevKPIName, AccSchedKPIWebService."KPI Name".Value, 'Expected KPI names to be different.');
        AccSchedKPIWebService.Close();
    end;

    local procedure ValidateAccSchedKpiIsReset()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
    begin
        AccSchedKPIWebSrvSetup.Get();
        Assert.AreEqual(0DT, AccSchedKPIWebSrvSetup."Data Last Updated", 'last updated not reset');
        Assert.AreEqual(0, AccSchedKPIWebSrvSetup."Last G/L Entry Included", 'Last gl entry not reset');
    end;

    local procedure ValidateAccSchedKpiIsNotReset()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
    begin
        AccSchedKPIWebSrvSetup.Get();
        Assert.AreNotEqual(0DT, AccSchedKPIWebSrvSetup."Data Last Updated", 'last updated was reset');
        Assert.AreNotEqual(0, AccSchedKPIWebSrvSetup."Last G/L Entry Included", 'Last gl entry was reset');
    end;
}

