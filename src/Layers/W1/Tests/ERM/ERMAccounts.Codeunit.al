codeunit 134020 "ERM Accounts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Account]
    end;

    var
        DeltaAssert: Codeunit "Delta Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        DimensionValueCode2: Code[20];
        DimensionValueCode3: Code[20];
        GLAccount3: Code[20];
        TotalAmount: Decimal;
        TotalAmount2: Decimal;
        GlobalOption: Option " ","No Limitation",Limited,Blocked;
        IncorrectColumnCaptionErr: Label 'Incorrect Column Caption';

    [Test]
    [Scope('OnPrem')]
    procedure TestAllAccounts()
    var
        BalAccount: Record "G/L Account";
    begin
        Initialize();
        BalAccount.SetRange("Direct Posting", true);
        BalAccount.SetRange("Account Type", BalAccount."Account Type"::Posting);
        BalAccount.FindSet();
        BalAccount.Next(LibraryRandom.RandInt(BalAccount.Count));

        // Test a random direct posting accounts.
        TestInvoiceAccount(BalAccount);
    end;

    local procedure TestInvoiceAccount(BalAccount: Record "G/L Account")
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        Delta: Decimal;
    begin
        LibrarySales.CreateCustomer(Customer);
        Delta := LibraryRandom.RandInt(100000) / 100;

        // Setup assertion delta contracts.
        SetupDeltaAssertions(Customer, BalAccount, Delta);

        // Exercise (Post random amount).
        PostInvoice(Customer, BalAccount."No.", Delta);

        // Verify that accounts changed correctly.
        DeltaAssert.Assert();
    end;

    [Test]
    [HandlerFunctions('GLBalancebyDimMatrixHandler')]
    [Scope('OnPrem')]
    procedure BalanceByDimensionsGLAccount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        AmountField: Option Amount,"Debit Amount","Credit Amount";
        GLAccountNo: Code[20];
        GLAccountNo2: Code[20];
    begin
        // Post General Lines with Different Dimension,Open G/L Balance by Dimension with G/L account filter and Verify G/L Balance by Dim. Matrix Page.

        // Setup: Create Multiple Dimension Value.
        Initialize();
        GeneralLedgerSetup.Get();
        DimensionValueCode2 := CreateDimensionValue(GeneralLedgerSetup."Global Dimension 1 Code");  // Global Variavle used for Page Handler.
        DimensionValueCode3 := CreateDimensionValue(GeneralLedgerSetup."Global Dimension 1 Code");  // Global Variavle used for Page Handler.

        // Exercise: Post General Lines With Different Dimensions and Set filter on G/L Balance by Dimension Page.
        SelectGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJnlLineWithDimension(GenJournalLine, GenJournalBatch, DimensionValueCode2);
        GLAccountNo := GenJournalLine."Account No.";
        TotalAmount := GenJournalLine.Amount;  // Global Variavle used for Page Handler.
        CreateGeneralJnlLineWithDimension(GenJournalLine, GenJournalBatch, DimensionValueCode3);
        GLAccountNo2 := GenJournalLine."Account No.";
        TotalAmount2 := GenJournalLine.Amount; // Global Variavle used for Page Handler.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        SetFilterOnGLBalancebyDimension(AmountField::Amount, GeneralLedgerSetup."Global Dimension 1 Code", '', GLAccountNo, GLAccountNo2);

        // Verify: Verify Dimension Value and Total Amount on G/L Balance by Dim. Matrix Page Handler.
    end;

    [Test]
    [HandlerFunctions('GLBalancebyDimMatrixDifferentDimensionHandler')]
    [Scope('OnPrem')]
    procedure BalanceByDimensionsDifferentDimension()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        AmountField: Option Amount,"Debit Amount","Credit Amount";
    begin
        // Post General Line with Dimension,Open G/L Balance by Dimension with different Dimension filter and Verify G/L Balance by Dim. Matrix Page.

        // Setup: Create Dimension Value with Different Dimension.
        Initialize();
        GeneralLedgerSetup.Get();
        DimensionValueCode2 := CreateDimensionValue(GeneralLedgerSetup."Global Dimension 1 Code");  // Global Variavle used for Page Handler.
        DimensionValueCode3 := CreateDimensionValue(GeneralLedgerSetup."Global Dimension 2 Code");  // Global Variavle used for Page Handler.

        // Exercise: Post General Line With Dimensions and Set filter on G/L Balance by Dimension Page with Different Dimension.
        SelectGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJnlLineWithDimension(GenJournalLine, GenJournalBatch, DimensionValueCode2);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        SetFilterOnGLBalancebyDimension(AmountField::Amount, GeneralLedgerSetup."Global Dimension 1 Code", DimensionValueCode3, '', '');

        // Verify: Verify Dimension Value and Total Amount on G/L Balance by Dim Matrix Different Dimension Handler.
    end;

    [Test]
    [HandlerFunctions('GLBalancebyDimMatrixAmountHandler')]
    [Scope('OnPrem')]
    procedure BalanceByDimensionsDebitAmount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        AmountField: Option Amount,"Debit Amount","Credit Amount";
    begin
        // Post General Line with Dimension,Open G/L Balance by Dimension with Amount Filed as Debit Amount and Verify G/L Balance by Dim. Matrix Page.

        // Setup: Create Dimension Value.
        Initialize();
        GeneralLedgerSetup.Get();
        DimensionValueCode2 := CreateDimensionValue(GeneralLedgerSetup."Global Dimension 1 Code");  // Global Variavle used for Page Handler.

        // Exercise: Post General Line With Dimensions and Set filter on G/L Balance by Dimension Page With Amount Field as Debit Amount.
        SelectGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJnlLineWithDimension(GenJournalLine, GenJournalBatch, DimensionValueCode2);
        TotalAmount := GenJournalLine.Amount;  // Global Variavle used for Page Handler.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        SetFilterOnGLBalancebyDimension(AmountField::"Debit Amount", GeneralLedgerSetup."Global Dimension 1 Code", '', '', '');

        // Verify: Verify Dimension Value and Total Amount on G/L Balance by Dim. Matrix Amount Page Handler.
    end;

    [Test]
    [HandlerFunctions('GLBalancebyDimMatrixAmountHandler')]
    [Scope('OnPrem')]
    procedure BalanceByDimensionsCreditAmount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        AmountField: Option Amount,"Debit Amount","Credit Amount";
    begin
        // Post General Line with Dimension,Open G/L Balance by Dimension with Amount Filed as Credit Amount and Verify G/L Balance by Dim. Matrix Page.

        // Setup: Create Dimension Value.
        Initialize();
        GeneralLedgerSetup.Get();
        DimensionValueCode2 := CreateDimensionValue(GeneralLedgerSetup."Global Dimension 1 Code");  // Global Variavle used for Page Handler.

        // Exercise: Post General Lines With Different Dimensions and Set filter on G/L Balance by Dimension Page With Amount Field as Debit Amount.
        SelectGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJnlLineWithDimension(GenJournalLine, GenJournalBatch, DimensionValueCode2);
        TotalAmount := GenJournalLine.Amount;  // Global Variavle used for Page Handler.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        SetFilterOnGLBalancebyDimension(AmountField::"Credit Amount", GeneralLedgerSetup."Global Dimension 1 Code", '', '', '');

        // Verify: Verify Dimension Value and Total Amount on G/L Balance by Dim. Matrix Page Amount Handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountByPage()
    var
        SourceGLAccount: Record "G/L Account";
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
        GLAccountNo: Code[20];
    begin
        // Create New G/L Account by Page and verify it.

        // Setup.
        Initialize();
        LibraryNotificationMgt.DisableMyNotification(FinancialReportMgt.GetUpdateFinancialReportNotificationId());

        // Exercise: Create New G/L Account by Chart Of Accounts Page.
        SourceGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccountNo := CreateGLAccountByPage(SourceGLAccount);

        // Verify: Verify values on G/L Account.
        VerifyValuesOnGLAccount(SourceGLAccount, GLAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceWithoutFilter()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLBalance: TestPage "G/L Balance";
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Post General Line with Account Type as G/L Account. Open G/L Balance Page Without Filters and Verify Balance.

        // Setup: Create and Post General Journal Line with Account Type as G/L Account and Random Values.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        Amount2 := Amount + LibraryRandom.RandDec(50, 2);
        CreateAndPostGeneralJnlLines(GenJournalLine, -Amount, Amount2);

        // Exercise: Open G/L Balance Page Without Filters.
        SetFilterOnGLBalancePage(GLBalance, false, GenJournalLine."Account No.");

        // Verify: Balance on G/L Balance Page.
        GLBalance."Debit Amount".AssertEquals(Amount2 - Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceDebitAndCreditTotals()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLBalance: TestPage "G/L Balance";
        Amount: Decimal;
    begin
        // Post General Line with Account Type as G/L Account. Open G/L Balance Page with Debit and Credit Totals as True and Verify Balance.

        // Setup: Create and Post General Journal Line with Account Type as G/L Account and Random Values.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        CreateAndPostGeneralJnlLines(GenJournalLine, -Amount, Amount);

        // Exercise: Open G/L Balance Page with Debit and Credit Totals as True.
        SetFilterOnGLBalancePage(GLBalance, true, GenJournalLine."Account No.");

        // Verify: Balance on G/L Balance Page.
        GLBalance."Debit Amount".AssertEquals(Amount);
        GLBalance."Credit Amount".AssertEquals(Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountBalanceWithoutFilter()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccountBalance: TestPage "G/L Account Balance";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Post General Line with Account Type as G/L Account. Open G/L Account Balance Page Without Filters and Verify Balance.

        // Setup: Create and Post General Journal Line with Account Type as G/L Account and Random Values.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        Amount2 := Amount + LibraryRandom.RandDec(50, 2);
        CreateAndPostGeneralJnlLines(GenJournalLine, -Amount, Amount2);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Open G/L Account Balance Page Without Filters.
        SetFilterOnGLAccountBalancePage(GLAccountBalance, PeriodType::Day, false, GenJournalLine."Account No.");

        // Verify: Balance on G/L Account Balance Page.
        GLAccountBalance.GLBalanceLines.DebitAmount.AssertEquals(Amount2 - Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountBalanceDebitAndCreditTotals()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccountBalance: TestPage "G/L Account Balance";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        Amount: Decimal;
    begin
        // Post General Line with Account Type as G/L Account. Open G/L Account Balance Page with Debit and Credit Totals as True and Verify Balance.

        // Setup: Create and Post General Journal Line with Account Type as G/L Account and Random Values.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        CreateAndPostGeneralJnlLines(GenJournalLine, -Amount, Amount);

        // Exercise: Open G/L Account Balance Page with Debit and Credit Totals as True.
        SetFilterOnGLAccountBalancePage(GLAccountBalance, PeriodType::Day, true, GenJournalLine."Account No.");

        // Verify: Balance on G/L Account Balance Page.
        GLAccountBalance.GLBalanceLines.DebitAmount.AssertEquals(Amount);
        GLAccountBalance.GLBalanceLines.CreditAmount.AssertEquals(Amount);
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionsHandler,AnalysisByDimensionsMatrixHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewWithoutUpdate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AnalysisViewCode: Code[10];
    begin
        // Verify Amount on Analysis by Dimension Matrix without Updating Analysis View.

        // Setup: Create and Post Invoice from General Journal.
        Initialize();
        CreateAndPostGeneralJournalLine(GenJournalLine);

        // Create Analysis View.
        AnalysisViewCode := CreateAnalysisView(GenJournalLine."Account No.");

        // Exercise: Open Page Analysis View List and Invoke Edit Analysis.
        SetFilterOnAnalysisViewList(AnalysisViewCode, false);

        // Verify: Verify Total Amount on Analysis By Dimensions Matrix page using AnalysisByDimensionsMatrixHandler.
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionsHandler,AnalysisByDimensionsMatrixHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewWithUpdate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AnalysisViewCode: Code[10];
    begin
        // Verify Amount on Analysis by Dimension Matrix with Updating Analysis View.

        // Setup: Create and Post Invoice from General Journal.
        Initialize();
        CreateAndPostGeneralJournalLine(GenJournalLine);
        TotalAmount := GenJournalLine.Amount;

        // Create Analysis View.
        AnalysisViewCode := CreateAnalysisView(GenJournalLine."Account No.");

        // Exercise: Open Page Analysis View List, Update Analysis View and Invoke Edit Analysis.
        SetFilterOnAnalysisViewList(AnalysisViewCode, true);

        // Verify: Verify Total Amount on Analysis By Dimensions Matrix page using AnalysisByDimensionsMatrixHandler.
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimShowColumnPeriodHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewWithDateFilter()
    var
        AnalysisViewList: TestPage "Analysis View List";
    begin
        // [SCENARIO 122000] Date Filter is not cleared after value input.
        Initialize();

        // [GIVEN] Open Page Analysis View List
        AnalysisViewList.OpenView();
        AnalysisViewList.First();

        // [WHEN] Change option Show as Lines and set Date Filter = X
        AnalysisViewList.EditAnalysis.Invoke();

        // [THEN] Verify that Date Filter = X in AnalysisByDimShowColumnPeriodHandler
    end;

    [Test]
    [HandlerFunctions('OptionDialogForDimensionCombination,ConfirmHandlerYes,MyDimValueCombinationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure SetDimensionCombinationToLimitedAndSeeValues()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        // Set Dimension Combination value to Limited on Dimension Combination page.

        // Setup: Create Dimension and set the Value of option as Limited.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        // Exercise: Open Dimension Combintion Page and set the option Value as Limited.
        GlobalOption := GlobalOption::Limited;  // Set Option Value to Limited on Dimension Combination Page.
        OpenDimensionCombinationPageAndSetValue(Dimension.Code);

        GlobalOption := GlobalOption::Blocked;  // Set Option Value to Blocked on Dimension Combination Page.
        OpenDimensionCombinationPageAndSetValue(Dimension.Code);

        // Verify in ModalPageHandler: MyDim Value Combinations is launched
    end;

    [Test]
    [HandlerFunctions('OptionDialogForDimensionCombination,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure SetDimensionCombinationToLimitedAndSkipValues()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        // Set Dimension Combination value to Limited on Dimension Combination page.

        // Setup: Create Dimension and set the Value of option as Limited.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        // Exercise: Open Dimension Combintion Page and set the option Value as Limited.
        GlobalOption := GlobalOption::Limited;  // Set Option Value to Limited on Dimension Combination Page.
        OpenDimensionCombinationPageAndSetValue(Dimension.Code);

        GlobalOption := GlobalOption::Blocked;  // Set Option Value to Blocked on Dimension Combination Page.
        OpenDimensionCombinationPageAndSetValue(Dimension.Code);

        // Verify in ModalPageHandler: MyDim Value Combinations is not launched
    end;

    [Test]
    [HandlerFunctions('GLEntriesDimOvervMatrixHandler')]
    [Scope('OnPrem')]
    procedure GLEntriesDimensionOverviewMatrix()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntriesDimensionOverview: TestPage "G/L Entries Dimension Overview";
    begin
        // Post General Line with Dimension and Verify Entries in G/L entry Dimension Overview Matrix.

        // Setup: Create Dimension Value. Create and Post General Journal Line with Dimension.
        Initialize();
        GeneralLedgerSetup.Get();
        SelectGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJnlLineWithDimension(
          GenJournalLine, GenJournalBatch, CreateDimensionValue(GeneralLedgerSetup."Global Dimension 1 Code"));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        TotalAmount := GenJournalLine.Amount;  // Global Variable used for Page Handler.
        GLAccount3 := GenJournalLine."Account No.";  // Global Variable used for Page Handler.

        // Exercise: Open G/L Entries Dimension Overview Page.
        GLEntriesDimensionOverview.OpenEdit();
        GLEntriesDimensionOverview.ShowMatrix.Invoke();

        // Verify: Verify Total Amount on G/L Entries Dimension Overview Matrix Page Handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceByDimMatrixOpen()
    var
        GLAccount: Record "G/L Account";
        GLBalByDimMatrix: TestPage "G/L Balance by Dim. Matrix";
    begin
        // Verify that G/L Balance By Dim. Matrix can be opened without Load() func
        GLAccount.FindFirst();
        GLBalByDimMatrix.OpenView();

        GLBalByDimMatrix.Code.AssertEquals(GLAccount."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceDimMatrixOpen()
    var
        GLBalanceByDimMatrix: TestPage "G/L Balance by Dim. Matrix";
    begin
        // [SCENARIO TFS107201] G/L Balance by Dim. Matrix can be opened without Load() func with column captions

        // [WHEN] Open G/L Balance by Dim. Matrix
        GLBalanceByDimMatrix.OpenView();

        // [THEN] Default caption loaded for Field1 column
        Assert.AreEqual(Format(WorkDate()), GLBalanceByDimMatrix.Field1.Caption, IncorrectColumnCaptionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroPostingNotAllowedGLAccPostingTypeEmpty()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Posting]
        // [SCENARIO 361902] Zero posting is not allowed if posting type is blank in the general journal and zero amount
        Initialize();

        // [GIVEN] Gen. Journal Line with G/L Account with blank Gen. Posting Type and 0 amount
        CreateGenJournalLine(
          GenJournalLine, CreateGLAccountWithPostingType(GLAccount."Gen. Posting Type"::" "), 0);

        // [WHEN] Posting Gen. Journal Line
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error message that Amount must have a value appears.
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption(Amount), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroPostingNotAllowedGLAccPostingTypeNonEmpty()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Posting]
        // [SCENARIO 361902] Zero posting is not allowed if posting type is not blank in the general journal and zero amount
        Initialize();

        // [GIVEN] Gen. Journal Line with G/L Account with not blank Gen. Posting Type and 0 amount
        CreateGenJournalLine(
          GenJournalLine, CreateGLAccountWithPostingType(GLAccount."Gen. Posting Type"::Purchase), 0);

        // [WHEN] Posting Gen. Journal Line
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error message that Amount must have a value appears.
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption(Amount), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceDateFilterFieldNetChange()
    var
        GLBalance: TestPage "G/L Balance";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";
    begin
        // [FEATURE] [UI] [G/L Balance] [Date Filter]
        // [SCENARIO 381766] Page 414 "G/L Balance" shows "Date Filter" field value in case of "View As" = "Net Change"
        Initialize();

        // [GIVEN] Open "G/L Balance" page
        GLBalance.OpenView();

        // [WHEN] Validate "View by" = "Day", "View As" = "Net Change"
        GLBalance.PeriodType.SetValue(PeriodType::Day);
        GLBalance.AmountType.SetValue(AmountType::"Net Change");

        // [THEN] "Date Filter" = "25-01-18..C25-01-18"
        GLBalance.DateFilter.AssertEquals(StrSubstNo('%1..%2', WorkDate(), ClosingDate(WorkDate())));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceDateFilterFieldBalanceAtDate()
    var
        GLBalance: TestPage "G/L Balance";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";
    begin
        // [FEATURE] [UI] [G/L Balance] [Date Filter]
        // [SCENARIO 381766] Page 414 "G/L Balance" shows "Date Filter" field value in case of "View As" = "Balance at Date"
        Initialize();

        // [GIVEN] Open "G/L Balance" page
        GLBalance.OpenView();

        // [WHEN] Validate "View by" = "Day", "View As" = "Balance at Date"
        GLBalance.PeriodType.SetValue(PeriodType::Day);
        GLBalance.AmountType.SetValue(AmountType::"Balance at Date");

        // [THEN] "Date Filter" = "''..C25-01-18"
        GLBalance.DateFilter.AssertEquals(StrSubstNo('%1..%2', '''''', ClosingDate(WorkDate())));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountCategoryValidationOfTheSameValue()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 203574] "Income/Balance" should not be changed when revalidate "Account Category" with empty value
        Initialize();

        // [GIVEN] G/L Account with empty "Account Category" and "Income/Balance" = "Income Statement"
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Account Category", GLAccount."Account Category"::" ");
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Income Statement");

        // [WHEN] Revalidate "Account Category" field
        GLAccount.Validate("Account Category");

        // [THEN] "Income/Balance" has "Income Statement" value
        GLAccount.TestField("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountCategoryValidationOnGLAccountCardWhenNameChanged()
    var
        GLAccount: Record "G/L Account";
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
        GLAccountCard: TestPage "G/L Account Card";
        AccName: Text[100];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 205100] "Name" should not be changed when revalidate "Account Category" with empty value on G/L Account Card
        Initialize();
        LibraryNotificationMgt.DisableMyNotification(FinancialReportMgt.GetUpdateFinancialReportNotificationId());

        // [GIVEN] G/L Account with empty "Account Category"
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Account Category", GLAccount."Account Category"::" ");
        GLAccount.Modify(true);

        // [GIVEN] Set Name = "ABC" on the G/L Account Card
        AccName := LibraryUtility.GenerateGUID();
        GLAccountCard.OpenEdit();
        GLAccountCard.GotoRecord(GLAccount);
        GLAccountCard.Name.SetValue(AccName);

        // [WHEN] Validate "Account Category" field with empty value on the G/L Account Card
        GLAccountCard."Account Category".SetValue(' ');

        // [THEN] Name have the same value "ABC"
        GLAccountCard.Name.AssertEquals(AccName);
    end;

    [Test]
    procedure GLBalanceByDimWrongDateFilterUI()
    var
        GLBalancebyDimension: TestPage "G/L Balance by Dimension";
    begin
        // [FEATURE] [UI] [G/L Balance] [Date Filter]
        // [SCENARIO 404617] An error trying validate a wrong Date Filter on the G/L Balance By Dimension page
        GLBalancebyDimension.OpenEdit();
        asserterror GLBalancebyDimension.DateFilter.SetValue('qwerty');
        Assert.ExpectedErrorCode('TestValidation');
        Assert.ExpectedError('Date Filter');
    end;

    [Test]
    procedure GLBalanceByDimDateFilterChangesColumnSetValue()
    var
        GLBalancebyDimension: TestPage "G/L Balance by Dimension";
        AnalysisPeriodType: Enum "Analysis Period Type";
        DateFilter: Text;
    begin
        // [FEATURE] [UI] [G/L Balance] [Date Filter]
        // [SCENARIO 404617] Validating of Date Filter on the G/L Balance By Dimension page changes the Column Set value
        GLBalancebyDimension.OpenEdit();
        GLBalancebyDimension.PeriodType.SetValue(AnalysisPeriodType::Month);

        DateFilter := StrSubstNo('%1..%2', 20210101D, 20210201D);
        GLBalancebyDimension.DateFilter.SetValue(DateFilter);
        GLBalancebyDimension.MATRIX_ColumnSet.AssertEquals(DateFilter);

        DateFilter := StrSubstNo('%1..%2', 20210101D, 20210301D);
        GLBalancebyDimension.DateFilter.SetValue(DateFilter);
        GLBalancebyDimension.MATRIX_ColumnSet.AssertEquals(DateFilter);

        GLBalancebyDimension.Close();
    end;

    [Test]
    [HandlerFunctions('GLBalancebyDimMatrixDrillDownAmount1Handler')]
    procedure GLBalanceByDimDateFilterForBalanceAtDate()
    var
        GLBalancebyDimension: TestPage "G/L Balance by Dimension";
        GeneralLedgerEntries: TestPage "General Ledger Entries";
        StartDate: Date;
        EndDate: Date;
        DateFilter: Text;
        ExpectedDateFilter: Text;
    begin
        // [FEATURE] [UI] [G/L Balance] [Date Filter]
        // [SCENARIO 413277] G/L Balance by Dimension does not apply date filter for option "View as" = "Balance at Date"
        Initialize();

        // [GIVEN] G/L Balance by Dimension with parameters "Period Type" = Month, "Amount Type" = "Balance at Date"
        GLBalancebyDimension.OpenEdit();
        GLBalancebyDimension.PeriodType.SetValue("Analysis Period Type"::Month);
        GLBalancebyDimension.AmountType.SetValue("Analysis Amount Type"::"Balance at Date");
        GLBalancebyDimension.ClosingEntryFilter.SetValue(0);

        // [GIVEN] Set "Date Filter" = "01.01.21..01.03.21"
        StartDate := CalcDate('<-CM>', WorkDate());
        EndDate := CalcDate('<-CM+2M', StartDate);
        DateFilter := StrSubstNo('%1..%2', StartDate, EndDate);
        GLBalancebyDimension.DateFilter.SetValue(DateFilter);

        // [GIVEN] Show matrix
        GeneralLedgerEntries.Trap();
        GLBalancebyDimension.ShowMatrix.Invoke();

        // [WHEN] DrillDown ammount for column 1 (in handler GLBalancebyDimMatrixDrillDownAmount1Handler)

        // [THEN] General Ledger Entries page has Posting Date filter = "''..C31.01.21"
        ExpectedDateFilter := StrSubstNo('''''..%1', ClosingDate(CalcDate('<CM>', StartDate)));
        Assert.AreEqual(ExpectedDateFilter, GeneralLedgerEntries.Filter.GetFilter("Posting Date"), 'Invalid date filter');
    end;

    [Test]
    procedure RunningBalance()
    var
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
        CalcRunningGLAccBalance: Codeunit "Calc. Running GL. Acc. Balance";
        i: Integer;
        TotalAmt: Decimal;
        TotalAmtACY: Decimal;
    begin
        // [SCENARIO] Bank ledger entries show a running balance
        // [FEATURE] [Bank]
        Initialize();

        // [GIVEN] Bank Account and some entries - also more on same day.
        LibraryERM.CreateGLAccount(GLAccount);
        if GLEntry.FindLast() then;
        for i := 1 to 5 do begin
            GLEntry."Entry No." += 1;
            GLEntry."G/L Account No." := GLAccount."No.";
            GLEntry."Posting Date" := DMY2Date(1 + i div 2, 1, 2025);  // should give Januar 1,2,2,3,3,4
            GLEntry.Amount := 1;
            GLEntry."Debit Amount" := 1;
            GLEntry."Credit Amount" := 0;
            GLEntry."Amount" := 1;
            GLEntry."Additional-Currency Amount" := 1;
            GLEntry.Insert();
        end;

        // [WHEN] Running balance is calculated per entry
        // [THEN] RunningBalance and RunningBalanceLCY are the sum of entries up till then.
        GLAccount.CalcFields(Balance, "Additional-Currency Balance");
        Assert.AreEqual(5, GLAccount.Balance, 'Amount out of balance.');
        Assert.AreEqual(5, GLAccount."Additional-Currency Balance", 'Amount (LCY) out of balance.');
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.SetCurrentKey("Posting Date", "Entry No.");
        if GLEntry.FindSet() then
            repeat
                TotalAmt += GLEntry.Amount;
                TotalAmtACY += GLEntry."Additional-Currency Amount";
                Assert.AreEqual(TotalAmt, CalcRunningGLAccBalance.GetGLAccBalance(GLEntry), 'TotalAmt out of balance');
                Assert.AreEqual(TotalAmtACY, CalcRunningGLAccBalance.GetGLAccBalanceACY(GLEntry), 'TotalAmtACY out of balance');
            until GLEntry.Next() = 0;
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Accounts");
        // Setup demo data.

        // Clear Global Variables.
        Clear(TotalAmount);
        Clear(TotalAmount2);
        Clear(DimensionValueCode2);
        Clear(DimensionValueCode3);
        Clear(GlobalOption);
        Clear(GLAccount3);
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Accounts");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Accounts");
    end;

    local procedure CreateAnalysisView(AccountFilter: Code[20]): Code[10]
    var
        AnalysisView: Record "Analysis View";
    begin
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate("Account Filter", AccountFilter);
        AnalysisView.Modify(true);
        exit(AnalysisView.Code);
    end;

    local procedure CreateDimensionValue(DimensionCode: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        exit(DimensionValue.Code);
    end;

    local procedure CreateGeneralJnlLineWithDimension(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; ShortcutDimension1Code: Code[20])
    begin
        // Create General Journal Line with Random Values.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Shortcut Dimension 1 Code", ShortcutDimension1Code);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; Amount: Decimal)
    var
        LibraryJournals: Codeunit "Library - Journals";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount);
    end;

    local procedure CreateGLAccountWithPostingType(PostingType: Enum "General Posting Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", PostingType);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateAndPostGeneralJnlLines(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; Amount2: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccountNo: Code[20];
    begin
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        SelectGeneralJournalBatch(GenJournalBatch);

        // Create General Journal Line with Random Values.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount2);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGeneralJournalBatch(GenJournalBatch);

        // Create General Journal Line with Random Values.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Account No.");
    end;

    local procedure SelectGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure SetFilterOnAnalysisViewList(AnalysisViewCode: Code[10]; UpdateAnalysisView: Boolean)
    var
        AnalysisViewList: TestPage "Analysis View List";
    begin
        AnalysisViewList.OpenView();
        AnalysisViewList.FILTER.SetFilter(Code, AnalysisViewCode);
        if UpdateAnalysisView then
            AnalysisViewList."&Update".Invoke();
        AnalysisViewList.EditAnalysis.Invoke();
    end;

    local procedure SetFilterOnGLBalancebyDimension(AmountField: Option; DimensionCode: Code[20]; Dim2Filter: Code[20]; GLAccountNo: Code[20]; GLAccountNo2: Code[20])
    var
        GLBalancebyDimension: TestPage "G/L Balance by Dimension";
    begin
        GLBalancebyDimension.OpenEdit();
        GLBalancebyDimension.GLAccFilter.SetValue('');
        GLBalancebyDimension.LineDimCode.SetValue(DimensionCode);
        GLBalancebyDimension.AmountField.SetValue(AmountField);
        if (GLAccountNo <> '') and (GLAccountNo2 <> '') then
            GLBalancebyDimension.GLAccFilter.SetValue(GLAccountNo + '|' + GLAccountNo2);
        GLBalancebyDimension.Dim2Filter.SetValue(Dim2Filter);
        GLBalancebyDimension.DateFilter.SetValue(WorkDate());
        GLBalancebyDimension.ShowMatrix.Invoke();
    end;

    local procedure SetFilterOnGLBalancePage(var GLBalance: TestPage "G/L Balance"; DebitAndCreditTotals: Boolean; AccountNo: Code[20])
    begin
        GLBalance.OpenView();
        GLBalance.DebitCreditTotals.SetValue(DebitAndCreditTotals);
        GLBalance.FILTER.SetFilter("No.", AccountNo);
        GLBalance.First();
    end;

    local procedure SetFilterOnGLAccountBalancePage(var GLAccountBalance: TestPage "G/L Account Balance"; PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"; DebitAndCreditTotals: Boolean; AccountNo: Code[20])
    begin
        GLAccountBalance.OpenView();
        GLAccountBalance.DebitCreditTotals.SetValue(DebitAndCreditTotals);
        GLAccountBalance.PeriodType.SetValue(PeriodType);
        GLAccountBalance.FILTER.SetFilter("No.", AccountNo);
        GLAccountBalance.GLBalanceLines.FILTER.SetFilter("Period Start", Format(WorkDate()));
        GLAccountBalance.First();
    end;

    local procedure SetupDeltaAssertions(Customer: Record Customer; BalAccount: Record "G/L Account"; Delta: Decimal)
    var
        Account: Record "G/L Account";
    begin
        FindPostingAccount(Account, Customer);

        // Setup contract that account must change by +Delta and balancing account by -Delta.
        DeltaAssert.Init();
        DeltaAssert.AddWatch(DATABASE::"G/L Account", Account.GetPosition(), Account.FieldNo(Balance), Delta);
        DeltaAssert.AddWatch(DATABASE::"G/L Account", BalAccount.GetPosition(), BalAccount.FieldNo(Balance), -Delta);
    end;

    local procedure FindPostingAccount(var Account: Record "G/L Account"; Customer: Record Customer)
    var
        PostingGroup: Record "Customer Posting Group";
    begin
        PostingGroup.Get(Customer."Customer Posting Group");
        Account.Get(PostingGroup."Receivables Account");
    end;

    local procedure CreateGLAccountByPage(GLAccount: Record "G/L Account") GLAccountNo: Code[20]
    var
        ChartOfAccounts: TestPage "Chart of Accounts";
    begin
        ChartOfAccounts.OpenNew();
        ChartOfAccounts."No.".SetValue(LibraryUtility.GenerateRandomCode(GLAccount.FieldNo("No."), DATABASE::"G/L Account"));
        ChartOfAccounts."Income/Balance".SetValue(GLAccount."Income/Balance");
        ChartOfAccounts."Account Type".SetValue(GLAccount."Account Type");
        ChartOfAccounts."Gen. Posting Type".SetValue(GLAccount."Gen. Posting Type");
        ChartOfAccounts."Gen. Bus. Posting Group".SetValue(GLAccount."Gen. Bus. Posting Group");
        ChartOfAccounts."Gen. Prod. Posting Group".SetValue(GLAccount."Gen. Prod. Posting Group");

        GLAccountNo := ChartOfAccounts."No.".Value();
        ChartOfAccounts.OK().Invoke();
    end;

    local procedure PostInvoice(Customer: Record Customer; AccountNo: Code[20]; Delta: Decimal)
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine,
          GenJnlBatch."Journal Template Name",
          GenJnlBatch.Name,
          GenJnlLine."Document Type"::Invoice,
          GenJnlLine."Account Type"::Customer,
          Customer."No.",
          Delta);

        GenJnlLine."Bal. Account No." := AccountNo;
        GenJnlLine."Currency Code" := '';
        GenJnlLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure OpenDimensionCombinationPageAndSetValue(DimensionCode: Code[20])
    var
        DimensionCombinations: TestPage "Dimension Combinations";
    begin
        DimensionCombinations.OpenEdit();
        DimensionCombinations.MatrixForm.FILTER.SetFilter(Code, DimensionCode);
        DimensionCombinations.MatrixForm.First();

        if DimensionCombinations.MatrixForm.Field1.Caption = DimensionCode then
            DimensionCombinations.MatrixForm.Field2.AssistEdit()
        else
            DimensionCombinations.MatrixForm.Field1.AssistEdit();
    end;

    local procedure VerifyValuesOnGLAccount(SourceGLAccount: Record "G/L Account"; GLAccountNo: Code[20])
    var
        GLAccount2: Record "G/L Account";
    begin
        GLAccount2.Get(GLAccountNo);
        GLAccount2.TestField("Income/Balance", SourceGLAccount."Income/Balance");
        GLAccount2.TestField("Account Type", SourceGLAccount."Account Type");
        GLAccount2.TestField("Gen. Posting Type", SourceGLAccount."Gen. Posting Type");
        GLAccount2.TestField("Gen. Bus. Posting Group", SourceGLAccount."Gen. Bus. Posting Group");
        GLAccount2.TestField("Gen. Prod. Posting Group", SourceGLAccount."Gen. Prod. Posting Group");
    end;

    local procedure VerifyAmountOnGLBalancebyDimMatrix(var GLBalancebyDimMatrix: TestPage "G/L Balance by Dim. Matrix"; DimensionValueCode: Code[20]; TotalAmount3: Decimal)
    begin
        GLBalancebyDimMatrix.FindFirstField(Code, DimensionValueCode);
        GLBalancebyDimMatrix.TotalAmount.AssertEquals(TotalAmount3);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLBalancebyDimMatrixHandler(var GLBalancebyDimMatrix: TestPage "G/L Balance by Dim. Matrix")
    begin
        VerifyAmountOnGLBalancebyDimMatrix(GLBalancebyDimMatrix, DimensionValueCode2, TotalAmount);
        VerifyAmountOnGLBalancebyDimMatrix(GLBalancebyDimMatrix, DimensionValueCode3, TotalAmount2);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLBalancebyDimMatrixDifferentDimensionHandler(var GLBalancebyDimMatrix: TestPage "G/L Balance by Dim. Matrix")
    begin
        GLBalancebyDimMatrix.First();
        repeat
            GLBalancebyDimMatrix.TotalAmount.AssertEquals(0);
        until not GLBalancebyDimMatrix.Next();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLBalancebyDimMatrixAmountHandler(var GLBalancebyDimMatrix: TestPage "G/L Balance by Dim. Matrix")
    begin
        VerifyAmountOnGLBalancebyDimMatrix(GLBalancebyDimMatrix, DimensionValueCode2, TotalAmount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLBalancebyDimMatrixDrillDownAmount1Handler(var GLBalancebyDimMatrix: TestPage "G/L Balance by Dim. Matrix")
    begin
        GLBalancebyDimMatrix.Field1.Drilldown();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLEntriesDimOvervMatrixHandler(var GLEntriesDimOvervMatrix: TestPage "G/L Entries Dim. Overv. Matrix")
    begin
        GLEntriesDimOvervMatrix.FILTER.SetFilter("G/L Account No.", GLAccount3);
        GLEntriesDimOvervMatrix.First();
        GLEntriesDimOvervMatrix.Amount.AssertEquals(TotalAmount);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionsHandler(var AnalysisbyDimensions: TestPage "Analysis by Dimensions")
    begin
        Commit();
        AnalysisbyDimensions.ShowMatrix.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AnalysisByDimShowColumnPeriodHandler(var AnalysisbyDimensions: TestPage "Analysis by Dimensions")
    var
        LineDimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4","Cash Flow Account","Cash Flow Forecast";
        ColumnDimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4","Cash Flow Account","Cash Flow Forecast";
        Days: Integer;
    begin
        AnalysisbyDimensions.ColumnDimCode.SetValue(ColumnDimOption::Period);
        AnalysisbyDimensions.LineDimCode.SetValue(LineDimOption::"Business Unit");
        Days := LibraryRandom.RandInt(10);
        AnalysisbyDimensions.DateFilter.SetValue(WorkDate() + Days);
        AnalysisbyDimensions.DateFilter.AssertEquals(WorkDate() + Days);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionsMatrixHandler(var AnalysisByDimensionsMatrix: TestPage "Analysis by Dimensions Matrix")
    begin
        AnalysisByDimensionsMatrix.First();
        AnalysisByDimensionsMatrix.TotalAmount.AssertEquals(TotalAmount);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure OptionDialogForDimensionCombination(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := GlobalOption;  // Set Value to Limited for Dimension.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MyDimValueCombinationsModalPageHandler(var MyDimValueCombinations: TestPage "MyDim Value Combinations")
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}
