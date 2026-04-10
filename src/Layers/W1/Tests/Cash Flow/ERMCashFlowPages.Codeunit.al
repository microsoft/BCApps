codeunit 134558 "ERM Cash Flow Pages"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cash Flow] [UI]
        isInitialized := false;
    end;

    var
        CashFlowAccount: Record "Cash Flow Account";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryCashFlowForecast: Codeunit "Library - Cash Flow";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryCashFlowHelper: Codeunit "Library - Cash Flow Helper";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryService: Codeunit "Library - Service";
        isInitialized: Boolean;
        DimensionValueCode: Code[20];
        SourceDocumentNo: Code[20];
        UnexpectedChartCFNoTxt: Label 'Unexpected Chart on Role Center CF No. in CF Setup.';
        CashFlowSetupReply: Boolean;
        CashFlowForeCastErrorTxt: Label 'You must choose a cash flow forecast.';

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowShowOnRoleCenter()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        CashFlowNo: Code[20];
    begin
        Initialize();

        // Deselect the shown cash flow card
        CashFlowSetup.Get();
        CashFlowSetup.Validate("CF No. on Chart in Role Center", '');
        CashFlowSetup.Modify(true);
        VerifyCashFlowOnRoleCenter('');

        // Create a new CF card
        CashFlowCard.OpenNew();
        CashFlowCard.Description.Activate(); // Will auto-fill "No."
        CashFlowNo := CashFlowCard."No.".Value();

        // Set it as the active card from the card page
        CashFlowCard.ShowInChart.SetValue(true);
        VerifyCashFlowOnRoleCenter(CashFlowNo);

        // Deselect it
        CashFlowCard.ShowInChart.SetValue(false);
        VerifyCashFlowOnRoleCenter('');

        CashFlowCard.Close();

        // Select the card for RoleCenter then delete it
        CashFlowSetup.Get();
        CashFlowSetup.Validate("CF No. on Chart in Role Center", CashFlowNo);
        CashFlowSetup.Modify(true);

        CashFlowForecast.Get(CashFlowNo);
        CashFlowForecast.Delete(true);
        VerifyCashFlowOnRoleCenter('');
    end;

    [Test]
    [HandlerFunctions('CashFlowSetupConfirmHandler')]
    [Scope('OnPrem')]
    procedure CashFlowChangeOnRoleCenter()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowForecast2: Record "Cash Flow Forecast";
    begin
        Initialize();

        // Deselect the shown cash flow card
        CashFlowSetup.Get();
        CashFlowSetup.Validate("CF No. on Chart in Role Center", '');
        CashFlowSetup.Modify(true);

        // Create two CF cards
        LibraryCashFlowForecast.CreateCashFlowCard(CashFlowForecast);
        LibraryCashFlowForecast.CreateCashFlowCard(CashFlowForecast2);

        // Set the first card to show on RC chart
        CashFlowSetup.Validate("CF No. on Chart in Role Center", CashFlowForecast."No.");
        CashFlowSetup.Modify(true);

        // Expect a confirmation dialog answer No
        CashFlowSetupReply := false;

        CashFlowSetup.Validate("CF No. on Chart in Role Center", CashFlowForecast2."No.");
        CashFlowSetup.Modify(true);

        VerifyCashFlowOnRoleCenter(CashFlowForecast."No.");

        // Expect a confirmation dialog answer No
        CashFlowSetupReply := true;

        CashFlowSetup.Validate("CF No. on Chart in Role Center", CashFlowForecast2."No.");
        CashFlowSetup.Modify(true);

        VerifyCashFlowOnRoleCenter(CashFlowForecast2."No.");
    end;

    [Test]
    [HandlerFunctions('CashFlowWorksheetPageHandler')]
    [Scope('OnPrem')]
    procedure OpenWorksheetActionOnCashFlowCard()
    var
        CashFlowForcastCard: TestPage "Cash Flow Forecast Card";
    begin
        CashFlowForcastCard.OpenNew();
        CashFlowForcastCard.CashFlowWorksheet.Invoke();
        // Verification by handler CashFlowWorksheetPageHandler catching opened worksheet page
        Assert.IsTrue(CashFlowForcastCard.CashFlowWorksheet.Visible(), 'Expected visible action');
        Assert.IsTrue(CashFlowForcastCard.CashFlowWorksheet.Enabled(), 'Expected enabled action');
        CashFlowForcastCard.Close();
    end;

    [Test]
    [HandlerFunctions('CashFlowWorksheetPageHandler')]
    [Scope('OnPrem')]
    procedure OpenWorksheetActionOnCashFlowList()
    var
        CashFlowForcastList: TestPage "Cash Flow Forecast List";
    begin
        CashFlowForcastList.OpenView();
        CashFlowForcastList.CashFlowWorksheet.Invoke();
        // Verification by handler CashFlowWorksheetPageHandler catching opened worksheet page
        Assert.IsTrue(CashFlowForcastList.CashFlowWorksheet.Visible(), 'Expected visible action');
        Assert.IsTrue(CashFlowForcastList.CashFlowWorksheet.Enabled(), 'Expected enabled action');
        CashFlowForcastList.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CashFlowWorksheetPageHandler(var CashFlowWorksheet: TestPage "Cash Flow Worksheet")
    begin
        CashFlowWorksheet.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('CashFlowAccountListPageHandler')]
    [Scope('OnPrem')]
    procedure CashFlowAccounts()
    var
        CashFlowAccount2: Record "Cash Flow Account";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        ChartofCashFlowAccounts: TestPage "Chart of Cash Flow Accounts";
        ExpectedFilter: Text;
    begin
        Initialize();

        // Open chart of accounts in edit mode
        // create a new set of accounts begin-total posting end-total
        // use lookup on totalling from chart of accounts to trigger CFAccList.GetSelectionFilter code
        // select posting account
        // verify that the filter is constructed correctly

        CreateCashFlowAccount(CashFlowAccount, CashFlowAccount."Account Type"::"Begin-Total");
        CreateCashFlowAccount(CashFlowAccount, CashFlowAccount."Account Type"::Entry);
        CreateCashFlowAccount(CashFlowAccount2, CashFlowAccount2."Account Type"::"End-Total");

        ExpectedFilter := SelectionFilterManagement.AddQuotes(CashFlowAccount."No.");

        ChartofCashFlowAccounts.OpenEdit();
        ChartofCashFlowAccounts.GotoRecord(CashFlowAccount2);
        ChartofCashFlowAccounts.Totaling.Lookup();

        Assert.AreEqual(ExpectedFilter, ChartofCashFlowAccounts.Totaling.Value, 'Incorrect totalling filter generated');

        ChartofCashFlowAccounts.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CashFlowJournalScenario()
    var
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
        GLAccount: Record "G/L Account";
        CashFlowAccount: Record "Cash Flow Account";
        CashFlowList: TestPage "Cash Flow Forecast List";
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
        CashFlowLedgerEntries: TestPage "Cash Flow Forecast Entries";
        CashFlowNo: Code[20];
        Amount: Decimal;
    begin
        Initialize();

        // Scenario:
        // * Create a new CF card (fill in fields accordingly)
        // * Open list of CF cards and verify the card exists
        // * Open CF journal and fill + post
        // * Open CF card
        // * Open CF ledger entries and verify the entry

        // Create a new cash flow card
        CashFlowCard.OpenNew();
        CashFlowCard.Description.Activate(); // Will auto-fill "No."
        CashFlowNo := CashFlowCard."No.".Value();
        CashFlowCard.Close();

        // Check that the new card is found in the list
        CashFlowList.OpenView();
        Assert.IsTrue(CashFlowList.GotoKey(CashFlowNo), 'Cash flow card: ' + CashFlowNo + ' was not found in list');
        CashFlowList.Close();

        // Open the cash flow journal and enter a manual line
        CashFlowJournal.OpenEdit();

        // Add a line
        Amount := LibraryRandom.RandDec(10000, 2);

        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.FindFirst();
        CashFlowAccount.SetRange("Account Type", CashFlowAccount."Account Type"::Entry);
        CashFlowAccount.FindFirst();

        CashFlowJournal."Cash Flow Date".SetValue(WorkDate());
        CashFlowJournal."Cash Flow Forecast No.".SetValue(CashFlowNo);
        CashFlowJournal."Source Type".SetValue(CashFlowWorksheetLine."Source Type"::"Liquid Funds");
        CashFlowJournal."Source No.".SetValue(GLAccount."No.");
        CashFlowJournal."Cash Flow Account No.".SetValue(CashFlowAccount."No.");
        CashFlowJournal."Amount (LCY)".SetValue(Amount);

        // Post journal
        CashFlowJournal.Register.Invoke();
        CashFlowJournal.Close();

        // Verify ledger entries for new cash flow card
        CashFlowCard.OpenView();
        CashFlowCard.GotoKey(CashFlowNo);
        CashFlowLedgerEntries.Trap();
        CashFlowCard."E&ntries".Invoke();

        Assert.AreEqual(Amount, CashFlowLedgerEntries."Amount (LCY)".AsDecimal(), 'Incorrect amount on CF ledger entry');

        CashFlowLedgerEntries.Close();
        CashFlowCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCashFlowJournalStatusLine()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFAccount: Record "Cash Flow Account";
        CashFlowJournalPage: TestPage "Cash Flow Worksheet";
    begin
        Initialize();

        // Setup:
        OpenJournal(CashFlowJournalPage, CashFlowForecast, CFAccount);

        // Exercise & Verify:
        CashFlowJournalPage.Last();
        ValidateCashFlowJournalStatusLine(CashFlowJournalPage, CashFlowForecast.Description, CFAccount.Name);

        CashFlowJournalPage.Next();
        ValidateCashFlowJournalStatusLine(CashFlowJournalPage, '', '');

        // Clean-up:
        CashFlowJournalPage.Close();
        CleanUpJournal(CashFlowForecast, CFAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCashFlowJournalStatusLineWhenCreatingNewJournalLine()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFAccount: Record "Cash Flow Account";
        CashFlowJournalPage: TestPage "Cash Flow Worksheet";
    begin
        Initialize();

        // Setup:
        OpenJournal(CashFlowJournalPage, CashFlowForecast, CFAccount);

        // Exercise:
        CashFlowJournalPage."Cash Flow Forecast No.".SetValue(CashFlowForecast."No.");
        CashFlowJournalPage."Cash Flow Account No.".SetValue(CFAccount."No.");

        // Verify:
        ValidateCashFlowJournalStatusLine(CashFlowJournalPage, CashFlowForecast.Description, CFAccount.Name);

        // Clean-up:
        CashFlowJournalPage.Close();
        CleanUpJournal(CashFlowForecast, CFAccount);
    end;

    local procedure VerifyCashFlowOnRoleCenter(CashFlowNo: Code[20])
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        CashFlowSetup.Get();
        Assert.AreEqual(
          CashFlowSetup."CF No. on Chart in Role Center", CashFlowNo, 'Incorrect cash flow No. specified for role center chart in setup');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyServiceOrderAmountInFactBox()
    var
        ServiceHeader: Record "Service Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        LibraryService.CreateDefaultServiceOrder(ServiceHeader);
        ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");
        LibraryCashFlowHelper.FilterSingleJournalLine(
          CFWorksheetLine, ServiceHeader."No.", "Cash Flow Source Type"::"Service Orders", CashFlowForecast."No.");
        LibraryCashFlowForecast.PostJournalLines(CFWorksheetLine);
        CFForecastEntry.SetRange("Document No.", ServiceHeader."No.");
        CFForecastEntry.FindFirst();

        // Exercise
        CashFlowCard.OpenView();
        CashFlowCard.GotoRecord(CashFlowForecast);

        // Verify
        CFForecastEntry.CalcSums("Amount (LCY)");
        CashFlowCard.Control1905906307.ServiceOrders.AssertEquals(CFForecastEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrdersInCFAvailabilityByPeriodMatrixViewByPeriod()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CFAvailabilityByPeriods: TestPage "CF Availability by Periods";
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        ConsiderSource: array[16] of Boolean;
        PeriodType: Option Day,Week,Month,Quarter,Year,Period;
        FromDate: Date;
        ToDate: Date;
        TotalAmount: Decimal;
    begin
        // Check Service Order amount value in CF Availability by Period matrix form
        // The lines are represented as Period, values as Net Change, rounding factor none

        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");
        // Identify service orders within the period of the first entry
        CFWorksheetLine.SetRange("Source Type", CFWorksheetLine."Source Type"::"Service Orders");
        CFWorksheetLine.FindFirst();
        // Period range is 1 month
        FromDate := CalcDate('<-CM>', CFWorksheetLine."Cash Flow Date");
        ToDate := CalcDate('<CM>', FromDate);
        // Sum all service orders within the period
        CFWorksheetLine.SetRange("Source Type", CFWorksheetLine."Source Type"::"Service Orders");
        CFWorksheetLine.SetRange("Cash Flow Date", FromDate, ToDate);
        CFWorksheetLine.FindSet();
        repeat
            TotalAmount += CFWorksheetLine."Amount (LCY)";
        until CFWorksheetLine.Next() = 0;
        LibraryCashFlowForecast.PostJournalLines(CFWorksheetLine);

        // Exercise
        CashFlowCard.OpenView();
        CashFlowCard.GotoRecord(CashFlowForecast);
        CFAvailabilityByPeriods.Trap();
        CashFlowCard."CF &Availability by Periods".Invoke();
        CFAvailabilityByPeriods.PeriodType.SetValue(PeriodType::Period);
        CFAvailabilityByPeriods.CFAvailabLines.FILTER.SetFilter("Period Start", Format(FromDate));
        CFAvailabilityByPeriods.CFAvailabLines.First();

        // Verify
        CFAvailabilityByPeriods.CFAvailabLines.ServiceOrders.AssertEquals(TotalAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrdersInCFAvailabilityByPeriodMatrixViewByDay()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CFAvailabilityByPeriods: TestPage "CF Availability by Periods";
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        ConsiderSource: array[16] of Boolean;
        PeriodType: Option Day,Week,Month,Quarter,Year,Period;
        FromDate: Date;
        TotalAmount: Decimal;
    begin
        // Check Service Order amount value in CF Availability by Period matrix form
        // The lines are represented as Day, values as Net Change, rounding factor none

        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");
        CFWorksheetLine.SetRange("Source Type", CFWorksheetLine."Source Type"::"Service Orders");
        CFWorksheetLine.FindFirst();
        FromDate := CFWorksheetLine."Cash Flow Date";
        CFWorksheetLine.SetRange("Cash Flow Date", FromDate);
        CFWorksheetLine.FindSet();
        repeat
            TotalAmount += CFWorksheetLine."Amount (LCY)";
        until CFWorksheetLine.Next() = 0;
        LibraryCashFlowForecast.PostJournalLines(CFWorksheetLine);

        // Exercise
        CashFlowCard.OpenView();
        CashFlowCard.GotoRecord(CashFlowForecast);
        CFAvailabilityByPeriods.Trap();
        CashFlowCard."CF &Availability by Periods".Invoke();
        CFAvailabilityByPeriods.PeriodType.SetValue(PeriodType::Day);
        CFAvailabilityByPeriods.CFAvailabLines.FILTER.SetFilter("Period Start", Format(FromDate));
        CFAvailabilityByPeriods.CFAvailabLines.First();

        // Verify
        CFAvailabilityByPeriods.CFAvailabLines.ServiceOrders.AssertEquals(TotalAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo,CFLedgerEntriesDimensionOverviewMatrixModalFormHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderInCFLedgerEntriesDimensionOverviewMatrix()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        ServiceHeader: Record "Service Header";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        CashFlowLedgerEntries: TestPage "Cash Flow Forecast Entries";
        CFLEDimOverview: TestPage "CF Entries Dim. Overview";
        CFLEDimOverviewMatrix: TestPage "CF Entries Dim. Matrix";
    begin
        // [FEATURE] [Change Global Dimensions]
        // Tests CF L. Entries Dim. Overv. Matrix page
        // Assigning a random dimension value to a service order, fill and post CF journal
        // Verify CF LE in page shows the assigned dimension

        // Setup
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryDimension.RunChangeGlobalDimensions(CreateDimension(), CreateDimension());
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        LibraryService.CreateDefaultServiceOrder(ServiceHeader);
        // make sure you get the first dimension available, required for verification
        // The dimension columns on page CFLEDimOverview cannot be accessed right now via code
        Dimension.SetRange(Blocked, false);
        Dimension.FindFirst();
        CreateDefDimensionForFirstIfNotExist(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        ServiceHeader.Validate("Dimension Set ID",
          LibraryDimension.CreateDimSet(ServiceHeader."Dimension Set ID", Dimension.Code, DimensionValue.Code));
        ServiceHeader.Modify(true);
        // keep values for validation in modal form handler
        DimensionValueCode := DimensionValue.Code;
        SourceDocumentNo := ServiceHeader."No.";
        FillAndPostCFJnlServiceOrderOnly(ServiceHeader, CashFlowForecast);

        // Exercise
        CashFlowCard.OpenView();
        CashFlowCard.GotoRecord(CashFlowForecast);
        CashFlowLedgerEntries.Trap();
        CashFlowCard."E&ntries".Invoke();
        CFLEDimOverview.Trap();
        CashFlowLedgerEntries.GLDimensionOverview.Invoke();
        CFLEDimOverviewMatrix.Trap();
        CFLEDimOverview.ShowMatrix.Invoke();

        // Verify - done in modal form handler CFLEDimOverviewMatrixModalFormHandler

        // TearDown: Reset Global Dimension Code in General Ledger Setup.
        LibraryDimension.RunChangeGlobalDimensions(
          GeneralLedgerSetup."Global Dimension 1 Code", GeneralLedgerSetup."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrdersInCashFlowStatistics()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        ServiceHeader: Record "Service Header";
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        CashFlowStatistics: TestPage "Cash Flow Forecast Statistics";
        ExpectedAmount: Decimal;
    begin
        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        LibraryService.CreateDefaultServiceOrder(ServiceHeader);
        ExpectedAmount := LibraryCashFlowHelper.GetTotalServiceAmount(ServiceHeader, false);
        FillAndPostCFJnlServiceOrderOnly(ServiceHeader, CashFlowForecast);

        // Exercise
        CashFlowCard.OpenView();
        CashFlowCard.GotoRecord(CashFlowForecast);
        CashFlowStatistics.Trap();
        CashFlowCard."&Statistics".Invoke();

        // Verify
        CashFlowStatistics.ServiceOrders.AssertEquals(ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitialEnableCFCardToShowInChart()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowCard: TestPage "Cash Flow Forecast Card";
    begin
        // Tests the behavior of enabling a CF card to be shown in the RTC chart
        // if there is no CF card set so far.

        // Setup
        Initialize();
        CashFlowSetup.SetChartRoleCenterCFNo('');
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);

        // Exercise
        CashFlowCard.OpenEdit();
        CashFlowCard.GotoRecord(CashFlowForecast);
        CashFlowCard.ShowInChart.SetValue(true);

        // Verify
        CashFlowSetup.Get();
        Assert.AreEqual(CashFlowForecast."No.", CashFlowSetup."CF No. on Chart in Role Center", UnexpectedChartCFNoTxt);

        // Tear down
        CashFlowCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeCFCardShownInChart()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowCard: TestPage "Cash Flow Forecast Card";
    begin
        // Tests the behavior of changing the CF card shown in the RTC chart

        // Setup
        Initialize();
        CashFlowSetup.SetChartRoleCenterCFNo('');
        CashFlowForecast.FindFirst();
        CashFlowForecast.ValidateShowInChart(true);
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);

        // Exercise
        CashFlowCard.OpenEdit();
        CashFlowCard.GotoRecord(CashFlowForecast);
        CashFlowCard.ShowInChart.SetValue(true);
        // A confirm handler catches the warning that you override the CF No. on Chart in Role Center

        // Verify
        CashFlowSetup.Get();
        Assert.AreEqual(CashFlowForecast."No.", CashFlowSetup."CF No. on Chart in Role Center", UnexpectedChartCFNoTxt);

        // Tear down
        CashFlowCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCFCardShownInChart()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecast: Record "Cash Flow Forecast";
    begin
        // Tests the behavior of deleting a CF card currently set as chart cash flow card

        // Setup
        Initialize();
        CashFlowSetup.SetChartRoleCenterCFNo('');
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CashFlowForecast.ValidateShowInChart(true);

        // Exercise
        CashFlowForecast.Delete(true);

        // Verify
        CashFlowSetup.Get();
        Assert.AreEqual(
          '', CashFlowSetup."CF No. on Chart in Role Center", 'CF No. on Chart in Role Center in CF Setup is expected to be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CFChartPeriodDay()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowSetup: Record "Cash Flow Setup";
        ServiceHeader: Record "Service Header";
        BusChartBuf: Record "Business Chart Buffer";
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
        CFChartMgt: Codeunit "Cash Flow Chart Mgt.";
        Value: Variant;
        Amount: Decimal;
        ExpectedAmount: Decimal;
    begin
        // Setup
        Initialize();
        CashFlowSetup.SetChartRoleCenterCFNo('');
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CashFlowForecast.ValidateShowInChart(true);
        LibraryService.CreateDefaultServiceOrder(ServiceHeader); // HACK - investigate in generic solution
        ExpectedAmount := LibraryCashFlowHelper.GetTotalServiceAmount(ServiceHeader, false);
        FillAndPostCFJnlServiceOrderOnly(ServiceHeader, CashFlowForecast);
        InitializeCashFlowChartSetup(
          CashFlowChartSetup."Start Date"::"First Entry Date",
          CashFlowChartSetup."Period Length"::Day,
          CashFlowChartSetup.Show::"Change in Cash",
          CashFlowChartSetup."Group By"::"Source Type");

        CFChartMgt.UpdateData(BusChartBuf);
        CashFlowForecast."Source Type Filter" := CashFlowForecast."Source Type Filter"::"Service Orders";
        BusChartBuf.GetValue(Format(CashFlowForecast."Source Type Filter"), 0, Value); // HACK - calc XIndex

        // Verify
        Evaluate(Amount, Format(Value));
        Assert.AreEqual(ExpectedAmount, Amount, 'Unexpected Cash Flow date.');
    end;

    [Test]
    [HandlerFunctions('CashFlowSetupConfirmHandler')]
    [Scope('OnPrem')]
    procedure CFChartBudgetEntriesPeriodDay()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLAccount: Record "G/L Account";
        CFAccount: Record "Cash Flow Account";
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
        BusChartBuf: Record "Business Chart Buffer";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        CFChartMgt: Codeunit "Cash Flow Chart Mgt.";
        LibraryERM: Codeunit "Library - ERM";
        Value: Variant;
        Amount: Decimal;
    begin
        // Setup
        Initialize();
        LibraryCashFlowForecast.CreateCashFlowCard(CashFlowForecast);
        CashFlowForecast.Validate("G/L Budget From", WorkDate());
        CashFlowForecast.Validate("G/L Budget To", WorkDate());
        CashFlowForecast.Modify(true);
        CashFlowSetupReply := true; // set global handler reply to TRUE
        CashFlowForecast.ValidateShowInChart(true);
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryCashFlowHelper.FindCFBudgetAccount(CFAccount);
        LibraryCashFlowHelper.FindFirstGLAccFromCFAcc(GLAccount, CFAccount);
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, CashFlowForecast."G/L Budget To", GLAccount."No.", GLBudgetName.Name);
        GLBudgetEntry.Validate(Amount, LibraryRandom.RandDec(100, 2));
        GLBudgetEntry.Modify(true);
        // fill and post budget only
        LibraryCashFlowForecast.FillBudgetJournal(false, CashFlowForecast."No.", GLBudgetName.Name);
        LibraryCashFlowForecast.PostJournal();
        InitializeCashFlowChartSetup(
          CashFlowChartSetup."Start Date"::"Working Date",
          CashFlowChartSetup."Period Length"::Day,
          CashFlowChartSetup.Show::"Change in Cash",
          CashFlowChartSetup."Group By"::"Source Type");

        CFChartMgt.UpdateData(BusChartBuf);
        BusChartBuf.GetValue(Format(CFForecastEntry."Source Type"::"G/L Budget"), 0, Value);

        // Verify
        Evaluate(Amount, Format(Value));
        Assert.AreEqual(GLBudgetEntry.Amount, -Amount, 'Unexpected Cash Flow amount.');
    end;

    local procedure CreateCashFlowAccount(var CashFlowAccount: Record "Cash Flow Account"; AccountType: Enum "Cash Flow Account Type")
    begin
        CashFlowAccount.Init();
        Evaluate(CashFlowAccount."No.", LibraryUtility.GenerateRandomCode(CashFlowAccount.FieldNo("No."), DATABASE::"Cash Flow Account"));
        CashFlowAccount."Account Type" := AccountType;
        CashFlowAccount.Insert(true);
    end;

    local procedure FillAndPostCFJnlServiceOrderOnly(ServiceHeader: Record "Service Header"; CashFlowForecast: Record "Cash Flow Forecast")
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ConsiderSource: array[16] of Boolean;
    begin
        // fill journal
        ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // filter on the created source document
        CFWorksheetLine.SetRange("Source Type", CFWorksheetLine."Source Type"::"Service Orders");
        CFWorksheetLine.SetRange("Document No.", ServiceHeader."No.");

        // post
        LibraryCashFlowForecast.PostJournalLines(CFWorksheetLine);
    end;

    local procedure InitializeCashFlowChartSetup(StartDate: Option; PeriodLength: Option; NewShow: Option; GroupBy: Option)
    var
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cash Flow Pages");
        if CashFlowChartSetup.Get(UserId) then
            CashFlowChartSetup.Delete();

        CashFlowChartSetup.Init();
        CashFlowChartSetup."User ID" := UserId;
        CashFlowChartSetup."Start Date" := StartDate;
        CashFlowChartSetup."Period Length" := PeriodLength;
        CashFlowChartSetup.Show := NewShow;
        CashFlowChartSetup."Group By" := GroupBy;
        CashFlowChartSetup.Insert();
    end;

    local procedure CleanUpJournal(CashFlowForecast: Record "Cash Flow Forecast"; CFAccount: Record "Cash Flow Account")
    begin
        CashFlowForecast.Delete();
        CFAccount.Delete();
    end;

    local procedure OpenJournal(var CashFlowJournalPage: TestPage "Cash Flow Worksheet"; var CashFlowForecast: Record "Cash Flow Forecast"; var CashFlowAccount: Record "Cash Flow Account")
    var
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
    begin
        // Create Cash Flow Card
        LibraryCashFlowForecast.CreateCashFlowCard(CashFlowForecast);
        CashFlowForecast.Validate(Description, CashFlowForecast."No.");
        CashFlowForecast.Modify(true);

        // Create Cash Flow Acount
        LibraryCashFlowForecast.CreateCashFlowAccount(CashFlowAccount, CashFlowAccount."Account Type"::Entry);
        CashFlowAccount.Validate(Name, CashFlowAccount."No.");
        CashFlowAccount.Modify(true);

        LibraryCashFlowForecast.CreateJournalLine(CashFlowWorksheetLine, CashFlowForecast."No.", CashFlowAccount."No.");

        CashFlowJournalPage.OpenEdit();
    end;

    local procedure ValidateCashFlowJournalStatusLine(CashFlowJournalPage: TestPage "Cash Flow Worksheet"; ExpectedCFName: Text[100]; ExpectedCFAccountName: Text[100])
    begin
        CashFlowJournalPage.CFName.AssertEquals(ExpectedCFName);
        CashFlowJournalPage.CFAccName.AssertEquals(ExpectedCFAccountName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CashFlowSetupConfirmHandler(Message: Text[1024]; var Answer: Boolean)
    begin
        Answer := CashFlowSetupReply;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text[1024]; var Answer: Boolean)
    begin
        Answer := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CashFlowAccountListPageHandler(var CashFlowAccountList: TestPage "Cash Flow Account List")
    begin
        CashFlowAccountList.GotoRecord(CashFlowAccount);
        CashFlowAccountList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CFLedgerEntriesDimensionOverviewMatrixModalFormHandler(var CFLEDimOverviewMatrix: TestPage "CF Entries Dim. Matrix")
    begin
        CFLEDimOverviewMatrix.FILTER.SetFilter("Document No.", SourceDocumentNo);
        // Field1 must be used because we cannot refer to specific dimension codes in the test page
        // TODO create bug for missing functions
        CFLEDimOverviewMatrix.Field1.AssertEquals(DimensionValueCode);
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Cash Flow Pages");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Cash Flow Pages");
    end;

    local procedure FillJournalWithoutGroupBy(ConsiderSource: array[16] of Boolean; CashFlowForecastNo: Code[20])
    begin
        LibraryCashFlowHelper.FillJournal(ConsiderSource, CashFlowForecastNo, false);
    end;

    [Test]
    [HandlerFunctions('EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure OpenDimensionSetEntriesFromCashFlowWorkSheet()
    var
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
        CashFlowForecastNo: Code[10];
    begin
        Initialize();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Inv. Rounding Precision (LCY)", GeneralLedgerSetup."Amount Rounding Precision");
        GeneralLedgerSetup.Modify(true);
        CashFlowForecastNo := FillCashFlowWorkSheetWithSalesOrder();
        CashFlowWorksheetLine.SetFilter("Cash Flow Forecast No.", CashFlowForecastNo);
        CashFlowWorksheetLine.FindFirst();
        LibraryVariableStorage.Enqueue(CashFlowWorksheetLine."Shortcut Dimension 1 Code");
        CashFlowJournal.OpenEdit();
        CashFlowJournal.Dimensions.Invoke();
        CashFlowJournal.Close();
    end;

    [Test]
    [HandlerFunctions('SuggestWorksheetLinesHandler')]
    [Scope('OnPrem')]
    procedure OpenSuggestWorkSheetLineFromCashFlowWorkSheet()
    var
        CashFlowJournal: TestPage "Cash Flow Worksheet";
    begin
        Initialize();
        CashFlowJournal.OpenView();
        asserterror CashFlowJournal.SuggestWorksheetLines.Invoke(); // Report is ran with default request page in SuggestWorksheetLinesHandler
        Assert.ExpectedError(CashFlowForeCastErrorTxt);
        CashFlowJournal.Close();
    end;

    local procedure FillCashFlowWorkSheetWithSalesOrder(): Code[10]
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        ConsiderSource: array[16] of Boolean;
    begin
        CashFlowForecast.FindFirst();
        ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] := true;
        LibraryCashFlowForecast.FillJournal(ConsiderSource, CashFlowForecast."No.", true);
        exit(CashFlowForecast."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditDimensionSetEntriesHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    var
        ShortcutDim1: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShortcutDim1);
        EditDimensionSetEntries.FILTER.SetFilter("Dimension Value Code", ShortcutDim1);
        EditDimensionSetEntries.First();
        EditDimensionSetEntries.DimensionValueCode.AssertEquals(ShortcutDim1);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestWorksheetLinesHandler(var SuggestWorksheetLines: TestRequestPage "Suggest Worksheet Lines")
    begin
        SuggestWorksheetLines.OK().Invoke();
    end;

    local procedure CreateDimension(): Code[20]
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        exit(Dimension.Code);
    end;

    local procedure CreateDefDimensionForFirstIfNotExist(var Dimension: Record Dimension)
    var
        DefDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        GLAccount: Record "G/L Account";
    begin
        DefDimension.SetRange("Dimension Code", Dimension.Code);
        DefDimension.SetRange("Value Posting", DefDimension."Value Posting"::"Code Mandatory");
        DefDimension.SetFilter("Allowed Values Filter", '<>%1', '');
        if not DefDimension.IsEmpty() then
            exit;

        LibraryERM.CreateGLAccount(GLAccount);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefDimension, GLAccount."No.", Dimension.Code, DimensionValue.Code);
        DefDimension.Validate("Value Posting", DefDimension."Value Posting"::"Code Mandatory");
        DefDimension.Validate("Allowed Values Filter", DimensionValue.Code);
        DefDimension.Modify();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

