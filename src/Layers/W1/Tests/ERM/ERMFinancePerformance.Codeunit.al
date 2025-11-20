codeunit 134923 "ERM Finance Performance"
{
    Permissions = TableData "G/L Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Performance]
        IsInitialized := false;
    end;

    var
        DrillDownAccScheduleLine: Record "Acc. Schedule Line";
        DrillDownColumnLayout: Record "Column Layout";
        DrillDownGLAccount: Record "G/L Account";
        DrillDownCostType: Record "Cost Type";
        DrillDownCFAccount: Record "Cash Flow Account";
        DrillDownAnalysisViewEntry: Record "Analysis View Entry";
        LibraryERM: Codeunit "Library - ERM";
        LibraryCostAcc: Codeunit "Library - Cost Accounting";
        LibraryCashFlow: Codeunit "Library - Cash Flow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        DimensionValueNotEqualERR: Label 'X-Axis Dimension value for interval no. %1 differs from expected value.';
        AmountNotEqualERR: Label 'Amount does not match expected value for measure %1, X-axis dimension %2.';
        CostAccUpdateMSG: Label 'has been updated in Cost Accounting';
        ColFormulaMSG: Label 'Column formula: %1.';
        RowFormulaMSG: Label 'Row formula: %1.';
        FormulaDrillDownERR: Label 'Incorrect %1 Formula message.';
        AccSchedChartManagement: Codeunit "Acc. Sched. Chart Management";
        AccSchedManagement: Codeunit AccSchedManagement;
        DrillDownValERR: Label 'DrillDown page Amount does not match the expected value for Acc. Sched. Line %1,Column Layout %2, Date Filter %3. ';
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        LibraryInventory: Codeunit "Library - Inventory";
        IsInitialized: Boolean;
        MaxNumberOfMeasures: Label 'The number of measures added should not exceed the number of different colors that can be shown on the chart.';
        ErrMaxNumberOfMeasures: Label 'You cannot add more than %1 measures.';
        MyNotificationFilterTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Table18">VERSION(1) SORTING(Field1) WHERE(Field1=1(%1))</DataItem></DataItems></ReportParameters>';

    [Test]
    [Scope('OnPrem')]
    procedure TestChart_Period_Day()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestChart(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, AccountSchedulesChartSetup."Period Length"::Day,
          LibraryRandom.RandIntInRange(5, 15));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChart_Period_Week()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestChart(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, AccountSchedulesChartSetup."Period Length"::Week,
          LibraryRandom.RandIntInRange(5, 15));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChart_Period_Month()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestChart(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, AccountSchedulesChartSetup."Period Length"::Month,
          LibraryRandom.RandIntInRange(5, 15));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChart_Period_Quarter()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestChart(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, AccountSchedulesChartSetup."Period Length"::Quarter,
          LibraryRandom.RandIntInRange(5, 15));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChart_Period_Year()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestChart(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, AccountSchedulesChartSetup."Period Length"::Year,
          LibraryRandom.RandIntInRange(5, 15));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChart_SchedLine()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestChart(AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line", LibraryRandom.RandIntInRange(1, 5) - 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChart_ColLayout()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestChart(AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column", AccountSchedulesChartSetup."Period Length", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_ChangePeriod_Period_MonthToDay()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestAction_ChangePeriod(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, AccountSchedulesChartSetup."Period Length"::Month,
          LibraryRandom.RandIntInRange(5, 15), AccountSchedulesChartSetup."Period Length"::Day);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_ChangePeriod_Period_QuarterToWeek()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestAction_ChangePeriod(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, AccountSchedulesChartSetup."Period Length"::Quarter,
          LibraryRandom.RandIntInRange(5, 15), AccountSchedulesChartSetup."Period Length"::Week);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_ChangePeriod_Period_DayToWeek()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestAction_ChangePeriod(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, AccountSchedulesChartSetup."Period Length"::Day,
          LibraryRandom.RandIntInRange(5, 15), AccountSchedulesChartSetup."Period Length"::Week);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_ChangePeriod_Period_WeekToMonth()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestAction_ChangePeriod(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, AccountSchedulesChartSetup."Period Length"::Week,
          LibraryRandom.RandIntInRange(5, 15), AccountSchedulesChartSetup."Period Length"::Month);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_ChangePeriod_SchedLine_MonthToDay()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestAction_ChangePeriod(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line", AccountSchedulesChartSetup."Period Length"::Month, 0,
          AccountSchedulesChartSetup."Period Length"::Day);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_ChangePeriod_SchedLine_QuarterToWeek()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestAction_ChangePeriod(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line", AccountSchedulesChartSetup."Period Length"::Quarter, 0,
          AccountSchedulesChartSetup."Period Length"::Week);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_ChangePeriod_ColLayout_DayToWeek()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestAction_ChangePeriod(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column", AccountSchedulesChartSetup."Period Length"::Day, 0,
          AccountSchedulesChartSetup."Period Length"::Week);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_ChangePeriod_ColLayout_WeekToMonth()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestAction_ChangePeriod(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column", AccountSchedulesChartSetup."Period Length"::Week, 0,
          AccountSchedulesChartSetup."Period Length"::Month);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_NextPeriod_Period()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        MovePeriod: Option " ",Next,Previous;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestAction_MovePeriod(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, LibraryRandom.RandIntInRange(1, 5) - 1,
          LibraryRandom.RandIntInRange(5, 15), MovePeriod::Next);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_PrevPeriod_Period()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        MovePeriod: Option " ",Next,Previous;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestAction_MovePeriod(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, LibraryRandom.RandIntInRange(1, 5) - 1,
          LibraryRandom.RandIntInRange(5, 15), MovePeriod::Previous);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_NextPeriod_SchedLine()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        MovePeriod: Option " ",Next,Previous;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestAction_MovePeriod(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          MovePeriod::Next);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_PrevPeriod_SchedLine()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        MovePeriod: Option " ",Next,Previous;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestAction_MovePeriod(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          MovePeriod::Previous);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_NextPeriod_ColLayout()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        MovePeriod: Option " ",Next,Previous;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestAction_MovePeriod(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          MovePeriod::Next);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_PrevPeriod_ColLayout()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        MovePeriod: Option " ",Next,Previous;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestAction_MovePeriod(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          MovePeriod::Previous);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_ColumnFormula_Period()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDown(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, LibraryRandom.RandIntInRange(1, 5) - 1,
          LibraryRandom.RandIntInRange(5, 15), TestDrillDownType::ColumnFormula);
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_RowFormula_Period()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDown(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, LibraryRandom.RandIntInRange(1, 5) - 1,
          LibraryRandom.RandIntInRange(5, 15), TestDrillDownType::RowFormula);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,GLChartofAccountsHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_GLAccount_Period()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDown(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, LibraryRandom.RandIntInRange(1, 5) - 1,
          LibraryRandom.RandIntInRange(5, 15), TestDrillDownType::GLAccount);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ChartofCostTypeHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_CostType_Period()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDown(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, LibraryRandom.RandIntInRange(1, 5) - 1,
          LibraryRandom.RandIntInRange(5, 15), TestDrillDownType::CostType);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ChartofCashFlowHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_CashFlowAccount_Period()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDown(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, LibraryRandom.RandIntInRange(1, 5) - 1,
          LibraryRandom.RandIntInRange(5, 15), TestDrillDownType::CashFlowAccount);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_ColumnFormula_SchedLine()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDown(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          TestDrillDownType::ColumnFormula);
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_RowFormula_SchedLine()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDown(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          TestDrillDownType::RowFormula);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,GLChartofAccountsHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_GLAccount_SchedLine()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDown(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          TestDrillDownType::GLAccount);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ChartofCostTypeHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_CostType_SchedLine()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDown(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          TestDrillDownType::CostType);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ChartofCashFlowHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_CashFlowAccount_SchedLine()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDown(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          TestDrillDownType::CashFlowAccount);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_ColumnFormula_ColLayout()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();

        AccountSchedulesChartSetup.Init();

        TestDrillDown(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          TestDrillDownType::ColumnFormula);
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_RowFormula_ColLayout()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDown(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          TestDrillDownType::RowFormula);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,GLChartofAccountsHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_GLAccount_ColLayout()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDown(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          TestDrillDownType::GLAccount);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ChartofCostTypeHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_CostType_ColLayout()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDown(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          TestDrillDownType::CostType);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ChartofCashFlowHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_CashFlowAccount_ColLayout()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDown(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          TestDrillDownType::CashFlowAccount);
    end;

    [Test]
    [HandlerFunctions('ChartofAccAnalysisViewHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_AnalysisViewGLAccount_Period()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        AnalysisViewType: Option GLAccount,CashFlow;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDownWithAnalysisView(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, LibraryRandom.RandIntInRange(1, 5) - 1,
          LibraryRandom.RandIntInRange(5, 15), AnalysisViewType::GLAccount);
    end;

    [Test]
    [HandlerFunctions('ChartofAccAnalysisViewHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_AnalysisViewGLAccount_SchedLine()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        AnalysisViewType: Option GLAccount,CashFlow;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDownWithAnalysisView(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          AnalysisViewType::GLAccount);
    end;

    [Test]
    [HandlerFunctions('ChartofAccAnalysisViewHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_AnalysisViewGLAccount_ColLayout()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        AnalysisViewType: Option GLAccount,CashFlow;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDownWithAnalysisView(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          AnalysisViewType::GLAccount);
    end;

    [Test]
    [HandlerFunctions('ChartofAccAnalysisViewHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_AnalysisViewCashFlowAccount_Period()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        AnalysisViewType: Option GLAccount,CashFlow;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDownWithAnalysisView(
          AccountSchedulesChartSetup."Base X-Axis on"::Period, LibraryRandom.RandIntInRange(1, 5) - 1,
          LibraryRandom.RandIntInRange(5, 15), AnalysisViewType::CashFlow);
    end;

    [Test]
    [HandlerFunctions('ChartofAccAnalysisViewHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_AnalysisViewCashFlowAccount_SchedLine()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        AnalysisViewType: Option GLAccount,CashFlow;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDownWithAnalysisView(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          AnalysisViewType::CashFlow);
    end;

    [Test]
    [HandlerFunctions('ChartofAccAnalysisViewHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_AnalysisViewCashFlowAccount_ColLayout()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        AnalysisViewType: Option GLAccount,CashFlow;
    begin
        // [FEATURE] [Account Schedule] [Chart]
        Initialize();
        AccountSchedulesChartSetup.Init();

        TestDrillDownWithAnalysisView(
          AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line", LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          AnalysisViewType::CashFlow);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBusChartBuffer_GetMaxNoOfMeasures()
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
    begin
        // [FEATURE] [Chart]
        Assert.AreEqual(6, BusinessChartBuffer.GetMaxNumberOfMeasures(), MaxNumberOfMeasures);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBusChartBuffer_ErrorOnExceedingMaxNoOfMeasures()
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
    begin
        // [FEATURE] [Chart]
        asserterror BusinessChartBuffer.RaiseErrorMaxNumberOfMeasuresExceeded();
        Assert.IsTrue(
          StrPos(GetLastErrorText, StrSubstNo(ErrMaxNumberOfMeasures, BusinessChartBuffer.GetMaxNumberOfMeasures())) > 0,
          MaxNumberOfMeasures);
    end;

    [Test]
    [HandlerFunctions('AnalysisViewBudgetEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_ChartOfAccAnalyViewBudgetAmt()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: Record "Analysis View";
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        ColumnLayout: Record "Column Layout";
        GLAccountNo: Code[20];
        StartDate: Date;
        EndDate: Date;
        AnalysisViewType: Option GLAccount,CashFlow;
    begin
        // [FEATURE] [Chart]
        // Test Drilldown from Chart Of Accs. Analysis View Budget Amount will open Analysis Budget View Entries.

        // Setup: Create Analysis View Budget Entry with Column Layout.
        Initialize();
        AccountSchedulesChartSetup.Init();
        SetupStartAndEndDates(
          StartDate, EndDate, AccountSchedulesChartSetup."Base X-Axis on"::Period, LibraryRandom.RandIntInRange(1, 5), 0);
        SetupAccountScheduleWithAnalysisView2Cols(AccScheduleLine, ColumnLayout, AnalysisView, GLAccountNo, AnalysisViewType::GLAccount);
        CreateAnalysisViewBudgetEntry(AnalysisViewBudgetEntry, StartDate, AnalysisView.Code, GLAccountNo);
        LibraryVariableStorage.Enqueue(AnalysisView.Code);
        LibraryVariableStorage.Enqueue(GLAccountNo);

        // Exercise: Drilldown Chart Of Accs. Analysis View Budget Amount.
        DrillDownChartOfAccsAnalysisViewBudgetAmt(GLAccountNo);

        // Verify: Verify Drilldown from Chart Of Accs. Analysis View Budget Amount will open Analysis Budget View Entries in AnalysisViewBudgetEntriesPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFunction_MyNotifications_IsEnabledForRecordByDefault()
    var
        Customer: Record Customer;
        MyNotifications: Record "My Notifications";
    begin
        // [FEATURE] [Sales] [My Notifications]
        // [SCENARIO 220587] Code Coverage for the Page function MyNotification.IsEnabledForRecord has only 1 hits execution profile without cycling and the dependance on Customer count.
        Initialize();
        MyNotifications.DeleteAll();

        // [GIVEN] Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] My Notification entry for Customer Credit Limit check without filters.
        SetupMyNotificationsForCredirLimitCheck(MyNotifications);

        // [WHEN] Public function MyNotifications.IsEnabledForRecord is invoked for Customer.
        CodeCoverageMgt.StartApplicationCoverage();
        MyNotifications.IsEnabledForRecord(MyNotifications."Notification Id", Customer);
        CodeCoverageMgt.StopApplicationCoverage();

        // [THEN] The Lines of MyNotification.IsEnabledForRecord function are processed only once.
        Verify_MyNotificationIsEnabledForRecord_OnlySingleHits();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFunction_MyNotifications_IsEnabledForRecordWithFilter()
    var
        Customer: Record Customer;
        MyNotifications: Record "My Notifications";
        FiltersOutStream: OutStream;
    begin
        // [FEATURE] [Sales] [My Notifications]
        // [SCENARIO 220587] Code Coverage for the Page function MyNotification.IsEnabledForRecord has only 1 hits execution profile without cycling and the dependance on Customer count when filter is applied.
        Initialize();
        MyNotifications.DeleteAll();

        // [GIVEN] Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] My Notification entry for Customer Credit Limit check with filter for Customer."No.".
        SetupMyNotificationsForCredirLimitCheck(MyNotifications);
        MyNotifications."Apply to Table Filter".CreateOutStream(FiltersOutStream);
        FiltersOutStream.Write(StrSubstNo(MyNotificationFilterTxt, Customer."No."));
        MyNotifications.Modify();

        // [WHEN] Public function MyNotifications.IsEnabledForRecord is invoked for Customer.
        CodeCoverageMgt.StartApplicationCoverage();
        MyNotifications.IsEnabledForRecord(MyNotifications."Notification Id", Customer);
        CodeCoverageMgt.StopApplicationCoverage();

        // [THEN] The Lines of MyNotification.IsEnabledForRecord function are processed only once.
        Verify_MyNotificationIsEnabledForRecord_OnlySingleHits();
    end;

    [Test]
    [HandlerFunctions('SelectExistingCustVendStrMenuHandler,CustomerListModalPageHandler')]
    [Scope('OnPrem')]
    procedure PickCustomerFunctionDoesNotMarkCustomersWhenNoCustMeetsFilter()
    var
        Customer: Record Customer;
        CodeCoverage: Record "Code Coverage";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 228888] Function "PickCustomer" does not call MARK on Customer Table when no customers meets input CustomerText filter

        Initialize();

        CodeCoverageMgt.StartApplicationCoverage();
        Customer.GetCustNo(LibraryUtility.GenerateGUID());
        CodeCoverageMgt.StopApplicationCoverage();
        Assert.AreEqual(
          1,
          CodeCoverageMgt.GetNoOfHitsCoverageForObject(
            CodeCoverage."Object Type"::Table, DATABASE::Customer, 'PickCustomer'),
          'PickCustomer function not called');
        Assert.AreEqual(
          0,
          CodeCoverageMgt.GetNoOfHitsCoverageForObject(
            CodeCoverage."Object Type"::Table, DATABASE::Customer, 'MarkCustomersByFilters'),
          'MarkCustomersByFilters function called');
    end;

    [Test]
    [HandlerFunctions('CustomerListModalPageHandler')]
    [Scope('OnPrem')]
    procedure PickCustomerFunctionMarkCustomersWhenCustMeetsFilter()
    var
        Customer: Record Customer;
        CodeCoverage: Record "Code Coverage";
        CustFilter: Text[10];
        i: Integer;
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 228888] Function "PickCustomer" call MARK on Customer Table when some customers meets input CustomerText filter

        Initialize();

        CustFilter := LibraryUtility.GenerateGUID();
        for i := 1 to 2 do begin
            Customer.Init();
            Customer."No." := Format(i) + CustFilter;
            Customer.Insert();
        end;

        CodeCoverageMgt.StartApplicationCoverage();
        Customer.GetCustNo(CustFilter);
        CodeCoverageMgt.StopApplicationCoverage();
        Assert.AreEqual(
          1,
          CodeCoverageMgt.GetNoOfHitsCoverageForObject(
            CodeCoverage."Object Type"::Table, DATABASE::Customer, 'PickCustomer'),
          'PickCustomer function not called');
        Assert.AreEqual(
          1,
          CodeCoverageMgt.GetNoOfHitsCoverageForObject(
            CodeCoverage."Object Type"::Table, DATABASE::Customer, 'MarkCustomersByFilters'),
          'MarkCustomersByFilters function was not called');
    end;

    [Test]
    [HandlerFunctions('SelectExistingCustVendStrMenuHandler,VendorModalPageHandler')]
    [Scope('OnPrem')]
    procedure PickVendorFunctionDoesNotMarkVendorsWhenNoVendMeetsFilter()
    var
        Vendor: Record Vendor;
        CodeCoverage: Record "Code Coverage";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 230142] Function "PickVendor" does not call MARK on Vendor Table when no vendors meets input VendorText filter

        Initialize();

        CodeCoverageMgt.StartApplicationCoverage();
        Vendor.GetVendorNo(LibraryUtility.GenerateGUID());
        CodeCoverageMgt.StopApplicationCoverage();
        Assert.AreEqual(
          1,
          CodeCoverageMgt.GetNoOfHitsCoverageForObject(
            CodeCoverage."Object Type"::Table, DATABASE::Vendor, 'PickVendor'),
          'PickVendor function not called');
        Assert.AreEqual(
          0,
          CodeCoverageMgt.GetNoOfHitsCoverageForObject(
            CodeCoverage."Object Type"::Table, DATABASE::Vendor, 'MarkVendorsByFilters'),
          'MarkVendorsByFilters function called');
    end;

    [Test]
    [HandlerFunctions('VendorModalPageHandler')]
    [Scope('OnPrem')]
    procedure PickVendorFunctionMarkVendorsWhenVendMeetsFilter()
    var
        Vendor: Record Vendor;
        CodeCoverage: Record "Code Coverage";
        VendFilter: Text[10];
        i: Integer;
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 230142] Function "PickVendor" call MARK on Vendor Table when some vendors meets input VendorText filter

        Initialize();

        VendFilter := LibraryUtility.GenerateGUID();
        for i := 1 to 2 do begin
            Vendor.Init();
            Vendor."No." := Format(i) + VendFilter;
            Vendor.Insert();
        end;

        CodeCoverageMgt.StartApplicationCoverage();
        Vendor.GetVendorNo(VendFilter);
        CodeCoverageMgt.StopApplicationCoverage();
        Assert.AreEqual(
          1,
          CodeCoverageMgt.GetNoOfHitsCoverageForObject(
            CodeCoverage."Object Type"::Table, DATABASE::Vendor, 'PickVendor'),
          'PickVendor function not called');
        Assert.AreEqual(
          1,
          CodeCoverageMgt.GetNoOfHitsCoverageForObject(
            CodeCoverage."Object Type"::Table, DATABASE::Vendor, 'MarkVendorsByFilters'),
          'MarkVendorsByFilters function was not called');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinesInstructionMgt_SalesCheckAllLinesHaveQuantityAssigned()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CodeCoverage: Record "Code Coverage";
        LinesInstructionMgt: Codeunit "Lines Instruction Mgt.";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 267982] The "No. Of Hits" must not depend on number of lines in sales document on COD1320.SalesCheckAllLinesHaveQuantityAssigned call
        Initialize();

        FilterCodeCoverageForLinesIntructionPerfTest(CodeCoverage);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', LibraryRandom.RandIntInRange(2, 5), '', 0D);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesLine."No.", LibraryRandom.RandIntInRange(2, 5));

        CodeCoverageMgt.StartApplicationCoverage();
        LinesInstructionMgt.SalesCheckAllLinesHaveQuantityAssigned(SalesHeader);
        CodeCoverageMgt.StopApplicationCoverage();

        Assert.RecordIsEmpty(CodeCoverage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinesInstructionMgt_PurchaseCheckAllLinesHaveQuantityAssigned()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CodeCoverage: Record "Code Coverage";
        LinesInstructionMgt: Codeunit "Lines Instruction Mgt.";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 267982] The "No. Of Hits" must not depend on number of lines in sales document on COD1320.PurchaseCheckAllLinesHaveQuantityAssigned call
        Initialize();

        FilterCodeCoverageForLinesIntructionPerfTest(CodeCoverage);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', '', LibraryRandom.RandIntInRange(2, 5), '', 0D);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLine."No.", LibraryRandom.RandIntInRange(2, 5));

        CodeCoverageMgt.StartApplicationCoverage();
        LinesInstructionMgt.PurchaseCheckAllLinesHaveQuantityAssigned(PurchaseHeader);
        CodeCoverageMgt.StopApplicationCoverage();

        Assert.RecordIsEmpty(CodeCoverage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStandardSalesInvoiceReportBlankOrderNoPerformance()
    var
        SalesShipmentBuffer: Record "Sales Shipment Buffer";
        InvoiceSalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CodeCoverage: Record "Code Coverage";
    begin
        // [FEATURE] [UT] [Report] [Posted Sales Invoice]
        // [SCENARIO 334288] Printing Posted Sales Invoice with blank "Order No." do not invoke calculation of shipped and invoiced items
        Initialize();

        // [GIVEN] Post Sales Order "SO" with an Item
        PostSalesOrderWithItem(SalesHeader, SalesLine);

        // [GIVEN] Post Sales Invoice "SI" with Item Charge assigned to an Item of from the posted "SO", "SI" has blank "Order No." field.
        PostSalesInvoiceWithItemCharge(SalesHeader, SalesLine, InvoiceSalesLine);

        FindPostedSalesInvoiceForItemCharge(
          SalesInvoiceHeader, SalesInvoiceLine, InvoiceSalesLine."Sell-to Customer No.", InvoiceSalesLine."No.");

        // [WHEN] Run function from Report 1306 "Standard Sales - Invoice" on a posted "SI", the function collects shipments to a buffer table "Sales Shipment Buffer"
        CodeCoverageMgt.StartApplicationCoverage();
        SalesShipmentBuffer.GetLinesForSalesInvoiceLine(SalesInvoiceLine, SalesInvoiceHeader);
        CodeCoverageMgt.StopApplicationCoverage();

        // [THEN] Assuming that "Order No." is blank at "SI", a function must exit early with no buffer records created
        FilterCodeCoverageForObject(CodeCoverage, CodeCoverage."Object Type"::Table, DATABASE::"Sales Shipment Buffer");
        CodeCoverage.SetRange("No. of Hits", 1);
        CodeCoverage.SetFilter(Line, '%1', '*GenerateBufferFromShipment*');
        Assert.RecordIsNotEmpty(CodeCoverage);
        CodeCoverage.SetFilter(Line, '%1', '*exit*');
        Assert.RecordIsNotEmpty(CodeCoverage);

        Assert.RecordIsEmpty(SalesShipmentBuffer);
    end;

    local procedure Initialize()
    var
        CostAccSetup: Record "Cost Accounting Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Finance Performance");
        CodeCoverageMgt.StopApplicationCoverage();
        CostAccSetup.Get();
        CostAccSetup."Align G/L Account" := CostAccSetup."Align G/L Account"::"No Alignment";
        CostAccSetup.Modify();
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Finance Performance");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Finance Performance");
        LibraryERMCountryData.CreateVATData();
    end;

    local procedure SetupChartParam(var AccountSchedulesChartSetup: Record "Account Schedules Chart Setup"; var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; ShowPer: Option; PeriodLength: Option; StartDate: Date; EndDate: Date; NoOfPeriods: Integer)
    begin
        Clear(AccountSchedulesChartSetup);
        AccountSchedulesChartSetup."User ID" := UserId;
        AccountSchedulesChartSetup.Name :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(AccountSchedulesChartSetup.FieldNo(Name), DATABASE::"Account Schedules Chart Setup"), 1, 30);
        AccountSchedulesChartSetup."Account Schedule Name" := AccScheduleLine."Schedule Name";
        AccountSchedulesChartSetup."Column Layout Name" := ColumnLayout."Column Layout Name";
        AccountSchedulesChartSetup."Base X-Axis on" := ShowPer;
        AccountSchedulesChartSetup."Period Length" := PeriodLength;
        AccountSchedulesChartSetup."Start Date" := StartDate;
        if AccountSchedulesChartSetup."Base X-Axis on" = AccountSchedulesChartSetup."Base X-Axis on"::Period then
            AccountSchedulesChartSetup."No. of Periods" := NoOfPeriods
        else
            AccountSchedulesChartSetup."End Date" := EndDate;
        AccountSchedulesChartSetup.Insert();

        CreatePerfIndSetupLines(AccountSchedulesChartSetup, AccScheduleLine, ColumnLayout);
    end;

    local procedure CreatePerfIndSetupLines(var AccountSchedulesChartSetup: Record "Account Schedules Chart Setup"; var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    var
        MeasureName: Text[111];
    begin
        AccScheduleLine.FindSet();
        case AccountSchedulesChartSetup."Base X-Axis on" of
            AccountSchedulesChartSetup."Base X-Axis on"::Period:
                repeat
                    ColumnLayout.FindSet();
                    repeat
                        MeasureName := CopyStr(AccScheduleLine.Description + ' ' + ColumnLayout."Column Header", 1, MaxStrLen(MeasureName));
                        CreateOnePerfIndSetupLine(AccountSchedulesChartSetup, AccScheduleLine."Line No.", ColumnLayout."Line No.", MeasureName,
                          Format(AccScheduleLine."Line No.") + ' ' + Format(ColumnLayout."Line No."),
                          "Account Schedule Chart Type".FromInteger(LibraryRandom.RandIntInRange(1, 3)));
                    until ColumnLayout.Next() = 0;
                until AccScheduleLine.Next() = 0;
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line",
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column":
                begin
                    repeat
                        MeasureName := AccScheduleLine.Description;
                        CreateOnePerfIndSetupLine(
                          AccountSchedulesChartSetup, AccScheduleLine."Line No.", 0, MeasureName, Format(AccScheduleLine."Line No."),
                          "Account Schedule Chart Type".FromInteger(LibraryRandom.RandIntInRange(1, 3)));
                    until AccScheduleLine.Next() = 0;
                    ColumnLayout.FindSet();
                    repeat
                        MeasureName := ColumnLayout."Column Header";
                        CreateOnePerfIndSetupLine(
                          AccountSchedulesChartSetup, 0, ColumnLayout."Line No.", MeasureName, Format(ColumnLayout."Line No."),
                          "Account Schedule Chart Type".FromInteger(LibraryRandom.RandIntInRange(1, 3)));
                    until ColumnLayout.Next() = 0;
                end;
        end;
    end;

    local procedure CreateOnePerfIndSetupLine(var AccountSchedulesChartSetup: Record "Account Schedules Chart Setup"; AccScheduleLineNo: Integer; ColLayoutLineNo: Integer; MeasureName: Text[111]; MeasureValue: Text[30]; ChartType: Enum "Account Schedule Chart Type")
    var
        AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
    begin
        AccSchedChartSetupLine.Init();
        AccSchedChartSetupLine."User ID" := AccountSchedulesChartSetup."User ID";
        AccSchedChartSetupLine.Name := AccountSchedulesChartSetup.Name;
        AccSchedChartSetupLine."Account Schedule Name" := AccountSchedulesChartSetup."Account Schedule Name";
        AccSchedChartSetupLine."Account Schedule Line No." := AccScheduleLineNo;
        AccSchedChartSetupLine."Column Layout Name" := AccountSchedulesChartSetup."Column Layout Name";
        AccSchedChartSetupLine."Column Layout Line No." := ColLayoutLineNo;
        AccSchedChartSetupLine."Original Measure Name" := MeasureName;
        AccSchedChartSetupLine."Measure Name" := MeasureName;
        AccSchedChartSetupLine."Measure Value" := MeasureValue;
        AccSchedChartSetupLine."Chart Type" := ChartType;
        AccSchedChartSetupLine.Insert();
    end;

    local procedure FilterCodeCoverageForLinesIntructionPerfTest(var CodeCoverage: Record "Code Coverage")
    begin
        FilterCodeCoverageForObject(CodeCoverage, CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Lines Instruction Mgt.");
        CodeCoverage.SetFilter("No. of Hits", '>%1', 1);
    end;

    local procedure FindPostedSalesInvoiceForItemCharge(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line"; CustomerNo: Code[20]; ChargeItemNo: Code[20])
    begin
        SalesInvoiceLine.SetRange("Bill-to Customer No.", CustomerNo);
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"Charge (Item)");
        SalesInvoiceLine.SetRange("No.", ChargeItemNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceHeader.Get(SalesInvoiceLine."Document No.");
    end;

    local procedure SetupGLEntries(var GLEntry: Record "G/L Entry"; AccountNo: Code[20]; BalAccountNo: Code[20]; StartingDate: Date; EndingDate: Date; PeriodLength: Option)
    var
        PostingDate: Date;
    begin
        PostingDate := StartingDate;

        repeat
            CreateGLEntry(GLEntry, PostingDate, AccountNo, BalAccountNo, LibraryRandom.RandDecInDecimalRange(1, 100, 2));
            PostingDate := CalculateNextDate(PostingDate, 1, PeriodLength);
        until PostingDate > EndingDate;
    end;

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry"; PostingDate: Date; AccountNo: Code[20]; BalAccountNo: Code[20]; Amount: Decimal)
    var
        LastGLEntry: Record "G/L Entry";
    begin
        Clear(GLEntry);
        GLEntry."G/L Account No." := AccountNo;
        GLEntry."Bal. Account No." := BalAccountNo;
        GLEntry."Posting Date" := PostingDate;
        GLEntry.Amount := Amount;
        if LastGLEntry.FindLast() then;
        GLEntry."Entry No." := LastGLEntry."Entry No." + 1;
        GLEntry.Insert();
    end;

    local procedure SetupCostEntries(var CostEntry: Record "Cost Entry"; CostTypeNo: Code[20]; StartingDate: Date; EndingDate: Date; PeriodLength: Option)
    var
        PostingDate: Date;
    begin
        PostingDate := StartingDate;

        repeat
            CreateCostEntry(CostEntry, PostingDate, CostTypeNo, LibraryRandom.RandDecInDecimalRange(1, 100, 2));
            PostingDate := CalculateNextDate(PostingDate, 1, PeriodLength);
        until PostingDate > EndingDate;
    end;

    local procedure CreateCostEntry(var CostEntry: Record "Cost Entry"; PostingDate: Date; CostTypeNo: Code[20]; Amount: Decimal)
    var
        LastCostEntry: Record "Cost Entry";
    begin
        Clear(CostEntry);
        CostEntry."Cost Type No." := CostTypeNo;
        CostEntry."Posting Date" := PostingDate;
        CostEntry.Amount := Amount;
        if LastCostEntry.FindLast() then;
        CostEntry."Entry No." := LastCostEntry."Entry No." + 1;
        CostEntry.Insert();
    end;

    local procedure SetupCashFlowEntries(var CashFlowForecastEntry: Record "Cash Flow Forecast Entry"; CFAccountNo: Code[20]; StartingDate: Date; EndingDate: Date; PeriodLength: Option)
    var
        PostingDate: Date;
    begin
        PostingDate := StartingDate;

        repeat
            CreateCashFlowEntry(CashFlowForecastEntry, PostingDate, CFAccountNo, LibraryRandom.RandDecInDecimalRange(1, 100, 2));
            PostingDate := CalculateNextDate(PostingDate, 1, PeriodLength);
        until PostingDate > EndingDate;
    end;

    local procedure CreateCashFlowEntry(var CashFlowForecastEntry: Record "Cash Flow Forecast Entry"; PostingDate: Date; CFAccountNo: Code[20]; Amount: Decimal)
    var
        LastCashFlowForecastEntry: Record "Cash Flow Forecast Entry";
    begin
        Clear(CashFlowForecastEntry);

        CashFlowForecastEntry."Cash Flow Account No." := CFAccountNo;
        CashFlowForecastEntry."Cash Flow Date" := PostingDate;
        CashFlowForecastEntry."Amount (LCY)" := Amount;
        if LastCashFlowForecastEntry.FindLast() then;
        CashFlowForecastEntry."Entry No." := LastCashFlowForecastEntry."Entry No." + 1;
        CashFlowForecastEntry.Insert();
    end;

    local procedure SetupAnalysisViewEntries(var AnalysisViewEntry: Record "Analysis View Entry"; AnalysisViewCode: Code[10]; GLAccountNo: Code[20]; StartingDate: Date; EndingDate: Date; PeriodLength: Option; AnalysisViewType: Option GLAccount,CashFlow)
    var
        PostingDate: Date;
        EntryNo: Integer;
    begin
        PostingDate := StartingDate;
        EntryNo := 1;

        repeat
            CreateAnalysisViewEntry(
              AnalysisViewEntry, PostingDate, AnalysisViewCode, GLAccountNo, LibraryRandom.RandDecInDecimalRange(1, 100, 2), EntryNo,
              AnalysisViewType);
            PostingDate := CalculateNextDate(PostingDate, 1, PeriodLength);
            EntryNo += 1;
        until PostingDate > EndingDate;
    end;

    local procedure CreateAnalysisViewEntry(var AnalysisViewEntry: Record "Analysis View Entry"; PostingDate: Date; AnalysisViewCode: Code[10]; GLAccountNo: Code[20]; Amount: Decimal; EntryNo: Integer; AnalysisViewType: Option GLAccount,CashFlow)
    begin
        Clear(AnalysisViewEntry);

        AnalysisViewEntry."Analysis View Code" := AnalysisViewCode;
        AnalysisViewEntry."Account No." := GLAccountNo;
        AnalysisViewEntry."Account Source" := "Analysis Account Source".FromInteger(AnalysisViewType);
        AnalysisViewEntry."Posting Date" := PostingDate;
        AnalysisViewEntry.Amount := Amount;
        AnalysisViewEntry."Entry No." := EntryNo;
        AnalysisViewEntry.Insert();
    end;

    local procedure CreateAnalysisViewBudgetEntry(var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry"; PostingDate: Date; AnalysisViewCode: Code[10]; GLAccountNo: Code[20])
    begin
        Clear(AnalysisViewBudgetEntry);
        AnalysisViewBudgetEntry."Analysis View Code" := AnalysisViewCode;
        AnalysisViewBudgetEntry."G/L Account No." := GLAccountNo;
        AnalysisViewBudgetEntry."Posting Date" := PostingDate;
        AnalysisViewBudgetEntry.Amount := LibraryRandom.RandDec(1000, 2);
        AnalysisViewBudgetEntry.Insert();
    end;

    local procedure ClearDrillDownGlobalParams()
    begin
        Clear(DrillDownAccScheduleLine);
        Clear(DrillDownColumnLayout);
        Clear(DrillDownGLAccount);
        Clear(DrillDownCostType);
        Clear(DrillDownCFAccount);
        Clear(DrillDownAnalysisViewEntry);
    end;

    local procedure DrillDownChartOfAccsAnalysisViewBudgetAmt(No: Code[20])
    var
        ChartOfAccsAnalysisView: TestPage "Chart of Accs. (Analysis View)";
    begin
        ChartOfAccsAnalysisView.OpenView();
        ChartOfAccsAnalysisView.FILTER.SetFilter("No.", No);
        ChartOfAccsAnalysisView."Budgeted Amount".DrillDown();
    end;

    local procedure PostSalesOrderWithItem(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(2, 5));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure PostSalesInvoiceWithItemCharge(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var InvoiceSalesLine: Record "Sales Line")
    var
        InvoiceSalesHeader: Record "Sales Header";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();

        LibrarySales.CreateSalesHeader(InvoiceSalesHeader, InvoiceSalesHeader."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(InvoiceSalesLine, InvoiceSalesHeader, InvoiceSalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, InvoiceSalesLine, ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment,
          SalesShipmentHeader."No.", SalesLine."Line No.", SalesLine."No.");
        InvoiceSalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        InvoiceSalesLine.Modify(true);
        LibrarySales.PostSalesDocument(InvoiceSalesHeader, false, true);
    end;

    local procedure SetupDrillDownData(var AccountSchedulesChartSetup: Record "Account Schedules Chart Setup"; var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; var BusinessChartBuffer: Record "Business Chart Buffer"; TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount)
    var
        NoOfLines: Integer;
        NoOfColumns: Integer;
        FromDate: Date;
        ToDate: Date;
    begin
        // This function assumes the last account schedule line and the last column layout records are of type formula
        ClearDrillDownGlobalParams();

        NoOfLines := AccScheduleLine.Count();
        NoOfColumns := ColumnLayout.Count();

        case AccountSchedulesChartSetup."Base X-Axis on" of
            AccountSchedulesChartSetup."Base X-Axis on"::Period:
                begin
                    BusinessChartBuffer."Drill-Down X Index" :=
                      LibraryRandom.RandIntInRange(1, AccountSchedulesChartSetup."No. of Periods") - 1;
                    ToDate := BusinessChartBuffer.GetXValueAsDate(BusinessChartBuffer."Drill-Down X Index");
                    FromDate := BusinessChartBuffer.CalcFromDate(ToDate);
                    case TestDrillDownType of
                        TestDrillDownType::ColumnFormula:
                            BusinessChartBuffer."Drill-Down Measure Index" := LibraryRandom.RandIntInRange(1, NoOfLines) * NoOfColumns - 1;
                        TestDrillDownType::RowFormula:
                            BusinessChartBuffer."Drill-Down Measure Index" :=
                              (NoOfLines - 1) * NoOfColumns + LibraryRandom.RandIntInRange(0, NoOfColumns - 2);
                        TestDrillDownType::GLAccount:
                            BusinessChartBuffer."Drill-Down Measure Index" := 0;
                        TestDrillDownType::CostType:
                            BusinessChartBuffer."Drill-Down Measure Index" := 2;
                        TestDrillDownType::CashFlowAccount:
                            BusinessChartBuffer."Drill-Down Measure Index" := 4;
                    end;
                end;
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line":
                begin
                    FromDate := AccountSchedulesChartSetup."Start Date";
                    ToDate := AccountSchedulesChartSetup."End Date";
                    case TestDrillDownType of
                        TestDrillDownType::ColumnFormula:
                            begin
                                BusinessChartBuffer."Drill-Down X Index" := LibraryRandom.RandIntInRange(1, NoOfLines) - 1;
                                BusinessChartBuffer."Drill-Down Measure Index" := NoOfColumns - 1;
                            end;
                        TestDrillDownType::RowFormula:
                            begin
                                BusinessChartBuffer."Drill-Down X Index" := NoOfLines - 1;
                                BusinessChartBuffer."Drill-Down Measure Index" := LibraryRandom.RandIntInRange(0, NoOfColumns - 2);
                            end;
                        TestDrillDownType::GLAccount:
                            begin
                                BusinessChartBuffer."Drill-Down X Index" := 0;
                                BusinessChartBuffer."Drill-Down Measure Index" := 0;
                            end;
                        TestDrillDownType::CostType:
                            begin
                                BusinessChartBuffer."Drill-Down X Index" := 1;
                                BusinessChartBuffer."Drill-Down Measure Index" := 0;
                            end;
                        TestDrillDownType::CashFlowAccount:
                            begin
                                BusinessChartBuffer."Drill-Down X Index" := 2;
                                BusinessChartBuffer."Drill-Down Measure Index" := 0;
                            end;
                    end;
                end;
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column":
                begin
                    FromDate := AccountSchedulesChartSetup."Start Date";
                    ToDate := AccountSchedulesChartSetup."End Date";
                    case TestDrillDownType of
                        TestDrillDownType::ColumnFormula:
                            begin
                                BusinessChartBuffer."Drill-Down X Index" := NoOfColumns - 1;
                                BusinessChartBuffer."Drill-Down Measure Index" := LibraryRandom.RandIntInRange(1, NoOfLines) - 1;
                            end;
                        TestDrillDownType::RowFormula:
                            begin
                                BusinessChartBuffer."Drill-Down X Index" := LibraryRandom.RandIntInRange(0, NoOfColumns - 2);
                                BusinessChartBuffer."Drill-Down Measure Index" := NoOfLines - 1;
                            end;
                        TestDrillDownType::GLAccount:
                            begin
                                BusinessChartBuffer."Drill-Down X Index" := 0;
                                BusinessChartBuffer."Drill-Down Measure Index" := 0;
                            end;
                        TestDrillDownType::CostType:
                            begin
                                BusinessChartBuffer."Drill-Down X Index" := 0;
                                BusinessChartBuffer."Drill-Down Measure Index" := 1;
                            end;
                        TestDrillDownType::CashFlowAccount:
                            begin
                                BusinessChartBuffer."Drill-Down X Index" := 0;
                                BusinessChartBuffer."Drill-Down Measure Index" := 2;
                            end;
                    end;
                end;
        end;

        SetupDrillDownFilters(AccScheduleLine, ColumnLayout, TestDrillDownType, FromDate, ToDate);
    end;

    local procedure SetupDrillDownFilters(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount; FromDate: Date; ToDate: Date)
    begin
        case TestDrillDownType of
            TestDrillDownType::ColumnFormula:
                begin
                    ColumnLayout.FindLast();
                    DrillDownColumnLayout := ColumnLayout;
                    DrillDownAccScheduleLine.Init();
                end;
            TestDrillDownType::RowFormula:
                begin
                    AccScheduleLine.FindLast();
                    DrillDownAccScheduleLine := AccScheduleLine;
                    DrillDownColumnLayout.Init();
                end;
            TestDrillDownType::GLAccount:
                begin
                    AccScheduleLine.FindFirst();
                    ColumnLayout.FindFirst();
                    AccScheduleLine.SetRange("Date Filter", FromDate, ToDate);
                    AccSchedManagement.SetStartDateEndDate(FromDate, ToDate);
                    AccSchedManagement.SetGLAccRowFilters(DrillDownGLAccount, AccScheduleLine);
                    AccSchedManagement.SetGLAccColumnFilters(DrillDownGLAccount, AccScheduleLine, ColumnLayout);
                    DrillDownAccScheduleLine.Copy(AccScheduleLine);
                    DrillDownColumnLayout.Copy(ColumnLayout);
                end;
            TestDrillDownType::CostType:
                begin
                    AccScheduleLine.FindSet();
                    AccScheduleLine.Next();
                    ColumnLayout.FindFirst();
                    AccScheduleLine.SetRange("Date Filter", FromDate, ToDate);
                    AccSchedManagement.SetStartDateEndDate(FromDate, ToDate);
                    AccSchedManagement.SetCostTypeRowFilters(DrillDownCostType, AccScheduleLine, ColumnLayout);
                    AccSchedManagement.SetCostTypeColumnFilters(DrillDownCostType, AccScheduleLine, ColumnLayout);
                    DrillDownAccScheduleLine.Copy(AccScheduleLine);
                    DrillDownColumnLayout.Copy(ColumnLayout);
                end;
            TestDrillDownType::CashFlowAccount:
                begin
                    AccScheduleLine.FindSet();
                    AccScheduleLine.Next(2);
                    ColumnLayout.FindFirst();
                    AccScheduleLine.SetRange("Date Filter", FromDate, ToDate);
                    AccSchedManagement.SetStartDateEndDate(FromDate, ToDate);
                    AccSchedManagement.SetCFAccRowFilter(DrillDownCFAccount, AccScheduleLine);
                    AccSchedManagement.SetCFAccColumnFilter(DrillDownCFAccount, AccScheduleLine, ColumnLayout);
                    DrillDownAccScheduleLine.Copy(AccScheduleLine);
                    DrillDownColumnLayout.Copy(ColumnLayout);
                end;
        end;
    end;

    local procedure SetupDrillDownDataAnalysisView(var AccountSchedulesChartSetup: Record "Account Schedules Chart Setup"; var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; var BusinessChartBuffer: Record "Business Chart Buffer"; AnalysisViewCode: Code[10]; AnalysisViewType: Option GLAccount,CashFlow)
    var
        GLAccount: Record "G/L Account";
        CFAccount: Record "Cash Flow Account";
        FromDate: Date;
        ToDate: Date;
    begin
        ClearDrillDownGlobalParams();

        case AccountSchedulesChartSetup."Base X-Axis on" of
            AccountSchedulesChartSetup."Base X-Axis on"::Period:
                begin
                    BusinessChartBuffer."Drill-Down X Index" :=
                      LibraryRandom.RandIntInRange(1, AccountSchedulesChartSetup."No. of Periods") - 1;
                    BusinessChartBuffer."Drill-Down Measure Index" := 0;
                    ToDate := BusinessChartBuffer.GetXValueAsDate(BusinessChartBuffer."Drill-Down X Index");
                    FromDate := BusinessChartBuffer.CalcFromDate(ToDate);
                end;
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line",
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column":
                begin
                    FromDate := AccountSchedulesChartSetup."Start Date";
                    ToDate := AccountSchedulesChartSetup."End Date";
                    BusinessChartBuffer."Drill-Down X Index" := 0;
                    BusinessChartBuffer."Drill-Down Measure Index" := 0;
                end;
        end;

        AccScheduleLine.FindFirst();
        ColumnLayout.FindFirst();
        AccScheduleLine.SetRange("Date Filter", FromDate, ToDate);
        AccSchedManagement.SetStartDateEndDate(FromDate, ToDate);
        if AnalysisViewType = AnalysisViewType::GLAccount then begin
            AccSchedManagement.SetGLAccRowFilters(GLAccount, AccScheduleLine);
            AccSchedManagement.SetGLAccColumnFilters(GLAccount, AccScheduleLine, ColumnLayout);
        end else begin
            AccSchedManagement.SetCFAccRowFilter(CFAccount, AccScheduleLine);
            AccSchedManagement.SetCFAccColumnFilter(CFAccount, AccScheduleLine, ColumnLayout);
        end;
        DrillDownAccScheduleLine.Copy(AccScheduleLine);
        DrillDownColumnLayout.Copy(ColumnLayout);
        Clear(DrillDownAnalysisViewEntry);
        DrillDownAnalysisViewEntry.SetRange("Analysis View Code", AnalysisViewCode);
        if AnalysisViewType = AnalysisViewType::GLAccount then begin
            DrillDownAnalysisViewEntry.SetRange("Account No.", GLAccount.GetFilter("No."));
            DrillDownAnalysisViewEntry.SetRange("Account Source", DrillDownAnalysisViewEntry."Account Source"::"G/L Account");
            GLAccount.CopyFilter("Date Filter", DrillDownAnalysisViewEntry."Posting Date");
        end else begin
            DrillDownAnalysisViewEntry.SetRange("Account No.", CFAccount.GetFilter("No."));
            DrillDownAnalysisViewEntry.SetRange("Account Source", DrillDownAnalysisViewEntry."Account Source"::"Cash Flow Account");
            CFAccount.CopyFilter("Date Filter", DrillDownAnalysisViewEntry."Posting Date");
        end;
    end;

    local procedure SetupStartAndEndDates(var StartDate: Date; var EndDate: Date; ShowPer: Option Period,"Acc. Sched. Line","Acc. Sched. Column"; PeriodLength: Option; NoOfPeriods: Integer)
    begin
        StartDate := WorkDate();

        if ShowPer = ShowPer::Period then
            EndDate := CalculatePeriodEndDate(CalculateNextDate(StartDate, NoOfPeriods - 1, PeriodLength), PeriodLength)
        else
            EndDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(100, 200)), WorkDate());
    end;

    local procedure SetupMyNotificationsForCredirLimitCheck(var MyNotifications: Record "My Notifications")
    var
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
    begin
        MyNotifications.InsertDefaultWithTableNum(
          CustCheckCrLimit.GetCreditLimitNotificationId(),
          LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(),
          DATABASE::Customer);
        MyNotifications.Enabled := true;
        MyNotifications.Modify();
    end;

    local procedure TestChart(ShowPer: Option; PeriodLength: Option; NoOfPeriods: Integer)
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        BusinessChartBuffer: Record "Business Chart Buffer";
        StartDate: Date;
        EndDate: Date;
    begin
        SetupStartAndEndDates(StartDate, EndDate, ShowPer, PeriodLength, NoOfPeriods);

        SetupChart2Accounts2Cols(
          AccountSchedulesChartSetup, AccScheduleLine, ColumnLayout, ShowPer, PeriodLength, StartDate, EndDate, NoOfPeriods);

        RunChart(BusinessChartBuffer, AccountSchedulesChartSetup, 0);
        VerifyChart(AccountSchedulesChartSetup, BusinessChartBuffer, AccScheduleLine, ColumnLayout, StartDate, EndDate);
    end;

    local procedure TestAction_ChangePeriod(ShowPer: Option; PeriodLength: Option; NoOfPeriods: Integer; NewPeriodLength: Option)
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        BusinessChartBuffer: Record "Business Chart Buffer";
        StartDate: Date;
        EndDate: Date;
    begin
        SetupStartAndEndDates(StartDate, EndDate, ShowPer, PeriodLength, NoOfPeriods);

        SetupChart2Accounts2Cols(
          AccountSchedulesChartSetup, AccScheduleLine, ColumnLayout, ShowPer, PeriodLength, StartDate, EndDate, NoOfPeriods);

        RunChart(BusinessChartBuffer, AccountSchedulesChartSetup, 0);
        VerifyChart(AccountSchedulesChartSetup, BusinessChartBuffer, AccScheduleLine, ColumnLayout, StartDate, EndDate);

        AccountSchedulesChartSetup."Period Length" := NewPeriodLength;
        AccountSchedulesChartSetup.Modify();
        if ShowPer = AccountSchedulesChartSetup."Base X-Axis on"::Period then
            EndDate :=
              CalculatePeriodEndDate(
                CalculateNextDate(StartDate, NoOfPeriods - 1, AccountSchedulesChartSetup."Period Length"),
                AccountSchedulesChartSetup."Period Length")
        else begin
            StartDate := CalculatePeriodStartDate(EndDate, AccountSchedulesChartSetup."Period Length");
            EndDate := CalculatePeriodEndDate(EndDate, AccountSchedulesChartSetup."Period Length");
        end;

        RunChart(BusinessChartBuffer, AccountSchedulesChartSetup, 0);
        VerifyChart(AccountSchedulesChartSetup, BusinessChartBuffer, AccScheduleLine, ColumnLayout, StartDate, EndDate);
    end;

    local procedure TestAction_MovePeriod(ShowPer: Option; PeriodLength: Option; NoOfPeriods: Integer; PeriodToCheck: Option)
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        BusinessChartBuffer: Record "Business Chart Buffer";
        StartDate: Date;
        EndDate: Date;
    begin
        SetupStartAndEndDates(StartDate, EndDate, ShowPer, PeriodLength, NoOfPeriods);

        SetupChart2Accounts2Cols(
          AccountSchedulesChartSetup, AccScheduleLine, ColumnLayout, ShowPer, PeriodLength, StartDate, EndDate, NoOfPeriods);

        RunChart(BusinessChartBuffer, AccountSchedulesChartSetup, 0);
        VerifyChart(AccountSchedulesChartSetup, BusinessChartBuffer, AccScheduleLine, ColumnLayout, StartDate, EndDate);

        ShiftPeriod(
          StartDate, EndDate, PeriodToCheck, AccountSchedulesChartSetup."Period Length", AccountSchedulesChartSetup."Base X-Axis on");

        RunChart(BusinessChartBuffer, AccountSchedulesChartSetup, PeriodToCheck);
        VerifyChart(AccountSchedulesChartSetup, BusinessChartBuffer, AccScheduleLine, ColumnLayout, StartDate, EndDate);
    end;

    local procedure TestDrillDown(ShowPer: Option; PeriodLength: Option; NoOfPeriods: Integer; TestDrillDownType: Option ColumnFormula,RowFormula,GLAccount,CostType,CashFlowAccount)
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        GLAccount: Record "G/L Account";
        BalGLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        CostEntry: Record "Cost Entry";
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        BusinessChartBuffer: Record "Business Chart Buffer";
        CostType: Record "Cost Type";
        CashFlowAccount: Record "Cash Flow Account";
        StartDate: Date;
        EndDate: Date;
    begin
        SetupStartAndEndDates(StartDate, EndDate, ShowPer, PeriodLength, NoOfPeriods);

        SetupAccountScheduleCFandTotAccounts2Cols(AccScheduleLine, ColumnLayout, GLAccount, CostType, CashFlowAccount);
        LibraryERM.CreateGLAccount(BalGLAccount);

        SetupChartParam(AccountSchedulesChartSetup, AccScheduleLine, ColumnLayout, ShowPer, PeriodLength, StartDate, EndDate, NoOfPeriods);
        SetupGLEntries(GLEntry, GLAccount."No.", BalGLAccount."No.", StartDate, EndDate, PeriodLength);
        SetupCostEntries(CostEntry, CostType."No.", StartDate, EndDate, PeriodLength);
        SetupCashFlowEntries(CashFlowForecastEntry, CashFlowAccount."No.", StartDate, EndDate, PeriodLength);

        RunChart(BusinessChartBuffer, AccountSchedulesChartSetup, 0);
        VerifyChart(AccountSchedulesChartSetup, BusinessChartBuffer, AccScheduleLine, ColumnLayout, StartDate, EndDate);

        SetupDrillDownData(AccountSchedulesChartSetup, AccScheduleLine, ColumnLayout, BusinessChartBuffer, TestDrillDownType);
        if TestDrillDownType = TestDrillDownType::RowFormula then
            LibraryVariableStorage.Enqueue(BusinessChartBuffer);
        DrillDownChart(BusinessChartBuffer, AccountSchedulesChartSetup);
    end;

    local procedure TestDrillDownWithAnalysisView(ShowPer: Option; PeriodLength: Option; NoOfPeriods: Integer; AnalysisViewType: Option GLAccount,CashFlow)
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        BalGLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        BusinessChartBuffer: Record "Business Chart Buffer";
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        AccountNo: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        SetupStartAndEndDates(StartDate, EndDate, ShowPer, PeriodLength, NoOfPeriods);

        SetupAccountScheduleWithAnalysisView2Cols(AccScheduleLine, ColumnLayout, AnalysisView, AccountNo, AnalysisViewType);

        SetupChartParam(AccountSchedulesChartSetup, AccScheduleLine, ColumnLayout, ShowPer, PeriodLength, StartDate, EndDate, NoOfPeriods);
        if AnalysisViewType = AnalysisViewType::GLAccount then begin
            LibraryERM.CreateGLAccount(BalGLAccount);
            SetupGLEntries(GLEntry, AccountNo, BalGLAccount."No.", StartDate, EndDate, PeriodLength);
        end else
            SetupCashFlowEntries(CashFlowForecastEntry, AccountNo, StartDate, EndDate, PeriodLength);

        SetupAnalysisViewEntries(AnalysisViewEntry, AnalysisView.Code, AccountNo, StartDate, EndDate, PeriodLength, AnalysisViewType);

        RunChart(BusinessChartBuffer, AccountSchedulesChartSetup, 0);
        VerifyChart(AccountSchedulesChartSetup, BusinessChartBuffer, AccScheduleLine, ColumnLayout, StartDate, EndDate);

        SetupDrillDownDataAnalysisView(
          AccountSchedulesChartSetup, AccScheduleLine, ColumnLayout, BusinessChartBuffer, AnalysisView.Code, AnalysisViewType);

        DrillDownChart(BusinessChartBuffer, AccountSchedulesChartSetup);
    end;

    local procedure RunChart(var BusinessChartBuffer: Record "Business Chart Buffer"; var AccountSchedulesChartSetup: Record "Account Schedules Chart Setup"; Period: Option)
    begin
        AccSchedChartManagement.UpdateData(BusinessChartBuffer, Period, AccountSchedulesChartSetup);
        AccSchedChartManagement.GetAccSchedMgtRef(AccSchedManagement);
    end;

    local procedure DrillDownChart(var BusinessChartBuffer: Record "Business Chart Buffer"; var AccountSchedulesChartSetup: Record "Account Schedules Chart Setup")
    begin
        AccSchedChartManagement.DrillDown(BusinessChartBuffer, AccountSchedulesChartSetup);
    end;

    local procedure VerifyChart(var AccountSchedulesChartSetup: Record "Account Schedules Chart Setup"; var BusinessChartBuffer: Record "Business Chart Buffer"; var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; StartDate: Date; EndDate: Date)
    var
        PeriodPageManagement: Codeunit PeriodPageManagement;
        ActualChartValue: Variant;
        PeriodStart: Date;
        PeriodEnd: Date;
        RowIndex: Integer;
        MeasureName: Text[111];
    begin
        case AccountSchedulesChartSetup."Base X-Axis on" of
            AccountSchedulesChartSetup."Base X-Axis on"::Period:
                begin
                    PeriodStart := StartDate;
                    PeriodEnd := CalculatePeriodEndDate(PeriodStart, AccountSchedulesChartSetup."Period Length");
                    RowIndex := 0;
                    repeat
                        Clear(ActualChartValue);
                        BusinessChartBuffer.GetValue(Format(BusinessChartBuffer."Period Length"), RowIndex, ActualChartValue);
                        if BusinessChartBuffer."Period Length" = BusinessChartBuffer."Period Length"::Day then
                            Assert.AreEqual(PeriodEnd, DT2Date(ActualChartValue), StrSubstNo(DimensionValueNotEqualERR, RowIndex + 1))
                        else
                            Assert.AreEqual(
                              PeriodPageManagement.CreatePeriodFormat("Analysis Period Type".FromInteger(BusinessChartBuffer."Period Length"), PeriodEnd), ActualChartValue,
                              StrSubstNo(DimensionValueNotEqualERR, RowIndex + 1));

                        AccScheduleLine.FindSet();
                        repeat
                            ColumnLayout.FindSet();
                            repeat
                                MeasureName := CopyStr(AccScheduleLine.Description + ' ' + ColumnLayout."Column Header", 1, MaxStrLen(MeasureName));
                                VerifyChartMeasure(
                                  BusinessChartBuffer, AccScheduleLine, ColumnLayout, MeasureName, Format(PeriodEnd), RowIndex, PeriodStart, PeriodEnd);
                            until ColumnLayout.Next() = 0;
                        until AccScheduleLine.Next() = 0;
                        PeriodStart := PeriodEnd + 1;
                        PeriodEnd :=
                          CalculatePeriodEndDate(
                            CalculateNextDate(PeriodEnd, 1, AccountSchedulesChartSetup."Period Length"),
                            AccountSchedulesChartSetup."Period Length");
                        RowIndex += 1;
                    until PeriodEnd >= EndDate;
                end;
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line":
                begin
                    AccScheduleLine.FindSet();
                    RowIndex := 0;
                    repeat
                        Clear(ActualChartValue);
                        BusinessChartBuffer.GetValue(AccScheduleLine.FieldCaption(Description), RowIndex, ActualChartValue);
                        Assert.AreEqual(AccScheduleLine.Description, ActualChartValue, StrSubstNo(DimensionValueNotEqualERR, RowIndex + 1));

                        ColumnLayout.FindSet();
                        repeat
                            VerifyChartMeasure(
                              BusinessChartBuffer, AccScheduleLine, ColumnLayout, ColumnLayout."Column Header", AccScheduleLine.Description, RowIndex,
                              StartDate, EndDate);
                        until ColumnLayout.Next() = 0;
                        RowIndex += 1;
                    until AccScheduleLine.Next() = 0;
                end;
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column":
                begin
                    ColumnLayout.FindSet();
                    RowIndex := 0;
                    repeat
                        Clear(ActualChartValue);
                        BusinessChartBuffer.GetValue(ColumnLayout.FieldCaption("Column Header"), RowIndex, ActualChartValue);
                        Assert.AreEqual(ColumnLayout."Column Header", ActualChartValue, StrSubstNo(DimensionValueNotEqualERR, RowIndex + 1));

                        AccScheduleLine.FindSet();
                        repeat
                            MeasureName := AccScheduleLine.Description;
                            VerifyChartMeasure(
                              BusinessChartBuffer, AccScheduleLine, ColumnLayout, MeasureName, ColumnLayout."Column Header", RowIndex, StartDate,
                              EndDate);
                        until AccScheduleLine.Next() = 0;
                        RowIndex += 1;
                    until ColumnLayout.Next() = 0;
                end;
        end;
    end;

    local procedure VerifyChartMeasure(var BusinessChartBuffer: Record "Business Chart Buffer"; var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; MeasureName: Text[111]; DimensionValue: Text[100]; RowIndex: Integer; PeriodStart: Date; PeriodEnd: Date)
    var
        CalcAccSchedLine: Record "Acc. Schedule Line";
        CalcColumnLayout: Record "Column Layout";
        RefAccSchedManagement: Codeunit AccSchedManagement;
        ActualChartValue: Variant;
    begin
        Clear(ActualChartValue);
        BusinessChartBuffer.GetValue(MeasureName, RowIndex, ActualChartValue);
        CalcAccSchedLine.SetRange("Date Filter", PeriodStart, PeriodEnd);
        CalcAccSchedLine.Get(AccScheduleLine."Schedule Name", AccScheduleLine."Line No.");
        CalcColumnLayout.Get(ColumnLayout."Column Layout Name", ColumnLayout."Line No.");
        Assert.AreEqual(RefAccSchedManagement.CalcCell(CalcAccSchedLine, CalcColumnLayout, false), ActualChartValue,
          StrSubstNo(AmountNotEqualERR, MeasureName, DimensionValue) + Format(RowIndex) + StrSubstNo('|%1..%2', PeriodStart, PeriodEnd));
    end;

    local procedure Verify_MyNotificationIsEnabledForRecord_OnlySingleHits()
    var
        CodeCoverage: Record "Code Coverage";
    begin
        FilterCodeCoverageForObject(
          CodeCoverage, CodeCoverage."Object Type"::Table, DATABASE::"My Notifications");
        CodeCoverage.SetRange("No. of Hits", 1);
        Assert.RecordIsNotEmpty(CodeCoverage);
        CodeCoverage.SetFilter("No. of Hits", '>%1', 1);
        Assert.RecordIsEmpty(CodeCoverage);
    end;

    local procedure SetupChart2Accounts2Cols(var AccountSchedulesChartSetup: Record "Account Schedules Chart Setup"; var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; ShowPer: Option; PeriodLength: Option; StartDate: Date; EndDate: Date; NoOfPeriods: Integer)
    var
        GLAccount: array[2] of Record "G/L Account";
        BalGLAccount: Record "G/L Account";
        GLEntry: array[2] of Record "G/L Entry";
    begin
        SetupAccountSchedule2Accounts2Cols(AccScheduleLine, ColumnLayout, GLAccount);
        LibraryERM.CreateGLAccount(BalGLAccount);
        SetupChartParam(AccountSchedulesChartSetup, AccScheduleLine, ColumnLayout, ShowPer, PeriodLength, StartDate, EndDate, NoOfPeriods);
        SetupGLEntries(GLEntry[1], GLAccount[1]."No.", BalGLAccount."No.", StartDate, EndDate, PeriodLength);
        SetupGLEntries(GLEntry[2], GLAccount[2]."No.", BalGLAccount."No.", StartDate, EndDate, PeriodLength);
    end;

    [Normal]
    local procedure SetupAccountSchedule2Accounts2Cols(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; var GLAccount: array[2] of Record "G/L Account")
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        LibraryERM.CreateGLAccount(GLAccount[1]);
        LibraryERM.CreateGLAccount(GLAccount[2]);
        CreateColumnLayoutWithNameAndDesc(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLine(
          AccScheduleLine, AccScheduleName.Name, GLAccount[1]."No.", AccScheduleLine."Totaling Type"::"Posting Accounts");
        CreateAccScheduleLine(
          AccScheduleLine, AccScheduleName.Name, GLAccount[2]."No.", AccScheduleLine."Totaling Type"::"Posting Accounts");

        AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.FindFirst();
    end;

    [Normal]
    local procedure SetupAccountScheduleCFandTotAccounts2Cols(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; var GLAccount: Record "G/L Account"; var CostType: Record "Cost Type"; var CashFlowAccount: Record "Cash Flow Account")
    var
        AccScheduleName: Record "Acc. Schedule Name";
        TotalingFormula: Text[250];
    begin
        LibraryCostAcc.CreateCostType(CostType);
        LibraryCashFlow.CreateCashFlowAccount(CashFlowAccount, CashFlowAccount."Account Type"::Entry);
        GLAccount.Get(CostType."G/L Account Range");

        CreateColumnLayoutWithNameAndDesc(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name, GLAccount."No.", AccScheduleLine."Totaling Type"::"Posting Accounts");
        TotalingFormula := AccScheduleLine."Row No.";
        CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name, CostType."No.", AccScheduleLine."Totaling Type"::"Cost Type");
        TotalingFormula += '|' + AccScheduleLine."Row No.";
        CreateAccScheduleLine(
          AccScheduleLine, AccScheduleName.Name, CashFlowAccount."No.", AccScheduleLine."Totaling Type"::"Cash Flow Entry Accounts");
        TotalingFormula += '|' + AccScheduleLine."Row No.";
        CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name, TotalingFormula, AccScheduleLine."Totaling Type"::Formula);

        AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.FindFirst();
    end;

    local procedure SetupAccountScheduleWithAnalysisView2Cols(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; var AnalysisView: Record "Analysis View"; var AccountNo: Code[20]; AnalysisViewType: Option GLAccount,CashFlow)
    var
        AccScheduleName: Record "Acc. Schedule Name";
        GLAccount: Record "G/L Account";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        LibraryERM.CreateAnalysisView(AnalysisView);
        if AnalysisViewType = AnalysisViewType::GLAccount then begin
            LibraryERM.CreateGLAccount(GLAccount);
            AnalysisView."Account Source" := AnalysisView."Account Source"::"G/L Account";
            AnalysisView."Account Filter" := GLAccount."No.";
            AccountNo := GLAccount."No.";
        end else begin
            LibraryCashFlow.CreateCashFlowAccount(CashFlowAccount, CashFlowAccount."Account Type"::Entry);
            AnalysisView."Account Source" := AnalysisView."Account Source"::"Cash Flow Account";
            AnalysisView."Account Filter" := CashFlowAccount."No.";
            AccountNo := CashFlowAccount."No.";
        end;
        AnalysisView.Modify();

        CreateColumnLayoutWithNameAndDesc(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        AccScheduleName."Analysis View Name" := CopyStr(AnalysisView.Name, 1, 10);
        AccScheduleName.Modify();

        if AnalysisViewType = AnalysisViewType::GLAccount then
            CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name, AccountNo, AccScheduleLine."Totaling Type"::"Posting Accounts")
        else
            CreateAccScheduleLine(
              AccScheduleLine, AccScheduleName.Name, AccountNo, AccScheduleLine."Totaling Type"::"Cash Flow Entry Accounts");

        AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.FindFirst();
    end;

    local procedure CreateColumnLayoutWithNameAndDesc(var ColumnLayout: Record "Column Layout")
    var
        ColumnLayoutName: Record "Column Layout Name";
        OldColumnNo: Code[10];
    begin
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        ColumnLayoutName.Validate(Description,
          CopyStr(
            LibraryUtility.GenerateRandomCode(ColumnLayoutName.FieldNo(Description), DATABASE::"Column Layout Name"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Column Layout Name", ColumnLayoutName.FieldNo(Description))));
        ColumnLayoutName.Modify(true);
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
        ColumnLayout.Validate("Column No.", Format(LibraryRandom.RandInt(10)));
        // Select any column type other than Formula
        ColumnLayout.Validate("Column Type", LibraryRandom.RandIntInRange(1, 6));
        ColumnLayout.Validate("Column Header",
          CopyStr(
            LibraryUtility.GenerateRandomCode(ColumnLayout.FieldNo("Column Header"), DATABASE::"Column Layout"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Column Layout", ColumnLayout.FieldNo("Column Header"))));
        ColumnLayout.Modify(true);
        OldColumnNo := ColumnLayout."Column No.";

        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
        ColumnLayout.Validate("Column No.", Format(LibraryRandom.RandInt(10)));
        ColumnLayout.Validate("Column Type", ColumnLayout."Column Type"::Formula);
        ColumnLayout.Validate(Formula, '-' + OldColumnNo);
        ColumnLayout.Validate("Column Header",
          CopyStr(
            LibraryUtility.GenerateRandomCode(ColumnLayout.FieldNo("Column Header"), DATABASE::"Column Layout"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Column Layout", ColumnLayout.FieldNo("Column Header"))));
        ColumnLayout.Modify(true);

        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName.Name);
        ColumnLayout.FindFirst();
    end;

    local procedure CreateAccScheduleLine(var AccScheduleLine: Record "Acc. Schedule Line"; AccScheduleName: Code[10]; Totaling: Text[250]; TotalingType: Enum "Acc. Schedule Line Totaling Type")
    begin
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName);
        AccScheduleLine.Validate("Row No.", Format(LibraryRandom.RandInt(100)));
        AccScheduleLine.Validate(
          Description, CopyStr(LibraryUtility.GenerateRandomCode(AccScheduleLine.FieldNo(Description), DATABASE::"Acc. Schedule Line"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Acc. Schedule Line", AccScheduleLine.FieldNo(Description))));
        AccScheduleLine.Validate("Totaling Type", TotalingType);
        AccScheduleLine.Validate(Totaling, Totaling);
        AccScheduleLine.Modify(true);
    end;

    local procedure CalculateNextDate(StartDate: Date; NoOfPeriods: Integer; PeriodLength: Option Day,Week,Month,Quarter,Year): Date
    begin
        exit(CalcDate(StrSubstNo('<%1%2>', NoOfPeriods, GetPeriodString(PeriodLength)), StartDate));
    end;

    local procedure CalculatePeriodStartDate(PeriodDate: Date; PeriodLength: Option Day,Week,Month,Quarter,Year): Date
    begin
        case PeriodLength of
            PeriodLength::Day:
                exit(PeriodDate);
            PeriodLength::Week,
          PeriodLength::Month,
          PeriodLength::Quarter,
          PeriodLength::Year:
                exit(CalcDate(StrSubstNo('<-C%1>', GetPeriodString(PeriodLength)), PeriodDate));
        end;
    end;

    local procedure CalculatePeriodEndDate(PeriodDate: Date; PeriodLength: Option Day,Week,Month,Quarter,Year): Date
    begin
        case PeriodLength of
            PeriodLength::Day:
                exit(PeriodDate);
            PeriodLength::Week,
          PeriodLength::Month,
          PeriodLength::Quarter,
          PeriodLength::Year:
                exit(CalcDate(StrSubstNo('<C%1>', GetPeriodString(PeriodLength)), PeriodDate));
        end;
    end;

    local procedure ShiftPeriod(var StartDate: Date; var EndDate: Date; PeriodToCheck: Option " ",Next,Previous; PeriodLength: Option Day,Week,Month,Quarter,Year; ShowPer: Option Period,"Acc. Sched. Line","Acc. Sched. Column")
    var
        PeriodIncrement: Integer;
    begin
        if PeriodToCheck = PeriodToCheck::" " then
            exit;

        if PeriodToCheck = PeriodToCheck::Next then
            PeriodIncrement := 1
        else
            PeriodIncrement := -1;

        if ShowPer = ShowPer::Period then
            StartDate := CalculatePeriodStartDate(CalculateNextDate(StartDate, PeriodIncrement, PeriodLength), PeriodLength)
        else
            StartDate := CalculatePeriodStartDate(CalculateNextDate(EndDate, PeriodIncrement, PeriodLength), PeriodLength);
        EndDate := CalculatePeriodEndDate(CalculateNextDate(EndDate, PeriodIncrement, PeriodLength), PeriodLength);
    end;

    local procedure GetPeriodString(PeriodLength: Option Day,Week,Month,Quarter,Year): Text[1]
    begin
        case PeriodLength of
            PeriodLength::Day:
                exit('D');
            PeriodLength::Week:
                exit('W');
            PeriodLength::Month:
                exit('M');
            PeriodLength::Quarter:
                exit('Q');
            PeriodLength::Year:
                exit('Y');
        end;
    end;

    local procedure FilterCodeCoverageForObject(var CodeCoverage: Record "Code Coverage"; ObjectType: Option; ObjectID: Integer)
    begin
        CodeCoverageMgt.Refresh();
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Code);
        CodeCoverage.SetRange("Object Type", ObjectType);
        CodeCoverage.SetRange("Object ID", ObjectID);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Message: Text[1024])
    begin
        if StrPos(Message, CostAccUpdateMSG) > 0 then
            exit;

        if DrillDownColumnLayout."Column Type" = DrillDownColumnLayout."Column Type"::Formula then
            Assert.AreEqual(
              StrSubstNo(ColFormulaMSG, DrillDownColumnLayout.Formula), Message,
              StrSubstNo(FormulaDrillDownERR, DrillDownColumnLayout.TableCaption()))
        else
            if DrillDownAccScheduleLine."Totaling Type" = DrillDownAccScheduleLine."Totaling Type"::Formula then
                Assert.AreEqual(
                  StrSubstNo(RowFormulaMSG, DrillDownAccScheduleLine.Totaling), Message,
                  StrSubstNo(FormulaDrillDownERR, DrillDownAccScheduleLine.TableCaption()));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLChartofAccountsHandler(var ChartOfAccountsPage: TestPage "Chart of Accounts (G/L)")
    var
        PageNetChangeValue: Decimal;
    begin
        DrillDownGLAccount.FindFirst();
        DrillDownGLAccount.CalcFields("Net Change");
        if ChartOfAccountsPage."Net Change".Value <> '' then
            Evaluate(PageNetChangeValue, ChartOfAccountsPage."Net Change".Value);
        Assert.AreEqual(DrillDownGLAccount."Net Change", PageNetChangeValue,
          CopyStr(
            StrSubstNo(
              DrillDownValERR, DrillDownAccScheduleLine.Description, DrillDownColumnLayout."Column Header",
              DrillDownAccScheduleLine.GetFilter("Date Filter")), 1, 250));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ChartofCostTypeHandler(var ChartofCostTypePage: TestPage "Chart of Cost Types")
    var
        PageNetChangeValue: Decimal;
    begin
        DrillDownCostType.FindFirst();
        DrillDownCostType.CalcFields("Net Change");
        if ChartofCostTypePage."Net Change".Value <> '' then
            Evaluate(PageNetChangeValue, ChartofCostTypePage."Net Change".Value);
        Assert.AreEqual(DrillDownCostType."Net Change", PageNetChangeValue,
          CopyStr(
            StrSubstNo(
              DrillDownValERR, DrillDownAccScheduleLine.Description, DrillDownColumnLayout."Column Header",
              DrillDownAccScheduleLine.GetFilter("Date Filter")), 1, 250));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ChartofCashFlowHandler(var ChartofCashFlowAccPage: TestPage "Chart of Cash Flow Accounts")
    var
        PageAmountValue: Decimal;
    begin
        DrillDownCFAccount.FindFirst();
        DrillDownCFAccount.CalcFields(Amount);
        if ChartofCashFlowAccPage.Amount.Value <> '' then
            Evaluate(PageAmountValue, ChartofCashFlowAccPage.Amount.Value);
        Assert.AreEqual(DrillDownCFAccount.Amount, PageAmountValue,
          CopyStr(
            StrSubstNo(
              DrillDownValERR, DrillDownAccScheduleLine.Description, DrillDownColumnLayout."Column Header",
              DrillDownAccScheduleLine.GetFilter("Date Filter")), 1, 250));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ChartofAccAnalysisViewHandler(var ChartofAccAnalysisViewPage: TestPage "Chart of Accs. (Analysis View)")
    var
        PageNetChangeValue: Decimal;
    begin
        DrillDownAnalysisViewEntry.CalcSums(DrillDownAnalysisViewEntry.Amount);
        if ChartofAccAnalysisViewPage."Net Change".Value <> '' then
            Evaluate(PageNetChangeValue, ChartofAccAnalysisViewPage."Net Change".Value);
        Assert.AreEqual(DrillDownAnalysisViewEntry.Amount, PageNetChangeValue,
          CopyStr(
            StrSubstNo(
              DrillDownValERR, DrillDownAccScheduleLine.Description, DrillDownColumnLayout."Column Header",
              DrillDownAccScheduleLine.GetFilter("Date Filter")), 1, 250));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AnalysisViewBudgetEntriesPageHandler(var AnalysisViewBudgetEntries: TestPage "Analysis View Budget Entries")
    var
        AnalysisViewCode: Variant;
        GLAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(AnalysisViewCode);
        LibraryVariableStorage.Dequeue(GLAccountNo);
        AnalysisViewBudgetEntries.FILTER.SetFilter("G/L Account No.", GLAccountNo);
        AnalysisViewBudgetEntries."Analysis View Code".AssertEquals(AnalysisViewCode);
        AnalysisViewBudgetEntries.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        BusinessChartBufferVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(BusinessChartBufferVar);
        BusinessChartBuffer := BusinessChartBufferVar;
        Assert.AreEqual(
          DrillDownAccScheduleLine."Schedule Name",
          AccScheduleOverview.CurrentSchedName.Value,
          'Unexpected account schedule in the overview page.');
        Assert.AreEqual(
          DrillDownAccScheduleLine."Row No.",
          AccScheduleOverview."Row No.".Value,
          'Unexpected account schedule line selected in the overview page.');
        Assert.AreEqual(
          BusinessChartBuffer."Period Length",
          AccScheduleOverview.PeriodTypeDefault.AsInteger(),
          'Unexpected account schedule period selected in the overview page.');

        AccScheduleOverview.Close();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure SelectExistingCustVendStrMenuHandler(Options: Text; var Choice: Integer; Instructions: Text)
    begin
        Choice := 2; // Select existing customer
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerListModalPageHandler(var CustomerList: TestPage "Customer List")
    begin
        CustomerList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorModalPageHandler(var VendorList: TestPage "Vendor List")
    begin
        VendorList.OK().Invoke();
    end;
}

