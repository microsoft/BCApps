codeunit 138029 "O365 Trial Balance"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Trial Balance] [SMB]
        isInitialized := false;
    end;

    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ExpectedAmount: Decimal;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestTrialBalanceIsCachedWhenTrialBalancePageIsOpened()
    var
        TrialBalanceCacheInfo: Record "Trial Balance Cache Info";
        TrialBalanceCache: Record "Trial Balance Cache";
        TrialBalanceMgt: Codeunit "Trial Balance Mgt.";
        TrialBalanceCacheMgt: Codeunit "Trial Balance Cache Mgt.";
        TrialBalance: TestPage "Trial Balance";
        Descriptions: array[9] of Text[80];
        Values: array[9, 2] of Decimal;
        PeriodCaptionTxt: array[2] of Text;
        I: Integer;
    begin
        // [SCENARIO] Trial Balance handles lack of accounting periods gracefully.
        Initialize();

        // [GIVEN] No Accounting periods
        TrialBalanceCacheInfo.DeleteAll();
        TrialBalanceCache.DeleteAll();

        // [WHEN] Opening the Trial Balance page
        TrialBalanceMgt.LoadData(Descriptions, Values, PeriodCaptionTxt, 2);
        TrialBalanceCacheMgt.SaveToCache(Descriptions, Values, PeriodCaptionTxt);
        TrialBalance.OpenEdit();

        // [THEN] the Trial Balance opens with no errors and shows a single column
        Assert.IsFalse(TrialBalanceCacheInfo.IsEmpty, 'Trial Balance Info record is not added.');
        Assert.IsFalse(TrialBalanceCache.IsEmpty, 'Trial Balance Info record is not added.');
        TrialBalanceMgt.LoadData(Descriptions, Values, PeriodCaptionTxt, 2);
        TrialBalanceCache.FindSet();
        I := 1;
        repeat
            Assert.AreEqual(Descriptions[I], TrialBalanceCache.Description, 'Description is not set correctly.');
            Assert.AreEqual(Values[I, 1], TrialBalanceCache."Period 1 Amount", 'Period 1 amount is not set correctly.');
            Assert.AreEqual(Values[I, 2], TrialBalanceCache."Period 2 Amount", 'Period 2 amount is not set correctly.');
            if I = 1 then begin
                Assert.AreEqual(PeriodCaptionTxt[1], TrialBalanceCache."Period 1 Caption", 'Period 1 caption is not set correctly.');
                Assert.AreEqual(PeriodCaptionTxt[2], TrialBalanceCache."Period 2 Caption", 'Period 2 caption is not set correctly.');
            end;
            I := I + 1;
        until TrialBalanceCache.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTrialBalanceMatchesAccSchedOverview()
    var
        TrialBalanceMgt: Codeunit "Trial Balance Mgt.";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        Descriptions: array[9] of Text[80];
        Values: array[9, 2] of Decimal;
        PeriodCaptionTxt: array[2] of Text;
    begin
        Initialize();
        OpenAccSchedOverviewPage(AccScheduleOverview);

        TrialBalanceMgt.LoadData(Descriptions, Values, PeriodCaptionTxt, 2);
        CompareResults(AccScheduleOverview, Values);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreviousNext()
    var
        TrialBalanceMgt: Codeunit "Trial Balance Mgt.";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        Descriptions: array[9] of Text[80];
        Values: array[9, 2] of Decimal;
        PeriodCaptionTxt: array[2] of Text;
        I: Integer;
        NoOfColumns: Integer;
    begin
        Initialize();
        OpenAccSchedOverviewPage(AccScheduleOverview);
        TrialBalanceMgt.LoadData(Descriptions, Values, PeriodCaptionTxt, 2);

        NoOfColumns := 2;
        for I := 1 to 2 do begin
            AccScheduleOverview.PreviousPeriod.Invoke();
            TrialBalanceMgt.PreviousPeriod(Descriptions, Values, PeriodCaptionTxt, NoOfColumns);
            CompareResults(AccScheduleOverview, Values);
        end;

        for I := 1 to 2 do begin
            AccScheduleOverview.NextPeriod.Invoke();
            TrialBalanceMgt.NextPeriod(Descriptions, Values, PeriodCaptionTxt, NoOfColumns);
            CompareResults(AccScheduleOverview, Values);
        end;
    end;

    [Test]
    [HandlerFunctions('CheckAmountOnGLAccountHandler')]
    [Scope('OnPrem')]
    procedure TestDrillDownOnGLAccounts()
    var
        TrialBalanceMgt: Codeunit "Trial Balance Mgt.";
        TrialBalanceCacheMgt: Codeunit "Trial Balance Cache Mgt.";
        TrialBalance: TestPage "Trial Balance";
        Descriptions: array[9] of Text[80];
        Values: array[9, 2] of Decimal;
        PeriodCaptionTxt: array[2] of Text;
    begin
        Initialize();
        TrialBalanceMgt.LoadData(Descriptions, Values, PeriodCaptionTxt, 2);
        TrialBalanceCacheMgt.SaveToCache(Descriptions, Values, PeriodCaptionTxt);
        TrialBalance.OpenEdit();

        // Test drill down on GL Accounts
        // Row 1
        ExpectedAmount := -TrialBalance.CurrentPeriodValues1.AsDecimal();
        TrialBalance.CurrentPeriodValues1.DrillDown();

        ExpectedAmount := -TrialBalance.CurrentPeriodMinusOneValues1.AsDecimal();
        TrialBalance.CurrentPeriodMinusOneValues1.DrillDown();

        // Row 2
        ExpectedAmount := -TrialBalance.CurrentPeriodValues2.AsDecimal();
        TrialBalance.CurrentPeriodValues2.DrillDown();

        ExpectedAmount := -TrialBalance.CurrentPeriodMinusOneValues2.AsDecimal();
        TrialBalance.CurrentPeriodMinusOneValues2.DrillDown();

        // Row 5
        ExpectedAmount := TrialBalance.CurrentPeriodValues5.AsDecimal();
        TrialBalance.CurrentPeriodValues5.DrillDown();

        ExpectedAmount := TrialBalance.CurrentPeriodMinusOneValues5.AsDecimal();
        TrialBalance.CurrentPeriodMinusOneValues5.DrillDown();

        // Row 8
        ExpectedAmount := TrialBalance.CurrentPeriodValues8.AsDecimal();
        TrialBalance.CurrentPeriodValues8.DrillDown();

        ExpectedAmount := TrialBalance.CurrentPeriodMinusOneValues8.AsDecimal();
        TrialBalance.CurrentPeriodMinusOneValues8.DrillDown();
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewHandler')]
    [Scope('OnPrem')]
    procedure TestDrillDownOnFormulas()
    var
        TrialBalanceMgt: Codeunit "Trial Balance Mgt.";
        TrialBalanceCacheMgt: Codeunit "Trial Balance Cache Mgt.";
        TrialBalance: TestPage "Trial Balance";
        Descriptions: array[9] of Text[80];
        Values: array[9, 2] of Decimal;
        PeriodCaptionTxt: array[2] of Text;
    begin
        Initialize();
        TrialBalanceMgt.LoadData(Descriptions, Values, PeriodCaptionTxt, 2);
        TrialBalanceCacheMgt.SaveToCache(Descriptions, Values, PeriodCaptionTxt);
        TrialBalance.OpenEdit();

        // Test drill down on Formulas
        LibraryVariableStorage.Enqueue(30);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodValues3.AsDecimal());
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodMinusOneValues3.AsDecimal());
        TrialBalance.CurrentPeriodValues3.DrillDown();
        LibraryVariableStorage.Enqueue(30);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodValues3.AsDecimal());
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodMinusOneValues3.AsDecimal());
        TrialBalance.CurrentPeriodMinusOneValues3.DrillDown();

        LibraryVariableStorage.Enqueue(40);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodValues4.AsDecimal());
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodMinusOneValues4.AsDecimal());
        TrialBalance.CurrentPeriodValues4.DrillDown();
        LibraryVariableStorage.Enqueue(40);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodValues4.AsDecimal());
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodMinusOneValues4.AsDecimal());
        TrialBalance.CurrentPeriodMinusOneValues4.DrillDown();

        LibraryVariableStorage.Enqueue(60);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodValues6.AsDecimal());
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodMinusOneValues6.AsDecimal());
        TrialBalance.CurrentPeriodValues6.DrillDown();
        LibraryVariableStorage.Enqueue(60);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodValues6.AsDecimal());
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodMinusOneValues6.AsDecimal());
        TrialBalance.CurrentPeriodMinusOneValues6.DrillDown();

        LibraryVariableStorage.Enqueue(70);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodValues7.AsDecimal());
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodMinusOneValues7.AsDecimal());
        TrialBalance.CurrentPeriodValues7.DrillDown();
        LibraryVariableStorage.Enqueue(70);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodValues7.AsDecimal());
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodMinusOneValues7.AsDecimal());
        TrialBalance.CurrentPeriodMinusOneValues7.DrillDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoErrorsOnEmptyAccountingPeriod()
    var
        AccountingPeriod: Record "Accounting Period";
        TrialBalanceMgt: Codeunit "Trial Balance Mgt.";
        TrialBalanceCacheMgt: Codeunit "Trial Balance Cache Mgt.";
        TrialBalance: TestPage "Trial Balance";
        Descriptions: array[9] of Text[80];
        Values: array[9, 2] of Decimal;
        PeriodCaptionTxt: array[2] of Text;
    begin
        // [SCENARIO] Trial Balance handles lack of accounting periods gracefully.
        Initialize();

        // [GIVEN] No Accounting periods
        TrialBalanceMgt.LoadData(Descriptions, Values, PeriodCaptionTxt, 2);
        TrialBalanceCacheMgt.SaveToCache(Descriptions, Values, PeriodCaptionTxt);
        AccountingPeriod.DeleteAll();

        // [WHEN] Opening the Trial Balance page
        TrialBalance.OpenEdit();

        // [THEN] the Trial Balance opens with no errors and shows a single column
        Assert.IsTrue(TrialBalance.CurrentPeriodValues1.Visible(), 'Current period should be visible');
        Assert.IsFalse(TrialBalance.CurrentPeriodMinusOneValues1.Visible(), 'Current period minus one should not be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleColumnHeaderPartOfColumnHeadersInTrialBalance()
    var
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: array[2] of Record "Column Layout";
        TrialBalanceCache: Record "Trial Balance Cache";
        TrialBalanceSetup: Record "Trial Balance Setup";
        TrialBalanceMgt: Codeunit "Trial Balance Mgt.";
        Index: Integer;
        DescriptionsArr: array[9] of Text[100];
        ValuesArr: array[9, 2] of Decimal;
        PeriodCaptionTxt: array[2] of Text;
    begin
        // [FEATURE] [Account Schedule]
        // [SCENARIO 391104] In the Mini Trial Balance the column header is a part to the period filter
        Initialize();

        TrialBalanceCache.DeleteAll();

        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        for Index := 1 to ArrayLen(ColumnLayout) do begin
            LibraryERM.CreateColumnLayout(ColumnLayout[Index], ColumnLayoutName.Name);
            ColumnLayout[Index].Validate("Column Header", LibraryUtility.GenerateGUID());
            ColumnLayout[Index].Modify(true);
        end;

        TrialBalanceSetup.Get();
        TrialBalanceSetup.Validate("Column Layout Name", ColumnLayoutName.Name);
        TrialBalanceSetup.Modify(true);

        TrialBalanceMgt.LoadData(DescriptionsArr, ValuesArr, PeriodCaptionTxt, 2);

        for Index := ArrayLen(ColumnLayout) downto 1 do
            Assert.ExpectedMessage(ColumnLayout[Index]."Column Header", PeriodCaptionTxt[3 - Index]);
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Trial Balance");
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Trial Balance");

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        FinancialReportMgt.Initialize();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Trial Balance");
    end;

    local procedure OpenAccSchedOverviewPage(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        TrialBalanceSetup: Record "Trial Balance Setup";
        FinancialReports: TestPage "Financial Reports";
        TrialAccSchedName: Code[10];
    begin
        TrialBalanceSetup.Get();
        TrialAccSchedName := TrialBalanceSetup."Account Schedule Name";

        FinancialReports.OpenView();
        FinancialReports.Filter.SetFilter(Name, TrialAccSchedName);
        AccScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();

        AccScheduleOverview.PeriodTypeDefault.SetValue(PeriodType::"Accounting Period");
    end;

    local procedure CompareResults(AccScheduleOverview: TestPage "Acc. Schedule Overview"; Values: array[9, 2] of Decimal)
    var
        I: Integer;
    begin
        I := 1;
        AccScheduleOverview.First();
        repeat
            Assert.AreEqual(AccScheduleOverview.ColumnValues1.AsDecimal(), Round(Values[I, 2]), 'Data in column 1 does not match');
            Assert.AreEqual(AccScheduleOverview.ColumnValues2.AsDecimal(), Round(Values[I, 1]), 'Data in column 2 does not match');
            I := I + 1;
        until not AccScheduleOverview.Next();
    end;

    [PageHandler]
    [HandlerFunctions('CheckAmountOnGLAccountHandler')]
    [Scope('OnPrem')]
    procedure CheckAmountOnGLAccountHandler(var ChartofAccountsGL: TestPage "Chart of Accounts (G/L)")
    var
        ActualAmount: Decimal;
    begin
        ActualAmount := 0;
        ChartofAccountsGL.First();
        repeat
            ActualAmount := ActualAmount + ChartofAccountsGL."Net Change".AsDecimal();
        until not ChartofAccountsGL.Next();

        Assert.AreEqual(ExpectedAmount, ActualAmount, 'Wrong amount on GL page');
        ChartofAccountsGL.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        RowNo: Variant;
        Amount1: Variant;
        Amount2: Variant;
    begin
        LibraryVariableStorage.Dequeue(RowNo);
        LibraryVariableStorage.Dequeue(Amount2);
        LibraryVariableStorage.Dequeue(Amount1);
        Assert.AreEqual(
          RowNo,
          AccScheduleOverview."Row No.".AsInteger(),
          'Unexpected account schedule line selected in the overview page.');
        Assert.AreEqual(
          Round(Amount1),
          AccScheduleOverview.ColumnValues1.AsDecimal(),
          'Unexpected amount shown in account schedule overview page.');
        Assert.AreEqual(
          Round(Amount2),
          AccScheduleOverview.ColumnValues2.AsDecimal(),
          'Unexpected amount shown in account schedule overview page.');

        AccScheduleOverview.Close();
    end;
}

