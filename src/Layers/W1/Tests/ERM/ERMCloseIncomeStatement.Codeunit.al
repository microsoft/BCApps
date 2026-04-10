codeunit 134228 "ERM Close Income Statement"
{
    Permissions = TableData "G/L Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Close Fiscal Year] [Close Income Statement]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        PostToRetainedEarningsAcc: Option Balance,Details;
        ExpectedMessageMsg: Label 'The journal lines have successfully been created.';
        GenJnlLineExistErr: Label 'There should be no %1 with %2=%3,%4=%5', Comment = '%1=Gen. Journal Line;%2=Account Type;%3=Account Type Value;%4=Account No.;%5=Account No. Value.';
        CannotDeleteGLAccGLEntryFoundErr: Label 'You cannot delete G/L account %1 because it has ledger entries in a fiscal year that has not been closed yet.';
        CannotDeleteGLAccGLBudgetEntryFoundErr: Label 'You cannot delete G/L account %1 because it contains budget ledger entries after %2 for G/L budget name %3.';
        ConfirmCloseAccPeriodQst: Label 'This function closes the fiscal year from %1 to %2. Once the fiscal year is closed it cannot be opened again, and the periods in the fiscal year cannot be changed.\\Do you want to close the fiscal year?';
        ConfirmDeleteGLAccountQst: Label 'Note that accounting regulations may require that you save accounting data for a certain number of years. Are you sure you want to delete the G/L account?';
        CannotDeleteGLAccGLEntryFoundAfterDateErr: Label 'You cannot delete G/L account %1 because it has ledger entries posted after %2.';
        UnexpectedConfirmErr: Label 'Unexpected confirm handler: %1';

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CloseIncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementOnce()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Covers document TFS_TC_ID = 7421.

        Initialize();

        // [WHEN] Create and post Gen. Journal Lines and Run Close Income Statement Batch job.
        DocumentNo := PostGeneralJournalLinesAndCloseIncomeStatement(GenJournalLine);

        // [THEN] Verify Balance in GL Account.
        VerifyGLAccountBalance(GenJournalLine."Account No.", DocumentNo, DocumentNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CloseIncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementTwice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Covers document TFS_TC_ID = 7422.

        // [GIVEN] Posted Gen. Journal Lines
        // [WHEN] Run Close Income Statement Batch job twice.
        Initialize();
        DocumentNo := CloseIncomeStatementWithPostingLines(GenJournalLine);

        // [THEN]: Verify Balance in GL Account.
        VerifyGLAccountBalance(GenJournalLine."Account No.", DocumentNo, GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CloseIncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementWithAddCur()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AdditionalReportingCurrency: Code[10];
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Covers document TFS_TC_ID = 7423, 4252

        // [GIVEN] Create and Post Gen. Journal Lines and Run Close Income Statement Batch job two times.
        Initialize();
        DocumentNo := CloseIncomeStatementWithPostingLines(GenJournalLine);

        // [GIVEN] Update General Ledger Setup for Additional Reporting Currency.
        AdditionalReportingCurrency := UpdateCurOnGeneralLedgerSetup(CreateCurrency());

        // [WHEN] Run "Close Income Statement"
        CloseIncomeStatement(GenJournalLine, IncStr(GenJournalLine."Document No."));

        // [THEN]: Verify Balance in GL Account.
        VerifyGLAccountBalance(GenJournalLine."Account No.", DocumentNo, GenJournalLine."Document No.");

        // Cleanup: Update General Ledger Setup.
        UpdateCurOnGeneralLedgerSetup(AdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CloseIncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementWithZeroAmount()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        AdditionalReportingCurrency: Code[10];
        Amount: Decimal;
    begin
        // [SCENARIO 287733] Check that no one general journal line with zero amount has been created

        Initialize();
        // [GIVEN] New Fiscal Year
        LibraryFiscalYear.CloseFiscalYear();
        ExecuteUIHandler();
        LibraryFiscalYear.CreateFiscalYear();
        AdditionalReportingCurrency := UpdateCurOnGeneralLedgerSetup(CreateCurrency());
        Amount := 1;

        LibraryERM.CreateGLAccount(GLAccount);
        CreateAndPostGenJnlLine(GenJournalLine, GLAccount."No.", Amount);

        UpdateCurOnGeneralLedgerSetup('');

        // [GIVEN] Balance of G/L Account = 0,00
        CreateAndPostGenJnlLine(GenJournalLine, GLAccount."No.", -Amount);

        LibraryFiscalYear.CloseFiscalYear();
        GenJournalLine.Reset();
        GenJournalLine.Init();
        GenJournalLine."Document No." := LibraryUtility.GenerateGUID();
        // [WHEN] Run "Close Income Statement"
        CloseIncomeStatement(GenJournalLine, IncStr(GenJournalLine."Document No."));

        // [THEN] General journal line with GLAccountNo does not exist (because of zero amount)
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.SetRange("Account No.", GLAccount."No.");
        Assert.IsTrue(GenJournalLine.IsEmpty,
          StrSubstNo(GenJnlLineExistErr,
            GenJournalLine.TableCaption(),
            GenJournalLine.FieldCaption("Account Type"), Format(GenJournalLine."Account Type"::"G/L Account"),
            GenJournalLine.FieldCaption("Account No."), GLAccount."No."));

        // Cleanup: Update General Ledger Setup.
        UpdateCurOnGeneralLedgerSetup(AdditionalReportingCurrency);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreationOfFiscalYear()
    var
        StartingDate: Date;
    begin
        // [SCENARIO 128966] Check that New Fiscal Year has been Created.

        // [GIVEN] Find Last Fiscal Year.
        Initialize();
        StartingDate := LibraryFiscalYear.GetLastPostingDate(false);

        // [WHEN] Create Fiscal Year.
        LibraryFiscalYear.CreateFiscalYear();

        // [THEN] Verify that New Fiscal Year created.
        Assert.AreNotEqual(StartingDate, LibraryFiscalYear.GetLastPostingDate(false), 'Fiscal Year must not be equal');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CloseIncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure LastNoUsedOnNoSeriesAfterClosingIncomeStatement()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        AddtionalReportingCurrency: Code[10];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 244918] Check Last No. Used field value on No. Series after closing Income Statement using an Additional Reporting Currency.

        // [GIVEN] Close and create new Fiscal year and Update General Ledger Setup.
        Initialize();
        LibraryFiscalYear.CloseFiscalYear();
        ExecuteUIHandler();
        LibraryFiscalYear.CreateFiscalYear();
        AddtionalReportingCurrency := UpdateCurOnGeneralLedgerSetup(CreateCurrency());

        // [GIVEN] Posted Gen. Journal Lines.
        CreateGeneralJournalLines(
          GenJournalLine, LibraryFiscalYear.GetLastPostingDate(true));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        DocumentNo := NoSeries.PeekNextNo(GenJournalBatch."No. Series");
        Commit();

        // [WHEN] Run "Close Income Statement"
        CloseIncomeStatement(GenJournalLine, IncStr(GenJournalLine."Document No."));

        // [THEN] Last No. Used field value on No. Series Line.
        VerifyNoSeriesLine(GenJournalBatch."No. Series", DocumentNo);

        // Tear Down: Update General Ledger Setup.
        UpdateCurOnGeneralLedgerSetup(AddtionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,CloseIncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostingNoSeriesUpdateAfterCloseIncomeStatement()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
        LastNoUsed: Code[20];
    begin
        // [SCENARIO 264217] Check that Posting No. Series updated in GL Entry and No. Series after posting General Journal entries created from Close Income Statement.

        // [GIVEN] Closed currect Fiscal Year
        // [GIVEN] Created new Fiscal Year
        // [GIVEN] Posted General Journal Lines to create entries in last Fiscal Year,
        // [GIVEN] Created General Journal Line by "Close Income Statement" report
        Initialize();
        LibraryFiscalYear.CloseFiscalYear();
        ExecuteUIHandler();
        LibraryFiscalYear.CreateFiscalYear();

        CreateGeneralJournalLines(GenJournalLine, LibraryFiscalYear.GetLastPostingDate(true));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGeneralJournalLineUsingNewJournalBatch(GenJournalLine);
        CloseIncomeStatement(GenJournalLine, GenJournalLine."Document No.");

        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindLast();
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        NoSeriesLine.SetRange("Series Code", GenJournalBatch."Posting No. Series");
        NoSeriesLine.FindFirst();
        LastNoUsed := NoSeriesLine."Starting No.";

        // [WHEN] Post created Gen. Journal Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN]: Verify Document No. in GL Entry and Last No. used in No. Series Line.
        VerifyDocumentNoInGLEntry(GenJournalLine."Posting Date", GenJournalLine."Source Code", LastNoUsed);
        VerifyNoSeriesLine(GenJournalBatch."Posting No. Series", LastNoUsed);

        // Tear Down: Delete the new General Journal Batch created earlier.
        GenJournalBatch.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalBatch.SetRange(Description, GenJournalBatch.Name);
        GenJournalBatch.FindFirst();
        GenJournalBatch.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CloseIncomeStatementRequestPageHandler,DimensionSelectionMultipleModalPageHandler')]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementWithDimensions()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DocumentNo: Code[20];
        PostingDate: Date;
        GLAccountNo: Code[20];
        BusinessUnitCode: array[2] of Code[10];
    begin
        // [FEATURE] [Dimension] [Business Unit]
        // [SCENARIO 364446] "Close Income Statement" report with Global Dimension Selected and grouped by Business Unit should post G/L Entry per Business Unit
        Initialize();
        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();
        // [GIVEN] Global Dimension Code "G"
        CreateDimensionSet(TempDimensionSetEntry);
        // [GIVEN] Posted Documents without dimenions at date "Date1"
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);
        CreateGeneralJournalLines(GenJournalLine, PostingDate + 1);
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        // [GIVEN] Posted Documents with dimenion code "G" for Business Unit "B1" at date "Date2" < "Date1"
        // [GIVEN] Total Amount of posted documents for "B1" is "A1"
        BusinessUnitCode[1] := CreateBusinessUnitCode();
        CreateGenJournalLinesWithDim(
          GenJournalLine, TempDimensionSetEntry, PostingDate, GLAccountNo, BusinessUnitCode[1]);
        // [GIVEN] Posted Documents with dimenion code "G" for Business Unit "Y" at date "Date2" < "Date1"
        // [GIVEN] Summary Amount of posted documents for "Y" = "Amount Y"
        BusinessUnitCode[2] := CreateBusinessUnitCode();
        CreateGenJournalLinesWithDim(
          GenJournalLine, TempDimensionSetEntry, PostingDate, GLAccountNo, BusinessUnitCode[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run 'Close Income Statement' report grouping by Business Units
        LibraryFiscalYear.CloseFiscalYear();
        PostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));  // Using true for closed.
        SelectDimForCloseIncomeStatement(TempDimensionSetEntry);
        DocumentNo := IncStr(GenJournalLine."Document No.");
        RunCloseIncomeStatement(GenJournalLine, PostingDate, LibraryERM.CreateGLAccountNo(),
          PostToRetainedEarningsAcc::Balance, true, true, IncStr(GenJournalLine."Document No."));
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // [THEN] Close Income Statement G/L Entry Amount for "X" = "Amount X"
        VerifyBusniessUnitCloseIncomeGLEntry(GLAccountNo, BusinessUnitCode[1], DocumentNo);
        // [THEN] Close Income Statement G/L Entry Amount for "Y" = "Amount Y"
        VerifyBusniessUnitCloseIncomeGLEntry(GLAccountNo, BusinessUnitCode[2], DocumentNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ExtenedConfirmHandler')]
    [Scope('OnPrem')]
    procedure CannotDeleteGLAccountInClosedAccountPeriodWithoutSetup()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GLSetup: Record "General Ledger Setup";
    begin
        // [SCENARIO 258044] Stan can confirm to delete G/L Account having posted G/L entries in closed accounting period with posting date later GLSetup."Allow G/L Acc. Deletion Before"

        Initialize();

        LibraryFiscalYear.UpdateAllowGAccDeletionBeforeDateOnGLSetup(0D);
        IntitializeGLAccountWithClosedEntriesClosedAccountingPeriod(GLAccount);

        asserterror GLAccount.Delete(true);
        Assert.ExpectedTestFieldError(GLSetup.FieldCaption("Allow G/L Acc. Deletion Before"), '');

        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ExtenedConfirmHandler')]
    [Scope('OnPrem')]
    procedure ConfirmDeleteGLAccountInClosedAccountPeriod()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO 258044] Stan can delete G/L Account having posted G/L entries in closed accounting period with posting date later GLSetup."Allow G/L Acc. Deletion Before".
        // [SCENARIO 258044] He must approve confirmation.
        Initialize();

        LibraryFiscalYear.UpdateAllowGAccDeletionBeforeDateOnGLSetup(LibraryFiscalYear.GetPastNewYearDate(5));
        IntitializeGLAccountWithClosedEntriesClosedAccountingPeriod(GLAccount);

        LibraryVariableStorage.Enqueue(true);
        GLAccount.Delete(true);

        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        Assert.RecordIsEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BlockDeleteGLAccountWhenBlockIsTrue()
    var
        GLAccount: Record "G/L Account";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [SCENARIO 317281] Stan can not delete a G/L Account when "Block Deleteon of G/L Accounts" is True in GL Setup
        Initialize();

        // [GIVEN] GL Account with entries exists
        IntitializeGLAccountWithClosedEntriesClosedAccountingPeriod(GLAccount);

        // [GIVEN] "Block Deleteon of G/L Accounts" was set to TRUE is GL Setup
        GeneralLedgerSetup.Validate("Block Deletion of G/L Accounts", true);
        GeneralLedgerSetup.Modify(true);

        // [WHEN] Stan tries to delete GL Account
        asserterror GLAccount.Delete(true);

        // [THEN] Testfield error is shown
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ExtenedConfirmHandler')]
    [Scope('OnPrem')]
    procedure RejectDeleteGLAccountInClosedAccountPeriodExisingGLEntries()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        AllowDeleteDate: Date;
    begin
        // [SCENARIO 258044] Stan cannot delete G/L Account having posted G/L entries in closed accounting period with posting date later GLSetup."Allow G/L Acc. Deletion Before".
        // [SCENARIO 258044] He must reject confirmation.
        Initialize();

        AllowDeleteDate := LibraryFiscalYear.GetPastNewYearDate(5);
        LibraryFiscalYear.UpdateAllowGAccDeletionBeforeDateOnGLSetup(AllowDeleteDate);
        IntitializeGLAccountWithClosedEntriesClosedAccountingPeriod(GLAccount);

        LibraryVariableStorage.Enqueue(false);
        asserterror GLAccount.Delete(true);

        Assert.ExpectedError(
          StrSubstNo(CannotDeleteGLAccGLEntryFoundAfterDateErr, GLAccount."No.", AllowDeleteDate));

        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ExtenedConfirmHandler')]
    [Scope('OnPrem')]
    procedure RejectDeleteGLAccountInClosedAccountPeriodExisingGLBudgeEntries()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GLBudgetEntry: Record "G/L Budget Entry";
        AllowDeleteDate: Date;
    begin
        // [SCENARIO 258044] Stan cannot delete G/L Account having G/L budget entries in closed accounting period with posting date later GLSetup."Allow G/L Acc. Deletion Before".
        // [SCENARIO 258044] He must reject confirmation. G/L entries do not exist
        Initialize();

        AllowDeleteDate := LibraryFiscalYear.GetPastNewYearDate(5);
        LibraryFiscalYear.UpdateAllowGAccDeletionBeforeDateOnGLSetup(AllowDeleteDate);
        IntitializeGLAccountWithClosedEntriesClosedAccountingPeriod(GLAccount);

        MockGLBudgetEntry(GLBudgetEntry, GLAccount."No.", AllowDeleteDate);
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.DeleteAll();
        Commit();

        LibraryVariableStorage.Enqueue(false);
        asserterror GLAccount.Delete(true);

        Assert.ExpectedError(
          StrSubstNo(CannotDeleteGLAccGLBudgetEntryFoundErr, GLAccount."No.", AllowDeleteDate, GLBudgetEntry."Budget Name"));

        GLBudgetEntry.SetRange("G/L Account No.", GLAccount."No.");
        Assert.RecordIsNotEmpty(GLBudgetEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ExtenedConfirmHandler')]
    [Scope('OnPrem')]
    procedure CannotDeleteGLAccountWithAccountingPeriods()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        AccountingPeriod: Record "Accounting Period";
    begin
        // [SCENARIO 258044] Stan cannot delete G/L Account having G/L entries in open accounting period.
        Initialize();

        LibraryFiscalYear.UpdateAllowGAccDeletionBeforeDateOnGLSetup(LibraryFiscalYear.GetPastNewYearDate(5));
        IntitializeGLAccountWithClosedEntriesClosedAccountingPeriod(GLAccount);

        AccountingPeriod.DeleteAll();
        Commit();

        asserterror GLAccount.Delete(true);

        Assert.ExpectedError(StrSubstNo(CannotDeleteGLAccGLEntryFoundErr, GLAccount."No."));

        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CloseIncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementWithPostToRetainedEarningsAccDetails()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        RetainedEarningsAccountNo: Code[20];
        PostingDate: Date;
    begin
        // [SCENARIO 296670] "Close Income Statement" report with "Post to Retained Earnings Acc." = Details
        // should suggested Gen. Journal with the Retained Earnings account as a balancing account on each line
        Initialize();
        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();

        // [GIVEN] Posted Document
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);
        CreateGeneralJournalLines(GenJournalLine, PostingDate + 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run 'Close Income Statement' report with "Post to Retained Earnings Acc." = Details
        LibraryFiscalYear.CloseFiscalYear();
        PostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));  // Using true for closed.
        DocumentNo := IncStr(GenJournalLine."Document No.");
        RetainedEarningsAccountNo := LibraryERM.CreateGLAccountNo();
        RunCloseIncomeStatement(GenJournalLine, PostingDate, RetainedEarningsAccountNo, 1, false, false, DocumentNo);

        // [THEN] All lines have Retained Earnings Account as balance account
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        if GenJournalLine.FindSet() then
            repeat
                GenJournalLine.TestField("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
                GenJournalLine.TestField("Bal. Account No.", RetainedEarningsAccountNo);
            until GenJournalLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CloseIncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementWithPostToRetainedEarningsAccBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        RetainedEarningsAccountNo: Code[20];
        PostingDate: Date;
    begin
        // [SCENARIO 296670] "Close Income Statement" report with "Post to Retained Earnings Acc." = Balance
        // should suggested Gen. Journal with the Retained Earnings account on an extra line with a summarized amount
        Initialize();
        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();

        // [GIVEN] Posted Document
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);
        CreateGeneralJournalLines(GenJournalLine, PostingDate + 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run 'Close Income Statement' report with "Post to Retained Earnings Acc." = Balance
        LibraryFiscalYear.CloseFiscalYear();
        PostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));  // Using true for closed.
        DocumentNo := IncStr(GenJournalLine."Document No.");
        RetainedEarningsAccountNo := LibraryERM.CreateGLAccountNo();
        RunCloseIncomeStatement(GenJournalLine, PostingDate, RetainedEarningsAccountNo, 0, false, false, DocumentNo);

        // [THEN] Last line have Retained Earnings Account
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindLast();
        GenJournalLine.TestField("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.TestField("Account No.", RetainedEarningsAccountNo);

        // [THEN] All lines have empty balance account
        GenJournalLine.SetFilter("Line No.", '<>%1', GenJournalLine."Line No.");
        if GenJournalLine.FindSet() then
            repeat
                GenJournalLine.TestField("Bal. Account No.", '');
            until GenJournalLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CloseIncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementWithPostToRetainedEarningsAccDetailsAllLinesHaveBalanceZero()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        RetainedEarningsAccountNo: Code[20];
        PostingDate: Date;
    begin
        // [SCENARIO 361507] "Close Income Statement" report with "Post to Retained Earnings Acc." = Details
        // [SCENARIO 361507] Must have balance zero for each line generated (since each line is balanced against itself)
        Initialize();
        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();

        // [GIVEN] Posted Document
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);
        CreateGeneralJournalLines(GenJournalLine, PostingDate + 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run 'Close Income Statement' report with "Post to Retained Earnings Acc." = Details
        LibraryFiscalYear.CloseFiscalYear();
        PostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));  // Using true for closed.
        DocumentNo := IncStr(GenJournalLine."Document No.");
        RetainedEarningsAccountNo := LibraryERM.CreateGLAccountNo();
        RunCloseIncomeStatement(GenJournalLine, PostingDate, RetainedEarningsAccountNo, PostToRetainedEarningsAcc::Details, false, false, DocumentNo);

        // [THEN] All lines have Balance (LCY) = 0
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetFilter("Balance (LCY)", '<>0');
        Assert.RecordIsEmpty(GenJournalLine);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Close Income Statement");
        // Lazy Setup.
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Close Income Statement");

        LibraryERMCountryData.CreateVATData();
        LibraryERM.SetBlockDeleteGLAccount(false);
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Close Income Statement");
    end;

    local procedure CloseIncomeStatementWithPostingLines(var GenJournalLine: Record "Gen. Journal Line") DocumentNo: Code[20]
    begin
        // Create and post Gen. Journal Lines and Run Close Income Statement Batch job.
        DocumentNo := PostGeneralJournalLinesAndCloseIncomeStatement(GenJournalLine);
        CreateGeneralJournalLines(
          GenJournalLine, LibraryFiscalYear.GetLastPostingDate(false));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CloseIncomeStatement(GenJournalLine, IncStr(GenJournalLine."Document No."));
    end;

    local procedure CreateBalanceGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure CreateBusinessUnitCode(): Code[10]
    var
        BusinessUnit: Record "Business Unit";
    begin
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        exit(BusinessUnit.Code);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
        Commit();  // Required to run the Test Case on RTC.

        // Create Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateDimensionSet(var DimSetEntry: Record "Dimension Set Entry")
    begin
        CreateAndAddDimValueToDimSetEntry(DimSetEntry, LibraryERM.GetGlobalDimensionCode(1));
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

    local procedure CreateGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Counter: Integer;
    begin
        // Create General Journal Lines in an open Fiscal Year; Generate random No. of Lines from 1 to 10 and
        // take any Random Amount from 1 to 1000.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        GenJournalBatch."Bal. Account No." := CreateBalanceGLAccountNo();
        GenJournalBatch.Modify();
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        for Counter := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandInt(1000));
            GenJournalLine.Validate("Posting Date", PostingDate);
            GenJournalLine.Modify(true);
        end;
    end;

    local procedure CreateGeneralJournalLineUsingNewJournalBatch(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Creating blank General Journal Line that is to be used for Close Income Statement's Request Page Parameters.
        CreateNewJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, '', 0);
        Commit();
    end;

    local procedure CreateNewJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Create a new General Journal Batch with Posting No. Series attached to it.
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.SetupNewBatch();
        GenJournalBatch.Validate("Posting No. Series", CreateNoSeries());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateAndPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount);
        GenJournalLine.Validate("Posting Date", LibraryFiscalYear.GetFirstPostingDate(false));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGenJournalLinesWithDim(var GenJournalLine: Record "Gen. Journal Line"; var TempDimensionSetEntry: Record "Dimension Set Entry" temporary; PostingDate: Date; GLAccountNo: Code[20]; BusinessUnitCode: Code[10])
    var
        DimensionManagement: Codeunit DimensionManagement;
        Index: Integer;
        BalanceGLAccountNo: Code[20];
    begin
        BalanceGLAccountNo := LibraryERM.CreateGLAccountNo();
        for Index := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            LibraryJournals.CreateGenJournalLine(
              GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
              GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::"G/L Account", GLAccountNo,
              GenJournalLine."Bal. Account Type"::"G/L Account", BalanceGLAccountNo,
              LibraryRandom.RandDec(100, 2));
            GenJournalLine.Validate("Posting Date", PostingDate);
            GenJournalLine."Business Unit Code" := BusinessUnitCode;
            GenJournalLine.Modify(true);

            GenJournalLine."Dimension Set ID" := DimensionManagement.GetDimensionSetID(TempDimensionSetEntry);
            DimensionManagement.UpdateGlobalDimFromDimSetID(
              GenJournalLine."Dimension Set ID", GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code");

            GenJournalLine.Modify(true);
        end;
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        exit(NoSeries.Code);
    end;

    local procedure CloseIncomeStatement(GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20])
    var
        Date: Record Date;
    begin
        // Run the Close Income Statement Batch Job.
        Date.SetRange("Period Type", Date."Period Type"::Month);
        Date.SetRange("Period Start", LibraryFiscalYear.GetLastPostingDate(true));
        Date.FindFirst();

        RunCloseIncomeStatement(GenJournalLine, NormalDate(Date."Period End"), LibraryERM.CreateGLAccountNo(), 0, true, false, DocumentNo);
    end;

    local procedure IntitializeGLAccountWithClosedEntriesClosedAccountingPeriod(var GLAccount: Record "G/L Account")
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        LibraryFiscalYear.CloseFiscalYear();
        ExecuteUIHandler();
        LibraryFiscalYear.CreateFiscalYear();
        Amount := LibraryRandom.RandIntInRange(10, 20);
        LibraryERM.CreateGLAccount(GLAccount);

        CreateAndPostGenJnlLine(GenJournalLine, GLAccount."No.", Amount);
        CreateAndPostGenJnlLine(GenJournalLine, GLAccount."No.", -Amount);

        Commit();
        LibraryFiscalYear.CloseFiscalYear();
    end;

    local procedure MockGLBudgetEntry(var GLBudgetEntry: Record "G/L Budget Entry"; GLAccountNo: Code[20]; EntryDate: Date)
    begin
        GLBudgetEntry."Entry No." := LibraryUtility.GetNewRecNo(GLBudgetEntry, GLBudgetEntry.FieldNo("Entry No."));
        GLBudgetEntry."G/L Account No." := GLAccountNo;
        GLBudgetEntry.Date := EntryDate;
        GLBudgetEntry."Budget Name" := LibraryUtility.GenerateGUID();
        GLBudgetEntry.Insert();
    end;

    local procedure PostGeneralJournalLinesAndCloseIncomeStatement(var GenJournalLine: Record "Gen. Journal Line") DocumentNo: Code[20]
    begin
        // Close existing Fiscal Year and Create new Fiscal Year.
        LibraryFiscalYear.CloseFiscalYear();
        ExecuteUIHandler();
        LibraryFiscalYear.CreateFiscalYear();

        // Create random Transactions in General Journal Line, Post the Journal Lines, Close the Fiscal Year and run Close Income Statement Batch Job.
        CreateGeneralJournalLines(
          GenJournalLine, LibraryFiscalYear.GetLastPostingDate(false));
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryFiscalYear.CloseFiscalYear();
        CloseIncomeStatement(GenJournalLine, IncStr(GenJournalLine."Document No."));
    end;

    local procedure RunCloseIncomeStatement(GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; RetainedEarningsAcc: Code[20]; PostToRetainedEarningsAcc: Option; ClosePerBusinessUnit: Boolean; UseDimensions: Boolean; DocumentNo: Code[20])
    begin
        // Enqueue values for CloseIncomeStatementRequestPageHandler.
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(RetainedEarningsAcc);
        LibraryVariableStorage.Enqueue(PostToRetainedEarningsAcc);
        LibraryVariableStorage.Enqueue(ClosePerBusinessUnit);
        LibraryVariableStorage.Enqueue(UseDimensions);

        Commit();  // commit requires to run report.
        REPORT.Run(REPORT::"Close Income Statement");
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

    local procedure UpdateCurOnGeneralLedgerSetup(CurrencyCode: Code[10]) OldAdditionalReportingCurrency: Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Update Additional Reporting Currency.
        GeneralLedgerSetup.Get();
        OldAdditionalReportingCurrency := GeneralLedgerSetup."Additional Reporting Currency";
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify(true);
        Commit();  // Required to run the Test Case on RTC because Modal Form Pops Up after modifying General Ledger Setup.
    end;

    local procedure VerifyDocumentNoInGLEntry(PostingDate: Date; SourceCode: Code[10]; DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.SetRange("Source Code", SourceCode);
        GLEntry.FindFirst();
        GLEntry.TestField("Document No.", DocumentNo);
    end;

    local procedure VerifyGLAccountBalance(AccountNo: Code[20]; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        TotalAmount: Decimal;
    begin
        GLEntry.SetRange("Document No.", DocumentNo, DocumentNo2);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.CalcSums(Amount);
        TotalAmount := GLEntry.Amount;
        GLAccount.Get(AccountNo);
        GLAccount.CalcFields(Balance);
        Assert.AreEqual(GLAccount.Balance, TotalAmount, 'Balance in GL Account not matched.');
    end;

    local procedure VerifyNoSeriesLine(SeriesCode: Code[20]; LastNoUsed: Code[20])
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", SeriesCode);
        NoSeriesLine.FindFirst();
        NoSeriesLine.TestField("Last No. Used", LastNoUsed);
    end;

    local procedure VerifyBusniessUnitCloseIncomeGLEntry(GLAccountNo: Code[20]; BusinessUnitCode: Code[10]; CloseIncomeDocumentNo: Code[20])
    var
        GLEntryPosted: Record "G/L Entry";
        GLEntryCloseIncome: Record "G/L Entry";
    begin
        GLEntryPosted.SetRange("G/L Account No.", GLAccountNo);
        GLEntryPosted.SetRange("Business Unit Code", BusinessUnitCode);
        GLEntryPosted.SetFilter("Document No.", '<>%1', CloseIncomeDocumentNo);
        GLEntryPosted.CalcSums(Amount);

        GLEntryCloseIncome.SetRange("G/L Account No.", GLAccountNo);
        GLEntryCloseIncome.SetRange("Business Unit Code", BusinessUnitCode);
        GLEntryCloseIncome.SetRange("Document No.", CloseIncomeDocumentNo);
        GLEntryCloseIncome.FindFirst();

        Assert.AreEqual(GLEntryPosted.Amount, -GLEntryCloseIncome.Amount, 'Closed Income Entry has invalid amount');
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully in ES.
        Message(ExpectedMessageMsg);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ExtenedConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        case Question of
            ConfirmCloseAccPeriodQst:
                Reply := true;
            ConfirmDeleteGLAccountQst:
                Reply := LibraryVariableStorage.DequeueBoolean();
            else
                Error(UnexpectedConfirmErr, Question);
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementRequestPageHandler(var CloseIncomeStatement: TestRequestPage "Close Income Statement")
    begin
        CloseIncomeStatement.FiscalYearEndingDate.SetValue(LibraryVariableStorage.DequeueDate()); // Fiscal Year Ending Date
        CloseIncomeStatement.GenJournalTemplate.SetValue(LibraryVariableStorage.DequeueText()); // Gen. Journal Template
        CloseIncomeStatement.GenJournalBatch.SetValue(LibraryVariableStorage.DequeueText()); // Gen. Journal Batch
        CloseIncomeStatement.DocumentNo.SetValue(LibraryVariableStorage.DequeueText()); // Document No.
        CloseIncomeStatement.RetainedEarningsAcc.SetValue(LibraryVariableStorage.DequeueText()); // Retained Earnings Acc.
        CloseIncomeStatement.PostToRetainedEarningsAccount.SetValue(LibraryVariableStorage.DequeueInteger()); // Post to Retained Earnings Account
        CloseIncomeStatement.ClosePerBusUnit.SetValue(LibraryVariableStorage.DequeueBoolean()); // Close Business Unit Code
        if LibraryVariableStorage.DequeueBoolean() then // get stored flag for usage Dimensions
            CloseIncomeStatement.Dimensions.AssistEdit(); // Select Dimensions
        CloseIncomeStatement.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSelectionMultipleModalPageHandler(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    begin
        // Select only two created dimensions
        DimensionSelectionMultiple.FILTER.SetFilter(Code, LibraryERM.GetGlobalDimensionCode(1));
        DimensionSelectionMultiple.First();
        DimensionSelectionMultiple.Selected.SetValue(true);
        DimensionSelectionMultiple.OK().Invoke();
    end;
}

