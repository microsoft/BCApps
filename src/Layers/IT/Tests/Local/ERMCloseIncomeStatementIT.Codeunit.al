codeunit 144113 "ERM Close Income Statement IT"
{
    // // [FEATURE] [Close Fiscal Year]
    // 1. Verify Error when no Balancing Account No. is defined on report.
    // 2. Check Amount on GL Entry After Running Close Income Statement with Closing Fiscal Year.
    // 3. Verify Error when no Closing Account No. is defined on report.
    // 4. Verify Error when no Document No. is defined on report.
    // 5. Verify Error when no Ending Date is defined on report.
    // 6. Check Amount on GL Entry After Running Close Open Balance Sheet Report without additional currency with Closing Fiscal Year.
    // 7. Check Amount on GL Entry After Running Close Open Balance Sheet Report with additional currency with Closing Fiscal Year.
    // 8. Check Amount on GL Entry After Running Close Open Balance Sheet with Additional Currency.
    // 9. Check Amount on GL Entry After Running Close Open Balance Sheet without Additional Currency.
    // 10. Check GL Account No. after running Fiscal Year Balance report.
    // 11. Check dimensions after running close open balance sheet report with global dimensions only
    // 12. Check dimensions after running close open balance sheet report with several dimensions including globals
    // 
    // Covers Test Cases for WI - 346255.
    // ------------------------------------------------------------
    // Test Function Name                                    TFS ID
    // ------------------------------------------------------------
    // CloseIncomeStatementBalancingAccountError      151892,151893
    // FiscalYearAdditionalCurrency                   151894,151895
    // 
    // Covers Test Cases for WI - 346256.
    // ---------------------------------------------------------------------------
    // Test Function Name                                                   TFS ID
    // ---------------------------------------------------------------------------
    // CloseOpenBalanceSheetClosingAccountError                             151896
    // CloseOpenBalanceSheetDocumentNoError
    // CloseOpenBalanceSheetEndingDateError
    // CloseOpenBalanceSheetWithoutAdditionalCurrency  152658,155478,155479,157174
    // CloseOpenBalanceSheetWithAdditionalCurrency     155485,155486,157176,157177
    // 
    // Covers Test Cases for WI - 346257.
    // ----------------------------------------------------------------------------
    // Test Function Name                                                    TFS ID
    // ----------------------------------------------------------------------------
    // AnnualProfitLossAmountWithAdditionalCurrency            268647,268406,268429
    // AnnualProfitLossAmountWithoutAdditionalCurrency  157175,268647,268407,268428
    // RunFiscalBalanceReport                                                244531
    // 
    // CloseOpenBalanceSheet_GlobalOnlyDim                                   355461
    // CloseOpenBalanceSheet_SeveralDim                                      355461

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryReportDataSet: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountErr: Label '%1 must be %2 in %3.';
        BalancingAccountNoErr: Label 'Please enter Balancing Account No.';
        ClosingAccountErr: Label 'Please specify the Closing Account No. and the Opening Account No.';
        DocumentNoErr: Label 'Please enter a Document No.';
        EndingDateErr: Label 'Please enter the ending date for the fiscal year.';
        GLAccountNoCap: Label 'G_L_Account___No__';
        LibraryDimension: Codeunit "Library - Dimension";
        IncorrectDimSetIDErr: Label 'Incorrect dimension set ID';
        IncomeBalanceType: Option "Income Statement","Balance Sheet";

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementBalancingAccountError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        OldAdditionalReportingCurrency: Code[10];
    begin
        // Verify Error when no Balancing Account No. is defined on report.

        // Setup: Update New currency on General Ledger Setup.
        Initialize();
        OldAdditionalReportingCurrency := UpdateAddnlReportingCurrencyGeneralLedgerSetup(CreateCurrencyAndExchangeRate());
        CreateAndPostGenJournalLine(GenJournalLine, CalcDate('<CM>', LibraryFiscalYear.GetLastPostingDate(true)));  // Using true for closed.

        // Exercise: Run Close Income Statement Report.
        asserterror RunCloseIncomeStatement(GenJournalLine, CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true)), '');  // Using true for closed, blank for Balancing Account No.

        // Verify: Verify actual error message Please enter Balancing Account No.
        Assert.ExpectedError(BalancingAccountNoErr);

        // Tear Down.
        UpdateAddnlReportingCurrencyGeneralLedgerSetup(OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FiscalYearAdditionalCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AdditionalCurrencyAmount: Decimal;
        CurrencyCode: Code[10];
        OldAdditionalReportingCurrency: Code[10];
    begin
        // Check Amount on GL Entry After Running Close Income Statement with Closing Fiscal Year.

        // Setup: Update New currency on General Ledger Setup.
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        OldAdditionalReportingCurrency := UpdateAddnlReportingCurrencyGeneralLedgerSetup(CurrencyCode);
        CreateAndPostGenJournalLine(GenJournalLine, CalcDate('<CM>', LibraryFiscalYear.GetLastPostingDate(true)));  // Using true for closed.
        AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(GenJournalLine.Amount, '', CurrencyCode, WorkDate());  // Using blank for To Currency.

        // Exercise: Run Close Income Statement Report.
        RunCloseIncomeStatement(GenJournalLine, CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true)), CreateGLAccount());  // Using true for closed.

        // Verify: Verify GL Entry for Fiscal Year Ending Date.
        VerifyGLEntryForFiscalYear(GenJournalLine."Account No.", -AdditionalCurrencyAmount, GenJournalLine.Amount);

        // Tear Down.
        UpdateAddnlReportingCurrencyGeneralLedgerSetup(OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('CloseOpenBalanceSheetRequestPageHandler,DimensionSelectionMultipleModalPageHandler,GeneralJournalBatchesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CloseOpenBalanceSheetClosingAccountError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Error when no Closing Account No. is defined on report.

        // Setup: Create and post General Journal Line.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, LibraryFiscalYear.GetLastPostingDate(true));  // Using true for closed.

        // Exercise: Run Close Open Balance Sheet Report.
        asserterror
          RunCloseOpenBalanceSheet(
            GenJournalLine, '', IncStr(GenJournalLine."Document No."), false,
            CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true)));  // Using blank for Closing Account No,false for Business Unit,true for closed.

        // Verify: Verify actual error message Please specify the Closing Account No. and the Opening Account No.
        Assert.ExpectedError(ClosingAccountErr);
    end;

    [Test]
    [HandlerFunctions('CloseOpenBalanceSheetRequestPageHandler,DimensionSelectionMultipleModalPageHandler,GeneralJournalBatchesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CloseOpenBalanceSheetDocumentNoError()
    begin
        // Verify Error when no Document No. is defined on report.

        // Exercise: Run Close Open Balance Sheet Report.
        CloseOpenBalanceSheetError(CreateGLAccount(), '', false, CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true)));  // Using blank for Document No,false for Business Unit,true for closed.

        // Verify: Verify actual error message Please enter a Document No.
        Assert.ExpectedError(DocumentNoErr);
    end;

    [Test]
    [HandlerFunctions('CloseOpenBalanceSheetRequestPageHandler,DimensionSelectionMultipleModalPageHandler,GeneralJournalBatchesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CloseOpenBalanceSheetEndingDateError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Error when no Ending Date is defined on report.

        // Exercise: Run Close Open Balance Sheet Report.
        CloseOpenBalanceSheetError(CreateGLAccount(), IncStr(GenJournalLine."Document No."), true, 0D);  // Using true for Business Unit,0D for ending date.

        // Verify: Verify actual error message Please enter the ending date for the fiscal year.
        Assert.ExpectedError(EndingDateErr);
    end;

    local procedure CloseOpenBalanceSheetError(GLAccount: Code[20]; DocumentNo: Code[20]; BusinessUnit: Boolean; EndingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Error when no Ending Date is defined on report.

        // Setup: Create and post General journal Line.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, LibraryFiscalYear.GetLastPostingDate(true));  // Using true for closed.

        // Exercise: Run Close Open Balance Sheet Report.
        asserterror RunCloseOpenBalanceSheet(GenJournalLine, GLAccount, DocumentNo, BusinessUnit, EndingDate);
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler,MessageHandler,CloseOpenBalanceSheetRequestPageHandler,GeneralJournalBatchesModalPageHandler,DimensionSelectionMultipleModalPageHandler')]
    [Scope('OnPrem')]
    procedure CloseOpenBalanceSheetWithoutAdditionalCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Amount on GL Entry After Running Close Open Balance Sheet Report without additional currency with Closing Fiscal Year.

        // Setup: Create and post General Journal Line.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, LibraryFiscalYear.GetLastPostingDate(true));  // Using true for closed.
        RunCloseIncomeStatement(GenJournalLine, CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true)), CreateGLAccount());  // Using true for closed.

        // Exercise: Run Close Open Balance Sheet Report.
        // Customized Date formula required to calculate Fiscal Ending Date,false for Business Unit and true for closed.
        RunCloseOpenBalanceSheet(
          GenJournalLine, GenJournalLine."Account No.", IncStr(GenJournalLine."Document No."), false,
          CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true)));

        // Verify: Verify GL Entry for Fiscal Year Ending Date.
        VerifyGLEntry(GenJournalLine."Account No.", GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler,ConfirmHandler,MessageHandler,CloseOpenBalanceSheetRequestPageHandler,DimensionSelectionMultipleModalPageHandler,GeneralJournalBatchesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CloseOpenBalanceSheetWithAdditionalCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AdditionalCurrencyAmount: Decimal;
        CurrencyCode: Code[10];
        OldAdditionalReportingCurrency: Code[10];
    begin
        // Check Amount on GL Entry After Running Close Open Balance Sheet Report with additional currency with Closing Fiscal Year.

        // Setup: Update New currency on General Ledger Setup.
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        OldAdditionalReportingCurrency := UpdateAddnlReportingCurrencyGeneralLedgerSetup(CurrencyCode);
        CreateAndPostGenJournalLine(GenJournalLine, LibraryFiscalYear.GetLastPostingDate(true));  // Using true for closed.
        AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(GenJournalLine.Amount, '', CurrencyCode, WorkDate());  // Using blank for To Currency.
        RunCloseIncomeStatement(GenJournalLine, CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true)), CreateGLAccount());  // Using true for closed.

        // Exercise: Run Close Open Balance Sheet Report.
        // Customized Date formula required to calculate Fiscal Ending Date,false for Business Unit and true for closed.
        RunCloseOpenBalanceSheet(
          GenJournalLine, GenJournalLine."Account No.", IncStr(GenJournalLine."Document No."), false,
          CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true)));

        // Verify: Verify GL Entry for Fiscal Year Ending Date.
        VerifyGLEntryForFiscalYear(GenJournalLine."Account No.", -AdditionalCurrencyAmount, GenJournalLine.Amount);

        // Tear Down.
        UpdateAddnlReportingCurrencyGeneralLedgerSetup(OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler,CloseOpenBalanceSheetRequestPageHandler,DimensionSelectionMultipleModalPageHandler,GeneralJournalBatchesModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AnnualProfitLossAmountWithAdditionalCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        OldAdditionalReportingCurrency: Code[10];
        PostingDate: Date;
        AdditionalCurrencyAmount: Decimal;
    begin
        // Check Amount on GL Entry After Running Close Open Balance Sheet with Additional Currency.

        // Setup: Close Already Opened Fiscal Year. Create New One, Update New currency on General Ledger Setup. Create and post General Journal Line.
        Initialize();
        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        OldAdditionalReportingCurrency := UpdateAddnlReportingCurrencyGeneralLedgerSetup(CurrencyCode);
        CreateAndPostGenJournalLine(GenJournalLine, LibraryFiscalYear.GetFirstPostingDate(false));  // Using false for closed.
        AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(GenJournalLine.Amount, '', CurrencyCode, WorkDate());  // Using blank for To Currecny.

        // Close Newly Created Fiscal Year. Customized Date formula required to calculate Fiscal Ending Date.
        LibraryFiscalYear.CloseFiscalYear();
        PostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));  // Using true for closed.
        RunCloseIncomeStatement(GenJournalLine, PostingDate, CreateGLAccount());

        // Exercise: Run Close Open Balance Sheet Report.
        RunCloseOpenBalanceSheet(GenJournalLine, GenJournalLine."Account No.", IncStr(GenJournalLine."Document No."), false, PostingDate);  // false for Business Unit and true for closed.

        // Verify: Verify GL Entry for Fiscal Year Ending Date.
        VerifyGLEntryForFiscalYear(GenJournalLine."Account No.", -AdditionalCurrencyAmount, GenJournalLine.Amount);

        // Tear Down.
        UpdateAddnlReportingCurrencyGeneralLedgerSetup(OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler,CloseOpenBalanceSheetRequestPageHandler,DimensionSelectionMultipleModalPageHandler,GeneralJournalBatchesModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AnnualProfitLossAmountWithoutAdditionalCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostingDate: Date;
    begin
        // Check Amount on GL Entry After Running Close Open Balance Sheet without Additional Currency.

        // Setup: Close Already Opened Fiscal Year. Create New One, Update New currency on General Ledger Setup. Create and post General Journal Line.
        Initialize();
        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();
        CreateAndPostGenJournalLine(GenJournalLine, LibraryFiscalYear.GetFirstPostingDate(false));  // Using false for closed.

        // Close Newly Created Fiscal Year. Customized Date formula required to calculate Fiscal Ending Date.
        LibraryFiscalYear.CloseFiscalYear();
        PostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));  // Using true for closed.
        RunCloseIncomeStatement(GenJournalLine, PostingDate, CreateGLAccount());

        // Exercise: Run Close Open Balance Sheet Report.
        RunCloseOpenBalanceSheet(GenJournalLine, GenJournalLine."Account No.", IncStr(GenJournalLine."Document No."), false, PostingDate);  // false for Business Unit and true for closed.

        // Verify: Verify GL Entry.
        VerifyGLEntry(GenJournalLine."Account No.", GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler,CloseOpenBalanceSheetRequestPageHandler,DimensionSelectionMultipleModalPageHandler,GeneralJournalBatchesModalPageHandler,ConfirmHandler,MessageHandler,FiscalYearBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RunFiscalBalanceReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostingDate: Date;
    begin
        // Check GL Account No. after running Fiscal Year Balance report.

        // Setup: Close Already Opened Fiscal Year. Create New One, Update New currency on General Ledger Setup. Create and post General Journal Line.
        Initialize();
        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();
        CreateAndPostGenJournalLine(GenJournalLine, LibraryFiscalYear.GetFirstPostingDate(false));  // Using False for closed.

        // Close Newly Created Fiscal Year. Customized Date formula required to calculate Fiscal Ending Date.
        LibraryFiscalYear.CloseFiscalYear();
        PostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));  // Using true for closed.
        RunCloseIncomeStatement(GenJournalLine, PostingDate, CreateGLAccount());
        RunCloseOpenBalanceSheet(GenJournalLine, GenJournalLine."Account No.", IncStr(GenJournalLine."Document No."), false, PostingDate);  // false for Business Unit and true for closed.
        PostingDate := LibraryFiscalYear.GetLastPostingDate(true);  // using true for closed.
        CreateAndPostGenJournalLine(GenJournalLine, PostingDate);

        // Exercise: Run Fiscal Year Balance Report.
        RunFiscalYearBalance(PostingDate, GenJournalLine."Account No.");

        // Verify: Verify GL Account No. on report.
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.AssertElementWithValueExists(GLAccountNoCap, GenJournalLine."Account No.");
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler,CloseOpenBalanceSheetRequestPageHandler,ConfirmHandler,MessageHandler,GeneralJournalBatchesModalPageHandler,DimensionSelectionMultipleModalPageHandler')]
    [Scope('OnPrem')]
    procedure CloseOpenBalanceSheet_GlobalOnlyDim()
    begin
        // verify that global dimensions populated by close/open balance sheet report
        CloseOpenBalanceSheetDimScenario(true);
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler,CloseOpenBalanceSheetRequestPageHandler,ConfirmHandler,MessageHandler,GeneralJournalBatchesModalPageHandler,DimensionSelectionMultipleModalPageHandler')]
    [Scope('OnPrem')]
    procedure CloseOpenBalanceSheet_SeveralDim()
    begin
        // verify that not global dimensions populated by close/open balance sheet report
        CloseOpenBalanceSheetDimScenario(false);
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler,ConfirmHandler,MessageHandler,CloseOpenBalanceSheetRequestPageHandler,DimensionSelectionMultipleModalPageHandler,GeneralJournalBatchesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CloseFiscalYearIncomeStatementBalanceSheetWithAdditionalCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        OldAdditionalReportingCurrency: Code[10];
        DocumentNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Additional Currency]
        // [SCENARIO 363241] Run Close Income Statement and Closed/Open Balance Sheet with Additional Currency
        // [GIVEN] Additional Currency is set
        Initialize();
        OldAdditionalReportingCurrency := UpdateAddnlReportingCurrencyGeneralLedgerSetup(CreateCurrencyAndExchangeRate());
        // [GIVEN] Closed Current Fiscal Year
        LibraryFiscalYear.CloseFiscalYear();
        // [GIVEN] Opened new Fiscal Year
        LibraryFiscalYear.CreateFiscalYear();
        // [GIVEN] Posted document with dimensions and amount "X"
        // There is no inconsistent error when dimensions are not involved
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);
        CreateAndPostGenJournalLineWithDim(GenJournalLine, PostingDate, TempDimSetEntry, true);

        // [GIVEN] Closed newly created Fiscal Year
        LibraryFiscalYear.CloseFiscalYear();
        DocumentNo := IncStr(GenJournalLine."Document No.");
        // [GIVEN] Ran Income Statement Report
        RunCloseIncomeStatement(
          GenJournalLine, CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true)), CreateGLAccount());

        // [WHEN] Run Closed/Open Balance Sheet Report
        // If additional currency is not involved then no gen. journal lines are not posted by report.
        RunCloseOpenBalanceSheet(
          GenJournalLine, CreateGLAccount(), DocumentNo, false,
          CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true)));

        // [THEN] Generated Gen. Journal Lines are posted and "G/L Entry".Amount = "X"
        VerifyGLEntry(GenJournalLine."Account No.", GenJournalLine.Amount);

        UpdateAddnlReportingCurrencyGeneralLedgerSetup(OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler,CloseOpenBalanceSheetRequestPageHandler,DimensionSelectionMultipleModalPageHandler,GeneralJournalBatchesModalPageHandler,ConfirmHandler,MessageHandler,FiscalYearBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RunFiscalBalanceReportTwoBusinessUnits()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        BusinessUnit: array[2] of Record "Business Unit";
        GLEntry: Record "G/L Entry";
        JournalPostingDate: Date;
        ClosingPostingDate: Date;
        Index: Integer;
    begin
        // [FEATURE] [Business Unit]
        // [SCENARIO 413343] User gets result running report "Close/Open Balance Sheet" having multiple Business Units in system and posted G/L entries on them.

        Initialize();

        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();

        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Income/Balance", IncomeBalanceType::"Balance Sheet");
        GLAccount.Modify();

        JournalPostingDate := LibraryFiscalYear.GetFirstPostingDate(false);

        for Index := 1 to ArrayLen(BusinessUnit) do begin
            LibraryERM.CreateBusinessUnit(BusinessUnit[Index]);

            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", -LibraryRandom.RandDecInRange(100, 200, 2));
            GenJournalLine.Validate("Posting Date", JournalPostingDate);
            GenJournalLine.Validate("Business Unit Code", BusinessUnit[Index].Code);
            GenJournalLine.Modify(true);

            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;

        LibraryFiscalYear.CloseFiscalYear();
        ClosingPostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));

        GLEntry.SetRange("Posting Date", JournalPostingDate, ClosingPostingDate);
        GLEntry.SetRange("Business Unit Code", BusinessUnit[1].Code);
        Assert.RecordIsNotEmpty(GLEntry);
        GLEntry.SetRange("Business Unit Code", BusinessUnit[2].Code);
        Assert.RecordIsNotEmpty(GLEntry);

        RunCloseIncomeStatement(GenJournalLine, ClosingPostingDate, CreateGLAccount());
        RunCloseOpenBalanceSheet(
          GenJournalLine, GLAccount."No.", IncStr(GenJournalLine."Document No."), true, ClosingPostingDate);

        ClosingPostingDate := LibraryFiscalYear.GetLastPostingDate(true);
        CreateAndPostGenJournalLine(GenJournalLine, ClosingPostingDate);

        RunFiscalYearBalance(ClosingPostingDate, GenJournalLine."Account No.");

        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.AssertElementWithValueExists(GLAccountNoCap, GenJournalLine."Account No.");
    end;

    [Test]
    [HandlerFunctions('CloseOpenBalanceSheetReqPageHandler,DimensionSelectionMultipleModalPageHandler,GeneralJournalBatchesModalPageHandler')]
    [Scope('OnPrem')]
    procedure DocNoOfCloseBalanceEntriesOnCloseOpenBalanceSheetReportStaysWhenReRun()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntryCard: TestPage "Job Queue Entry Card";
        ClosingPostingDate: Date;
        DocNo: Code[10];
    begin
        // [SCENARIO 557759] When Stan runs Report Request Page action from Job Queue Entry Card page 
        // Then Document No. of Close Balance Entries is not empty once entered before.
        Initialize();

        // [GIVEN] Create a Job Queue Entry.
        JobQueueEntry.Init();
        JobQueueEntry.Validate("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.Validate("Object ID to Run", Report::"Close/Open Balance Sheet");
        JobQueueEntry.Insert(true);

        // [GIVEN] Close and Create Fiscal Year and save it in a Variable.
        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();
        ClosingPostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));

        // [GIVEN] Create a GL Account and Validate Account Type and Income/Balance in GL Account.
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Income/Balance", IncomeBalanceType::"Balance Sheet");
        GLAccount.Modify();

        // [GIVEN] Create a Gen. Journal Template.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] Create a Gen. Journal Batch.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] Create a Gen. Journal Line.
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(0));

        // [GIVEN] Run Report Request Page action from Job Queue Entry Card page.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandText(4));
        RunReportRequestPageFromJobQueueEntryCard(GenJournalLine, JobQueueEntry, ClosingPostingDate);

        // [WHEN] Save Document No. in a Variable.
        DocNo := Format(LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(DocNo);
        Commit();

        // [THEN] Open Job Queue Entry Card page and run Report Request Page action.
        JobQueueEntryCard.OpenEdit();
        JobQueueEntryCard.GoToRecord(JobQueueEntry);
        JobQueueEntryCard.ReportRequestPage.Invoke();
        JobQueueEntryCard.Close();
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler,CloseOpenBalanceSheetRequestPageHandler,ConfirmHandler,MessageHandler,GeneralJournalBatchesModalPageHandler,DimensionSelectionMultipleModalPageHandler')]
    [Scope('OnPrem')]
    procedure CloseOpenBalanceSheetWithShortcutDim3()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        GLEntry: Record "G/L Entry";
        Dimension: Record Dimension;
        OldShortcutDim3Code: Code[20];
        PostingDate: Date;
        DocumentNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // [SCENARIO 614952] Close/Open Balance Sheet report amounts are correct when Shortcut Dimension 3 is used
        // [GIVEN] Shortcut Dimension 3 is set in General Ledger Setup
        Initialize();
        GeneralLedgerSetup.Get();
        OldShortcutDim3Code := GeneralLedgerSetup."Shortcut Dimension 3 Code";
        LibraryDimension.CreateDimension(Dimension);
        GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", Dimension.Code);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Closed Current Fiscal Year
        LibraryFiscalYear.CloseFiscalYear();
        // [GIVEN] Opened new Fiscal Year
        LibraryFiscalYear.CreateFiscalYear();
        // [GIVEN] Posted Balance Sheet entry with dimensions including Shortcut Dimension 3
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);
        CreateAndPostGenJournalLineWithDim(GenJournalLine, PostingDate, TempDimSetEntry, false);

        // [GIVEN] Calculate expected amount from G/L Entries
        GLEntry.SetRange("G/L Account No.", GenJournalLine."Account No.");
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.CalcSums(Amount);
        ExpectedAmount := GLEntry.Amount;

        // [GIVEN] Closed newly created Fiscal Year
        LibraryFiscalYear.CloseFiscalYear();
        DocumentNo := IncStr(GenJournalLine."Document No.");
        PostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));
        // [GIVEN] Ran Income Statement Report
        SelectDimForCloseIncomeStatement(TempDimSetEntry);
        RunCloseIncomeStatement(GenJournalLine, PostingDate, CreateGLAccount());
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // [WHEN] Run Close/Open Balance Sheet Report
        RunCloseOpenBalanceSheet(GenJournalLine, CreateGLAccount(), DocumentNo, false, PostingDate);

        // [THEN] Generated Gen. Journal Lines have correct amounts matching G/L Entry amounts
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine2.SetRange("Account No.", GenJournalLine."Account No.");
        GenJournalLine2.SetFilter(Amount, '<>%1', 0);
        GenJournalLine2.SetRange("Document No.", DocumentNo);
        if GenJournalLine2.Findfirst() then
            repeat
                Assert.AreEqual(
                  -ExpectedAmount, GenJournalLine2.Amount,
                  StrSubstNo('Amount in journal line should be %1 but was %2', -ExpectedAmount, GenJournalLine2.Amount));
            until GenJournalLine2.Next() = 0;

        // Tear Down
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", OldShortcutDim3Code);
        GeneralLedgerSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler,CloseOpenBalanceSheetRequestPageHandler,ConfirmHandler,MessageHandler,GeneralJournalBatchesModalPageHandler,DimensionSelectionMultipleModalPageHandler')]
    [Scope('OnPrem')]
    procedure CloseOpenBalanceSheetDimGroupingWithMultipleEntries()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        TempDimSetEntry1: Record "Dimension Set Entry" temporary;
        TempDimSetEntry2: Record "Dimension Set Entry" temporary;
        Dimension: Record Dimension;
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        SelectedDimension: Record "Selected Dimension";
        PostingDate: Date;
        ClosingPostingDate: Date;
        DocumentNo: Code[20];
        Amount1: Decimal;
        Amount2: Decimal;
        DimSetID1: Integer;
        DimSetID2: Integer;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 623780] Close/Open Balance Sheet generates separate journal lines per dimension combination

        Initialize();

        // [GIVEN] Closed current Fiscal Year and opened new one
        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);

        // [GIVEN] Balance Sheet G/L Account "A"
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", IncomeBalanceType::"Balance Sheet");
        GLAccount.Modify();

        // [GIVEN] Non-global dimension "D" with two values "DV1" and "DV2"
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue1, Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue2, Dimension.Code);

        // [GIVEN] Dimension set with "DV1"
        TempDimSetEntry1.Init();
        TempDimSetEntry1."Dimension Code" := Dimension.Code;
        TempDimSetEntry1."Dimension Value Code" := DimensionValue1.Code;
        TempDimSetEntry1."Dimension Value ID" := DimensionValue1."Dimension Value ID";
        TempDimSetEntry1.Insert();
        DimSetID1 := DimMgt.GetDimensionSetID(TempDimSetEntry1);

        // [GIVEN] Dimension set with "DV2"
        TempDimSetEntry2.Init();
        TempDimSetEntry2."Dimension Code" := Dimension.Code;
        TempDimSetEntry2."Dimension Value Code" := DimensionValue2.Code;
        TempDimSetEntry2."Dimension Value ID" := DimensionValue2."Dimension Value ID";
        TempDimSetEntry2.Insert();
        DimSetID2 := DimMgt.GetDimensionSetID(TempDimSetEntry2);

        // [GIVEN] Posted G/L entry on "A" with dimension "DV1" and amount 100
        Amount1 := -LibraryRandom.RandDecInRange(100, 200, 2);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", Amount1);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine."Dimension Set ID" := DimSetID1;
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted G/L entry on "A" with dimension "DV2" and amount 200
        Amount2 := -LibraryRandom.RandDecInRange(300, 400, 2);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", Amount2);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine."Dimension Set ID" := DimSetID2;
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Closed newly created Fiscal Year
        LibraryFiscalYear.CloseFiscalYear();
        ClosingPostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));

        // [GIVEN] Selected dimension "D" for Close Income Statement
        SelectedDimension.DeleteAll();
        SelectedDimension."User ID" := UserId;
        SelectedDimension."Object Type" := 3;
        SelectedDimension."Object ID" := REPORT::"Close Income Statement";
        SelectedDimension."Dimension Code" := Dimension.Code;
        SelectedDimension.Insert();

        // [GIVEN] Ran Close Income Statement
        DocumentNo := IncStr(GenJournalLine."Document No.");
        RunCloseIncomeStatement(GenJournalLine, ClosingPostingDate, CreateGLAccount());
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // [WHEN] Run Close/Open Balance Sheet Report
        RunCloseOpenBalanceSheet(GenJournalLine, CreateGLAccount(), DocumentNo, false, ClosingPostingDate);

        // [THEN] Two separate journal lines are generated for account "A" with correct amounts per dimension
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine2.SetRange("Account No.", GLAccount."No.");
        GenJournalLine2.SetRange("Document No.", DocumentNo);
        GenJournalLine2.SetFilter(Amount, '>%1', 0);
        Assert.AreEqual(2, GenJournalLine2.Count(), 'Expected two journal lines for two different dimension combinations');

        // [THEN] Total amount across both lines matches sum of original entries
        GenJournalLine2.CalcSums(Amount);
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(-GLEntry.Amount, GenJournalLine2.Amount, 'Total journal line amount must equal negated G/L entry total');
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler,CloseOpenBalanceSheetRequestPageHandler,ConfirmHandler,MessageHandler,GeneralJournalBatchesModalPageHandler,DimensionSelectionMultipleModalPageHandler')]
    [Scope('OnPrem')]
    procedure CloseOpenBalSheetSameGlobalDimDiffOtherDim()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        TempDimSetEntry1: Record "Dimension Set Entry" temporary;
        TempDimSetEntry2: Record "Dimension Set Entry" temporary;
        Dimension: Record Dimension;
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        GlobalDimValue1: Record "Dimension Value";
        GlobalDimValue2: Record "Dimension Value";
        SelectedDimension: Record "Selected Dimension";
        PostingDate: Date;
        ClosingPostingDate: Date;
        DocumentNo: Code[20];
        Amount1: Decimal;
        Amount2: Decimal;
        DimSetID1: Integer;
        DimSetID2: Integer;
    begin
        // [SCENARIO 623780] Close/Open Balance Sheet generates separate journal lines when Global Dimensions 1 and 2 are the same but a non-global dimension differs

        Initialize();

        // [GIVEN] Closed current Fiscal Year and opened new one
        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);

        // [GIVEN] Balance Sheet G/L Account "A"
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", IncomeBalanceType::"Balance Sheet");
        GLAccount.Modify();

        // [GIVEN] Shared Global Dimension 1 and 2 values
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(GlobalDimValue1, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(GlobalDimValue2, GeneralLedgerSetup."Global Dimension 2 Code");

        // [GIVEN] Non-global dimension "D" with two values "DV1" and "DV2"
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue1, Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue2, Dimension.Code);

        // [GIVEN] Dimension set 1: Global Dim 1, Global Dim 2, non-global "DV1"
        TempDimSetEntry1.Init();
        TempDimSetEntry1."Dimension Code" := GeneralLedgerSetup."Global Dimension 1 Code";
        TempDimSetEntry1."Dimension Value Code" := GlobalDimValue1.Code;
        TempDimSetEntry1."Dimension Value ID" := GlobalDimValue1."Dimension Value ID";
        TempDimSetEntry1.Insert();
        TempDimSetEntry1.Init();
        TempDimSetEntry1."Dimension Code" := GeneralLedgerSetup."Global Dimension 2 Code";
        TempDimSetEntry1."Dimension Value Code" := GlobalDimValue2.Code;
        TempDimSetEntry1."Dimension Value ID" := GlobalDimValue2."Dimension Value ID";
        TempDimSetEntry1.Insert();
        TempDimSetEntry1.Init();
        TempDimSetEntry1."Dimension Code" := Dimension.Code;
        TempDimSetEntry1."Dimension Value Code" := DimensionValue1.Code;
        TempDimSetEntry1."Dimension Value ID" := DimensionValue1."Dimension Value ID";
        TempDimSetEntry1.Insert();
        DimSetID1 := DimMgt.GetDimensionSetID(TempDimSetEntry1);

        // [GIVEN] Dimension set 2: same Global Dim 1, same Global Dim 2, non-global "DV2"
        TempDimSetEntry2.Init();
        TempDimSetEntry2."Dimension Code" := GeneralLedgerSetup."Global Dimension 1 Code";
        TempDimSetEntry2."Dimension Value Code" := GlobalDimValue1.Code;
        TempDimSetEntry2."Dimension Value ID" := GlobalDimValue1."Dimension Value ID";
        TempDimSetEntry2.Insert();
        TempDimSetEntry2.Init();
        TempDimSetEntry2."Dimension Code" := GeneralLedgerSetup."Global Dimension 2 Code";
        TempDimSetEntry2."Dimension Value Code" := GlobalDimValue2.Code;
        TempDimSetEntry2."Dimension Value ID" := GlobalDimValue2."Dimension Value ID";
        TempDimSetEntry2.Insert();
        TempDimSetEntry2.Init();
        TempDimSetEntry2."Dimension Code" := Dimension.Code;
        TempDimSetEntry2."Dimension Value Code" := DimensionValue2.Code;
        TempDimSetEntry2."Dimension Value ID" := DimensionValue2."Dimension Value ID";
        TempDimSetEntry2.Insert();
        DimSetID2 := DimMgt.GetDimensionSetID(TempDimSetEntry2);

        // [GIVEN] Posted G/L entry on "A" with dimension set 1 and amount 100
        Amount1 := -LibraryRandom.RandDecInRange(100, 200, 2);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", Amount1);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine."Dimension Set ID" := DimSetID1;
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted G/L entry on "A" with dimension set 2 and amount 200
        Amount2 := -LibraryRandom.RandDecInRange(300, 400, 2);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", Amount2);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine."Dimension Set ID" := DimSetID2;
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Closed newly created Fiscal Year
        LibraryFiscalYear.CloseFiscalYear();
        ClosingPostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));

        // [GIVEN] Selected all three dimensions for Close Income Statement
        SelectedDimension.DeleteAll();
        SelectedDimension."User ID" := UserId;
        SelectedDimension."Object Type" := 3;
        SelectedDimension."Object ID" := REPORT::"Close Income Statement";
        SelectedDimension."Dimension Code" := GeneralLedgerSetup."Global Dimension 1 Code";
        SelectedDimension.Insert();
        SelectedDimension."Dimension Code" := GeneralLedgerSetup."Global Dimension 2 Code";
        SelectedDimension.Insert();
        SelectedDimension."Dimension Code" := Dimension.Code;
        SelectedDimension.Insert();

        // [GIVEN] Ran Close Income Statement
        DocumentNo := IncStr(GenJournalLine."Document No.");
        RunCloseIncomeStatement(GenJournalLine, ClosingPostingDate, CreateGLAccount());
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // [WHEN] Run Close/Open Balance Sheet Report
        RunCloseOpenBalanceSheet(GenJournalLine, CreateGLAccount(), DocumentNo, false, ClosingPostingDate);

        // [THEN] Two separate journal lines are generated because non-global dimension differs
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine2.SetRange("Account No.", GLAccount."No.");
        GenJournalLine2.SetRange("Document No.", DocumentNo);
        GenJournalLine2.SetFilter(Amount, '>%1', 0);
        Assert.AreEqual(2, GenJournalLine2.Count(), 'Expected two journal lines because non-global dimension values differ');

        // [THEN] Both lines share the same Global Dimension 1 and 2 codes
        GenJournalLine2.FindSet();
        repeat
            Assert.AreEqual(
              GlobalDimValue1.Code, GenJournalLine2."Shortcut Dimension 1 Code",
              'Global Dimension 1 Code must be the same on both lines');
            Assert.AreEqual(
              GlobalDimValue2.Code, GenJournalLine2."Shortcut Dimension 2 Code",
              'Global Dimension 2 Code must be the same on both lines');
        until GenJournalLine2.Next() = 0;

        // [THEN] Total amount across both lines matches sum of original entries
        GenJournalLine2.CalcSums(Amount);
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(-GLEntry.Amount, GenJournalLine2.Amount, 'Total journal line amount must equal negated G/L entry total');
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler,CloseOpenBalanceSheetRequestPageHandler,ConfirmHandler,MessageHandler,GeneralJournalBatchesModalPageHandler,DimensionSelectionMultipleModalPageHandler')]
    [Scope('OnPrem')]
    procedure CloseOpenBalanceSheetSeparateLinesForDiffDimensionSets()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        Dimension: Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        GlobalDimensionValue: array[2] of Record "Dimension Value";
        PostingDate: Date;
        DocumentNo: Code[20];
        DimensionSetID: array[2] of Integer;
        Amount: array[2] of Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 629280] Close/Open Balance Sheet keeps separate lines for entries with different Dimension Set IDs
        Initialize();

        // [GIVEN] Closed Current Fiscal Year and opened new one
        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);

        // [GIVEN] G/L Account "A" of type Balance Sheet
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", IncomeBalanceType::"Balance Sheet");
        GLAccount.Modify();

        // [GIVEN] Non-global dimension "D" with two different values "V1" and "V2"
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue[1], Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], Dimension.Code);

        // [GIVEN] Shared global dimension values "GD1" and "GD2"
        LibraryDimension.CreateDimensionValue(GlobalDimensionValue[1], GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(GlobalDimensionValue[2], GeneralLedgerSetup."Global Dimension 2 Code");

        // [GIVEN] Dimension Set 1 with global dimensions and non-global dimension value "V1"
        AddDimensionValueToDimensionSetEntry(TempDimensionSetEntry, GlobalDimensionValue[1]);
        AddDimensionValueToDimensionSetEntry(TempDimensionSetEntry, GlobalDimensionValue[2]);
        AddDimensionValueToDimensionSetEntry(TempDimensionSetEntry, DimensionValue[1]);
        DimensionSetID[1] := DimMgt.GetDimensionSetID(TempDimensionSetEntry);
        TempDimensionSetEntry.DeleteAll();

        // [GIVEN] Dimension Set 2 with same global dimensions but non-global dimension value "V2"
        AddDimensionValueToDimensionSetEntry(TempDimensionSetEntry, GlobalDimensionValue[1]);
        AddDimensionValueToDimensionSetEntry(TempDimensionSetEntry, GlobalDimensionValue[2]);
        AddDimensionValueToDimensionSetEntry(TempDimensionSetEntry, DimensionValue[2]);
        DimensionSetID[2] := DimMgt.GetDimensionSetID(TempDimensionSetEntry);

        // [GIVEN] Posted general journal lines for G/L Account "A" with two different Dimension Set IDs
        SelectGenJournalBatch(GenJournalBatch);
        Amount[1] := LibraryRandom.RandInt(100);
        Amount[2] := LibraryRandom.RandInt(200);
        CreateBalanceSheetGeneralJournalLineWithDimensionSetID(
            GenJournalLine, GenJournalBatch, GLAccount."No.", PostingDate,
            -Amount[1], DimensionSetID[1], GlobalDimensionValue[1].Code, GlobalDimensionValue[2].Code);
        CreateBalanceSheetGeneralJournalLineWithDimensionSetID(
            GenJournalLine, GenJournalBatch, GLAccount."No.", PostingDate,
            -Amount[2], DimensionSetID[2], GlobalDimensionValue[1].Code, GlobalDimensionValue[2].Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Closed newly created Fiscal Year
        LibraryFiscalYear.CloseFiscalYear();
        DocumentNo := IncStr(GenJournalLine."Document No.");
        PostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));

        // [GIVEN] Ran Close Income Statement Report and posted
        SelectDimForCloseIncomeStatement(TempDimensionSetEntry);
        RunCloseIncomeStatement(GenJournalLine, PostingDate, CreateGLAccount());
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // [WHEN] Run Close/Open Balance Sheet Report
        RunCloseOpenBalanceSheet(GenJournalLine, CreateGLAccount(), DocumentNo, false, PostingDate);

        // [THEN] Two separate close and two separate open journal lines are generated
        VerifySeparateCloseBalanceSheetLines(GenJournalLine, DocumentNo, GLAccount."No.", DimensionSetID);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    begin
        CreateGenJournalLine(GenJournalLine, PostingDate, IncomeBalanceType::"Income Statement");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGenJournalLineWithDim(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; var DimSetEntry: Record "Dimension Set Entry"; GlobalDimOnly: Boolean)
    begin
        CreateGenJournalLine(GenJournalLine, PostingDate, IncomeBalanceType::"Balance Sheet");
        CreateDimSet(DimSetEntry, GlobalDimOnly);
        GenJournalLine."Dimension Set ID" := DimMgt.GetDimensionSetID(DimSetEntry);
        DimMgt.UpdateGlobalDimFromDimSetID(GenJournalLine."Dimension Set ID",
          GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code");

        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; IncomeBanalce: Option)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", IncomeBanalce);
        GLAccount.Modify();
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", -LibraryRandom.RandDec(100, 2));  // Using random for amount.
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", CreateGLAccount());
        Currency.Validate("Residual Losses Account", Currency."Residual Gains Account");
        Currency.Validate("Realized G/L Gains Account", CreateGLAccount());
        Currency.Validate("Realized G/L Losses Account", Currency."Realized G/L Gains Account");
        Currency.Modify(true);

        // Create Currency Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateDimSet(var DimSetEntry: Record "Dimension Set Entry"; GlobalDimOnly: Boolean): Code[20]
    var
        GLSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
    begin
        GLSetup.Get();
        // add to dimension set 2 new global dimension values
        CreateAndAddDimValueToDimSetEntry(DimSetEntry, GLSetup."Global Dimension 1 Code");
        CreateAndAddDimValueToDimSetEntry(DimSetEntry, GLSetup."Global Dimension 2 Code");

        // add new dimension's value
        if not GlobalDimOnly then begin
            LibraryDimension.CreateDimension(Dimension);
            CreateAndAddDimValueToDimSetEntry(DimSetEntry, Dimension.Code);
        end;
    end;

    local procedure CreateAndAddDimValueToDimSetEntry(var DimSetEntry: Record "Dimension Set Entry"; DimensionCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);

        DimSetEntry.Init();
        DimSetEntry."Dimension Code" := DimensionCode;
        DimSetEntry."Dimension Value Code" := DimensionValue.Code;
        DimSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        DimSetEntry.Insert();
    end;

    local procedure CloseOpenBalanceSheetDimScenario(GlobalDimOnly: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        PostingDate: Date;
        DocumentNo: Code[20];
    begin
        // Setup: Close Already Opened Fiscal Year. Create New One, Create and post General Journal Line, run Close Income Statement
        Initialize();
        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();
        CreateAndPostGenJournalLineWithDim(GenJournalLine, LibraryFiscalYear.GetFirstPostingDate(false), TempDimSetEntry, GlobalDimOnly);

        // Close Newly Created Fiscal Year. Customized Date formula required to calculate Fiscal Ending Date.
        LibraryFiscalYear.CloseFiscalYear();
        PostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));  // Using true for closed.

        SelectDimForCloseIncomeStatement(TempDimSetEntry);
        DocumentNo := IncStr(GenJournalLine."Document No.");
        RunCloseIncomeStatement(GenJournalLine, PostingDate, CreateGLAccount());
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // Exercise: Run Close/Open Balance Sheet Report.
        RunCloseOpenBalanceSheet(GenJournalLine, CreateGLAccount(), DocumentNo, false,
          CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true)));

        // Verify: check dimensions
        VerifyGenJnlLineDim(GenJournalLine, DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; AccountNo: Code[20])
    begin
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.FindFirst();
    end;

    local procedure RunCloseIncomeStatement(GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; GLAccount: Code[20])
    var
        CloseIncomeStatement: Report "Close Income Statement";
    begin
        // Enqueue values for CloseIncomeStatementRequestPageHandler.
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(IncStr(GenJournalLine."Document No."));
        LibraryVariableStorage.Enqueue(GLAccount);
        LibraryVariableStorage.Enqueue(true); // Close by Business Unit
        Commit();
        Clear(CloseIncomeStatement);
        CloseIncomeStatement.Run();
    end;

    local procedure RunCloseOpenBalanceSheet(GenJournalLine: Record "Gen. Journal Line"; GLAccount: Code[20]; DocumentNo: Code[20]; BusinessUnit: Boolean; FiscalYearEndingDate: Date)
    var
        CloseOpenBalanceSheet: Report "Close/Open Balance Sheet";
    begin
        // Enqueue values for CloseOpenBalanceSheetRequestPageHandler.
        LibraryVariableStorage.Enqueue(FiscalYearEndingDate);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(DocumentNo);
        if GLAccount <> '' then
            LibraryVariableStorage.Enqueue(LibraryERM.CreateGLAccountNo())
        else
            LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(DocumentNo);
        if GLAccount <> '' then
            LibraryVariableStorage.Enqueue(LibraryERM.CreateGLAccountNo())
        else
            LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(BusinessUnit);
        Commit();
        Clear(CloseOpenBalanceSheet);
        CloseOpenBalanceSheet.Run();
    end;

    local procedure RunFiscalYearBalance(StartingDate: Date; GLAccount: Code[20])
    var
        FiscalYearBalance: Report "Fiscal Year Balance";
    begin
        // Enqueue values for FiscalYearBalanceRequestPageHandler.
        LibraryVariableStorage.Enqueue(GLAccount);
        LibraryVariableStorage.Enqueue(StartingDate);
        Clear(FiscalYearBalance);
        FiscalYearBalance.Run();
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exists before creating General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure SelectDimForCloseIncomeStatement(var DimSetEntry: Record "Dimension Set Entry")
    var
        SelectedDimension: Record "Selected Dimension";
    begin
        SelectedDimension.DeleteAll();

        DimSetEntry.FindSet();
        repeat
            SelectedDimension."User ID" := UserId;
            SelectedDimension."Object Type" := 3;
            SelectedDimension."Object ID" := REPORT::"Close Income Statement";
            SelectedDimension."Dimension Code" := DimSetEntry."Dimension Code";
            SelectedDimension.Insert();
        until DimSetEntry.Next() = 0;
    end;

    local procedure UpdateAddnlReportingCurrencyGeneralLedgerSetup(AdditionalReportingCurrency: Code[10]) OldAdditionalReportingCurrency: Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldAdditionalReportingCurrency := GeneralLedgerSetup."Additional Reporting Currency";
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyGLEntryForFiscalYear(AccountNo: Code[20]; AdditionalCurrencyAmount: Decimal; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Posting Date", ClosingDate(CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true))));  // Customized Date formula required to calculate Fiscal Ending Date.Using true for Closed.
        FindGLEntry(GLEntry, AccountNo);
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, GLEntry."Additional-Currency Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption("Additional-Currency Amount"), AdditionalCurrencyAmount, GLEntry.TableCaption()));
        VerifyGLEntry(AccountNo, Amount);
    end;

    local procedure VerifyGLEntry(AccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, AccountNo);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGenJnlLineDim(var GenJournalLine: Record "Gen. Journal Line"; DimSetId: Integer)
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindLast();
        Assert.AreEqual(DimSetId, GenJournalLine."Dimension Set ID", IncorrectDimSetIDErr);
    end;

    local procedure RunReportRequestPageFromJobQueueEntryCard(GenJournalLine: Record "Gen. Journal Line"; JobQueueEntry: Record "Job Queue Entry"; ClosingPostingDate: Date)
    var
        JobQueueEntryCard: TestPage "Job Queue Entry Card";
    begin
        LibraryVariableStorage.Enqueue(ClosingPostingDate);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(IncStr(GenJournalLine."Document No."));
        LibraryVariableStorage.Enqueue(LibraryERM.CreateGLAccountNo());
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(IncStr(GenJournalLine."Document No."));
        LibraryVariableStorage.Enqueue(LibraryERM.CreateGLAccountNo());
        LibraryVariableStorage.Enqueue(true);
        Commit();

        JobQueueEntryCard.OpenEdit();
        JobQueueEntryCard.GoToRecord(JobQueueEntry);
        JobQueueEntryCard.ReportRequestPage.Invoke();
        JobQueueEntryCard.Close();
    end;

    local procedure AddDimensionValueToDimensionSetEntry(var TempDimensionSetEntry: Record "Dimension Set Entry" temporary; DimensionValue: Record "Dimension Value")
    begin
        TempDimensionSetEntry.Init();
        TempDimensionSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        TempDimensionSetEntry."Dimension Value Code" := DimensionValue.Code;
        TempDimensionSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        TempDimensionSetEntry.Insert();
    end;

    local procedure CreateBalanceSheetGeneralJournalLineWithDimensionSetID(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; GLAccountNo: Code[20]; PostingDate: Date; Amount: Decimal; DimensionSetID: Integer; GlobalDimensionCode1: Code[20]; GlobalDimensionCode2: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
            GLAccountNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine."Dimension Set ID" := DimensionSetID;
        GenJournalLine."Shortcut Dimension 1 Code" := GlobalDimensionCode1;
        GenJournalLine."Shortcut Dimension 2 Code" := GlobalDimensionCode2;
        GenJournalLine.Modify(true);
    end;

    local procedure VerifySeparateCloseBalanceSheetLines(GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; GLAccountNo: Code[20]; DimensionSetID: array[2] of Integer)
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine2.SetRange("Account No.", GLAccountNo);
        GenJournalLine2.SetRange("Document No.", DocumentNo);

        GenJournalLine2.SetRange("Dimension Set ID", DimensionSetID[1]);
        GenJournalLine2.FindFirst();
        Assert.AreEqual(DimensionSetID[1], GenJournalLine2."Dimension Set ID", IncorrectDimSetIDErr);

        GenJournalLine2.SetRange("Dimension Set ID", DimensionSetID[2]);
        GenJournalLine2.FindFirst();
        Assert.AreEqual(DimensionSetID[2], GenJournalLine2."Dimension Set ID", IncorrectDimSetIDErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementRequestPageHandler(var CloseIncomeStatement: TestRequestPage "Close Income Statement")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseIncomeStatement.FiscalYearEndingDate.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseIncomeStatement.GenJournalTemplate.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseIncomeStatement.GenJournalBatch.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseIncomeStatement.DocumentNo.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseIncomeStatement.BalancingAccountNo.SetValue(FieldValue);
        CloseIncomeStatement.NetProfitAccountNo.SetValue(FieldValue);
        CloseIncomeStatement.NetLossAccountNo.SetValue(FieldValue);
        CloseIncomeStatement.ClosePerBusUnit.SetValue(LibraryVariableStorage.DequeueBoolean()); // Close by Business Unit
        CloseIncomeStatement.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CloseOpenBalanceSheetRequestPageHandler(var CloseOpenBalanceSheet: TestRequestPage "Close/Open Balance Sheet")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseOpenBalanceSheet.FiscalYearEndingDate.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseOpenBalanceSheet.GenJournalTemplate_CloseBalanceEntries.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseOpenBalanceSheet.GenJournalBatch_CloseBalanceEntries.Lookup();
        CloseOpenBalanceSheet.GenJournalBatch_CloseBalanceEntries.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseOpenBalanceSheet.DocumentNo_CloseBalanceEntries.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseOpenBalanceSheet.ClosingAccountNo.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseOpenBalanceSheet.GenJournalTemplate_OpenBalanceEntries.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseOpenBalanceSheet.GenJournalBatch_OpenBalanceEntries.Lookup();
        CloseOpenBalanceSheet.GenJournalBatch_OpenBalanceEntries.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseOpenBalanceSheet.DocumentNo_OpenBalanceEntries.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseOpenBalanceSheet.OpeningAccountNo.SetValue(FieldValue);
        CloseOpenBalanceSheet.Dimensions.AssistEdit();
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseOpenBalanceSheet.BusinessUnitCode.SetValue(FieldValue);
        CloseOpenBalanceSheet.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CloseOpenBalanceSheetReqPageHandler(var CloseOpenBalanceSheet: TestRequestPage "Close/Open Balance Sheet")
    var
        FieldValue: Variant;
        ReOpen: Boolean;
    begin
        ReOpen := LibraryVariableStorage.DequeueBoolean();
        if not ReOpen then begin
            LibraryVariableStorage.Dequeue(FieldValue);
            CloseOpenBalanceSheet.DocumentNo_CloseBalanceEntries.SetValue(FieldValue);
            LibraryVariableStorage.Dequeue(FieldValue);
            CloseOpenBalanceSheet.FiscalYearEndingDate.SetValue(FieldValue);
            LibraryVariableStorage.Dequeue(FieldValue);
            CloseOpenBalanceSheet.GenJournalTemplate_CloseBalanceEntries.SetValue(FieldValue);
            LibraryVariableStorage.Dequeue(FieldValue);
            CloseOpenBalanceSheet.GenJournalBatch_CloseBalanceEntries.Lookup();
            CloseOpenBalanceSheet.GenJournalBatch_CloseBalanceEntries.SetValue(FieldValue);
            LibraryVariableStorage.Dequeue(FieldValue);
            CloseOpenBalanceSheet.DocumentNo_CloseBalanceEntries.SetValue(FieldValue);
            LibraryVariableStorage.Dequeue(FieldValue);
            CloseOpenBalanceSheet.ClosingAccountNo.SetValue(FieldValue);
            LibraryVariableStorage.Dequeue(FieldValue);
            CloseOpenBalanceSheet.GenJournalTemplate_OpenBalanceEntries.SetValue(FieldValue);
            LibraryVariableStorage.Dequeue(FieldValue);
            CloseOpenBalanceSheet.GenJournalBatch_OpenBalanceEntries.Lookup();
            CloseOpenBalanceSheet.GenJournalBatch_OpenBalanceEntries.SetValue(FieldValue);
            LibraryVariableStorage.Dequeue(FieldValue);
            CloseOpenBalanceSheet.DocumentNo_OpenBalanceEntries.SetValue(FieldValue);
            LibraryVariableStorage.Dequeue(FieldValue);
            CloseOpenBalanceSheet.OpeningAccountNo.SetValue(FieldValue);
            CloseOpenBalanceSheet.Dimensions.AssistEdit();
            LibraryVariableStorage.Dequeue(FieldValue);
            CloseOpenBalanceSheet.BusinessUnitCode.SetValue(FieldValue);
            LibraryVariableStorage.Enqueue(Format(CloseOpenBalanceSheet.DocumentNo_CloseBalanceEntries));
            CloseOpenBalanceSheet.OK().Invoke();
        end
        else begin
            LibraryVariableStorage.Dequeue(FieldValue);
            CloseOpenBalanceSheet.DocumentNo_CloseBalanceEntries.AssertEquals(FieldValue);
            CloseOpenBalanceSheet.OK().Invoke();
        end
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSelectionMultipleModalPageHandler(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    begin
        DimensionSelectionMultiple.Selected.SetValue(true);
        DimensionSelectionMultiple.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FiscalYearBalanceRequestPageHandler(var FiscalYearBalance: TestRequestPage "Fiscal Year Balance")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        FiscalYearBalance."G/L Account".SetFilter("No.", FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        FiscalYearBalance.StartingDate.SetValue(FieldValue);
        FiscalYearBalance.EndingDate.SetValue(FieldValue);
        FiscalYearBalance.SaveAsXml(LibraryReportDataSet.GetParametersFileName(), LibraryReportDataSet.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalBatchesModalPageHandler(var GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        GeneralJournalBatches.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm the Message.
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

