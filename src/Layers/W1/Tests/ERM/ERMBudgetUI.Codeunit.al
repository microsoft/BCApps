codeunit 134927 "ERM Budget UI"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [UI] [Budget]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure BudgetPageOpensWithViewByMonthAndCurrCalendarYearForDateFilter()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetNames: TestPage "G/L Budget Names";
        Budget: TestPage Budget;
    begin
        // [SCENARIO 213513] Budget page opens with default values "View By" = Month and "Date Filter" = current calendar year

        Initialize();

        // [GIVEN] Today is 07.07.2017
        // [GIVEN] Budget "X"
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryLowerPermissions.SetFinancialReporting();

        // [GIVEN] Opened "G/L Budget Names" page and selected Budget "X"
        GLBudgetNames.OpenEdit();
        GLBudgetNames.Name.SetValue(GLBudgetName.Name);
        Budget.Trap();

        // [WHEN] Press "Edit Budget" in "G/L Budget Names" page
        GLBudgetNames.EditBudget.Invoke();

        // [THEN] "View By" is "Month" on Budget page
        Budget.PeriodType.AssertEquals('Month');

        // [THEN] "Date Filter" is "01.01.2017..31.12.2017" on Budget page
        Budget.DateFilter.AssertEquals(Format(CalcDate('<-CY>', Today)) + '..' + Format(CalcDate('<CY>', Today)));

        Budget.Close();
        GLBudgetNames.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BudgetPageHasDefaultFilterIncomeStatementForIncomeBalanceFilter()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLAccount: Record "G/L Account";
        GLBudgetNames: TestPage "G/L Budget Names";
        Budget: TestPage Budget;
    begin
        // [SCENARIO 213513] Budget page has default filter "Income Statement" for "Income/Balance G/L Account Filter"

        Initialize();

        CreateSetOfGLAccountsWithDiffCategoryAndIncomeBal();
        // [GIVEN] Budget "X"
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryLowerPermissions.SetFinancialReporting();

        // [GIVEN] Opened "G/L Budget Names" page and selected Budget "X"
        GLBudgetNames.OpenEdit();
        GLBudgetNames.Name.SetValue(GLBudgetName.Name);
        Budget.Trap();

        // [WHEN] Press "Edit Budget" in "G/L Budget Names" page and set "G/L Account" for "Show as Lines"
        GLBudgetNames.EditBudget.Invoke();
        Budget.LineDimCode.SetValue('G/L Account');

        // [THEN] "Income/Balance" is "Income Statement" on Budget page
        Budget.IncomeBalGLAccFilter.AssertEquals('Income Statement');

        // [THEN] Only G/L accounts with "Income/Balance" = "Income Statement" are shown on Budget page
        repeat
            GLAccount.Get(Budget.MatrixForm.Code.Value);
            GLAccount.TestField("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        until not Budget.MatrixForm.Next();

        Budget.Close();
        GLBudgetNames.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BudgetPageShowsOnlyBalanceSheetGLAccWhenIncomeBalFilterIsBalanceSheet()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLAccount: Record "G/L Account";
        GLBudgetNames: TestPage "G/L Budget Names";
        Budget: TestPage Budget;
    begin
        // [SCENARIO 213513] Budget page shows only G/L Accounts with type "Balance Sheet" when "Income Balance G/L Account Filter" is "Balance Sheet"

        Initialize();

        CreateSetOfGLAccountsWithDiffCategoryAndIncomeBal();
        // [GIVEN] Budget "X"
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryLowerPermissions.SetFinancialReporting();

        // [GIVEN] Opened "G/L Budget Names" page and selected Budget "X"
        GLBudgetNames.OpenEdit();
        GLBudgetNames.Name.SetValue(GLBudgetName.Name);
        Budget.Trap();

        // [GIVEN] Budget page opened with "Show as Lines" = "G/L Account"
        GLBudgetNames.EditBudget.Invoke();
        Budget.LineDimCode.SetValue('G/L Account');

        // [WHEN] Set "Income Balance G/L Account Filter" = "Balance Sheet" on Budget page
        Budget.IncomeBalGLAccFilter.SetValue('Balance Sheet');

        // [THEN] Only G/L accounts with "Income/Balance" = "Balance Sheet" are shown on Budget page
        repeat
            GLAccount.Get(Budget.MatrixForm.Code.Value);
            GLAccount.TestField("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        until not Budget.MatrixForm.Next();

        Budget.Close();
        GLBudgetNames.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BudgetPageShowsOnlyIncomeGLAccWhenGLAccCategoryFilterIsIncome()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLAccount: Record "G/L Account";
        GLBudgetNames: TestPage "G/L Budget Names";
        Budget: TestPage Budget;
    begin
        // [SCENARIO 213513] Budget page shows only G/L Accounts with "Account Category" = "Income" when "G/L Account Category Filter" is "Income"

        Initialize();

        CreateSetOfGLAccountsWithDiffCategoryAndIncomeBal();
        // [GIVEN] Budget "X"
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryLowerPermissions.SetFinancialReporting();

        // [GIVEN] Opened "G/L Budget Names" page and selected Budget "X"
        GLBudgetNames.OpenEdit();
        GLBudgetNames.Name.SetValue(GLBudgetName.Name);
        Budget.Trap();

        // [GIVEN] Budget page opened with "Show as Lines" = "G/L Account"
        GLBudgetNames.EditBudget.Invoke();
        Budget.LineDimCode.SetValue('G/L Account');

        // [WHEN] Set "G/L Account Category Filter" = "Income" on Budget page
        Budget.GLAccCategory.SetValue('Income');

        // [THEN] Only G/L accounts with "Account Category" = "Income" are shown on Budget page
        repeat
            GLAccount.Get(Budget.MatrixForm.Code.Value);
            GLAccount.TestField("Account Category", GLAccount."Account Category"::Income);
        until not Budget.MatrixForm.Next();

        Budget.Close();
        GLBudgetNames.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccBalancePageInheritsFiltersFromBudgetPage()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccount: Record "G/L Account";
        GLBudgetName: Record "G/L Budget Name";
        Budget: TestPage Budget;
        GLAccountBalanceBudget: TestPage "G/L Account Balance/Budget";
        DateFilter: Text;
    begin
        // [FEATURE] [G/L Account Balance/Budget]
        // [SCENARIO 213513] "G/L Account Balance/Budget" page inherits filters from Budget page

        Initialize();

        CreateSetOfGLAccountsWithDiffCategoryAndIncomeBal();
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryLowerPermissions.SetFinancialReporting();

        // [GIVEN] Opened Budget page with "Show as Lines" = ADM (dimension), "Income Balance G/L Account Filter" = "Income Statement", "G/L Account Category Filter" = Income, "Date Filter" = "02.04.2017..27.04.2017"
        Budget.OpenEdit();
        Budget.BudgetName.SetValue(GLBudgetName.Name);
        GeneralLedgerSetup.Get();
        Budget.LineDimCode.SetValue(UpperCase(GeneralLedgerSetup."Global Dimension 1 Code"));
        Budget.IncomeBalGLAccFilter.SetValue('Income Statement');
        Budget.GLAccCategory.SetValue('Income');
        DateFilter := Format(LibraryRandom.RandDate(-10)) + '..' + Format(LibraryRandom.RandDate(10));
        Budget.DateFilter.SetValue(DateFilter);
        GLAccountBalanceBudget.Trap();

        // [WHEN] Open "G/L Account Balance/Budget" page from Budget page
        Budget.MatrixForm.GLAccBalanceBudget.Invoke();

        // [THEN] G/L account with "Income/Balance" = "Income Statement" and "Account Category" = Income is shown on "G/L Account Balance/Budget" page
        // There is no field for G/L Account No. on page "G/L Account Balance/Budget" page, only caption of the page contains No. and Name of G/L Account
        FindGLAccountByType(GLAccount, GLAccount."Account Category"::Income, GLAccount."Income/Balance"::"Income Statement");
        Assert.ExpectedMessage(GLAccount."No.", GLAccountBalanceBudget.Caption);
        Assert.ExpectedMessage(GLAccount.Name, GLAccountBalanceBudget.Caption);

        // [THEN] "Date Filter" is "02.04.2017..27.04.2017" on "G/L Account Balance/Budget" page
        GLAccountBalanceBudget.DateFilter.AssertEquals(DateFilter);

        GLAccountBalanceBudget.Close();
        Budget.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceBudgetPageInheritsFiltersFromBudgetPage()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccount: Record "G/L Account";
        GLBudgetName: Record "G/L Budget Name";
        Budget: TestPage Budget;
        GLBalanceBudget: TestPage "G/L Balance/Budget";
        DateFilter: Text;
    begin
        // [FEATURE] [G/L Balance/Budget]
        // [SCENARIO 213513] "G/L Balance/Budget" page inherits filters from Budget page

        Initialize();

        CreateSetOfGLAccountsWithDiffCategoryAndIncomeBal();
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryLowerPermissions.SetFinancialReporting();

        // [GIVEN] Opened Budget page with "Show as Lines" = ADM (dimension), "Income Balance G/L Account Filter" = "Income Statement", "G/L Account Category Filter" = Income, "Date Filter" = "02.04.2017..30.04.2017"
        Budget.OpenEdit();
        Budget.BudgetName.SetValue(GLBudgetName.Name);
        GeneralLedgerSetup.Get();
        Budget.LineDimCode.SetValue(UpperCase(GeneralLedgerSetup."Global Dimension 1 Code"));
        Budget.IncomeBalGLAccFilter.SetValue('Income Statement');
        Budget.GLAccCategory.SetValue('Income');
        DateFilter := Format(LibraryRandom.RandDate(-10)) + '..' + Format(LibraryRandom.RandDate(10));
        Budget.DateFilter.SetValue(DateFilter);
        GLBalanceBudget.Trap();

        // [WHEN] Open "G/L Balance/Budget" page from Budget page
        Budget.GLBalanceBudget.Invoke();

        // [THEN] Only G/L accounts with "Income/Balance" = "Income Statement" and "Account Category" = Income is shown on "G/L Balance/Budget" page
        repeat
            GLAccount.Get(GLBalanceBudget."No.".Value);
            GLAccount.TestField("Account Category", GLAccount."Account Category"::Income);
        until not Budget.MatrixForm.Next();

        // [THEN] "Date Filter" is "01.04.2017..C30.04.2017" on "G/L Balance/Budget" page
        GLBalanceBudget.DateFilter.AssertEquals(GetClosingMonthFilterFromDateFilter(DateFilter));

        // [THEN "G/L Account Category Filter" is Income on "G/L Balance/Budget" page
        GLBalanceBudget.GLAccCategory.AssertEquals(Budget.GLAccCategory.Value);

        // [THEN "Income Balance G/L Account Filter" is "Income Statement" on "G/L Balance/Budget" page
        GLBalanceBudget.IncomeBalGLAccFilter.AssertEquals(Budget.IncomeBalGLAccFilter.Value);

        GLBalanceBudget.Close();
        Budget.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccBalanceBudgetedDebitAmountBasedOnFilters()
    var
        GLAccount: Record "G/L Account";
        GLBudgetName: Record "G/L Budget Name";
        Budget: TestPage Budget;
        GLAccountBalanceBudget: TestPage "G/L Account Balance/Budget";
        DimValueCode: Code[20];
        ExpectedAmount: Decimal;
        DateFilter: Text;
    begin
        // [FEATURE] [G/L Account Balance/Budget]
        // [SCENARIO 213513] "Budgeted Debit Amount" calculates based on page filters on "G/L Account Balance/Budget" page

        Initialize();

        // [GIVEN] Budget "X"
        LibraryERM.CreateGLBudgetName(GLBudgetName);

        // [GIVEN] G/L Account "Y" with G/L Budget Entries for Budget "X":
        // [GIVEN] G/L Budget Entry 1 with "Posting Date" = 01.01.2017, "Global Dimension 1 Code" = "PROD", "Debit Amount" = 100
        // [GIVEN] G/L Budget Entry 1 with "Posting Date" = 01.01.2017, "Global Dimension 1 Code" = "ADM", "Debit Amount" = 110
        // [GIVEN] G/L Budget Entry 2 with "Posting Date" = 04.04.2017, "Global Dimension 1 Code" = "PROD", "Debit Amount" = 120
        // [GIVEN] G/L Budget Entry 1 with "Posting Date" = 04.04.2017, "Global Dimension 1 Code" = "ADM", "Debit Amount" = 130
        LibraryERM.CreateGLAccount(GLAccount);
        SetupGLBalBudgetBasedOnFiltersScenario(DimValueCode, DateFilter, ExpectedAmount, GLBudgetName.Name, GLAccount."No.");

        // [GIVEN] Opened "G/L Budget" page with Budget "X" and "G/L Account Filter" = "Y"
        LibraryLowerPermissions.SetFinancialReporting();
        Budget.OpenEdit();
        Budget.BudgetName.SetValue(GLBudgetName.Name);
        Budget.LineDimCode.SetValue('G/L Account');
        Budget.IncomeBalGLAccFilter.SetValue(0);
        Budget.GLAccFilter.SetValue(GLAccount."No.");

        // [GIVEN] Opened "G/L Account Balance/Budget" page from "G/L Budget" page
        GLAccountBalanceBudget.Trap();
        Budget.MatrixForm.GLAccBalanceBudget.Invoke();

        // [WHEN] Set "Date Filter" = "04.04.2017.." and "Global Dimension 1 Code" = "ADM" on "G/L Account Balance/Budget" page
        GLAccountBalanceBudget.PeriodType.SetValue('Day');
        GLAccountBalanceBudget.AmountType.SetValue('Net Change');
        GLAccountBalanceBudget.DateFilter.SetValue(DateFilter);
        GLAccountBalanceBudget.GlobalDim1Filter.SetValue(DimValueCode);

        // [THEN] "Budgeted Debit Amount" is 130 for G/L Account "Y" on "G/L Account Balance/Budget" page
        GLAccountBalanceBudget.GLBalanceLines.BudgetedDebitAmount.AssertEquals(ExpectedAmount);

        GLAccountBalanceBudget.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceBudgetedDebitAmountBasedOnFilters()
    var
        GLAccount: Record "G/L Account";
        GLBudgetName: Record "G/L Budget Name";
        Budget: TestPage Budget;
        GLBalanceBudget: TestPage "G/L Balance/Budget";
        DimValueCode: Code[20];
        ExpectedAmount: Decimal;
        DateFilter: Text;
    begin
        // [FEATURE] [G/L Account Balance/Budget]
        // [SCENARIO 213513] "Budgeted Debit Amount" calculates based on page filters on "G/L Balance/Budget" page

        Initialize();

        // [GIVEN] Budget "X"
        LibraryERM.CreateGLBudgetName(GLBudgetName);

        // [GIVEN] G/L Account "Y" with G/L Budget Entries for Budget "X":
        // [GIVEN] G/L Budget Entry 1 with "Posting Date" = 01.01.2017, "Global Dimension 1 Code" = "PROD", "Debit Amount" = 100
        // [GIVEN] G/L Budget Entry 1 with "Posting Date" = 01.01.2017, "Global Dimension 1 Code" = "ADM", "Debit Amount" = 110
        // [GIVEN] G/L Budget Entry 2 with "Posting Date" = 04.04.2017, "Global Dimension 1 Code" = "PROD", "Debit Amount" = 120
        // [GIVEN] G/L Budget Entry 1 with "Posting Date" = 04.04.2017, "Global Dimension 1 Code" = "ADM", "Debit Amount" = 130
        LibraryERM.CreateGLAccount(GLAccount);
        SetupGLBalBudgetBasedOnFiltersScenario(DimValueCode, DateFilter, ExpectedAmount, GLBudgetName.Name, GLAccount."No.");

        // [GIVEN] Opened "G/L Budget" page with Budget "X" and "G/L Account Filter" = "Y"
        LibraryLowerPermissions.SetFinancialReporting();
        Budget.OpenEdit();
        Budget.BudgetName.SetValue(GLBudgetName.Name);
        Budget.LineDimCode.SetValue('G/L Account');
        Budget.IncomeBalGLAccFilter.SetValue(0);
        Budget.GLAccFilter.SetValue(GLAccount."No.");

        // [GIVEN] Opened "G/L Balance/Budget" page from "G/L Budget" page and focus on G/L Account "Y"
        GLBalanceBudget.Trap();
        Budget.GLBalanceBudget.Invoke();
        GLBalanceBudget.FILTER.SetFilter("No.", GLAccount."No.");

        // [WHEN] Set "Date Filter" = "04.04.2017.." and "Global Dimension 1 Code" = "ADM" on "G/L Balance/Budget" page
        GLBalanceBudget.PeriodType.SetValue('Day');
        GLBalanceBudget.AmountType.SetValue('Net Change');
        GLBalanceBudget.DateFilter.SetValue(DateFilter);
        GLBalanceBudget.GlobalDim1Filter.SetValue(DimValueCode);

        // [THEN] "Budgeted Debit Amount" is 130 for G/L Account "Y" on "G/L Balance/Budget" page
        GLBalanceBudget."Budgeted Debit Amount".AssertEquals(ExpectedAmount);

        GLBalanceBudget.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceBudgetPageShowsOnlyBalanceSheetGLAccWhenIncomeBalFilterIsBalanceSheet()
    var
        GLAccount: Record "G/L Account";
        GLBalanceBudget: TestPage "G/L Balance/Budget";
    begin
        // [FEATURE] [G/L Balance/Budget]
        // [SCENARIO 213513] "G/L Balance/Budget" page shows only G/L Accounts with type "Balance Sheet" if "Income Balance G/L Account Filter" is "Balance Sheet"

        Initialize();

        CreateSetOfGLAccountsWithDiffCategoryAndIncomeBal();
        LibraryLowerPermissions.SetFinancialReporting();

        // [GIVEN] Opened "G/L Balance/Budget" page
        GLBalanceBudget.OpenEdit();

        // [WHEN] Set "Income Balance G/L Account Filter" = "Balance Sheet" on "G/L Balance/Budget" page
        GLBalanceBudget.IncomeBalGLAccFilter.SetValue('Balance Sheet');

        // [THEN] Only G/L accounts with "Income/Balance" = "Balance Sheet" are shown on "G/L Balance/Budget" page
        repeat
            GLAccount.Get(GLBalanceBudget."No.".Value);
            GLAccount.TestField("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        until (not GLBalanceBudget.Next()) or (GLBalanceBudget."No.".Value = '');

        GLBalanceBudget.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceBudgetPageShowsOnlyIncomeGLAccWhenGLAccCategoryFilterIsIncome()
    var
        GLAccount: Record "G/L Account";
        GLBalanceBudget: TestPage "G/L Balance/Budget";
    begin
        // [FEATURE] [G/L Balance/Budget]
        // [SCENARIO 213513] "G/L Balance/Budget" page shows only G/L Accounts with "Account Category" = "Income" if "G/L Account Category Filter" is "Income"

        Initialize();

        CreateSetOfGLAccountsWithDiffCategoryAndIncomeBal();
        LibraryLowerPermissions.SetFinancialReporting();

        // [GIVEN] Opened "G/L Balance/Budget" page
        GLBalanceBudget.OpenEdit();

        // [WHEN] Set "G/L Account Category Filter" = "Income" on "G/L Balance/Budget" page
        GLBalanceBudget.GLAccCategory.SetValue('Income');

        // [THEN] Only G/L accounts with "Income/Balance" = "Balance Sheet" are shown on "G/L Balance/Budget" page
        repeat
            GLAccount.Get(GLBalanceBudget."No.".Value);
            GLAccount.TestField("Account Category", GLAccount."Account Category"::Income);
        until (not GLBalanceBudget.Next()) or (GLBalanceBudget."No.".Value = '');

        GLBalanceBudget.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccBalancePageHideIncomeBalanceFieldByIncomeBalanceFilter()
    var
        GLBudgetName: Record "G/L Budget Name";
        Budget: TestPage Budget;
        GLBalanceBudget: TestPage "G/L Balance/Budget";
    begin
        // [FEATURE] [G/L Account Balance/Budget]
        // [SCENARIO 216953] "G/L Balance/Budget" page hide field "Income/Balance" depends on filter "Income/Balance G/L Account Filter"

        Initialize();

        CreateSetOfGLAccountsWithDiffCategoryAndIncomeBal();
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryLowerPermissions.SetFinancialReporting();

        // [GIVEN] Opened Budget page with "Income Balance G/L Account Filter" = "Income Statement"
        Budget.OpenEdit();
        Budget.BudgetName.SetValue(GLBudgetName.Name);
        Budget.IncomeBalGLAccFilter.SetValue('Income Statement');
        GLBalanceBudget.Trap();

        // [GIVEN] Opend "G/L Balance/Budget" page from Budget page with hidden field "Income/Balance"
        Budget.GLBalanceBudget.Invoke();
        Assert.IsFalse(GLBalanceBudget."Income/Balance".Visible(), 'Income/Balance field is visible on page G/L Balance Budget');

        // [WHEN] Blank "Income Balance G/L Account Filter" on "G/L Balance/Budget" page
        GLBalanceBudget.IncomeBalGLAccFilter.SetValue(0);

        // [THEN] Field "Income/Balance" is visible on "G/L Balance/Budget" page
        Assert.IsTrue(GLBalanceBudget."Income/Balance".Visible(), 'Income/Balance field is not visible on page G/L Balance Budget');

        GLBalanceBudget.Close();
        Budget.Close();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Budget UI");
        ClearPagesSavedValues();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Budget UI");

        LibraryERMCountryData.UpdateCalendarSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Budget UI");
    end;

    local procedure ClearPagesSavedValues()
    var
        Budget: TestPage Budget;
        GLBalanceBudget: TestPage "G/L Balance/Budget";
    begin
        Budget.OpenEdit();
        Budget.GLAccCategory.SetValue(0);
        Budget.IncomeBalGLAccFilter.SetValue(0);
        Budget.Close();

        GLBalanceBudget.OpenEdit();
        GLBalanceBudget.GLAccCategory.SetValue(0);
        GLBalanceBudget.IncomeBalGLAccFilter.SetValue(0);
        GLBalanceBudget.Close();
    end;

    local procedure SetupGLBalBudgetBasedOnFiltersScenario(var DimValueCode: Code[20]; var DateFilter: Text; var ExpectedAmount: Decimal; GLBudgetName: Code[10]; GLAccNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        ExpectedDate: Date;
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue2, GeneralLedgerSetup."Global Dimension 1 Code");
        MockGLBudgetEntry(GLAccNo, GLBudgetName, WorkDate(), DimensionValue.Code, LibraryRandom.RandDec(100, 2));
        MockGLBudgetEntry(GLAccNo, GLBudgetName, WorkDate(), DimensionValue2.Code, LibraryRandom.RandDec(100, 2));
        ExpectedDate := LibraryRandom.RandDateFrom(WorkDate(), 50);
        ExpectedAmount := LibraryRandom.RandDec(100, 2);
        MockGLBudgetEntry(GLAccNo, GLBudgetName, ExpectedDate, DimensionValue.Code, LibraryRandom.RandDec(100, 2));
        MockGLBudgetEntry(GLAccNo, GLBudgetName, ExpectedDate, DimensionValue2.Code, ExpectedAmount);
        DateFilter := StrSubstNo('%1..', ExpectedDate);
        DimValueCode := DimensionValue2.Code;
    end;

    local procedure CreateSetOfGLAccountsWithDiffCategoryAndIncomeBal()
    var
        GLAcc: Record "G/L Account";
        i: Integer;
        j: Integer;
    begin
        for i := GLAcc."Account Category"::Assets.AsInteger() to GLAcc."Account Category"::Expense.AsInteger() do
            for j := GLAcc."Income/Balance"::"Income Statement".AsInteger() to GLAcc."Income/Balance"::"Balance Sheet".AsInteger() do
                CreateGLAccountWithSetup(i, "G/L Account Report Type".FromInteger(j));
    end;

    local procedure CreateGLAccountWithSetup(AccountCategory: Option; IncomeBalance: Enum "G/L Account Report Type")
    var
        GLAcc: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAcc);
        GLAcc.Validate("Account Category", AccountCategory);
        GLAcc.Validate("Income/Balance", IncomeBalance);
        GLAcc.Modify(true);
    end;

    local procedure FindGLAccountByType(var GLAccount: Record "G/L Account"; AccountCategory: Enum "G/L Account Category"; IncomeBalance: Enum "G/L Account Report Type")
    begin
        GLAccount.Reset();
        GLAccount.SetRange("Account Category", AccountCategory);
        GLAccount.SetRange("Income/Balance", IncomeBalance);
        GLAccount.FindFirst();
    end;

    local procedure GetClosingMonthFilterFromDateFilter(DateFilter: Text): Text
    var
        Date: Record Date;
        PeriodPageManagement: Codeunit PeriodPageManagement;
    begin
        Date.SetFilter("Period Start", DateFilter);
        PeriodPageManagement.FindDate('+', Date, "Analysis Period Type"::Day);
        Date.SetRange("Period Start");
        PeriodPageManagement.FindDate('', Date, "Analysis Period Type"::Month);
        exit(StrSubstNo('%1..C%2', Date."Period Start", Date."Period End"));
    end;

    local procedure MockGLBudgetEntry(GLAccNo: Code[20]; BudgetName: Code[10]; PostingDate: Date; GlobalDimension1Code: Code[20]; EntryAmount: Decimal)
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry.Init();
        GLBudgetEntry."Entry No." := LibraryUtility.GetNewRecNo(GLBudgetEntry, GLBudgetEntry.FieldNo("Entry No."));
        GLBudgetEntry."G/L Account No." := GLAccNo;
        GLBudgetEntry.Date := PostingDate;
        GLBudgetEntry."Global Dimension 1 Code" := GlobalDimension1Code;
        GLBudgetEntry.Amount := EntryAmount;
        GLBudgetEntry."Budget Name" := BudgetName;
        GLBudgetEntry.Insert();
    end;
}

