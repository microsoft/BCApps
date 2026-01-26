codeunit 141046 "UT REP Currency Rounding"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Rounding] [Amounts In Whole] [Report] [UT]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        ReportManagement: Codeunit "Report Management APAC";
        AmountsCap: Label 'AmountsAreIn1000sCaption';
        ColumnAmountCap: Label 'ColumnAmountText_1_';
        ColumnAmountTwoCap: Label 'ColumnAmountText_2_';
        CurrentYTDNetChangeCap: Label 'CurrentYTDNetChange';
        CustSalesLCYCap: Label 'CustSalesLCY2';
        DateFilterTxt: Label '%1..%2';
        FiscalYearBalanceCap: Label 'FiscalYearBalance';
        GLAccNoCap: Label 'No_GLAcc';
        GLAccountNoCap: Label 'No_GLAccount';
        PrecisionTxt: Label '<Precision,%1:><Standard Format,0>', Locked = true;
        ReptMgmntDescRoundingCap: Label 'ReptMgmntDescRounding';
        RoundFactorCap: Label 'RoundFactorText';
        RoundingCap: Label 'RoundingText';
        SalespersonCodeCap: Label 'Salesperson_Purchaser_Code';
        ValueEntryItemNoCap: Label 'ValueEntryBuffer__Item_No__';

    [Test]
    [HandlerFunctions('BalanceSheetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeBlankBalanceSheet()
    var
        GLAccount: Record "G/L Account";
        Amount: Decimal;
        AmountsInWhole: Option " ",Tens;
        GLAccountNo: Code[20];
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28024 Balance Sheet with blank Amounts In Whole.

        // Setup.
        Initialize();
        Amount := LibraryRandom.RandDecInRange(100000, 10000000, 2);  // Using large value for Amount to display the value on report according to Amount In Whole.
        GLAccountNo := CreateGLBudgetEntry(GLAccount."Income/Balance"::"Balance Sheet", Amount);
        EnqueueValuesInRequestPageHandler(GLAccountNo, AmountsInWhole::" ");  // Enqueue values for BalanceSheetRequestPageHandler.

        // Exercise and Verify.
        OnPreReportAmountsInWholeBalanceSheet(AmountsInWhole, Format(Amount, 0, StrSubstNo(PrecisionTxt, 2)));  // Using 0 for length.
    end;

    [Test]
    [HandlerFunctions('BalanceSheetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeTensBalanceSheet()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28024 Balance Sheet with Tens.
        AmountsInWholeBalanceSheet(AmountsInWhole::Tens);
    end;

    [Test]
    [HandlerFunctions('BalanceSheetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeHundredsBalanceSheet()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28024 Balance Sheet with Hundreds.
        AmountsInWholeBalanceSheet(AmountsInWhole::Hundreds);
    end;

    [Test]
    [HandlerFunctions('BalanceSheetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeThousandBalanceSheet()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28024 Balance Sheet with Thousands.
        AmountsInWholeBalanceSheet(AmountsInWhole::Thousands);
    end;

    [Test]
    [HandlerFunctions('BalanceSheetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeHundredThousandsBalSheet()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28024 Balance Sheet with Hundred Thousands.
        AmountsInWholeBalanceSheet(AmountsInWhole::"Hundred Thousands");
    end;

    [Test]
    [HandlerFunctions('BalanceSheetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeMillionsBalanceSheet()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28024 Balance Sheet with Millions.
        AmountsInWholeBalanceSheet(AmountsInWhole::Millions);
    end;

    local procedure AmountsInWholeBalanceSheet(AmountsInWhole: Option)
    var
        GLAccount: Record "G/L Account";
        Amount: Decimal;
        GLAccountNo: Code[20];
    begin
        // Setup.
        Initialize();
        Amount := LibraryRandom.RandDecInRange(100000, 10000000, 2);  // Using large value for Amount to display the value on report according to Amount In Whole.
        GLAccountNo := CreateGLBudgetEntry(GLAccount."Income/Balance"::"Balance Sheet", Amount);
        EnqueueValuesInRequestPageHandler(GLAccountNo, AmountsInWhole);  // Enqueue values for BalanceSheetRequestPageHandler.

        // Exercise and Verify.
        OnPreReportAmountsInWholeBalanceSheet(
          AmountsInWhole, Format(ReportManagement.RoundAmount(Amount, AmountsInWhole), 0, StrSubstNo(PrecisionTxt, 1)));  // Using 0 for length.
    end;

    [Test]
    [HandlerFunctions('BudgetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeBlankBudget()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 8 Budget with Blank..
        OnPreReportAmountsInWholeForGLBudgetEntry(AmountsCap, GLAccNoCap, REPORT::Budget, AmountsInWhole::" ");
    end;

    [Test]
    [HandlerFunctions('BudgetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeTensBudget()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 8 Budget with Tens
        OnPreReportAmountsInWholeForGLBudgetEntry(AmountsCap, GLAccNoCap, REPORT::Budget, AmountsInWhole::Tens);
    end;

    [Test]
    [HandlerFunctions('BudgetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeHundredsBudget()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 8 Budget with Hundreds
        OnPreReportAmountsInWholeForGLBudgetEntry(AmountsCap, GLAccNoCap, REPORT::Budget, AmountsInWhole::Hundreds);
    end;

    [Test]
    [HandlerFunctions('BudgetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeThousandsBudget()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 8 Budget with Thousands.
        OnPreReportAmountsInWholeForGLBudgetEntry(AmountsCap, GLAccNoCap, REPORT::Budget, AmountsInWhole::Thousands);
    end;

    [Test]
    [HandlerFunctions('BudgetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeHundredThousandsBudget()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 8 Budget with Hundred Thousnds.
        OnPreReportAmountsInWholeForGLBudgetEntry(AmountsCap, GLAccNoCap, REPORT::Budget, AmountsInWhole::"Hundred Thousands");
    end;

    [Test]
    [HandlerFunctions('BudgetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeMillionsBudget()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 8 Budget with Millions.
        OnPreReportAmountsInWholeForGLBudgetEntry(AmountsCap, GLAccNoCap, REPORT::Budget, AmountsInWhole::Millions);
    end;

    [Test]
    [HandlerFunctions('ClosingTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeBlankClosingTrialBalance()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 10 Closing Trial Balance with Blank.
        OnPreReportAmountsInWholeForGLBudgetEntry(
          ReptMgmntDescRoundingCap, GLAccountNoCap, REPORT::"Closing Trial Balance", AmountsInWhole::" ");
    end;

    [Test]
    [HandlerFunctions('ClosingTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeTensClosingTrialBalance()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 10 Closing Trial Balance with Tens.
        OnPreReportAmountsInWholeForGLBudgetEntry(
          ReptMgmntDescRoundingCap, GLAccountNoCap, REPORT::"Closing Trial Balance", AmountsInWhole::Tens);
    end;

    [Test]
    [HandlerFunctions('ClosingTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeHundredsClosingTrialBal()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 10 Closing Trial Balance with Hundreds.
        OnPreReportAmountsInWholeForGLBudgetEntry(
          ReptMgmntDescRoundingCap, GLAccountNoCap, REPORT::"Closing Trial Balance", AmountsInWhole::Hundreds);
    end;

    [Test]
    [HandlerFunctions('ClosingTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeThousandsClosingTrialBal()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 10 Closing Trial Balance with Thousands.
        OnPreReportAmountsInWholeForGLBudgetEntry(
          ReptMgmntDescRoundingCap, GLAccountNoCap, REPORT::"Closing Trial Balance", AmountsInWhole::Thousands);
    end;

    [Test]
    [HandlerFunctions('ClosingTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeHunThousandsClosingTrialBal()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 10 Closing Trial Balance with Hundred Thousands.
        OnPreReportAmountsInWholeForGLBudgetEntry(
          ReptMgmntDescRoundingCap, GLAccountNoCap, REPORT::"Closing Trial Balance", AmountsInWhole::"Hundred Thousands");
    end;

    [Test]
    [HandlerFunctions('ClosingTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeMillionsClosingTrialBal()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 10 Closing Trial Balance with Millions.
        OnPreReportAmountsInWholeForGLBudgetEntry(
          ReptMgmntDescRoundingCap, GLAccountNoCap, REPORT::"Closing Trial Balance", AmountsInWhole::Millions);
    end;

    local procedure OnPreReportAmountsInWholeForGLBudgetEntry(RoundCap: Text; GLAccountCap: Text; ReportID: Integer; AmountsInWhole: Option)
    var
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        // Setup.
        Initialize();
        GLAccountNo :=
          CreateGLBudgetEntry(GLAccount."Income/Balance"::"Income Statement", LibraryRandom.RandDecInRange(100000, 10000000, 2));
        EnqueueValuesInRequestPageHandler(GLAccountNo, AmountsInWhole);  // Enqueue G/L Account No. for ClosingTrialBalanceRequestPageHandler, BudgetRequestPageHandler.

        // Exercise.
        REPORT.Run(ReportID);

        // Verify.
        VerifyXMLValuesOnReport(RoundCap, GLAccountCap, AmountsInWhole, GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeBlankCustomerItemSales()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 113 Customer/Item Sales with Blank..
        AmountsInWholeCustomerItemSales(AmountsInWhole::" ");
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeTensCustomerItemSales()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 113 Customer/Item Sales with Tens
        AmountsInWholeCustomerItemSales(AmountsInWhole::Tens);
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeHundredsCustomerItemSales()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 113 Customer/Item Sales with Hundreds
        AmountsInWholeCustomerItemSales(AmountsInWhole::Hundreds);
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeThousandsCustomerItemSales()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 113 Customer/Item Sales with Thousands.
        AmountsInWholeCustomerItemSales(AmountsInWhole::Thousands);
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeHunThousandsCustItemSales()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 113 Customer/Item Sales with Hundred Thousnds.
        AmountsInWholeCustomerItemSales(AmountsInWhole::"Hundred Thousands");
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeMillionsCustomerItemSales()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 113 Customer/Item Sales with Millions.
        AmountsInWholeCustomerItemSales(AmountsInWhole::Millions);
    end;

    local procedure AmountsInWholeCustomerItemSales(AmountsInWhole: Option)
    var
        ValueEntry: Record "Value Entry";
    begin
        // Setup.
        Initialize();
        CreateValueEntry(ValueEntry);
        EnqueueValuesInRequestPageHandler(ValueEntry."Source No.", AmountsInWhole);  // Enqueue G/L Account No. for ClosingTrialBalanceRequestPageHandler, BudgetRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Customer/Item Sales");  // Opens CustomerItemSalesRequestPageHandler.

        // Verify.
        VerifyXMLValuesOnReport(RoundingCap, ValueEntryItemNoCap, AmountsInWhole, ValueEntry."Item No.");
    end;

    [Test]
    [HandlerFunctions('FinancialAnalysisReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeWithBlankFinAnalysisRpt()
    var
        AmountsInWhole: Option " ",Tens;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28026 Finanncial Analysis Report for blank.
        AmountsInWholeFinancialAnalysisReport(AmountsInWhole::" ", StrSubstNo(PrecisionTxt, 2));
    end;

    [Test]
    [HandlerFunctions('FinancialAnalysisReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeTensFinAnalysisRpt()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28026 Finanncial Analysis Report for Tens.
        AmountsInWholeFinancialAnalysisReport(AmountsInWhole::Tens, StrSubstNo(PrecisionTxt, 1));  // Passing random option in Amounts In Whole.
    end;

    [Test]
    [HandlerFunctions('FinancialAnalysisReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeHundredsFinAnalysisRpt()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28026 Finanncial Analysis Report for Hundreds.
        AmountsInWholeFinancialAnalysisReport(AmountsInWhole::Hundreds, StrSubstNo(PrecisionTxt, 1));  // Passing random option in Amounts In Whole.
    end;

    [Test]
    [HandlerFunctions('FinancialAnalysisReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeThousandsFinAnalysisRpt()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28026 Finanncial Analysis Report for Thousands.
        AmountsInWholeFinancialAnalysisReport(AmountsInWhole::Thousands, StrSubstNo(PrecisionTxt, 1));  // Passing random option in Amounts In Whole.
    end;

    [Test]
    [HandlerFunctions('FinancialAnalysisReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeHunThousandsFinAnalysisRpt()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28026 Finanncial Analysis Report for Hundred Thousands.
        AmountsInWholeFinancialAnalysisReport(AmountsInWhole::"Hundred Thousands", StrSubstNo(PrecisionTxt, 1));  // Passing random option in Amounts In Whole.
    end;

    [Test]
    [HandlerFunctions('FinancialAnalysisReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeMillionsFinAnalysisRpt()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28026 Finanncial Analysis Report for Millions.
        AmountsInWholeFinancialAnalysisReport(AmountsInWhole::Millions, StrSubstNo(PrecisionTxt, 1));  // Passing random option in Amounts In Whole.
    end;

    local procedure AmountsInWholeFinancialAnalysisReport(AmountsInWhole: Option; Precision: Text)
    var
        GLEntry: Record "G/L Entry";
    begin
        // Setup.
        Initialize();
        CreateGLEntry(GLEntry);
        EnqueueValuesInRequestPageHandler(GLEntry."G/L Account No.", AmountsInWhole);  // Enqueue values for FinancialAnalysisReportRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Financial Analysis Report");  // Opens FinancialAnalysisReportRequestPageHandler.

        // Verify.
        VerifyXMLValuesOnReport(
          RoundFactorCap, ColumnAmountCap,
          AmountsInWhole, Format(ReportManagement.RoundAmount(GLEntry.Amount, AmountsInWhole), 0, Precision));
    end;

    [Test]
    [HandlerFunctions('IncomeStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeBlankIncomeStatement()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28025 Income Statement for blank.
        AmountsInWholeForGLEntry(RoundFactorCap, CurrentYTDNetChangeCap, AmountsInWhole::" ", REPORT::"Income Statement");
    end;

    [Test]
    [HandlerFunctions('IncomeStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeTensIncomeStatement()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28025 Income Statement for Tens.
        AmountsInWholeForGLEntry(RoundFactorCap, CurrentYTDNetChangeCap, AmountsInWhole::Tens, REPORT::"Income Statement");
    end;

    [Test]
    [HandlerFunctions('IncomeStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeHundredsIncomeStatement()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28025 Income Statement for Hundreds.
        AmountsInWholeForGLEntry(RoundFactorCap, CurrentYTDNetChangeCap, AmountsInWhole::Hundreds, REPORT::"Income Statement");
    end;

    [Test]
    [HandlerFunctions('IncomeStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeThousandsIncomeStatement()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28025 Income Statement for Thousands.
        AmountsInWholeForGLEntry(RoundFactorCap, CurrentYTDNetChangeCap, AmountsInWhole::Thousands, REPORT::"Income Statement");
    end;

    [Test]
    [HandlerFunctions('IncomeStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeHundredThousandIncomeStmt()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28025 Income Statement for Hundred Thousands.
        AmountsInWholeForGLEntry(RoundFactorCap, CurrentYTDNetChangeCap, AmountsInWhole::"Hundred Thousands", REPORT::"Income Statement");
    end;

    [Test]
    [HandlerFunctions('IncomeStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeMillionsIncomeStatement()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 28025 Income Statement for Millions.
        AmountsInWholeForGLEntry(RoundFactorCap, CurrentYTDNetChangeCap, AmountsInWhole::Millions, REPORT::"Income Statement");
    end;

    [Test]
    [HandlerFunctions('TrialBalancePreviousYearRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeBlankTrialBalPreviousYear()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 7 Trial Balance/Previous Year for blank.
        AmountsInWholeForGLEntry(RoundingCap, FiscalYearBalanceCap, AmountsInWhole::" ", REPORT::"Trial Balance/Previous Year");
    end;

    [Test]
    [HandlerFunctions('TrialBalancePreviousYearRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeTensTrialBalPreviousYear()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 7 Trial Balance/Previous Year for Tens.
        AmountsInWholeForGLEntry(RoundingCap, FiscalYearBalanceCap, AmountsInWhole::Tens, REPORT::"Trial Balance/Previous Year");
    end;

    [Test]
    [HandlerFunctions('TrialBalancePreviousYearRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeHundredsTrialBalPreviousYear()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 7 Trial Balance/Previous Year for Hundreds.
        AmountsInWholeForGLEntry(RoundingCap, FiscalYearBalanceCap, AmountsInWhole::Hundreds, REPORT::"Trial Balance/Previous Year");
    end;

    [Test]
    [HandlerFunctions('TrialBalancePreviousYearRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeThousandsTrialBalPreviousYear()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 7 Trial Balance/Previous Year for Thousands.
        AmountsInWholeForGLEntry(RoundingCap, FiscalYearBalanceCap, AmountsInWhole::Thousands, REPORT::"Trial Balance/Previous Year");
    end;

    [Test]
    [HandlerFunctions('TrialBalancePreviousYearRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeHundThousTrialBalPreviousYear()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 7 Trial Balance/Previous Year for Hundred Thousands.
        AmountsInWholeForGLEntry(
          RoundingCap, FiscalYearBalanceCap, AmountsInWhole::"Hundred Thousands", REPORT::"Trial Balance/Previous Year");
    end;

    [Test]
    [HandlerFunctions('TrialBalancePreviousYearRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeMillionsTrialBalPreviousYear()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 7 Trial Balance/Previous Year for Millions.
        AmountsInWholeForGLEntry(RoundingCap, FiscalYearBalanceCap, AmountsInWhole::Millions, REPORT::"Trial Balance/Previous Year");
    end;

    local procedure AmountsInWholeForGLEntry(RoundCap: Text; BalanceCap: Text; AmountsInWhole: Option; ReportID: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        // Setup.
        Initialize();
        CreateGLEntry(GLEntry);

        // Enqueue G/L Account No. for IncomeStatementRequestPageHandler, TrialBalanceBudgetRequestPageHandler and TrialBalancePreviousYearRequestPageHandler.
        EnqueueValuesInRequestPageHandler(GLEntry."G/L Account No.", AmountsInWhole);

        // Exercise.
        REPORT.Run(ReportID);

        // Verify.
        VerifyXMLValuesOnReport(
          RoundCap, BalanceCap, AmountsInWhole, ReportManagement.RoundAmount(GLEntry.Amount, AmountsInWhole));
    end;

    [Test]
    [HandlerFunctions('SalespersonSalesStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeBlankSalespersonSalesStats()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 114 Salesperson - Sales Statistics for blank.
        AmountsInWholeSalespersonSalesStatistics(AmountsInWhole::" ");
    end;

    [Test]
    [HandlerFunctions('SalespersonSalesStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmntsInWholeTensSalespersonSalesStats()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 114 Salesperson - Sales Statistics for Tens.
        AmountsInWholeSalespersonSalesStatistics(AmountsInWhole::Tens);
    end;

    [Test]
    [HandlerFunctions('SalespersonSalesStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmntsInWholeHundsSalespersonSalesStats()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 114 Salesperson - Sales Statistics for Hundreds.
        AmountsInWholeSalespersonSalesStatistics(AmountsInWhole::Hundreds);
    end;

    [Test]
    [HandlerFunctions('SalespersonSalesStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeThousSalespersonSalesStats()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 114 Salesperson - Sales Statistics for Thousands.
        AmountsInWholeSalespersonSalesStatistics(AmountsInWhole::Thousands);
    end;

    [Test]
    [HandlerFunctions('SalespersonSalesStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmntsInWholeHundThousSalespersonSalesStats()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 114 Salesperson - Sales Statistics for Hundred Thousands.
        AmountsInWholeSalespersonSalesStatistics(AmountsInWhole::"Hundred Thousands");
    end;

    [Test]
    [HandlerFunctions('SalespersonSalesStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeMillionsSalespersonSalesStats()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 114 Salesperson - Sales Statistics for Millions.
        AmountsInWholeSalespersonSalesStatistics(AmountsInWhole::Millions);
    end;

    local procedure AmountsInWholeSalespersonSalesStatistics(AmountsInWhole: Option)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Setup.
        Initialize();
        CreateCustomerLedgerEntry(CustLedgerEntry);
        EnqueueValuesInRequestPageHandler(CustLedgerEntry."Customer No.", AmountsInWhole);  // Enqueue values for SalespersonSalesStatisticsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Salesperson - Sales Statistics");  // Opens SalespersonSalesStatisticsRequestPageHandler.

        // Verify.
        VerifyXMLValuesOnReport(RoundingCap, SalespersonCodeCap, AmountsInWhole, CustLedgerEntry."Salesperson Code");
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeBlankSalesStatistics()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 112 Sales Statistics for blank.
        AmountsInWholeSalesStatistics(AmountsInWhole::" ");
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeTensSalesStatistics()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 112 Sales Statistics for Tens.
        AmountsInWholeSalesStatistics(AmountsInWhole::Tens);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAmountsInWholeHundredsSalesStatistics()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 112 Sales Statistics for Hundreds.
        AmountsInWholeSalesStatistics(AmountsInWhole::Hundreds);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAmountsInWholeThousandsSalesStatistics()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 112 Sales Statistics for Thousands.
        AmountsInWholeSalesStatistics(AmountsInWhole::Thousands);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeHundredThousandsSalesStats()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 112 Sales Statistics for Hundred Thousands.
        AmountsInWholeSalesStatistics(AmountsInWhole::"Hundred Thousands");
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReptAmtsInWholeMillionsSalesStatistics()
    var
        AmountsInWhole: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
    begin
        // [SCENARIO] validate Amounts In Whole - OnPreReport Trigger of Report - 112 Sales Statistics for Millions.
        AmountsInWholeSalesStatistics(AmountsInWhole::Millions);
    end;

    local procedure AmountsInWholeSalesStatistics(AmountsInWhole: Option)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Setup.
        Initialize();
        CreateCustomerLedgerEntry(CustLedgerEntry);
        EnqueueValuesInRequestPageHandler(CustLedgerEntry."Customer No.", AmountsInWhole);  // Enqueue values for SalesStatisticsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Sales Statistics");  // Opens SalesStatisticsRequestPageHandler.

        // Verify.
        VerifyXMLValuesOnReport(
          RoundingCap, CustSalesLCYCap, AmountsInWhole, ReportManagement.RoundAmount(CustLedgerEntry."Sales (LCY)", AmountsInWhole));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry2.FindLast();
        CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Customer No." := CreateCustomer();
        CustLedgerEntry."Sales (LCY)" := LibraryRandom.RandDecInRange(100000, 10000000, 2);  // Using large value for Sales(LCY) to display the value on report according to Amount In Whole.
        CustLedgerEntry."Salesperson Code" := CreateSalesPersonPurchaser();
        CustLedgerEntry.Insert();
    end;

    local procedure CreateGLAccount(IncomeBalance: Enum "G/L Account Report Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount."Income/Balance" := IncomeBalance;
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateGLBudgetEntry(IncomeBalance: Enum "G/L Account Report Type"; Amount: Decimal): Code[20]
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry."G/L Account No." := CreateGLAccount(IncomeBalance);
        GLBudgetEntry.Amount := Amount;
        GLBudgetEntry.Insert();
        exit(GLBudgetEntry."G/L Account No.");
    end;

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry")
    var
        GLAccount: Record "G/L Account";
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."G/L Account No." := CreateGLAccount(GLAccount."Income/Balance"::"Income Statement");
        GLEntry."Posting Date" := WorkDate();
        GLEntry.Amount := LibraryRandom.RandDecInRange(100000, 10000000, 2);  // Using large value for Amount to display the value on report according to Amount In Whole.
        GLEntry.Insert();
    end;

    local procedure CreateItemLedgerEntry(SourceNo: Code[20]): Code[20]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntry2: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry2.FindLast();
        ItemLedgerEntry."Entry No." := ItemLedgerEntry2."Entry No." + 1;
        ItemLedgerEntry."Item No." := LibraryUTUtility.GetNewCode();
        ItemLedgerEntry."Source Type" := ItemLedgerEntry."Source Type"::Customer;
        ItemLedgerEntry."Source No." := SourceNo;
        ItemLedgerEntry.Insert();
        exit(ItemLedgerEntry."Item No.");
    end;

    local procedure CreateSalesPersonPurchaser(): Code[10]
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        SalespersonPurchaser.Code := LibraryUTUtility.GetNewCode10();
        SalespersonPurchaser.Insert();
        exit(SalespersonPurchaser.Code);
    end;

    local procedure CreateValueEntry(var ValueEntry: Record "Value Entry")
    var
        ValueEntry2: Record "Value Entry";
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomer();
        ValueEntry2.FindLast();
        ValueEntry."Entry No." := ValueEntry2."Entry No." + 1;
        ValueEntry."Item No." := CreateItemLedgerEntry(CustomerNo);
        ValueEntry."Source Type" := ValueEntry."Source Type"::Customer;
        ValueEntry."Source No." := CustomerNo;
        ValueEntry."Cost Amount (Actual)" := LibraryRandom.RandDecInRange(100000, 10000000, 2);  // Using large value for Cost Amount(Actual) to display the value on report according to Amount In Whole.
        ValueEntry.Insert();
    end;

    local procedure EnqueueValuesInRequestPageHandler(GLAccountNo: Code[20]; AmountsInWhole: Option)
    begin
        LibraryVariableStorage.Enqueue(GLAccountNo);
        LibraryVariableStorage.Enqueue(AmountsInWhole);
    end;

    local procedure OnPreReportAmountsInWholeBalanceSheet(AmountsInWhole: Option; ExpectedAmount: Text)
    begin
        // Exercise.
        REPORT.Run(REPORT::"Balance Sheet");  // Opens BalanceSheetRequestPageHandler.

        // Verify.
        VerifyXMLValuesOnReport(RoundFactorCap, ColumnAmountTwoCap, AmountsInWhole, ExpectedAmount);
    end;

    local procedure VerifyXMLValuesOnReport(Caption: Text; Caption2: Text; AmountInWhole: Option; CaptionValue: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption, ReportManagement.RoundDescription(AmountInWhole));
        LibraryReportDataset.AssertElementWithValueExists(Caption2, CaptionValue);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BalanceSheetRequestPageHandler(var BalanceSheet: TestRequestPage "Balance Sheet")
    var
        AmountsInWhole: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(AmountsInWhole);
        BalanceSheet."G/L Account".SetFilter("No.", No);
        BalanceSheet."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        BalanceSheet.AmountsInWhole.SetValue(AmountsInWhole);
        BalanceSheet.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BudgetRequestPageHandler(var Budget: TestRequestPage Budget)
    var
        AmountsInWhole: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(AmountsInWhole);
        Budget."G/L Account".SetFilter("No.", No);
        Budget."G/L Account".SetFilter("Date Filter", StrSubstNo(DateFilterTxt, WorkDate(), CalcDate('<CY>', WorkDate())));
        Budget.AmountsInWhole.SetValue(AmountsInWhole);
        Budget.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ClosingTrialBalanceRequestPageHandler(var ClosingTrialBalance: TestRequestPage "Closing Trial Balance")
    var
        AmountsInWhole: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(AmountsInWhole);
        ClosingTrialBalance."G/L Account".SetFilter("No.", No);
        ClosingTrialBalance."G/L Account".SetFilter("Date Filter", StrSubstNo(DateFilterTxt, WorkDate(), CalcDate('<CY>', WorkDate())));
        ClosingTrialBalance.StartingDate.SetValue(CalcDate('<-CY>', WorkDate()));
        ClosingTrialBalance.AmountsInWhole.SetValue(AmountsInWhole);
        ClosingTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerItemSalesRequestPageHandler(var CustomerItemSales: TestRequestPage "Customer/Item Sales")
    var
        AmountsInWhole: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(AmountsInWhole);
        CustomerItemSales.Customer.SetFilter("No.", No);
        CustomerItemSales.AmountsInWhole.SetValue(AmountsInWhole);
        CustomerItemSales.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FinancialAnalysisReportRequestPageHandler(var FinancialAnalysisReport: TestRequestPage "Financial Analysis Report")
    var
        AmountsInWhole: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(AmountsInWhole);
        FinancialAnalysisReport."G/L Account".SetFilter("No.", No);
        FinancialAnalysisReport."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        FinancialAnalysisReport.ReportType.SetValue(FinancialAnalysisReport.ReportType.GetOption(2));  // Set Report Type as Net Change/Budget.
        FinancialAnalysisReport.AmountsInWhole.SetValue(AmountsInWhole);
        FinancialAnalysisReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IncomeStatementRequestPageHandler(var IncomeStatement: TestRequestPage "Income Statement")
    var
        AmountsInWhole: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(AmountsInWhole);
        IncomeStatement."G/L Account".SetFilter("No.", No);
        IncomeStatement."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        IncomeStatement.AmountsInWhole.SetValue(AmountsInWhole);
        IncomeStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalancePreviousYearRequestPageHandler(var TrialBalancePreviousYear: TestRequestPage "Trial Balance/Previous Year")
    var
        AmountsInWhole: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(AmountsInWhole);
        TrialBalancePreviousYear."G/L Account".SetFilter("No.", No);
        TrialBalancePreviousYear."G/L Account".SetFilter("Date Filter", StrSubstNo(DateFilterTxt, WorkDate(), CalcDate('<CY>', WorkDate())));
        TrialBalancePreviousYear.AmountsInWhole.SetValue(AmountsInWhole);
        TrialBalancePreviousYear.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalespersonSalesStatisticsRequestPageHandler(var SalespersonSalesStatistics: TestRequestPage "Salesperson - Sales Statistics")
    var
        AmountsInWhole: Variant;
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        LibraryVariableStorage.Dequeue(AmountsInWhole);
        SalespersonSalesStatistics."Cust. Ledger Entry".SetFilter("Customer No.", CustomerNo);
        SalespersonSalesStatistics.AmountsInWhole.SetValue(AmountsInWhole);
        SalespersonSalesStatistics.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsRequestPageHandler(var SalesStatistics: TestRequestPage "Sales Statistics")
    var
        AmountsInWhole: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(AmountsInWhole);
        SalesStatistics.Customer.SetFilter("No.", No);
        SalesStatistics.StartingDate.SetValue(WorkDate());
        SalesStatistics.AmountsInWhole.SetValue(AmountsInWhole);
        SalesStatistics.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

