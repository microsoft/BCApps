codeunit 134550 "ERM Cash Flow Simplifications"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cash Flow] [Forecast] [Simplification]
        IsInitialized := false;
    end;

    var
        LibraryCashFlow: Codeunit "Library - Cash Flow";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        DefaultTxt: Label 'Default';
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cash Flow Simplifications");
        DeleteCashFlowSetup();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Cash Flow Simplifications");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Cash Flow Simplifications");
    end;

    local procedure DeleteCashFlowSetup()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowAccount: Record "Cash Flow Account";
        CashFlowAccountComment: Record "Cash Flow Account Comment";
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        CashFlowManualRevenue: Record "Cash Flow Manual Revenue";
        CashFlowManualExpense: Record "Cash Flow Manual Expense";
        CashFlowReportSelection: Record "Cash Flow Report Selection";
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
    begin
        CashFlowSetup.DeleteAll();
        CashFlowChartSetup.DeleteAll();
        CashFlowForecast.DeleteAll();
        CashFlowAccount.DeleteAll();
        CashFlowAccountComment.DeleteAll();
        CashFlowForecastEntry.DeleteAll();
        CashFlowWorksheetLine.DeleteAll();
        CashFlowManualRevenue.DeleteAll();
        CashFlowManualExpense.DeleteAll();
        CashFlowReportSelection.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCashFlowSetupAfterSimpleSetUpRun()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowAccount: Record "Cash Flow Account";
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
        CashFlowManagement: Codeunit "Cash Flow Management";
    begin
        // [SCENARIO 168420] The simplified Cash Flow Forecast Setup is functional
        Initialize();

        // [GIVEN] A newly setup company without any cash flow forecast setup
        Assert.RecordIsEmpty(CashFlowSetup);
        Assert.RecordIsEmpty(CashFlowChartSetup);
        Assert.RecordIsEmpty(CashFlowForecast);
        Assert.RecordIsEmpty(CashFlowAccount);
        Assert.RecordIsEmpty(CashFlowForecastEntry);

        // [GIVEN] Mock customer ledger entry
        LibraryCashFlow.MockCashFlowCustOverdueData();

        // [WHEN] The Cash Flow Forecast is set up using the simplified setup functionality
        CashFlowManagement.SetupCashFlow(CopyStr(CashFlowManagement.GetCashAccountFilter(), 1, 250));
        CashFlowSetup.Get();
        CashFlowManagement.UpdateCashFlowForecast(CashFlowSetup."Azure AI Enabled");

        // [THEN] Cash Flow Forecast is set up and data is available for the chart to be consumed
        Assert.RecordIsNotEmpty(CashFlowSetup);
        Assert.RecordIsNotEmpty(CashFlowChartSetup);
        Assert.RecordIsNotEmpty(CashFlowForecast);
        Assert.RecordIsNotEmpty(CashFlowAccount);
        Assert.RecordIsNotEmpty(CashFlowForecastEntry);

        Assert.IsTrue(CashFlowForecast.Get(DefaultTxt), 'No DEFAULT Cash Flow Forecast exists');
        Assert.IsTrue(
          CashFlowForecast."Overdue CF Dates to Work Date", 'Move Overdue Cash Flow Dates to Work Date is not enabled by default');
        Assert.IsTrue(CashFlowForecast.GetShowInChart(), 'DEFAULT Cash Flow Forecast is not set to be shown in chart on role center');

        Assert.IsTrue(CashFlowAccount.Count >= 12, 'There should be at least 12 Cash Flow Accounts');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMoveOverdueCashFlowDatesToWorkDate()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        CashFlowManagement: Codeunit "Cash Flow Management";
        CashFlowForecastEntryCount: Integer;
    begin
        // [SCENARIO 168420] Enabling the "Move Overdue Cash Flow Dates to Work Date" moves all overdue cash flow dates to workdate
        Initialize();

        // [GIVEN] A working cash flow forecast setup where "Move Overdue Cash Flow Dates to Work Date" is enabled (default)
        CashFlowManagement.SetupCashFlow(CopyStr(CashFlowManagement.GetCashAccountFilter(), 1, 250));

        // [GIVEN] Mock overdue customer entry
        LibraryCashFlow.MockCashFlowCustOverdueData();

        // [WHEN] The Cash Flow Forecast is updated
        CashFlowSetup.Get();
        CashFlowManagement.UpdateCashFlowForecast(CashFlowSetup."Azure AI Enabled");

        // [THEN] Cash Flow Forecast Entries are created
        CashFlowForecastEntryCount := CashFlowForecastEntry.Count();
        Assert.AreNotEqual(0, CashFlowForecastEntryCount, 'There are no Cash Flow Forecast Entries for the test.');

        // [THEN] No Cash Flow Forecast Entries with Cash Flow Date prior to workdate exist
        CashFlowForecastEntry.SetFilter("Cash Flow Date", '<%1', WorkDate());
        Assert.RecordIsEmpty(CashFlowForecastEntry);

        // [THEN] Cash Flow Forecast Entries with the overdue flag exist
        CashFlowForecastEntry.Reset();
        CashFlowForecastEntry.SetRange(Overdue, true);
        Assert.RecordIsNotEmpty(CashFlowForecastEntry);

        // [WHEN] "Move Overdue Cash Flow Dates to Work Date" is disabled
        CashFlowForecast.FindFirst();
        CashFlowForecast.Validate("Overdue CF Dates to Work Date", false);
        CashFlowForecast.Modify();

        // [WHEN] The Cash Flow Forecast is updated
        CashFlowManagement.UpdateCashFlowForecast(false);

        // [THEN] Cash Flow Forecast Entries with Cash Flow Date prior to workdate do exist
        CashFlowForecastEntry.Reset();
        CashFlowForecastEntry.SetFilter("Cash Flow Date", '<%1', WorkDate());
        Assert.RecordIsNotEmpty(CashFlowForecastEntry);

        // [THEN] The number of cash flow forecast entries is the same as when "Move Overdue Cash Flow Dates to Work Date" was enabled
        CashFlowForecastEntry.Reset();
        Assert.AreEqual(CashFlowForecastEntryCount, CashFlowForecastEntry.Count,
          'The number of cash flow forecast entires has changed during test.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowForecastRecalculateUsesDefaultGLBudget()
    var
        GLAccount: Record "G/L Account";
        CashFlowForecast: Record "Cash Flow Forecast";
        GLBudgetName: Record "G/L Budget Name";
        CashFlowManagement: Codeunit "Cash Flow Management";
    begin
        // [SCENARIO 216343] Cash Flow Forecast Entry created with G/L Budget equal "Default G/L Budget" of Cash Flow Forecast after running "Recalculate Forecast"

        Initialize();

        // [GIVEN] Cash Flow Forecast with "Default G/L Budget Name" = "X"
        CashFlowManagement.SetupCashFlow(CopyStr(CashFlowManagement.GetCashAccountFilter(), 1, 250));
        CashFlowForecast.Get(DefaultTxt);
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        CashFlowForecast.Validate("Default G/L Budget Name", GLBudgetName.Name);
        CashFlowForecast.Modify(true);
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Cash Flow Account with integration to G/L Account "1000"
        CreateCashFlowAccountForGLBudgetIntegration(GLAccount."No.");

        // [GIVEN] G/L Budget Entry for Budget "X" and "G/L Account" = "1000"
        MockGLBudgetEntryWithGLAcc(CashFlowForecast."Default G/L Budget Name", GLAccount."No.", CashFlowForecast."G/L Budget From");

        // [WHEN] Recalculate Cash Flow Forecast
        CashFlowManagement.UpdateCashFlowForecast(false);

        // [THEN] Cash Flow Forecast Entry with "Source Type" = "G/L Budget" and "G/L Budget Name" = "X" for Cash Flow Forecast is created
        VerifyGLBudgetNameInCFForecastEntry(CashFlowForecast."No.", CashFlowForecast."Default G/L Budget Name");
    end;

    local procedure CreateCashFlowAccountForGLBudgetIntegration(GLAccNo: Code[20])
    var
        CashFlowAccount: Record "Cash Flow Account";
    begin
        LibraryCashFlow.CreateCashFlowAccount(CashFlowAccount, CashFlowAccount."Account Type"::Entry);
        CashFlowAccount.Validate("G/L Integration", CashFlowAccount."G/L Integration"::Both);
        CashFlowAccount.Validate("G/L Account Filter", GLAccNo);
        CashFlowAccount.Modify(true);
    end;

    local procedure MockGLBudgetEntryWithGLAcc(BudgetName: Code[10]; GLAccNo: Code[20]; EntryDate: Date)
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry.Init();
        GLBudgetEntry."Entry No." := LibraryUtility.GetNewRecNo(GLBudgetEntry, GLBudgetEntry.FieldNo("Entry No."));
        GLBudgetEntry."Budget Name" := BudgetName;
        GLBudgetEntry."G/L Account No." := GLAccNo;
        GLBudgetEntry.Date := EntryDate;
        GLBudgetEntry.Amount := LibraryRandom.RandDec(100, 2);
        GLBudgetEntry.Insert();
    end;

    local procedure VerifyGLBudgetNameInCFForecastEntry(CFNo: Code[20]; GLBudgetName: Code[10])
    var
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
    begin
        CashFlowForecastEntry.SetRange("Source Type", CashFlowForecastEntry."Source Type"::"G/L Budget");
        CashFlowForecastEntry.SetRange("Cash Flow Forecast No.", CFNo);
        CashFlowForecastEntry.FindFirst();
        CashFlowForecastEntry.TestField("G/L Budget Name", GLBudgetName);
    end;
}

