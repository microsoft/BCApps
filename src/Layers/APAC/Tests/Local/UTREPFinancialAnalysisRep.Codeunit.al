codeunit 141068 "UT REP Financial Analysis Rep"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report] [Financial Analysis Report] [UT]
    end;

    var
        ColumnAmountText1Cap: Label 'ColumnAmountText_1_';
        GLAccountNoCap: Label 'G_L_Account_No_';
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        PrecisionCap: Label '<Precision,2:><Standard Format,1>', Locked = true;
        TodayDateCap: Label 'FORMAT_TODAY_0_4_';

    [Test]
    [HandlerFunctions('FinancialAnalysisReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLAccReportTypeNetChgBudg()
    var
        GLAccount: Record "G/L Account";
        ReportType: Option " ",,"Net Change/Budget","Net Change (This Year/Last Year)","Balance (This Year/Last Year)";
    begin
        // [SCENARIO] verify Report Type Net Change/Budget without Dimension and Additional Currency Amount on Report - 28026 Financial Analysis Report.
        Initialize();
        ReportTypeWithAndWithoutDimension(
          '', false, GLAccount."Income/Balance"::"Income Statement", ReportType::"Net Change/Budget",
          0, LibraryRandom.RandDecInRange(100, 200, 2));  // Using blank for Dimension, False for ShowAmountsInAddReportingCurrency, Random Number for Amount and 0 for AdditionalCurrencyAmount.
    end;

    [Test]
    [HandlerFunctions('FinancialAnalysisReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLAccReportTypeNetChgBudgWithDim()
    var
        GLAccount: Record "G/L Account";
        ReportType: Option " ",,"Net Change/Budget","Net Change (This Year/Last Year)","Balance (This Year/Last Year)";
    begin
        // [SCENARIO] verify Report Type Net Change/Budget with Dimension on Report - 28026 Financial Analysis Report.
        Initialize();
        ReportTypeWithAndWithoutDimension(
          LibraryUTUtility.GetNewCode(), false, GLAccount."Income/Balance"::"Income Statement", ReportType::"Net Change/Budget",
          0, LibraryRandom.RandDecInRange(100, 200, 2));  // False for ShowAmountsInAddReportingCurrency, 0 for AdditionalCurrencyAmount and  Random Number for Amount.
    end;

    [Test]
    [HandlerFunctions('FinancialAnalysisReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLAccRptTypeNetChgThisYearLastYear()
    var
        GLAccount: Record "G/L Account";
        ReportType: Option " ",,"Net Change/Budget","Net Change (This Year/Last Year)","Balance (This Year/Last Year)";
    begin
        // [SCENARIO] verify Report Type Net Change (This Year/Last Year) without Dimension and Additional Currency Amount on Report - 28026 Financial Analysis Report.
        Initialize();
        ReportTypeWithAndWithoutDimension(
          '', true, GLAccount."Income/Balance"::"Income Statement", ReportType::"Net Change (This Year/Last Year)",
          LibraryRandom.RandDecInRange(100, 200, 2), 0);  // Using blank for Dimension, True for ShowAmountsInAddReportingCurrency, 0 for Amount and Random Number for AdditionalCurrencyAmount.
    end;

    [Test]
    [HandlerFunctions('FinancialAnalysisReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLAccRptTypeNetChgThisYearLastYearWithDim()
    var
        GLAccount: Record "G/L Account";
        ReportType: Option " ",,"Net Change/Budget","Net Change (This Year/Last Year)","Balance (This Year/Last Year)";
    begin
        // [SCENARIO] verify Report Type Net Change (This Year/Last Year) with Dimension on Report - 28026 Financial Analysis Report.
        Initialize();
        ReportTypeWithAndWithoutDimension(
          LibraryUTUtility.GetNewCode(), false, GLAccount."Income/Balance"::"Income Statement",
          ReportType::"Net Change (This Year/Last Year)", 0, LibraryRandom.RandDecInRange(100, 200, 2));  // False for ShowAmountsInAddReportingCurrency,0 for AdditionalCurrencyAmount and Random Number for AdditionalCurrencyAmount..
    end;

    [Test]
    [HandlerFunctions('FinancialAnalysisReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLAccRptTypeBalThisYearLastYear()
    var
        GLAccount: Record "G/L Account";
        ReportType: Option " ",,"Net Change/Budget","Net Change (This Year/Last Year)","Balance (This Year/Last Year)";
    begin
        // [SCENARIO] verify Report Type Balance (This Year/Last Year) and Additional Currency Amount on Report - 28026 Financial Analysis Report.
        Initialize();
        ReportTypeWithAndWithoutDimension(
          '', true, GLAccount."Income/Balance"::"Balance Sheet", ReportType::"Balance (This Year/Last Year)",
          LibraryRandom.RandDecInRange(100, 200, 2), 0);    // Using blank for Dimension, True for ShowAmountsInAddReportingCurrency, Random Number for AdditionalCurrencyAmount and 0 for Amount.
    end;

    [Test]
    [HandlerFunctions('FinancialAnalysisReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLAccRptTypeBalThisYearLastYearWithDim()
    var
        GLAccount: Record "G/L Account";
        ReportType: Option " ",,"Net Change/Budget","Net Change (This Year/Last Year)","Balance (This Year/Last Year)";
    begin
        // [SCENARIO] verify Report Type Balance (This Year/Last Year) with Dimension on Report - 28026 Financial Analysis Report.
        Initialize();
        ReportTypeWithAndWithoutDimension(
          LibraryUTUtility.GetNewCode(), false, GLAccount."Income/Balance"::"Balance Sheet", ReportType::"Balance (This Year/Last Year)",
          0, LibraryRandom.RandDecInRange(100, 200, 2));    // False for ShowAmountsInAddReportingCurrency, 0 for AdditionalCurrencyAmount and Random Number for AdditionalCurrencyAmount.
    end;

    local procedure ReportTypeWithAndWithoutDimension(GlobalDimension1Code: Code[20]; ShowAmountsInAddReportingCurrency: Boolean; IncomeBalance: Enum "G/L Account Report Type"; ReportType: Option; AdditionalCurrencyAmount: Decimal; Amount: Decimal)
    var
        GLAccountNo: Code[20];
    begin
        // Setup: Create GL Account and GL entries.
        GLAccountNo := CreateGLAccountWithEntry(GlobalDimension1Code, AdditionalCurrencyAmount, Amount, IncomeBalance);

        // Enqueue value for FinancialAnalysisReportRequestPageHandler.
        LibraryVariableStorage.Enqueue(GLAccountNo);
        LibraryVariableStorage.Enqueue(ShowAmountsInAddReportingCurrency);
        LibraryVariableStorage.Enqueue(ReportType);

        // Exercise.
        REPORT.Run(REPORT::"Financial Analysis Report");

        // Verify.
        VerifyValuesOnFinancialAnalysisReport(GLAccountNo, AdditionalCurrencyAmount + Amount);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateGLAccountWithEntry(GlobalDimension1Code: Code[20]; AdditionalCurrencyAmount: Decimal; Amount: Decimal; IncomeBalance: Enum "G/L Account Report Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount."Income/Balance" := IncomeBalance;
        GLAccount."Budget Filter" := LibraryUTUtility.GetNewCode10();
        GLAccount.Insert();
        CreateGLBudgetEntry(GLAccount."No.", GLAccount."Budget Filter");
        CreateGLEntry(GLAccount."No.", GlobalDimension1Code, AdditionalCurrencyAmount, Amount);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLBudgetEntry(GLAccountNo: Code[20]; BudgetName: Code[10]): Decimal
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        GLBudgetEntry2: Record "G/L Budget Entry";
    begin
        GLBudgetEntry2.FindLast();
        GLBudgetEntry."Entry No." := GLBudgetEntry2."Entry No." + 1;
        GLBudgetEntry."Budget Name" := BudgetName;
        GLBudgetEntry."G/L Account No." := GLAccountNo;
        GLBudgetEntry.Amount := LibraryRandom.RandDecInRange(100, 200, 2);
        GLBudgetEntry.Insert();
        exit(GLBudgetEntry.Amount);
    end;

    local procedure CreateGLEntry(GLAccountNo: Code[20]; GlobalDimension1Code: Code[20]; AdditionalCurrencyAmount: Decimal; Amount: Decimal): Decimal
    var
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."Posting Date" := WorkDate();
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry.Amount := Amount;
        GLEntry."Additional-Currency Amount" := AdditionalCurrencyAmount;
        GLEntry."Global Dimension 1 Code" := GlobalDimension1Code;
        GLEntry.Insert();
        exit(GLEntry.Amount);
    end;

    local procedure VerifyValuesOnFinancialAnalysisReport(GLAccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLAccountNoCap, GLAccountNo);
        LibraryReportDataset.AssertElementWithValueExists(TodayDateCap, Format(Today, 0, 4));
        LibraryReportDataset.AssertElementWithValueExists(ColumnAmountText1Cap, Format(Amount, 0, PrecisionCap));  // Using 0 for length.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FinancialAnalysisReportRequestPageHandler(var FinancialAnalysisReport: TestRequestPage "Financial Analysis Report")
    var
        No: Variant;
        ReportType: Variant;
        ShowAmountsInAddReportingCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(ShowAmountsInAddReportingCurrency);
        LibraryVariableStorage.Dequeue(ReportType);
        FinancialAnalysisReport."G/L Account".SetFilter("No.", No);
        FinancialAnalysisReport."G/L Account".SetFilter("Date Filter", StrSubstNo('%1..%2', WorkDate(), CalcDate('<CY>', WorkDate())));
        FinancialAnalysisReport.ReportType.SetValue(FinancialAnalysisReport.ReportType.GetOption(ReportType));
        FinancialAnalysisReport.IndentAccountName.SetValue(true);
        FinancialAnalysisReport.AddCurr.SetValue(ShowAmountsInAddReportingCurrency);
        FinancialAnalysisReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

