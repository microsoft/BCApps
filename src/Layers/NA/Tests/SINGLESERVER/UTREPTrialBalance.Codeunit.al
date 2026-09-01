codeunit 141013 "UT REP Trial Balance"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Trial Balance] [Reports]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        ColumnHeadCap: Label 'ColumnHead1';
        DialogErr: Label 'Dialog';
        GLFilterCap: Label 'GLFilter';
        SubTitleCap: Label 'SubTitle';
        SubTitleFilterTxt: Label '%1 %2';
        AmountFilterTxt: Label 'Amounts are in %1';
        PeriodTextCap: Label 'PeriodText';
        SourceNameCap: Label 'SourceName';
        ChangesFromTxt: Label 'Changes from ';
        AsOfTxt: Label 'As of ';
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";
        TurnOverCalculationErr: Label 'Total turnover calculation is not correct';
        TotalBalanceAtDateErr: Label 'Total balance at date is wrong';

    [Test]
    [HandlerFunctions('TrialBalanceDetailSummaryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportTrialBalanceDetailSummary()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10021 Trial Balance Detail/Summary.
        // Setup.
        Initialize();
        CreateGLEntry(GLEntry, CreateGLAccount(), '', GLEntry."Source Type");

        // Exercise.
        REPORT.Run(REPORT::"Trial Balance Detail/Summary");  // Opens TrialBalanceDetailSummaryRequestPageHandler

        // Verify: Verify Filters on G/L Account, PeriodText, Debit and Credit Amount on Report Trial Balance Detail/Summary.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLFilterCap, StrSubstNo('%1: %2', GLAccount.FieldCaption("No."), GLEntry."G/L Account No."));
        LibraryReportDataset.AssertElementWithValueExists(PeriodTextCap, StrSubstNo('Includes Activities from %1 to %2', Format(WorkDate(), 0, 4), Format(WorkDate(), 0, 4)));
        LibraryReportDataset.AssertElementWithValueExists('DebitAmount_GLAccount', GLEntry."Debit Amount");
        LibraryReportDataset.AssertElementWithValueExists('CreditAmount_GLAccount', GLEntry."Credit Amount");
    end;

    [Test]
    [HandlerFunctions('RPHTrialBalanceDetailSummaryTotals')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TrialBalanceDetailSummaryTotals()
    var
        GLEntry: Record "G/L Entry";
        Index: Integer;
        "Count": Integer;
        Found: Boolean;
        EndBalance: Decimal;
        StartBalance: Decimal;
        CreditTurnover: Decimal;
        DebitTurnover: Decimal;
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10021 Trial Balance Detail/Summary.
        // Setup.
        Initialize();
        Count := LibraryRandom.RandIntInRange(5, 10);
        LibraryVariableStorage.Enqueue(Count);
        for Index := 1 to Count do
            CreateGLEntry(GLEntry, CreateGLAccount(), '', GLEntry."Source Type");

        // Exercise.
        REPORT.Run(REPORT::"Trial Balance Detail/Summary");  // Opens RPHTrialBalanceDetailSummaryTotals

        // Verify: Report totals
        // Row Index = 12 (Rows for header) + Count (Account rows) + 1 (Total row) = 13 + Count
        // Beginning Balance Column = 8
        // Debit  Column = 9
        // Credit Column = 10
        // Endinning Balance Column = 12
        Index := 13 + Count;
        Evaluate(EndBalance, LibraryReportValidation.GetValueAt(Found, Index, 12));
        Evaluate(StartBalance, LibraryReportValidation.GetValueAt(Found, Index, 8));
        Evaluate(DebitTurnover, LibraryReportValidation.GetValueAt(Found, Index, 9));
        Evaluate(CreditTurnover, LibraryReportValidation.GetValueAt(Found, Index, 10));
        Assert.IsTrue((CreditTurnover > 0) or (DebitTurnover > 0), TurnOverCalculationErr);
        Assert.AreEqual(StartBalance + DebitTurnover - CreditTurnover, EndBalance, TotalBalanceAtDateErr);
    end;

    [Test]
    [HandlerFunctions('TrialBalanceDetailSummaryUseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerTrialBalDetailSummary()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        CurrencyDescription: Text[30];
    begin
        // Purpose of the test is to validate G/L Entry -OnAfterGetRecord Trigger of Report ID - 10021 Trial Balance Detail/Summary.
        // Setup.
        Initialize();
        CreateGLEntry(GLEntry, CreateGLAccount(), CreateCustomer(), GLEntry."Source Type"::Customer);
        CurrencyDescription := UpdateGLSetupDimensionsAndAddReportingCurrency('', '');   // Global Dimensions Blank.

        // Exercise.
        REPORT.Run(REPORT::"Trial Balance Detail/Summary");  // Opens TrialBalanceDetailSummaryUseAddRptCurrRequestPageHandler.

        // Verify: Verify Source Name is updated with Customer Name and SubTitle on Report Trial Balance Detail/Summary.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SourceNameCap, GLEntry."Source No.");
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, StrSubstNo(SubTitleFilterTxt, 'Amounts are in', CurrencyDescription));
    end;

    [Test]
    [HandlerFunctions('TrialBalanceDetailSummaryUseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorTrialBalDetailSummary()
    var
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate G/L Entry -OnAfterGetRecord Trigger of Report ID - 10021 Trial Balance Detail/Summary.

        // Setup:  Test to verify Source Name is updated with Vendor Name on Report Trial Balance Detail/Summary.
        Initialize();
        OnAfterGetRecordGLEntryTrialBalDetailSummary(CreateVendor(), GLEntry."Source Type"::Vendor);
    end;

    [Test]
    [HandlerFunctions('TrialBalanceDetailSummaryUseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordFixedAssetTrialBalDetailSummary()
    var
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate G/L Entry -OnAfterGetRecord Trigger of Report ID - 10021 Trial Balance Detail/Summary.

        // Setup: Test to verify Source Name is updated with Fixed Asset Description on Report Trial Balance Detail/Summary.
        Initialize();
        OnAfterGetRecordGLEntryTrialBalDetailSummary(CreateFixedAsset(), GLEntry."Source Type"::"Fixed Asset");
    end;

    [Test]
    [HandlerFunctions('TrialBalanceDetailSummaryUseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccTrialBalDetailSummary()
    var
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate G/L Entry -OnAfterGetRecord Trigger of Report ID - 10021 Trial Balance Detail/Summary.

        // Setup: Test to verify Source Name is updated with Bank Account Name on Report Trial Balance Detail/Summary.
        Initialize();
        OnAfterGetRecordGLEntryTrialBalDetailSummary(CreateBankAccount(), GLEntry."Source Type"::"Bank Account");
    end;

    [Test]
    [HandlerFunctions('TrialBalanceDetailSummaryUseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordEmployeeTrialBalDetailSummary()
    var
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate G/L Entry -OnAfterGetRecord Trigger of Report ID - 10021 Trial Balance Detail/Summary.

        // Setup: Test to verify Source Name is updated with Employee Last Name on Report Trial Balance Detail/Summary.
        Initialize();
        OnAfterGetRecordGLEntryTrialBalDetailSummary(CreateEmployee, GLEntry."Source Type"::Employee);
    end;

    local procedure OnAfterGetRecordGLEntryTrialBalDetailSummary(SourceNo: Code[20]; SourceType: Option)
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        CreateGLEntry(GLEntry, CreateGLAccount(), SourceNo, SourceType);
        UpdateGLSetupDimensionsAndAddReportingCurrency('', '');  // Global Dimensions Blank.

        // Exercise.
        REPORT.Run(REPORT::"Trial Balance Detail/Summary");  // Opens TrialBalanceDetailSummaryUseAddRptCurrRequestPageHandler.

        // Verify: Verify Source Name is updated for different Source Type on Report Trial Balance Detail/Summary.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SourceNameCap, GLEntry."Source No.");
    end;

    [Test]
    [HandlerFunctions('TrialBalaneUseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportTrialBalance()
    var
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
        Show: Option "Last Year",Budget;
        CurrencyDescription: Text[30];
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10022 Trial Balance.
        // Setup.
        Initialize();
        GLAccountNo := CreateGLAccount();
        CurrencyDescription := UpdateGLSetupDimensionsAndAddReportingCurrency('', '');  // Global Dimensions Blank.
        LibraryVariableStorage.Enqueue(Show::Budget);  // Required inside TrialBalaneUseAddRptCurrRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Trial Balance");  // Opens TrialBalaneUseAddRptCurrRequestPageHandler

        // Verify: Verify Filter on G/L Account, Period text and SubTitle on Report Trial Balance.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('GLAccountFilter', StrSubstNo('%1: %2', GLAccount.FieldCaption("No."), GLAccountNo));
        LibraryReportDataset.AssertElementWithValueExists(PeriodTextCap, StrSubstNo('Changes and Budgeted Changes from %1 %2 %3', Format(WorkDate(), 0, 4), 'to', Format(WorkDate(), 0, 4)));
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, StrSubstNo('Amounts are in %1', CurrencyDescription));
    end;

    [Test]
    [HandlerFunctions('TrialBalaneUseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportUseAddRptCurrencyTrialBalance()
    var
        GLAccount: Record "G/L Account";
        Show: Option "Last Year",Budget;
        PeriodText: Text;
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10022 Trial Balance.
        // Setup.
        Initialize();
        CreateGLAccount();
        UpdateGLSetupDimensionsAndAddReportingCurrency('', '');  // Global Dimensions Blank.
        LibraryVariableStorage.Enqueue(Show::"Last Year");  // Required inside TrialBalaneUseAddRptCurrRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Trial Balance");  // Opens TrialBalaneUseAddRptCurrRequestPageHandler.

        // Verify: Verify Period Text on Report Trial Balance.
        PeriodText := StrSubstNo('Changes from %1 %2 %3 %4 %5 %6 %7', Format(WorkDate(), 0, 4), 'to', Format(WorkDate(), 0, 4), 'and from', Format(CalcDate('<-1Y>', WorkDate() + 1) - 1, 0, 4), 'to', Format(CalcDate('<-1Y>', WorkDate() + 1) - 1, 0, 4));
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PeriodTextCap, PeriodText);  // Calculation based on General Ledger Account filter - WORKDATE.
    end;

    [Test]
    [HandlerFunctions('TrialBalaneRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportShowBudgetTrialBalance()
    var
        Show: Option "Last Year",Budget;
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10022 Trial Balance.

        // Setup: Test to verify Period Text on Report Trial Balance.
        Initialize();
        OnPreReportShowTrialBalance(Show::Budget, StrSubstNo('Actual vs Budget as of %1', Format(WorkDate(), 0, 4)));  // Calculation based on General Ledger Account filter - WORKDATE.
    end;

    [Test]
    [HandlerFunctions('TrialBalaneRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportShowLastYearTrialBalance()
    var
        Show: Option "Last Year",Budget;
        PeriodText: Text;
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10022 Trial Balance.

        // Setup: Test to verify Period Text on Report Trial Balance.
        Initialize();
        PeriodText := StrSubstNo('As of %1 %2 %3', Format(WorkDate(), 0, 4), 'and', Format(Date2DMY(CalcDate('<-1Y>', WorkDate() + 1) - 1, 3)));  // Calculation based on General Ledger Account filter - WORKDATE.
        OnPreReportShowTrialBalance(Show::"Last Year", PeriodText);
    end;

    local procedure OnPreReportShowTrialBalance(Show: Option; PeriodText: Text[120])
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccount();
        LibraryVariableStorage.Enqueue(Show);  // Required inside TrialBalanceDetailSummaryRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Trial Balance");  // Opens TrialBalanceDetailSummaryRequestPageHandler.

        // Verify: Verify Period Text on Report Trial Balance.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PeriodTextCap, PeriodText);
    end;

    [Test]
    [HandlerFunctions('BudgetFromHistoryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemHistoryBeginDateBudgetFromHistoryError()
    begin
        // Purpose of the test is to validate G/L Account -OnPreDataItem Trigger of Report ID - 10022 Trial Balance.

        // Setup: Test to verify Error Code, Actual error: Please enter a beginning date for the history.
        Initialize();
        OnPreDataItemGLAccBudgetFromHistory(0D, 0D);  // HistoryBeginningDate - 0D, BudgetBeginningDate -0D.
    end;

    [Test]
    [HandlerFunctions('BudgetFromHistoryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemBeginDateBudgetFromHistoryError()
    begin
        // Purpose of the test is to validate G/L Account -OnPreDataItem Trigger of Report ID - 10022 Trial Balance.

        // Setup: Test to verify Error Code, Actual error: Please enter a beginning date for the budget.
        Initialize();
        OnPreDataItemGLAccBudgetFromHistory(WorkDate(), 0D);  // HistoryBeginningDate - WorkDate(), BudgetBeginningDate -0D.
    end;

    [Test]
    [HandlerFunctions('BudgetFromHistoryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemPeriodsBudgetFromHistoryError()
    begin
        // Purpose of the test is to validate G/L Account -OnPreDataItem Trigger of Report ID - 10022 Trial Balance.

        // Setup: Test to verify Error Code, Actual error: Please enter the number of periods to budget.
        Initialize();
        OnPreDataItemGLAccBudgetFromHistory(WorkDate(), WorkDate());  // HistoryBeginningDate - WorkDate(), BudgetBeginningDate - WORKDATE.
    end;

    local procedure OnPreDataItemGLAccBudgetFromHistory(HistoryBeginningDate: Date; BudgetBeginningDate: Date)
    begin
        // Required inside BudgetFromHistoryRequestPageHandler.
        LibraryVariableStorage.Enqueue(HistoryBeginningDate);
        LibraryVariableStorage.Enqueue(BudgetBeginningDate);
        LibraryVariableStorage.Enqueue(0);   // Period Length - 0.

        // Exercise.
        asserterror REPORT.Run(REPORT::"Budget from History");  // Opens BudgetFromHistoryRequestPageHandler.

        // Verify: Verify Error Code, Actual error: Please enter the beginning date for History, Budget and number of periods to budget.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('BudgetFromHistoryWithRoundingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordIntegerGLAccountBudgetFromHistory()
    var
        RoundingTo: Option ,Pennies,Dollars,Hundreds,Thousands,Millions;
        GLBudgetEntry: Record "G/L Budget Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountNo: Code[20];
    begin
        // Purpose of the test is to validate Integer-OnAfterGetRecord Trigger of Report ID - 10022 Trial Balance.
        // Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        GLAccountNo := CreateGLAccountWithDimensions(GeneralLedgerSetup."Global Dimension 1 Code", GeneralLedgerSetup."Global Dimension 2 Code");
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(1);  // Period Length - 1.
        LibraryVariableStorage.Enqueue(RoundingTo::Pennies);  // Required inside BudgetFromHistoryRoundingToRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Budget from History");  // Opens BudgetFromHistoryRoundingToRequestPageHandler.

        // Verify: Verify G/L Budget Entry created for G/L Account.
        GLBudgetEntry.SetRange("G/L Account No.", GLAccountNo);
        GLBudgetEntry.FindFirst();
        GLBudgetEntry.TestField(Date, WorkDate());  // Date related to Budget Beginning Date.
    end;

    [Test]
    [HandlerFunctions('TrialBalancePerGlobalDimensionCodeRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnOpenPageTrialBalancePerGlobalDimError()
    begin
        // Purpose of the test is to validate OnOpenPage Trigger of Report ID - 10023 Trial Balance, per Global Dim.
        // Setup.
        Initialize();
        OnOpenPageGlobalDimensions(REPORT::"Trial Balance, per Global Dim.");
    end;

    [Test]
    [HandlerFunctions('TrialBalanceSpreadGlobalDimensionCodeRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnOpenPageTrialBalanceSpreadGDimError()
    begin
        // Purpose of the test is to validate OnOpenPage Trigger of Report ID - 10025 Trial Balance, Spread G. Dim.
        // Setup.
        Initialize();
        OnOpenPageGlobalDimensions(REPORT::"Trial Balance, Spread G. Dim.");
    end;

    local procedure OnOpenPageGlobalDimensions(ReportID: Integer)
    begin
        // Updated General Ledger Setup with blank Global Dimension.
        UpdateGLSetupDimensionsAndAddReportingCurrency('', '');  // Blank value for Global Dimension 1 Code and Global Dimension 2 Code.

        // Exercise.
        asserterror REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Actual Error Code: There are no Global Dimensions set up in General Ledger Setup. This report can only be used with Global Dimensions.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('TrialBalancePerGlobalDimensionCodeRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportTrialBalancePerGlobalDimError()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10023 Trial Balance, per Global Dim.

        // Setup: Create Dimension.
        Initialize();
        CreateDimension();

        // Exercise.
        asserterror REPORT.Run(REPORT::"Trial Balance, per Global Dim.");  // Opens TrialBalancePerGlobalDimensionErrorRequestPageHandler.

        // Verify: Verify Actual Error Code - Validation error for Field:DimCode,  Message = 'You must select a Global Dimension that has been set up in General Ledger Setup.'
        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    [HandlerFunctions('TrialBalancePerGlobalDimensionRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportTrialBalancePerGlobalDim()
    var
        GLAccountNo: Code[20];
        DimensionValueCode: Code[20];
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10023 Trial Balance, per Global Dim.

        // Setup: Create Dimension, Dimension Value, General Ledger and update General Ledger Setup.
        Initialize();
        DimensionValueCode := CreateDimensionValue;
        UpdateGLSetupDimensionsAndAddReportingCurrency('', DimensionValueCode);  // Blank value for Global Dimension 1 Code and Currency code.
        GLAccountNo := CreateGLAccountWithDimensions('', DimensionValueCode);  // Blank value for Global Dimension 1 Code.

        // Exercise: Set ActualBalance, ComparisonBalances as True on TrialBalancePerGlobalDimensionRequestPageHandler.
        REPORT.Run(REPORT::"Trial Balance, per Global Dim.");

        // Verify: Verify Dimension Code, General Ledger Account on Report - Trial Balance, per Global Dim.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DimCode_DimValue', DimensionValueCode);
        LibraryReportDataset.AssertElementWithValueExists('GLAcccountNo', GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('TrialBalancePerGlobalDimensionLastYearRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportShowComparisonLastYearTrialBalancePerGlobalDim()
    var
        DimensionValueCode: Code[20];
        CurrencyDescription: Text[30];
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10023 Trial Balance, per Global Dim.

        // Setup: Create Dimension, Dimension Value, General Ledger and update General Ledger Setup.
        Initialize();
        DimensionValueCode := CreateDimensionValue;
        CurrencyDescription := UpdateGLSetupDimensionsAndAddReportingCurrency(DimensionValueCode, '');  // Blank value for Global Dimension 2 Code.
        CreateGLAccountWithDimensions(DimensionValueCode, '');  // Blank value for Global Dimension 2 Code.


        // Exercise: Set Actual Change, Use Additional Reporting Currency, Variance in Change as True and Round To option - Dollars on TrialBalancePerGlobalDimensionLastYearRequestPageHandler.
        REPORT.Run(REPORT::"Trial Balance, per Global Dim.");

        // Verify: Verify Column head 1, Column head 2 and SubTitle on Report - Trial Balance, per Global Dim.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ColumnHeadCap, 'Net Change');
        LibraryReportDataset.AssertElementWithValueExists('ColumnHead2', 'Change Variance');
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, StrSubstNo(AmountFilterTxt, CurrencyDescription));
    end;

    [Test]
    [HandlerFunctions('TrialBalancePerGlobalDimensionBudgetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportShowComparisonBudgetTrialBalancePerGlobalDim()
    var
        DimensionValueCode: Code[20];
        CurrencyDescription: Text[30];
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10023 Trial Balance, per Global Dim.

        // Setup: Create Dimension, Dimension Value, General Ledger and update General Ledger Setup.
        Initialize();
        DimensionValueCode := CreateDimensionValue;
        CurrencyDescription := UpdateGLSetupDimensionsAndAddReportingCurrency(DimensionValueCode, DimensionValueCode);
        CreateGLAccountWithDimensions(DimensionValueCode, DimensionValueCode);

        // Exercise: Set Comparison Change, Use Additional Reporting Currency as True and Show Comparison option - Budget, Round To - Thousands on TrialBalancePerGlobalDimensionBudgetRequestPageHandler.
        REPORT.Run(REPORT::"Trial Balance, per Global Dim.");

        // Verify: Verify SubTitle and Column Head 1 on Report - Trial Balance, per Global Dim.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ColumnHeadCap, 'Budgeted, Net Change (Thousands)');
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, StrSubstNo(AmountFilterTxt, CurrencyDescription));
    end;

    [Test]
    [HandlerFunctions('TrialBalanceSpreadGlobalDimensionRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportActualChangeTrialBalanceSpreadGDim()
    var
        AmountType: Option "Actual Change","Budget Change","Last Year Change","Actual Balance","Budget Balance","Last Year Balance";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10025 Trial Balance, Spread G. Dim.
        // Setup.
        Initialize();
        OnPreReportAmountTypeTrialBalanceSpreadGDim(AmountType::"Actual Change", ChangesFromTxt + Format(WorkDate(), 0, 4) + ' to ' + Format(WorkDate(), 0, 4));  // Calculation based on General Ledger Account filter - WORKDATE.
    end;

    [Test]
    [HandlerFunctions('TrialBalanceSpreadGlobalDimensionRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportBudgetChangeTrialBalanceSpreadGDim()
    var
        AmountType: Option "Actual Change","Budget Change","Last Year Change","Actual Balance","Budget Balance","Last Year Balance";
        PeriodText: Text;
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10025 Trial Balance, Spread G. Dim.

        // Setup: Calculation based on General Ledger Account filter - WORKDATE.
        Initialize();
        PeriodText := 'Budgeted Changes from ' + Format(WorkDate(), 0, 4) + ' to ' + Format(WorkDate(), 0, 4);
        OnPreReportAmountTypeTrialBalanceSpreadGDim(AmountType::"Budget Change", PeriodText);  // Calculation based on General Ledger Account filter - WORKDATE.
    end;

    [Test]
    [HandlerFunctions('TrialBalanceSpreadGlobalDimensionRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportLastYearChangeTrialBalanceSpreadGDim()
    var
        AmountType: Option "Actual Change","Budget Change","Last Year Change","Actual Balance","Budget Balance","Last Year Balance";
        PeriodText: Text;
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10025 Trial Balance, Spread G. Dim.

        // Setup: Calculation based on General Ledger Account filter - WORKDATE.
        Initialize();
        PeriodText := ChangesFromTxt + Format(CalcDate('<-1Y>', WorkDate() + 1) - 1, 0, 4) + ' to ' + Format(CalcDate('<-1Y>', WorkDate() + 1) - 1, 0, 4);
        OnPreReportAmountTypeTrialBalanceSpreadGDim(AmountType::"Last Year Change", PeriodText);
    end;

    [Test]
    [HandlerFunctions('TrialBalanceSpreadGlobalDimensionRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportActualBalanceTrialBalanceSpreadGDim()
    var
        AmountType: Option "Actual Change","Budget Change","Last Year Change","Actual Balance","Budget Balance","Last Year Balance";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10025 Trial Balance, Spread G. Dim.
        // Setup.
        Initialize();
        OnPreReportAmountTypeTrialBalanceSpreadGDim(AmountType::"Actual Balance", AsOfTxt + Format(WorkDate(), 0, 4));  // Calculation based on General Ledger Account filter - WORKDATE.
    end;

    [Test]
    [HandlerFunctions('TrialBalanceSpreadGlobalDimensionRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportBudgetBalanceTrialBalanceSpreadGDim()
    var
        AmountType: Option "Actual Change","Budget Change","Last Year Change","Actual Balance","Budget Balance","Last Year Balance";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10025 Trial Balance, Spread G. Dim.
        // Setup.
        Initialize();
        OnPreReportAmountTypeTrialBalanceSpreadGDim(AmountType::"Budget Balance", 'Budget as of ' + Format(WorkDate(), 0, 4));  // Calculation based on General Ledger Account filter - WORKDATE.
    end;

    [Test]
    [HandlerFunctions('TrialBalanceSpreadGlobalDimensionRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportLastYearBalanceTrialBalanceSpreadGDim()
    var
        AmountType: Option "Actual Change","Budget Change","Last Year Change","Actual Balance","Budget Balance","Last Year Balance";
        PeriodText: Text;
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10025 Trial Balance, Spread G. Dim.
        // Setup.
        Initialize();
        PeriodText := AsOfTxt + Format(CalcDate('<-1Y>', WorkDate() + 1) - 1, 0, 4);
        OnPreReportAmountTypeTrialBalanceSpreadGDim(AmountType::"Last Year Balance", PeriodText);  // Calculation based on General Ledger Account filter - WORKDATE.
    end;

    local procedure OnPreReportAmountTypeTrialBalanceSpreadGDim(AmountType: Option; PeriodValue: Text)
    var
        GLAccountNo: Code[20];
        DimensionValueCode: Code[20];
        CurrencyDescription: Text[30];
    begin
        // Create Dimension, Dimension Value, General Ledger and update General Ledger Setup.
        DimensionValueCode := CreateDimensionValue;
        CurrencyDescription := UpdateGLSetupDimensionsAndAddReportingCurrency('', DimensionValueCode);  // Blank value for Global Dimension 1 Code and Currency code.
        GLAccountNo := CreateGLAccountWithDimensions('', DimensionValueCode);  // Blank value for Global Dimension 1 Code.
        LibraryVariableStorage.Enqueue(AmountType); // Enqueue Amount Type in TrialBalanceSpreadGlobalDimensionRequestPageHandler.

        // Exercise: Set Amount Type option on TrialBalanceSpreadGlobalDimensionRequestPageHandler.
        REPORT.Run(REPORT::"Trial Balance, Spread G. Dim.");

        // Verify: Verify Sub Title, Period Text and General Ledger Account number on Report - Trial Balance, Spread G. Dim.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, StrSubstNo(AmountFilterTxt, CurrencyDescription));
        LibraryReportDataset.AssertElementWithValueExists(PeriodTextCap, PeriodValue);
        LibraryReportDataset.AssertElementWithValueExists('G_L_Account_No_', GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('TrialBalanceSpreadPeriodsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportActualChangeTrialBalanceSpreadPeriods()
    var
        AmountType: Option "Actual Change","Budget Change","Last Year Change","Actual Balance","Budget Balance","Last Year Balance";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10026 Trial Balance, Spread Periods.
        // Setup.
        Initialize();
        OnPreReportAmountTypeTrialBalanceSpreadPeriods(AmountType::"Actual Change", 'Net Changes');  // Net Changes as Amount Text on Report - Trial Balance, Spread Periods.
    end;

    [Test]
    [HandlerFunctions('TrialBalanceSpreadPeriodsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportBudgetedChangesTrialBalanceSpreadPeriods()
    var
        AmountType: Option "Actual Change","Budget Change","Last Year Change","Actual Balance","Budget Balance","Last Year Balance";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10026 Trial Balance, Spread Periods.
        // Setup.
        Initialize();
        OnPreReportAmountTypeTrialBalanceSpreadPeriods(AmountType::"Budget Change", 'Budgeted Changes');  // Budgeted Changes as Amount Text on Report - Trial Balance, Spread Periods.
    end;

    [Test]
    [HandlerFunctions('TrialBalanceSpreadPeriodsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportActualBalanceTrialBalanceSpreadPeriods()
    var
        AmountType: Option "Actual Change","Budget Change","Last Year Change","Actual Balance","Budget Balance","Last Year Balance";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10026 Trial Balance, Spread Periods.
        // Setup.
        Initialize();
        OnPreReportAmountTypeTrialBalanceSpreadPeriods(AmountType::"Actual Balance", 'Balances');  // Balances as Amount Text on Report - Trial Balance, Spread Periods.
    end;

    [Test]
    [HandlerFunctions('TrialBalanceSpreadPeriodsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportBudgetBalanceTrialBalanceSpreadPeriods()
    var
        AmountType: Option "Actual Change","Budget Change","Last Year Change","Actual Balance","Budget Balance","Last Year Balance";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10026 Trial Balance, Spread Periods.
        // Setup.
        Initialize();
        OnPreReportAmountTypeTrialBalanceSpreadPeriods(AmountType::"Budget Balance", 'Budgeted Balances');  // Budgeted Balances as Amount Text on Report - Trial Balance, Spread Periods.
    end;

    local procedure OnPreReportAmountTypeTrialBalanceSpreadPeriods(AmountType: Option; AmountValue: Text)
    var
        GLAccount: Record "G/L Account";
        CurrencyDescription: Text[30];
        GLAccountNo: Code[20];
    begin
        // Create G/L Setup with Additional Reporting Currency.
        GLAccountNo := CreateGLAccount();
        CurrencyDescription := UpdateGLSetupDimensionsAndAddReportingCurrency('', '');  // Global Dimensions Blank.
        LibraryVariableStorage.Enqueue(AmountType); // Enqueue Amount Type in TrialBalanceSpreadPeriodsRequestPageHandler.

        // Exercise: Set Amount Type on TrialBalanceSpreadGlobalDimensionRequestPageHandler.
        REPORT.Run(REPORT::"Trial Balance, Spread Periods");

        // Verify: Verify Sub Title, Amount Text and General Ledger Account number on Report - Trial Balance, Spread Periods.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, StrSubstNo(AmountFilterTxt, CurrencyDescription));
        LibraryReportDataset.AssertElementWithValueExists('AmountText', AmountValue);
        LibraryReportDataset.AssertElementWithValueExists('No_GLAccount', GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGeneralJournalTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate General Journal Line - OnAfterGetRecord Trigger of Report ID - 2, General Journal - Test.

        // Setup: Create General Journal Line.
        Initialize();
        CreateGeneralJournalLine(GenJournalLine);

        // Exercise.
        REPORT.Run(REPORT::"General Journal - Test");  // Opens GeneralJournalTestRequestPageHandler.

        // Verify: Verify Journal Batch Name, Amount LCY and Balance LCY on Report - General Journal - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('JnlBatchName_GenJnlLine', GenJournalLine."Journal Batch Name");
        LibraryReportDataset.AssertElementWithValueExists('AmountLCY', GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('BalanceLCY', GenJournalLine.Amount);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateDimensionValue(): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue."Dimension Code" := CreateDimension();
        DimensionValue.Code := LibraryUTUtility.GetNewCode();
        DimensionValue.Insert();
        exit(DimensionValue."Dimension Code");
    end;

    local procedure CreateDimension(): Code[20]
    var
        Dimension: Record Dimension;
    begin
        Dimension.Code := LibraryUTUtility.GetNewCode();
        Dimension.Insert();
        LibraryVariableStorage.Enqueue(Dimension.Code);  // Required inside multiple RequestPageHandlers
        exit(Dimension.Code);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount.Insert();
        LibraryVariableStorage.Enqueue(GLAccount."No.");  // Required inside multiple RequestPageHandlers.
        exit(GLAccount."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Name := Vendor."No.";
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Name := Customer."No.";
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount.Name := BankAccount."No.";
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset."No." := LibraryUTUtility.GetNewCode();
        FixedAsset.Description := FixedAsset."No.";
        FixedAsset.Insert();
        exit(FixedAsset."No.");
    end;

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; SourceNo: Code[20]; SourceType: Option)
    var
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."IC Partner Code" := LibraryUTUtility.GetNewCode();
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Debit Amount" := 0;
        GLEntry."Credit Amount" := 0;
        GLEntry.Amount := LibraryRandom.RandDec(10, 2);
        if LibraryRandom.RandInt(10) > 5 then
            GLEntry.Amount := -GLEntry.Amount;
        GLEntry."Additional-Currency Amount" := LibraryRandom.RandDec(10, 2);
        if GLEntry.Amount < 0 then
            GLEntry."Credit Amount" := Abs(GLEntry.Amount)
        else
            GLEntry."Debit Amount" := GLEntry.Amount;
        GLEntry."Posting Date" := WorkDate();
        GLEntry."Source Type" := SourceType;
        GLEntry."Source No." := SourceNo;
        GLEntry.Insert();
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Description := Currency.Code;
        Currency.Insert();
        exit(Currency.Code);
    end;

    local procedure CreateEmployee(): Code[20]
    var
        Employee: Record Employee;
    begin
        Employee."No." := LibraryUTUtility.GetNewCode();
        Employee."Last Name" := Employee."No.";
        Employee.Insert();
        exit(Employee."No.");
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate.Insert();
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Insert();
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Line No." := LibraryRandom.RandInt(10);
        GenJournalLine."Account Type" := GenJournalLine."Account Type";
        GenJournalLine.Amount := LibraryRandom.RandDec(10, 2);
        GenJournalLine.Insert();

        // Enqueue value for Request Page Handler - GeneralJournalTestRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
    end;

    local procedure CreateGLAccountWithDimensions(GlobalDimension1Code: Code[20]; GlobalDimension2Code: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(CreateGLAccount);
        GLAccount."Global Dimension 1 Code" := GlobalDimension1Code;
        GLAccount."Global Dimension 2 Code" := GlobalDimension2Code;
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure FilterOnReportTrialBalancePerGlobalDimension(var TrialBalancePerGlobalDim: TestRequestPage "Trial Balance, per Global Dim.")
    var
        DimCode: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimCode);
        LibraryVariableStorage.Dequeue(No);
        TrialBalancePerGlobalDim."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        TrialBalancePerGlobalDim."G/L Account".SetFilter("No.", No);
        TrialBalancePerGlobalDim.DimCode.SetValue(DimCode);
    end;

    local procedure FilterOnTrialBalaneRequestPage(TrialBalance: TestRequestPage "Trial Balance")
    var
        No: Variant;
        Show: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(Show);
        TrialBalance."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        TrialBalance."G/L Account".SetFilter("No.", No);
        TrialBalance.ActualChange.SetValue(true);
        TrialBalance.ShowComaprison.SetValue(Show);
    end;

    local procedure FilterOnBudgetFromHistoryRequestPage(BudgetFromHistory: TestRequestPage "Budget from History")
    var
        HistoryBeginningDate: Variant;
        BudgetBeginningDate: Variant;
        NoOfPeriods: Variant;
    begin
        LibraryVariableStorage.Dequeue(HistoryBeginningDate);
        LibraryVariableStorage.Dequeue(BudgetBeginningDate);
        LibraryVariableStorage.Dequeue(NoOfPeriods);
        BudgetFromHistory.HistoryBeginningDate.SetValue(HistoryBeginningDate);
        BudgetFromHistory.BudgetBeginningDate.SetValue(BudgetBeginningDate);
        BudgetFromHistory.NoOfPeriods.SetValue(NoOfPeriods);
    end;

    local procedure UpdateGLSetupDimensionsAndAddReportingCurrency(GlobalDimension1Code: Code[20]; GlobalDimension2Code: Code[20]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Global Dimension 1 Code" := GlobalDimension1Code;
        GeneralLedgerSetup."Global Dimension 2 Code" := GlobalDimension2Code;
        GeneralLedgerSetup."Additional Reporting Currency" := CreateCurrency();
        GeneralLedgerSetup.Modify();
        exit(GeneralLedgerSetup."Additional Reporting Currency");
    end;

    local procedure SaveAsXMLTrialBalanceDetailReport(TrialBalanceDetailSummary: TestRequestPage "Trial Balance Detail/Summary")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        TrialBalanceDetailSummary."G/L Account".SetFilter("No.", No);
        TrialBalanceDetailSummary."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        TrialBalanceDetailSummary.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalancePerGlobalDimensionCodeRequestPageHandler(var TrialBalancePerGlobalDim: TestRequestPage "Trial Balance, per Global Dim.")
    var
        DimCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimCode);
        TrialBalancePerGlobalDim.DimCode.SetValue(DimCode);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalanceSpreadGlobalDimensionCodeRequestPageHandler(var TrialBalanceSpreadGDim: TestRequestPage "Trial Balance, Spread G. Dim.")
    var
        DimCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimCode);
        TrialBalanceSpreadGDim.DimCode.SetValue(DimCode);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalancePerGlobalDimensionRequestPageHandler(var TrialBalancePerGlobalDim: TestRequestPage "Trial Balance, per Global Dim.")
    begin
        FilterOnReportTrialBalancePerGlobalDimension(TrialBalancePerGlobalDim);
        TrialBalancePerGlobalDim.ActualBalance.SetValue(true);
        TrialBalancePerGlobalDim.ComparisonBalances.SetValue(true);
        TrialBalancePerGlobalDim.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalancePerGlobalDimensionLastYearRequestPageHandler(var TrialBalancePerGlobalDim: TestRequestPage "Trial Balance, per Global Dim.")
    var
        RoundTo: Option Pennies,Dollars,Thousands;
    begin
        FilterOnReportTrialBalancePerGlobalDimension(TrialBalancePerGlobalDim);
        TrialBalancePerGlobalDim.ActualChange.SetValue(true);
        TrialBalancePerGlobalDim.VarianceinChange.SetValue(true);
        TrialBalancePerGlobalDim.RoundTo.SetValue(RoundTo::Dollars);
        TrialBalancePerGlobalDim.UseAdditionalReportingCurrency.SetValue(true);
        TrialBalancePerGlobalDim.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalancePerGlobalDimensionBudgetRequestPageHandler(var TrialBalancePerGlobalDim: TestRequestPage "Trial Balance, per Global Dim.")
    var
        ShowComparison: Option "Last Year",Budget;
        RoundTo: Option Pennies,Dollars,Thousands;
    begin
        FilterOnReportTrialBalancePerGlobalDimension(TrialBalancePerGlobalDim);
        TrialBalancePerGlobalDim.ComparisonChange.SetValue(true);
        TrialBalancePerGlobalDim.ShowComparison.SetValue(ShowComparison::Budget);
        TrialBalancePerGlobalDim.RoundTo.SetValue(RoundTo::Thousands);
        TrialBalancePerGlobalDim.UseAdditionalReportingCurrency.SetValue(true);
        TrialBalancePerGlobalDim.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalanceSpreadGlobalDimensionRequestPageHandler(var TrialBalanceSpreadGDim: TestRequestPage "Trial Balance, Spread G. Dim.")
    var
        DimCode: Variant;
        No: Variant;
        SelectReportAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimCode);
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(SelectReportAmount);
        TrialBalanceSpreadGDim."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        TrialBalanceSpreadGDim."G/L Account".SetFilter("No.", No);
        TrialBalanceSpreadGDim.DimCode.SetValue(DimCode);
        TrialBalanceSpreadGDim.SelectReportAmount.SetValue(SelectReportAmount);
        TrialBalanceSpreadGDim.UseAdditionalReportingCurrency.SetValue(true);
        TrialBalanceSpreadGDim.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalanceSpreadPeriodsRequestPageHandler(var TrialBalanceSpreadPeriods: TestRequestPage "Trial Balance, Spread Periods")
    var
        No: Variant;
        SelectReportAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(SelectReportAmount);
        TrialBalanceSpreadPeriods."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        TrialBalanceSpreadPeriods."G/L Account".SetFilter("No.", No);
        TrialBalanceSpreadPeriods.SelectReportAmount.SetValue(SelectReportAmount);
        TrialBalanceSpreadPeriods.UseAdditionalReportingCurrency.SetValue(true);
        TrialBalanceSpreadPeriods.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTestRequestPageHandler(var GeneralJournalTest: TestRequestPage "General Journal - Test")
    var
        JournalTemplateName: Variant;
        JournalBatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        GeneralJournalTest."Gen. Journal Line".SetFilter("Journal Template Name", JournalTemplateName);
        GeneralJournalTest."Gen. Journal Line".SetFilter("Journal Batch Name", JournalBatchName);
        GeneralJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalanceDetailSummaryRequestPageHandler(var TrialBalanceDetailSummary: TestRequestPage "Trial Balance Detail/Summary")
    begin
        SaveAsXMLTrialBalanceDetailReport(TrialBalanceDetailSummary);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHTrialBalanceDetailSummaryTotals(var TrialBalanceDetailSummary: TestRequestPage "Trial Balance Detail/Summary")
    var
        Value: Variant;
        "Count": Integer;
        Index: Integer;
        "Filter": Text;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Count := Value;
        for Index := 1 to Count do begin
            if Index > 1 then
                Filter += '|';
            LibraryVariableStorage.Dequeue(Value);
            Filter += Format(Value);
        end;

        TrialBalanceDetailSummary."G/L Account".SetFilter("No.", Filter);
        TrialBalanceDetailSummary.PrintTransactionDetail.SetValue(false);
        TrialBalanceDetailSummary."G/L Account".SetFilter("Date Filter", Format(WorkDate()));

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        TrialBalanceDetailSummary.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalanceDetailSummaryUseAddRptCurrRequestPageHandler(var TrialBalanceDetailSummary: TestRequestPage "Trial Balance Detail/Summary")
    begin
        TrialBalanceDetailSummary.PrintTransactionDetail.SetValue(true);
        TrialBalanceDetailSummary.PrintSourceNames.SetValue(true);
        TrialBalanceDetailSummary.UseAdditionalReportingCurrency.SetValue(true);
        SaveAsXMLTrialBalanceDetailReport(TrialBalanceDetailSummary);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalaneUseAddRptCurrRequestPageHandler(var TrialBalance: TestRequestPage "Trial Balance")
    begin
        FilterOnTrialBalaneRequestPage(TrialBalance);
        TrialBalance.ComparisonChanges.SetValue(true);
        TrialBalance.UseAdditionalReportingCurrency.SetValue(true);
        TrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalaneRequestPageHandler(var TrialBalance: TestRequestPage "Trial Balance")
    begin
        FilterOnTrialBalaneRequestPage(TrialBalance);
        TrialBalance.ComparisonBalances.SetValue(true);
        TrialBalance.ActualBalances.SetValue(true);
        TrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BudgetFromHistoryRequestPageHandler(var BudgetFromHistory: TestRequestPage "Budget from History")
    begin
        FilterOnBudgetFromHistoryRequestPage(BudgetFromHistory);
        BudgetFromHistory.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BudgetFromHistoryWithRoundingRequestPageHandler(var BudgetFromHistory: TestRequestPage "Budget from History")
    var
        RoundTo: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        FilterOnBudgetFromHistoryRequestPage(BudgetFromHistory);
        LibraryVariableStorage.Dequeue(RoundTo);
        BudgetFromHistory."G/L Account".SetFilter("No.", No);
        BudgetFromHistory.RoundTo.SetValue(RoundTo);
        BudgetFromHistory.OK().Invoke();
    end;
}

