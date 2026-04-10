codeunit 134360 "No Accounting Periods: Basic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [No Accounting Periods]
    end;

    var
        Assert: Codeunit Assert;
        WrongPeriodStartingDateErr: Label 'Wrong period starting date.';
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        WrongValueErr: Label 'Wrong value.';
        LibraryERM: Codeunit "Library - ERM";
        CloseIncomeStatementErr: Label 'The fiscal year does not exist.';
        NoAccountingPeriodsErr: Label 'No accounting periods have been set up. In order to run date compression you must set up accounting periods.';
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    [Test]
    [Scope('OnPrem')]
    procedure GetPeriodStartingDateWhenNoPeriodsUT()
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] First day of the year is default starting period date when no periods defined
        Initialize();
        Assert.AreEqual(
          CalcDate('<-CY>', WorkDate()), AccountingPeriodMgt.GetPeriodStartingDate(), WrongPeriodStartingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPeriodStartingDateForOpenAccPeriodUT()
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] First posting date is starting period date when accounting periods are defined
        LibraryFiscalYear.CloseAccountingPeriod();
        LibraryFiscalYear.CreateFiscalYear();
        Assert.AreEqual(
          CalcDate('<-CY>', LibraryFiscalYear.GetFirstPostingDate(false)),
          AccountingPeriodMgt.GetPeriodStartingDate(), WrongPeriodStartingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultAccountingPeriodUT()
    var
        AccountingPeriod: Record "Accounting Period";
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] Default accounting period starts on the 1st day of month
        AccountingPeriodMgt.InitDefaultAccountingPeriod(AccountingPeriod, WorkDate());
        Assert.AreEqual(CalcDate('<-CM>', WorkDate()), AccountingPeriod."Starting Date", WrongValueErr);
        Assert.IsFalse(AccountingPeriod."New Fiscal Year", WrongValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultStartYearAccountingPeriodUT()
    var
        AccountingPeriod: Record "Accounting Period";
        InventorySetup: Record "Inventory Setup";
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] Default start year accounting period starts on the 1st day of year and has average cost settings from Inventory setup
        AccountingPeriodMgt.InitStartYearAccountingPeriod(AccountingPeriod, WorkDate());
        Assert.AreEqual(CalcDate('<-CY>', WorkDate()), AccountingPeriod."Starting Date", WrongValueErr);
        Assert.IsTrue(AccountingPeriod."New Fiscal Year", WrongValueErr);
        InventorySetup.Get();
        AccountingPeriod.TestField("Average Cost Calc. Type", InventorySetup."Average Cost Calc. Type");
        AccountingPeriod.TestField("Average Cost Period", InventorySetup."Average Cost Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportCloseIncomeStatementError()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        CloseIncomeStatement: Report "Close Income Statement";
    begin
        // [FEATURE] [UT] [Report]
        // [SCENARIO 222561] Close Income Statement report generates error when no accounting periods
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        CloseIncomeStatement.InitializeRequestTest(WorkDate(), GenJournalLine, GLAccount, false);
        CloseIncomeStatement.UseRequestPage(false);
        asserterror CloseIncomeStatement.Run();

        Assert.ExpectedError(CloseIncomeStatementErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportDateCompressionGeneralLedgerError()
    var
        AnalysisView: Record "Analysis View";
        GLEntry: Record "G/L Entry";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateCompressGeneralLedger: Report "Date Compress General Ledger";
    begin
        // [FEATURE] [UT] [Report]
        // [SCENARIO 222561] Date Compress General Ledger report generates error when no accounting periods
        Initialize();
        AnalysisView.DeleteAll();
        GLEntry.Init();
        GLEntry."G/L Account No." := LibraryERM.CreateGLAccountNo();
        GLEntry."Posting Date" := WorkDate();
        GLEntry.Amount := LibraryRandom.RandDec(100, 2);
        GLEntry.Insert();
        DateComprRetainFields."Retain Document Type" := false;
        DateComprRetainFields."Retain Document No." := false;
        DateComprRetainFields."Retain Job No." := false;
        DateComprRetainFields."Retain Business Unit Code" := false;
        DateComprRetainFields."Retain Quantity" := false;
        DateComprRetainFields."Retain Journal Template Name" := false;
        DateCompressGeneralLedger.InitializeRequest(WorkDate(), WorkDate(), 0, '', DateComprRetainFields, '', false);
        DateCompressGeneralLedger.UseRequestPage(false);
        asserterror DateCompressGeneralLedger.Run();

        Assert.ExpectedError(NoAccountingPeriodsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFiscalYearWhenNoPeriods()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] Create Fiscal Year when no accounting periods
        Initialize();
        LibraryFiscalYear.CreateFiscalYear();
        Assert.RecordIsNotEmpty(AccountingPeriod);
        Assert.RecordCount(AccountingPeriod, 13);
        VerifyAccountingPeriod(AccountingPeriod, CalcDate('<-CY>', WorkDate()), true, false);
        VerifyAccountingPeriod(AccountingPeriod, CalcDate('<-CY+1Y>', WorkDate()), false, false);
    end;

    [Test]
    [HandlerFunctions('CreateFiscalYearRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateFiscalYearBeforeExistingPeriod()
    var
        AccountingPeriod: Record "Accounting Period";
        DateInPeriodBefore: Date;
    begin
        // [SCENARIO 222561] Create Fiscal Year before existing period is allowed

        // [GIVEN] One open fiscal year
        Initialize();
        LibraryFiscalYear.CreateFiscalYear();
        AccountingPeriod.FindFirst();
        DateInPeriodBefore := CalcDate('<-CY-1Y>', AccountingPeriod."Starting Date");

        // [WHEN] Create new fiscal year before existing
        RunCreateFiscalYear(DateInPeriodBefore);
        Assert.RecordCount(AccountingPeriod, 25);

        // [THEN] Closed fiscal year is created
        VerifyAccountingPeriod(AccountingPeriod, DMY2Date(1, 1, Date2DMY(DateInPeriodBefore, 3)), true, true);
    end;

    [Test]
    [HandlerFunctions('CreateFiscalYearRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateFiscalYearBetweenTwoPeriods()
    var
        AccountingPeriod: Record "Accounting Period";
        LastPeriodStartingDate: Date;
        DateInPeriodBetween: Date;
    begin
        // [SCENARIO 222561] Create Fiscal Year between two existing periods

        // [GIVEN] Open 2020 fiscal year, closed 2018 fiscal year
        Initialize();
        LibraryFiscalYear.CreateFiscalYear();
        AccountingPeriod.FindFirst();
        LastPeriodStartingDate := AccountingPeriod."Starting Date";
        RunCreateFiscalYear(CalcDate('<-2Y>', LastPeriodStartingDate));

        // [WHEN] Create 2019 fiscal year
        DateInPeriodBetween := CalcDate('<-1Y>', LastPeriodStartingDate);
        RunCreateFiscalYear(DateInPeriodBetween);

        // [THEN] Closed 2019 fiscal year is created
        Assert.RecordCount(AccountingPeriod, 37);
        VerifyAccountingPeriod(AccountingPeriod, DateInPeriodBetween, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateApproveTimesheet()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] Create and approve time sheets is possible
        Initialize();
        LibraryTimeSheet.InitResourceScenario(TimeSheetHeader, TimeSheetLine, true);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Approved);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure O365StatisticsGetCurrentPeriod()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // [FEATURE] [UT] [Statistics]
        // [SCENARIO 222561] Accounting Period is initialized from start of the year in O365Statistics
        Initialize();
        GetCurrentAccountingPeriod(AccountingPeriod);
        AccountingPeriod.TestField("Starting Date", CalcDate('<-CY>', WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure O365StatisticsGetCurrentPeriodWithFilters()
    var
        AccountingPeriod: Record "Accounting Period";
        AccountingPeriodStat: Record "Accounting Period";
    begin
        // [FEATURE] [UT] [Statistics]
        // [SCENARIO 222561] Accounting Period is initialized from existing accounting period in O365Statistics when we have filter after first run
        Initialize();
        AccountingPeriod.Init();
        AccountingPeriod."Starting Date" := WorkDate();
        AccountingPeriod."New Fiscal Year" := true;
        AccountingPeriod.Insert();
        GetCurrentAccountingPeriod(AccountingPeriodStat);
        Assert.IsTrue(AccountingPeriodStat.GetFilter("New Fiscal Year") <> '', '');
        AccountingPeriod."New Fiscal Year" := false;
        AccountingPeriod.Modify();
        GetCurrentAccountingPeriod(AccountingPeriodStat);
        AccountingPeriodStat.TestField("Starting Date", AccountingPeriod."Starting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindFiscalYearNoAccPeriods()
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        RequestDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] AccountingPeriodMgt.FindFiscalYear returns first date of the year for requested date when no accounting periods
        Initialize();
        RequestDate := LibraryRandom.RandDate(10);
        Assert.AreEqual(CalcDate('<-CY>', RequestDate), AccountingPeriodMgt.FindFiscalYear(RequestDate), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindFiscalYearNoAccPeriodsNoDate()
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] AccountingPeriodMgt.FindFiscalYear returns first date of the year of workdate when no accounting periods and no requested date specified
        Initialize();
        Assert.AreEqual(CalcDate('<-CY>', WorkDate()), AccountingPeriodMgt.FindFiscalYear(0D), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindFiscalYearForExistingAccountingPeriod()
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        RequestDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] AccountingPeriodMgt.FindFiscalYear returns first date of the year for requested date inside existing accounting period
        Initialize();
        LibraryFiscalYear.CreateFiscalYear();
        RequestDate := LibraryRandom.RandDateFrom(LibraryFiscalYear.GetFirstPostingDate(false), 100);
        Assert.AreEqual(CalcDate('<-CY>', RequestDate), AccountingPeriodMgt.FindFiscalYear(RequestDate), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindFiscalYearBeforeExistingAccountingPeriod()
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        FirstPostingDate: Date;
        RequestDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] AccountingPeriodMgt.FindFiscalYear returns first date of the year for requested date before existing accounting period
        Initialize();
        LibraryFiscalYear.CreateFiscalYear();
        FirstPostingDate := LibraryFiscalYear.GetFirstPostingDate(false);
        RequestDate := CalcDate('<-5Y>', FirstPostingDate);
        Assert.AreEqual(FirstPostingDate, AccountingPeriodMgt.FindFiscalYear(RequestDate), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindFiscalYearAfterExistingAccountingPeriod()
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        FirstPostingDate: Date;
        RequestDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] AccountingPeriodMgt.FindFiscalYear returns last posting date in the year for requested date after existing accounting period
        Initialize();
        LibraryFiscalYear.CreateFiscalYear();
        FirstPostingDate := LibraryFiscalYear.GetFirstPostingDate(false);
        RequestDate := CalcDate('<5Y>', FirstPostingDate);
        Assert.AreEqual(LibraryFiscalYear.GetLastPostingDate(false), AccountingPeriodMgt.FindFiscalYear(RequestDate), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindEndOfFiscalYearNoAccPeriods()
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        RequestDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] AccountingPeriodMgt.FindEndOfFiscalYear returns last date of the year for requested date when no accounting periods
        Initialize();
        RequestDate := LibraryRandom.RandDate(10);
        Assert.AreEqual(CalcDate('<CY>', RequestDate), AccountingPeriodMgt.FindEndOfFiscalYear(RequestDate), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindEndOfFiscalYearNoAccPeriodsNoDate()
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] AccountingPeriodMgt.FindEndOfFiscalYear returns last date of the year of workdate when no accounting periods and no requested date specified
        Initialize();
        Assert.AreEqual(CalcDate('<CY>', WorkDate()), AccountingPeriodMgt.FindEndOfFiscalYear(0D), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindEndOfFiscalYearForExistingAccountingPeriod()
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        RequestDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] AccountingPeriodMgt.FindEndOfFiscalYear returns last date of the year for requested date inside existing accounting period
        Initialize();
        LibraryFiscalYear.CreateFiscalYear();
        RequestDate := LibraryRandom.RandDateFrom(LibraryFiscalYear.GetFirstPostingDate(false), 100);
        Assert.AreEqual(CalcDate('<CY>', RequestDate), AccountingPeriodMgt.FindEndOfFiscalYear(RequestDate), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindEndOfFiscalYearBeforeExistingAccountingPeriod()
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        LastPostingDate: Date;
        RequestDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] AccountingPeriodMgt.FindEndOfFiscalYear returns last posting date of the year for requested date before existing accounting period
        Initialize();
        LibraryFiscalYear.CreateFiscalYear();
        LastPostingDate := LibraryFiscalYear.GetLastPostingDate(false) - 1;
        RequestDate := CalcDate('<-5Y>', LastPostingDate);
        Assert.AreEqual(LastPostingDate, AccountingPeriodMgt.FindEndOfFiscalYear(RequestDate), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindEndOfFiscalYearAfterExistingAccountingPeriod()
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        LastPostingDate: Date;
        RequestDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] AccountingPeriodMgt.FindEndFiscalYear returns 31-12-9999 for requested date after existing accounting period
        Initialize();
        LibraryFiscalYear.CreateFiscalYear();
        LastPostingDate := LibraryFiscalYear.GetLastPostingDate(false) - 1;
        RequestDate := CalcDate('<5Y>', LastPostingDate);
        Assert.AreEqual(DMY2Date(31, 12, 9999), AccountingPeriodMgt.FindEndOfFiscalYear(RequestDate), '');
    end;

    local procedure Initialize()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"No Accounting Periods: Basic");
        AccountingPeriod.DeleteAll();
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

    local procedure VerifyAccountingPeriod(AccountingPeriod: Record "Accounting Period"; StartingDate: Date; DateLocked: Boolean; IsClosed: Boolean)
    begin
        AccountingPeriod.SetRange("Starting Date", StartingDate);
        AccountingPeriod.FindFirst();
        AccountingPeriod.TestField("New Fiscal Year", true);
        AccountingPeriod.TestField("Date Locked", DateLocked);
        AccountingPeriod.TestField(Closed, IsClosed);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
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

    local procedure GetCurrentAccountingPeriod(var AccountingPeriod: Record "Accounting Period")
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        if IsEmptyAccountingPeriod() then begin
            AccountingPeriod.Reset();
            AccountingPeriodMgt.InitStartYearAccountingPeriod(AccountingPeriod, WorkDate());
            exit;
        end;

        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetFilter("Starting Date", '..%1', WorkDate());

        if not AccountingPeriod.FindLast() then begin
            AccountingPeriod.SetRange("New Fiscal Year");
            if AccountingPeriod.FindFirst() then;
        end;
    end;

    local procedure IsEmptyAccountingPeriod(): Boolean
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        exit(AccountingPeriod.IsEmpty);
    end;
}

