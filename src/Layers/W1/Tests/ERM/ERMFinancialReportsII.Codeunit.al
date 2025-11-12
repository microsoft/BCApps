codeunit 134986 "ERM Financial Reports II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Reports]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        ValidationErr: Label '%1 must be %2 in Report.';
        WarningMsg: Label 'Statement Ending Balance is not equal to Total Balance.';
        HeaderDimensionTxt: Label '%1 - %2';
        NoSeriesGapWarningMsg: Label 'There is a gap in the number series.';
        TotalTxt: Label 'Total %1';
        AddnlFeeLabelTxt: Label 'Additional Fee';
        AmtInclVATLabelTxt: Label 'Amount Including VAT';
        VATBaseLabelTxt: Label 'VAT Base';
        VATAmtSpecLabelTxt: Label 'VAT Amount Specification';
        VATAmtSpecLCYLbl: Label 'VAT Amount Specification in GBP';
        VATAmtLbl: Label 'VAT Amount';
        CustomerNotFoundErr: Label '%1 must be specified.';
        ErrorMsg: Label 'Specify a filter for the Date Filter field in the G/L Account table.';
        ValidateErr: Label 'Error must be Same.';
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2.';
        EmptyDatasetErr: Label 'Dataset does not contain any rows.';
        BlankLinesQtyErr: Label 'Wrong blank lines quantity in dataset.';
        AdjustExchangeErr: Label 'Bank Account Ledger Entry should exist.';
        LibraryUTUtility: Codeunit "Library UT Utility";
        ReminderReportLastLineErr: Label 'Last non-empty Reminder report line should be "Please remit your payment..."';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        OriginalWorkdate: Date;
        ExchRateWasAdjustedTxt: Label 'One or more currency exchange rates have been adjusted.';
        GenJnlTemplateNameTok: Label 'JnlTemplateName_GenJnlBatch';
        GenJnlTmplNameTok: Label 'JnlTmplName_GenJnlBatch';
        GenJnlBatchNameTok: Label 'JnlName_GenJnlBatch';
        WarningCaptionTok: Label 'WarningCaption';
        ErrorTextNumberTok: Label 'ErrorTextNumber';
        WarningErrorErr: Label 'Warning and error text should be empty in line %1.';
        LineNoTok: Label 'LineNo_GenJnlLine';
        CurrentSaveValuesId: Integer;
        DifferentCustomerSameDocumentErr: Label '%1 posted on %2 includes more than one customer or vendor. In order for the program to calculate VAT, the entries must be separated by another document number';
        TestReportDifferentCustomerSameDocumentErr: Label '%1 posted on %2, must be separated by an empty line';
        IsInitialized: Boolean;
        InvoiceOutOfBalanceErr: Label 'Invoice %1 is out of balance by %2.';
        DateOutOfBalanceErr: Label 'As of %1, the lines are out of balance by %2.';
        TotalOutOfBalanceErr: Label 'The total of the lines is out of balance by%1.';
        NotAllowedPostingDateErr: Label 'The Posting Date is not within your range of allowed posting dates.';
        PreviewPostingErr: Label 'Preview Posting Boolean must be false when Report Request Page is rendered.';

    [Test]
    [HandlerFunctions('RHBankaccRecon')]
    [Scope('OnPrem')]
    procedure BankAccReconTestReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        StatementNo: Code[20];
    begin
        // Test Bank Account Reconciliation Test Report.

        // Setup.
        Initialize();
        CreateAndPostBankAccountEntry(GenJournalLine);
        StatementNo := CreateBankAccReconciliation(GenJournalLine."Bal. Account No.");

        // Exercise: Save Bank Reconciliation Test Report.
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.Enqueue(StatementNo);

        Commit();
        REPORT.Run(REPORT::"Bank Acc. Recon. - Test");

        // Verify.
        VerifyBankAccReconTest(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('RHBankAccountCheckDetails')]
    [Scope('OnPrem')]
    procedure BankAccountCheckDetailsReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test Bank Account Check Details Report.

        // Setup.
        Initialize();
        CreateAndPostBankAccountEntry(GenJournalLine);

        // Exercise: Save Bank Account Check Details Report.
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");

        Commit();
        REPORT.Run(REPORT::"Bank Account - Check Details");

        // Verify.
        VerifyBankAccountCheckDetails(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('RHReminderTest')]
    [Scope('OnPrem')]
    procedure ReminderTestError()
    var
        ReminderHeader: Record "Reminder Header";
    begin
        // Check Error Message while Saving Reminder Test Report.

        // Setup.
        Initialize();
        LibraryERM.CreateReminderHeader(ReminderHeader);

        // Exercise: Save Reminder Test Report without any option.
        LibraryVariableStorage.Enqueue(ReminderHeader."No.");
        LibraryVariableStorage.Enqueue(false);

        Commit();
        asserterror REPORT.Run(REPORT::"Reminder - Test");

        // Verify: Verify Error Message.
        Assert.ExpectedErrorCannotFind(Database::"Customer Posting Group");
    end;

    [Test]
    [HandlerFunctions('RHReminderTest')]
    [Scope('OnPrem')]
    procedure ReminderTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReminderNo: Code[20];
    begin
        // Check Reminder Test Report.

        // Setup. Create Reminder for Customer. Take Random Invoice Amount.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomer(), LibraryRandom.RandDec(1000, 2));
        ReminderNo := CreateReminderWithGivenDocNo(GenJournalLine."Document No.", GenJournalLine."Account No.");

        // Exercise: Save Reminder Test Report with Show Dimensions FALSE.
        LibraryVariableStorage.Enqueue(ReminderNo);
        LibraryVariableStorage.Enqueue(false);

        Commit();
        REPORT.Run(REPORT::"Reminder - Test");

        // Verify.
        VerifyReminderTest(GenJournalLine, ReminderNo);
    end;

    [Test]
    [HandlerFunctions('RHReminderTest')]
    [Scope('OnPrem')]
    procedure ReminderTestWithDimension()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DimensionValue: Record "Dimension Value";
        ReminderNo: Code[20];
    begin
        // Check Reminder Test Report with Show Dimensions Option.

        // Setup. Create Reminder for Customer with Dimensions attached. Take Random Invoice Amount.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomerWithDimension(DimensionValue), LibraryRandom.RandDec(1000, 2));
        ReminderNo := CreateReminderWithGivenDocNo(GenJournalLine."Document No.", GenJournalLine."Account No.");

        // Exercise: Save Reminder Test Report with Show Dimensions TRUE.
        LibraryVariableStorage.Enqueue(ReminderNo);
        LibraryVariableStorage.Enqueue(true);

        Commit();
        REPORT.Run(REPORT::"Reminder - Test");

        // Verify.
        VerifyDimensionsOnReport(DimensionValue);
    end;

    [Test]
    [HandlerFunctions('RHReminderTest')]
    [Scope('OnPrem')]
    procedure ReminderTestVATEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReminderNo: Code[20];
        SavedAddFeeAccountNo: Code[20];
    begin
        // Check VAT Entries for Reminder Test Report.

        // Setup: Create Invoice Entry for Customer with Random Amount. Update Customer Posting Group and Create Reminder.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomer(), LibraryRandom.RandDec(1000, 2));
        SavedAddFeeAccountNo := UpdateCustomerPostingGroup(GenJournalLine."Account No.", FindAndUpdateGLAccountWithVAT());
        ReminderNo := CreateReminderWithGivenDocNo(GenJournalLine."Document No.", GenJournalLine."Account No.");

        // Exercise: Save Reminder Test Report with Show Dimensions FALSE.
        LibraryVariableStorage.Enqueue(ReminderNo);
        LibraryVariableStorage.Enqueue(false);

        Commit();
        REPORT.Run(REPORT::"Reminder - Test");

        // Verify.
        VerifyReminderTestVATEntry(ReminderNo);

        // Tear Down
        UpdateCustomerPostingGroup(GenJournalLine."Account No.", SavedAddFeeAccountNo);
    end;

    [Test]
    [HandlerFunctions('RHFinanceChargeMemo')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        IssuedFinChargeMemoNo: Code[20];
        FinChargeMemoNo: Code[20];
    begin
        // Check Finance Charge Memo Report.

        // Setup: Create and Issue Finance Charge Memo for a Customer. Take Random value for Invoice Amount.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomer(), LibraryRandom.RandDec(1000, 2));
        FinChargeMemoNo := CreateSuggestFinanceChargeMemo(GenJournalLine."Account No.", GenJournalLine."Document No.");
        IssuedFinChargeMemoNo := IssueAndGetFinChargeMemoNo(FinChargeMemoNo);

        // Exercise: Save Finance Charge Memo Report with Show Internal Information and Interaction Log as FALSE.
        RunReportFinanceChargeMemo(IssuedFinChargeMemoNo, false, false);

        // Verify.
        VerifyFinanceChargeMemo(IssuedFinChargeMemoNo);
    end;

    [Test]
    [HandlerFunctions('RHFinanceChargeMemo')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoInternalInfo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DimensionValue: Record "Dimension Value";
        FinChargeMemoNo: Code[20];
        IssuedFinChargeMemoNo: Code[20];
    begin
        // Check Dimension Values on saved Finance Charge Memo Report with Show Internal Information TRUE.

        // Setup: Create and Issue Finance Charge Memo for a Customer. Take Random value for Invoice Amount.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomerWithDimension(DimensionValue), LibraryRandom.RandDec(1000, 2));
        FinChargeMemoNo := CreateSuggestFinanceChargeMemo(GenJournalLine."Account No.", GenJournalLine."Document No.");
        IssuedFinChargeMemoNo := IssueAndGetFinChargeMemoNo(FinChargeMemoNo);

        // Exercise: Save Finance Charge Memo Report with Show Internal Information as TRUE.
        RunReportFinanceChargeMemo(IssuedFinChargeMemoNo, true, false);

        // Verify:
        VerifyDimensionsOnReport(DimensionValue);
    end;

    [Test]
    [HandlerFunctions('RHFinanceChargeMemo')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoLogEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        InteractionLogEntry: Record "Interaction Log Entry";
        FinChargeMemoNo: Code[20];
        IssuedFinChargeMemoNo: Code[20];
    begin
        // Check Interaction Log Entry for saved Finance Charge Memo Report with Interaction Log TRUE.

        // Setup: Create and Issue Finance Charge Memo for a Customer. Take Random value for Invoice Amount.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomer(), LibraryRandom.RandDec(1000, 2));
        FinChargeMemoNo := CreateSuggestFinanceChargeMemo(GenJournalLine."Account No.", GenJournalLine."Document No.");
        IssuedFinChargeMemoNo := IssueAndGetFinChargeMemoNo(FinChargeMemoNo);

        // Exercise: Save Finance Charge Memo Report with Interaction Log as TRUE.
        RunReportFinanceChargeMemo(IssuedFinChargeMemoNo, false, true);

        // Verify.
        VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Sales Finance Charge Memo", IssuedFinChargeMemoNo);
    end;

    [Test]
    [HandlerFunctions('RHFinanceChargeMemo')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoVATEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FinChargeMemoNo: Code[20];
        IssuedFinChargeMemoNo: Code[20];
        SavedAddFeeAccountNo: Code[20];
    begin
        // Check VAT Entries for saved Finance Charge Memo Report.

        // Setup: Update Customer Posting Group. Create and Issue Finance Charge Memo for Customer. Take Random value for Invoice Amount.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomer(), LibraryRandom.RandDec(1000, 2));
        SavedAddFeeAccountNo := UpdateCustomerPostingGroup(GenJournalLine."Account No.", FindAndUpdateGLAccountWithVAT());
        FinChargeMemoNo := CreateSuggestFinanceChargeMemo(GenJournalLine."Account No.", GenJournalLine."Document No.");
        IssuedFinChargeMemoNo := IssueAndGetFinChargeMemoNo(FinChargeMemoNo);

        // Exercise: Save Finance Charge Memo Report with Show Internal Information and Interaction Log as FALSE.
        RunReportFinanceChargeMemo(IssuedFinChargeMemoNo, false, false);

        // Verify.
        VerifyFinChrgMemoVATEntry(IssuedFinChargeMemoNo);

        // Tear Down
        UpdateCustomerPostingGroup(GenJournalLine."Account No.", SavedAddFeeAccountNo);
    end;

    [Test]
    [HandlerFunctions('RHFinanceChargeMemoTest')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FinChargeMemoNo: Code[20];
    begin
        // Check Finance Charge Memo Test Report.

        // Setup: Create Finance Charge Memo for Customer. Take Random value for Invoice Amount.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomer(), LibraryRandom.RandDec(1000, 2));
        FinChargeMemoNo := CreateSuggestFinanceChargeMemo(GenJournalLine."Account No.", GenJournalLine."Document No.");

        // Exercise: Save Finance Charge Memo Test Report with Show Dimensions False.
        RunReportFinanceChargeMemoTest(FinChargeMemoNo, false);

        // Verify.
        VerifyFinanceChargeMemoTest(GenJournalLine, FinChargeMemoNo);
    end;

    [Test]
    [HandlerFunctions('RHFinanceChargeMemoTest')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoTestDimension()
    var
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        FinChargeMemoNo: Code[20];
    begin
        // Check Finance Charge Memo Test Report with Show Dimensions TRUE.

        // Setup: Suggest Finance Charge Memo for a Customer having Dimension attached. Take Random Invoice Amount.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomerWithDimension(DimensionValue), LibraryRandom.RandDec(1000, 2));
        FinChargeMemoNo := CreateSuggestFinanceChargeMemo(GenJournalLine."Account No.", GenJournalLine."Document No.");

        // Exercise: Save Finance Charge Memo Test Report with Show Dimensions TRUE.
        RunReportFinanceChargeMemoTest(FinChargeMemoNo, true);

        // Verify.
        VerifyDimensionsOnReport(DimensionValue);
    end;

    [Test]
    [HandlerFunctions('RHFinanceChargeMemoTest')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoTestWarnings()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
    begin
        // Check Warnings on Finance Charge Memo Test Report when Customer No. is not present on created Finance Charge Memo.

        // Setup: Create Finance Charge Memo Header with No Customer Attached.
        Initialize();
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, '');

        // Exercise: Save Finance Charge Memo Test Report with Show Dimensions FALSE.
        RunReportFinanceChargeMemoTest(FinanceChargeMemoHeader."No.", false);

        // Verify: Verify Warnings on Finance Charge Memo Test Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo(CustomerNotFoundErr, FinanceChargeMemoHeader.FieldCaption("Customer No.")));
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_',
          StrSubstNo(CustomerNotFoundErr, FinanceChargeMemoHeader.FieldCaption("Customer Posting Group")));
    end;

    [Test]
    [HandlerFunctions('RHFinanceChargeMemoTest')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoTestVATEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FinChargeMemoNo: Code[20];
        SavedAddFeeAccountNo: Code[20];
    begin
        // Check VAT Entries on Finance Charge Memo Test Report.

        // Setup: Create Finance Charge Memo and Update Customer Posting Group. Take Random Amount for Invoice.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomer(), LibraryRandom.RandDec(1000, 2));
        SavedAddFeeAccountNo := UpdateCustomerPostingGroup(GenJournalLine."Account No.", FindAndUpdateGLAccountWithVAT());
        FinChargeMemoNo := CreateSuggestFinanceChargeMemo(GenJournalLine."Account No.", GenJournalLine."Document No.");

        // Exercise: Save Finance Charge Memo Test Report with Show Dimensions FALSE.
        RunReportFinanceChargeMemoTest(FinChargeMemoNo, false);

        // Verify.
        VerifyFinChrgMemoTestVATEntry(FinChargeMemoNo);

        // Tear Down
        UpdateCustomerPostingGroup(GenJournalLine."Account No.", SavedAddFeeAccountNo);
    end;

    [Test]
    [HandlerFunctions('RHReceivablesPayables')]
    [Scope('OnPrem')]
    procedure ReceivablesPayables()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PeriodLength: DateFormula;
    begin
        // Verify Customer Balance, Vendor Balance and Net Change Column values.

        // Setup.
        Initialize();
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');

        // Exercise: Save Report Receivables Payables.
        RunReportReceivablesPayables(WorkDate(), LibraryRandom.RandInt(5), PeriodLength);

        // Verify: Verify Receivables Payables different Amounts.
        GeneralLedgerSetup.FindFirst();
        GeneralLedgerSetup.CalcFields("Cust. Balances Due", "Vendor Balances Due");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CustBalancesDue_GLSetup', GeneralLedgerSetup."Cust. Balances Due");
        LibraryReportDataset.AssertElementWithValueExists('VenBalancesDue_GLSetup', GeneralLedgerSetup."Vendor Balances Due");
        if not LibraryReportDataset.GetNextRow() then
            Error(EmptyDatasetErr);
        GeneralLedgerSetup.SetRange("Date Filter", 0D, WorkDate() - 1);
        GeneralLedgerSetup.CalcFields("Cust. Balances Due", "Vendor Balances Due");
        LibraryReportDataset.AssertCurrentRowValueEquals('BeforeCustBalanceLCY', GeneralLedgerSetup."Cust. Balances Due");
        LibraryReportDataset.AssertCurrentRowValueEquals('BeforeVendorBalanceLCY', GeneralLedgerSetup."Vendor Balances Due");
    end;

    [Test]
    [HandlerFunctions('RHGeneralJournalTest')]
    [Scope('OnPrem')]
    procedure GeneralJournalTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check General Journal Test Report without Dimension.

        // Setup.
        Initialize();
        CreatePaymentGenLine(GenJournalLine);

        // Exercise: Save General Journal Test Report without Dimension.
        RunReportGeneralJournalTest(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", false);

        // Verify: Verify General Journal Test Report without Dimension.
        VerifyGeneralJournalTest(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('RHGeneralJournalTest')]
    [Scope('OnPrem')]
    procedure GeneralJournalTestDimension()
    var
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check General Journal Test Report with Dimension.

        // Setup: Create General Journal Line with Dimension.
        Initialize();
        CreatePaymentGenLine(GenJournalLine);

        // 1 is required to Set Proper General Journal Line Dimension.
        DimensionValue.SetRange("Global Dimension No.", 1);
        DimensionValue.FindFirst();
        GenJournalLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        GenJournalLine.Modify(true);

        // Exercise: Save General Journal Test Report with Dimension.
        RunReportGeneralJournalTest(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", true);

        // Verify: Verify General Journal Test Report with Dimension.
        VerifyGeneralJournalTest(GenJournalLine);
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('DimensionsCaption', 'Dimensions');
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'DimensionsCaption', 'Dimensions');
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'DimText', StrSubstNo(HeaderDimensionTxt, DimensionValue."Dimension Code", DimensionValue.Code));
    end;

    [Test]
    [HandlerFunctions('RHTrialBalancePreviousYear')]
    [Scope('OnPrem')]
    procedure TrialBalPreviousYearNoOption()
    begin
        // Check Trial Balance Previous Year Report without any option selected.

        // Setup.
        Initialize();

        // Exercise.
        asserterror RunReportTrialBalancePreviousYear('', 0D);

        // Verify: Verify Error Raised during Save the Report.
        Assert.AreEqual(StrSubstNo(ErrorMsg), GetLastErrorText, ValidateErr);
    end;

    [Test]
    [HandlerFunctions('RHTrialBalancePreviousYear')]
    [Scope('OnPrem')]
    procedure TrialBalPreviousYearGLAcc()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        FiscalYearStartDate: Date;
        FiscalYearEndDate: Date;
        LastYearStartDate: Date;
        LastYearEndDate: Date;
        FiscalYearBalance: Decimal;
        FiscalYearNetChange: Decimal;
        NetChangeIncreasePct: Decimal;
        BalanceIncreasePct: Decimal;
    begin
        // Check Trial Balance Previous Year for GL Account.

        // Setup.
        Initialize();
        WorkDate := CalcDate('<+1Y>', WorkDate());
        PostGenLinesCustomPostingDate(GenJournalLine);

        // Exercise: Save Trial Balance Previous Year Report.
        RunReportTrialBalancePreviousYear(GenJournalLine."Account No.", WorkDate());

        // Below Customized Formula is required as per Report Requirement.
        FindGLAccount(GLAccount, GenJournalLine."Account No.", WorkDate(), WorkDate());
        FiscalYearStartDate := GLAccount.GetRangeMin("Date Filter");
        FiscalYearEndDate := GLAccount.GetRangeMax("Date Filter");
        LastYearStartDate := CalcDate('<-1Y>', NormalDate(FiscalYearStartDate) + 1) - 1;
        LastYearEndDate := CalcDate('<-1Y>', NormalDate(FiscalYearEndDate) + 1) - 1;
        if FiscalYearStartDate <> NormalDate(FiscalYearStartDate) then
            LastYearStartDate := ClosingDate(LastYearStartDate);
        if FiscalYearEndDate <> NormalDate(FiscalYearEndDate) then
            LastYearEndDate := ClosingDate(LastYearEndDate);

        FindGLAccount(GLAccount, GenJournalLine."Account No.", FiscalYearStartDate, FiscalYearEndDate);
        GLAccount.CalcFields("Net Change", "Balance at Date");
        FiscalYearBalance := GLAccount."Balance at Date";
        FiscalYearNetChange := GLAccount."Net Change";
        FindGLAccount(GLAccount, GenJournalLine."Account No.", LastYearStartDate, LastYearEndDate);
        GLAccount.CalcFields("Net Change", "Balance at Date");
        NetChangeIncreasePct := Round(FiscalYearNetChange / GLAccount."Net Change" * 100, 0.1);
        BalanceIncreasePct := Round(FiscalYearBalance / GLAccount."Balance at Date" * 100, 0.1);

        // Verify: Verify Saved Report Data.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_GLAccount', GenJournalLine."Account No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'No_GLAccount', GenJournalLine."Account No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('FiscalYearNetChange', FiscalYearNetChange);
        LibraryReportDataset.AssertCurrentRowValueEquals('NetChangeIncreasePct', NetChangeIncreasePct);
        LibraryReportDataset.AssertCurrentRowValueEquals('LastYearNetChange', GLAccount."Net Change");
        LibraryReportDataset.AssertCurrentRowValueEquals('BalanceIncreasePct', BalanceIncreasePct);
        LibraryReportDataset.AssertCurrentRowValueEquals('LastYearBalance', GLAccount."Balance at Date");
    end;

    [Test]
    [HandlerFunctions('RHTrialBalancePreviousYear')]
    [Scope('OnPrem')]
    procedure TrialBalancePreviousYear_GLAccountWithBlankLines_BlankLinesExistsInDataset()
    begin
        VerifyTrialBalancePreviousYearReportWithBlankLines(LibraryRandom.RandInt(5) + 1);
    end;

    [Test]
    [HandlerFunctions('RHTrialBalancePreviousYear')]
    [Scope('OnPrem')]
    procedure TrialBalancePreviousYear_GLAccountWithBlankLine_OnlyOneBlankLineExistsInDataset()
    begin
        VerifyTrialBalancePreviousYearReportWithBlankLines(1);
    end;

    [Test]
    [HandlerFunctions('RHTrialBalancePreviousYear')]
    [Scope('OnPrem')]
    procedure TrialBalancePreviousYear_GLAccountWithNoBlankLines_NoBlankLinesExistsInDataset()
    begin
        VerifyTrialBalancePreviousYearReportWithBlankLines(0);
    end;

    [Test]
    [HandlerFunctions('RHGeneralJournalTest')]
    [Scope('OnPrem')]
    procedure GeneralJournalTestWithCustomerInvoice()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Check General Journal Test Report for Reconciliation related values.

        // Setup: Create Gen. Journal Line for Customer with Random Amount.
        Initialize();
        ClearGeneralJournalLines(GenJournalBatch);
        GLAccount.Get(GenJournalBatch."Bal. Account No.");
        GLAccount.Validate("Reconciliation Account", true);
        GLAccount.Modify(true);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CreateCustomer(), LibraryRandom.RandDec(1000, 2));

        // Exercise: Save General Journal Test Report without Dimension.
        RunReportGeneralJournalTest(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", false);

        // Verify: Verify General Journal Test Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('GLAccNetChangeNo', GenJournalLine."Bal. Account No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'GLAccNetChangeNo', GenJournalLine."Bal. Account No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('GLAccNetChangeNetChangeJnl', -GenJournalLine.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('GLAccNetChangeBalafterPost', -GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('RHReminder')]
    [Scope('OnPrem')]
    procedure ReminderReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReminderNo: Code[20];
        IssuedReminderNo: Code[20];
    begin
        // Check Reminder Report.

        // Setup: Create and post General Journal Line, Create and Issue Reminder.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomer(), LibraryRandom.RandDec(1000, 2));  // Using Random value for Amount.
        ReminderNo := CreateReminderWithGivenDocNo(GenJournalLine."Document No.", GenJournalLine."Account No.");
        IssuedReminderNo := IssueReminderAndGetIssuedNo(ReminderNo);

        // Exercise.
        RunReportReminder(IssuedReminderNo);

        // Verify.
        VerifyReminderReport(IssuedReminderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InterestAmountOnReminderStatistics()
    var
        ReminderHeader: Record "Reminder Header";
        VATPostingSetup: Record "VAT Posting Setup";
        ReminderStatisticsPage: TestPage "Reminder Statistics";
    begin
        // Verify interest amount on Reminder Statistics Page.

        // Setup: Create Reminder.
        Initialize();
        CreateReminderWithInterestAmount(ReminderHeader, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // Excercise: Open the Statistics Page.
        OpenReminderStatisticsPage(ReminderStatisticsPage, ReminderHeader."No.");

        // Verify: Verifying interest amount on Reminder Statistics Page.
        ReminderStatisticsPage.Interest.AssertEquals(ReminderHeader."Interest Amount");
    end;

    [Test]
    [HandlerFunctions('RHReminderTest')]
    [Scope('OnPrem')]
    procedure InterestAmountOnTestReminderReport()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify interest amount on Reminder Test Report.
        VerifyInterestAmountOnReminderTestReport(VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InterestAmountOnIssuedReminderStatistics()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        VATPostingSetup: Record "VAT Posting Setup";
        IssuedReminderStatistics: TestPage "Issued Reminder Statistics";
    begin
        // Verify interest amount on Issued Reminder Statistics Page.

        // Setup: Create Issued Reminder.
        Initialize();
        CreateIssuedReminderWithInterestAmount(IssuedReminderHeader, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // Excercise: Open the Statistics Page.
        OpenIssuedReminderStatisticsPage(IssuedReminderStatistics, IssuedReminderHeader."No.");

        // Verify: Verifying interest amount on Issued Reminder Statistics Page.
        IssuedReminderStatistics.Interest.AssertEquals(IssuedReminderHeader."Interest Amount");
    end;

    [Test]
    [HandlerFunctions('RHReminder')]
    [Scope('OnPrem')]
    procedure InterestAmountOnReminderReport()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify interest amount on Reminder Report.

        VerifyInterestAmountOnReminderReport(VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
    end;

    [Test]
    [HandlerFunctions('RHReminderTest')]
    [Scope('OnPrem')]
    procedure InterestAmountOnTestReminderReportForNormalVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify interest amount on Reminder Test Report.
        VerifyInterestAmountOnReminderTestReport(VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    [Test]
    [HandlerFunctions('RHReminder')]
    [Scope('OnPrem')]
    procedure InterestAmountOnreminderReportForNormalVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify interest amount on Reminder Report.

        VerifyInterestAmountOnReminderReport(VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    [Test]
    [HandlerFunctions('ExchRateAdjustmentReportReqPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure CheckAdjustExchangeRatesReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
        CurrencyCode: Code[10];
    begin
        // Verify Adjust Exchange Rates Report with Bank Account Ledger Entry created and Check Adjustment Ledger Entry created.

        // 1. Setup: Create Bank Account with Currency & post Ledger Entry with General Journal Line.
        Initialize();
        CurrencyCode := CreateCurrencyWithMultipleExchangeRates();
        BankAccountNo := CreateBankAccountWithDimension(CurrencyCode);
        CreateAndPostGenJournalLineWithCurrency(GenJournalLine, BankAccountNo, CurrencyCode);
        LibraryVariableStorage.Enqueue(CurrencyCode);

        // 2. Exercise: Running the Adjust Exchange Rates Report.
        REPORT.Run(REPORT::"Exch. Rate Adjustment");

        // 3. Verify: Check whether Adjustment Entry is created after Running the Adjust Exchange Rates Report.
        VerifyBankLedgerEntryExist(BankAccountNo);
    end;

    [Test]
    [HandlerFunctions('RHReminder')]
    [Scope('OnPrem')]
    procedure VATBaseAndVATAmountOnReminderReport()
    var
        IssuedReminderNo: Code[20];
    begin
        // Check "VAT Base" and "VAT Amount" for Fee in the "VAT Amount Specification" and "VAT Amount Specification in GBP" sections of Report Reminder.

        // Setup: Set 'Print VAT specification in LCY" = TRUE in General Ledger Setup. Create and post General Journal Line.
        // Create Reminder, add a line for the reminder with fee include VAT. Issued the Reminder.
        Initialize();
        UpdateVATSpecInLCYGeneralLedgerSetup(true);
        IssuedReminderNo := CreateAndIssueReminderWithCurrencyAndVATFee();

        // Exercise: Run the Report - Reminder.
        RunReportReminder(IssuedReminderNo);

        // Verify: Verify "VAT Base" and "VAT Amount" in the "VAT Amount Specification" and "VAT Amount Specification in GBP" sections.
        VerifyReminderVATAmountSpecification(IssuedReminderNo);
    end;

    [Test]
    [HandlerFunctions('RHFinanceChargeMemo')]
    [Scope('OnPrem')]
    procedure VATBaseAndVATAmountOnFinChargeMemoReport()
    var
        IssuedFinanceChargeMemoNo: Code[20];
    begin
        // Check "VAT Base" and "VAT Amount" for Fee in the "VAT Amount Specification in GBP" section of Report Finance Charge Memo.

        // Setup: Set Print VAT specification in LCY = TRUE in General Ledger Setup. Create and post General Journal Line.
        // Create Finance Charge Memo, add a line for the Finance Charge Memo with fee include VAT. Issued the Finance Charge Memo.
        Initialize();
        UpdateVATSpecInLCYGeneralLedgerSetup(true);
        IssuedFinanceChargeMemoNo := CreateAndIssueFinChargeMemoWithCurrencyAndVATFee();

        // Exercise: Run the Report - Finance Charge Memo.
        RunReportFinanceChargeMemo(IssuedFinanceChargeMemoNo, false, true);

        // Verify: Verify "VAT Base" and "VAT Amount" in "VAT Amount Specification in GBP" section.
        VerifyFinanceChargeMemoVATAmountSpecInGBP(IssuedFinanceChargeMemoNo);
    end;

    [Test]
    [HandlerFunctions('RHReminder')]
    [Scope('OnPrem')]
    procedure ReminderReportDoesntShowNotDueDocsWhenRunWithoutShowNotDue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        ReminderNo: Code[20];
        IssuedReminderNo: Code[20];
    begin
        // [SCENARIO 122513] Reminder Report doesn't print Not Due documents when run with "Show Not Due Amounts" = FALSE
        Initialize();
        CustomerNo := CreateCustomer();

        // [GIVEN] Posted invoice with "Posting Date" = WorkDate() + 2 Month
        CreateAndPostGenJournalLineWithDate(GenJournalLine, CalcDate('<2M>', WorkDate()), CustomerNo, LibraryRandom.RandDec(1000, 2));  // Using Random value for Amount.

        // [GIVEN] Posted invoice with "Posting Date" = WORKDATE
        CreateAndPostGenJournalLineWithDate(GenJournalLine, WorkDate(), CustomerNo, LibraryRandom.RandDec(1000, 2));  // Using Random value for Amount.

        // [GIVEN] Issued reminder with WORKDATE
        ReminderNo := CreateReminderWithGivenCust(CustomerNo);
        IssuedReminderNo := IssueReminderAndGetIssuedNo(ReminderNo);

        // [WHEN] Run Reminder report with "Show Not Due Amounts" = FALSE
        RunReportReminder(IssuedReminderNo);

        // [THEN] Last non-empty report line = "Please remit your payment..."
        VerifyReminderReportLastLineIsPleaseRemitYourPayment(GenJournalLine.Amount, CustomerNo, IssuedReminderNo);
    end;

    [Test]
    [HandlerFunctions('RHGenJournalTest')]
    [Scope('OnPrem')]
    procedure FilteringBatchesInGenJournalTestReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FirstGenJournalBatchName: Code[10];
        SecondGenJournalBatchName: Code[10];
        GenJournalTemplateName: Code[10];
    begin
        // [SCENARIO 377820] "Gen. Journal - Test" Report shows Gen. Journal Lines from all batches of filtered template
        Initialize();

        // [GIVEN] Gen. Journal Template = "X" has Gen. Journal Batch = "X1" and Gen. Journal Batch = "X2" with Gen. Journal Lines
        CreateGenJnlBatchesWithLines(GenJournalTemplateName, FirstGenJournalBatchName, SecondGenJournalBatchName);

        // [GIVEN] Gen. Journal Template = "Y" has Gen. Journal Batch = "Y1" with Gen. Journal Lines
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandInt(1000));
        Commit();

        // [WHEN] Run "Gen. Journal - Test" report with filtered Gen. Journal Template "X"
        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplateName);
        REPORT.Run(REPORT::"General Journal - Test", true, false, GenJournalLine);

        // [THEN] Report dataset contains records from batches "X1" and "X2"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GenJnlTemplateNameTok, GenJournalTemplateName);
        LibraryReportDataset.AssertElementWithValueExists(GenJnlBatchNameTok, FirstGenJournalBatchName);
        LibraryReportDataset.AssertElementWithValueExists(GenJnlBatchNameTok, SecondGenJournalBatchName);

        // [THEN] Report dataset doesn't contain record from batch "Y1"
        LibraryReportDataset.AssertElementWithValueNotExist(GenJnlTemplateNameTok, GenJournalLine."Journal Template Name");
        LibraryReportDataset.AssertElementWithValueNotExist(GenJnlBatchNameTok, GenJournalLine."Journal Batch Name");
    end;

    [Test]
    [HandlerFunctions('RHGeneralJournalTest')]
    [Scope('OnPrem')]
    procedure CheckWarningCustomerBlockedShip()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 377906] Gen. Journal Test Report shouldn't show warning for Gen. Journal Line of Customer with Blocked = Ship
        Initialize();

        // [GIVEN] Customer - "C" with Blocked = Ship
        LibrarySales.CreateCustomer(Customer);
        Customer.Blocked := Customer.Blocked::Ship;
        Customer.Modify();

        // [GIVEN] Gen. Journal Line with customer = "C", Document type = Invoice
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandInt(100));

        // [WHEN] Invoke Test Report
        RunReportGeneralJournalTest(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", false);

        // [THEN] Report dataset doesn't contain warning for gen. journal line
        // [THEN] Report dataset doesn't contain error text for gen. journal line
        VerifyEmptyValueOfField(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
    end;

    [Test]
    [HandlerFunctions('RHBankAccDetailTrialBalance')]
    [Scope('OnPrem')]
    procedure BankAccDetailTrialBalanceStartBalanceLCY()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 161527] Check show field Start Balance (LCY) amount in report Bank Acc. - Detail Trial Balance

        // [GIVEN] Create and post Bank Account Entries
        Initialize();
        BankAccountNo := CreateBankAccount();
        CreateAndPostGenJournalLineWithCurrency(GenJournalLine, BankAccountNo, '');

        // [WHEN] Save Bank Acc. - Detail Trial Balance report
        RunReportBankAccDetailTrialBal(BankAccountNo, WorkDate() + 1);

        // [THEN] Report Bank Acc. - Detail Trial Bal. show field Start Balance (LCY) amount
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Posting Date", WorkDate());
        BankAccountLedgerEntry.CalcSums(Amount, "Amount (LCY)");
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.VerifyCellValueByRef(
          'J', 15, 1, LibraryReportValidation.FormatDecimalValue(BankAccountLedgerEntry."Amount (LCY)"));
        LibraryReportValidation.VerifyCellValueByRef(
          'H', 15, 1, LibraryReportValidation.FormatDecimalValue(BankAccountLedgerEntry.Amount)); // TFSID: 268356 - Verify format of Balance in Bank Acc. Detail Trial Balance Report
    end;

    [Test]
    [HandlerFunctions('RHGeneralJournalTest')]
    [Scope('OnPrem')]
    procedure CheckWarningDifferentCustomersSameDocNo()
    var
        CustomerA: Record Customer;
        CustomerB: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [General Journal] [Test Report] [Customer]
        // [SCENARIO 261332] Stan gets error message in report "General Journal - Test" output when balanced journal contains VAT and different customers.
        Initialize();

        // [GIVEN] Customers "A" and "B" and G/L Account "G" with VAT setup
        // [GIVEN] General journal lines with the same "Document No." and "Posting Date":
        // [GIVEN] 1: "Account Type" = Customer, "Account No." = "A" and Amount = 5
        // [GIVEN] 2: "Account Type" = Customer, "Account No." = "B" and Amount = 5
        // [GIVEN] 3: "Account Type" = G/L Account, "Account No." = "G" and Amount = -10
        LibrarySales.CreateCustomer(CustomerA);
        LibrarySales.CreateCustomer(CustomerB);

        CreateGeneralJournalWithThreeLines(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerA."No.", CustomerB."No.",
          LibraryERM.CreateGLAccountWithSalesSetup(), 1);

        Commit();

        // [GIVEN] Journal posting throws error "DOC1 posted on 27/01/2018 includes more than one customer or vendor. In order for the program to calculate VAT, the entries must be separated by another document number".
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        Assert.ExpectedError(StrSubstNo(DifferentCustomerSameDocumentErr, GenJournalLine."Document No.", GenJournalLine."Posting Date"));

        // [GIVEN] Run report "General Journal - Test" from the journal
        RunReportGeneralJournalTest(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", false);

        // [THEN] Report produced warning line with error text "DOC1 posted on 27/01/2018, must be separated by an empty line"
        VerifyGeneralJournalTestLineErrorText(
          GenJournalLine."Journal Template Name",
          GenJournalLine."Journal Batch Name",
          GenJournalLine."Line No.",
          StrSubstNo(TestReportDifferentCustomerSameDocumentErr, GenJournalLine."Document No.", GenJournalLine."Posting Date"));
    end;

    [Test]
    [HandlerFunctions('RHGeneralJournalTest')]
    [Scope('OnPrem')]
    procedure CheckWarningDifferentVendorsSameDocNo()
    var
        VendorA: Record Vendor;
        VendorB: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [General Journal] [Test Report] [Vendor]
        // [SCENARIO 261332] Stan gets error message in report "General Journal - Test" output when balanced journal contains VAT and different vendors.
        Initialize();

        // [GIVEN] Vendors "A" and "B" and G/L Account "G" with VAT setup
        // [GIVEN] General journal lines with the same "Document No." and "Posting Date":
        // [GIVEN] 1: "Account Type" = Vendor, "Account No." = "A" and Amount = -5
        // [GIVEN] 2: "Account Type" = Vendor, "Account No." = "B" and Amount = -5
        // [GIVEN] 3: "Account Type" = G/L Account, "Account No." = "G" and Amount = 10
        LibraryPurchase.CreateVendor(VendorA);
        LibraryPurchase.CreateVendor(VendorB);

        CreateGeneralJournalWithThreeLines(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorA."No.", VendorB."No.",
          LibraryERM.CreateGLAccountWithPurchSetup(), -1);

        Commit();

        // [GIVEN] Journal posting throws error "DOC1 posted on 27/01/2018 includes more than one customer or vendor. In order for the program to calculate VAT, the entries must be separated by another document number".
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        Assert.ExpectedError(StrSubstNo(DifferentCustomerSameDocumentErr, GenJournalLine."Document No.", GenJournalLine."Posting Date"));

        // [GIVEN] Run report "General Journal - Test" from the journal
        RunReportGeneralJournalTest(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", false);

        // [THEN] Report produced warning line with error text "DOC1 posted on 27/01/2018, must be separated by an empty line"
        VerifyGeneralJournalTestLineErrorText(
          GenJournalLine."Journal Template Name",
          GenJournalLine."Journal Batch Name",
          GenJournalLine."Line No.",
          StrSubstNo(TestReportDifferentCustomerSameDocumentErr, GenJournalLine."Document No.", GenJournalLine."Posting Date"));
    end;

    [Test]
    [HandlerFunctions('RHBankAccDetailTrialBalanceXML')]
    [Scope('OnPrem')]
    procedure BankAccDetailTrialBalanceExtDocNo()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
    begin
        // [FEATURE] [Bank Account] [Detail Trial Balance]
        // [SCENARIO 262729] Check field External Document No. in report Bank Acc. - Detail Trial Balance.

        // [GIVEN] Create and post Bank Account Entry with External Document No.
        Initialize();
        BankAccountNo := CreateBankAccount();
        CreateAndPostGenJournalLineWithExtDocNo(GenJournalLine, BankAccountNo);

        // [WHEN] Run Bank Acc. - Detail Trial Balance report.
        RunReportBankAccDetailTrialBal(BankAccountNo, WorkDate());

        // [THEN] Report Bank Acc. - Detail Trial Bal. show field External Document No.
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Posting Date", WorkDate());
        BankAccountLedgerEntry.FindFirst();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocNo_BankAccLedg', BankAccountLedgerEntry."Document No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ExtDocNo_BankAccLedg', BankAccountLedgerEntry."External Document No.");
    end;

    [Test]
    [HandlerFunctions('ReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CompanyLogoOnlyInFirstRowRemindersReport()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        // [SCENARIO 271843] The Reminder report contains Company Logo only in the first row of dataset
        Initialize();

        // [GIVEN] "Sales & Receivables Setup"."Logo Position on Document" = Left (the position is not matter)
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Logo Position on Documents" := SalesReceivablesSetup."Logo Position on Documents"::Left;
        SalesReceivablesSetup.Modify();

        // [GIVEN] Issued Reminder
        CreateIssuedReminderWithInterestAmount(IssuedReminderHeader, "Tax Calculation Type"::"Normal VAT"); // VAT Calculation type is not matter
        Commit();

        // [WHEN] Run report Reminder
        REPORT.Run(REPORT::Reminder, true, false, IssuedReminderHeader);

        // [THEN] The first row of dataset contains logo
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueNotEquals('CompanyInfo1Picture', '');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('CompanyInfo1Picture', '');
    end;

    [Test]
    [HandlerFunctions('RHGeneralJournalTestSimple')]
    [Scope('OnPrem')]
    procedure GeneralJournalTestDocBalanceWarningNotShownWhenReorder()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocNo: Code[20];
    begin
        // [FEATURE] [General Journal - Test] [Balance (LCY)]
        // [SCENARIO 273766] Report "General Journal - Test" shows no balance warnings when Total Balance is <zero> for this Journal, Posting Date and Document.
        Initialize();
        DocNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Gen. Journal Batch
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::"Cash Receipts");

        // [GIVEN] Gen. Journal Lines "L1" and "L2" with <blank> Bal. Account and different G/L Accounts
        // [GIVEN] "L1" has Balance (LCY) = 1000; "L2" has Balance (LCY) = -1000;
        // [GIVEN] "L1" and "L2" have same Posting Date, Document Type and Document No.
        CreateInvoiceGenJnlLineWithAmount(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocNo, LibraryRandom.RandDecInRange(100, 200, 2),
          WorkDate());
        CreateInvoiceGenJnlLineWithAmount(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocNo, -GenJournalLine.Amount, WorkDate());
        GenJournalLine.SetRecFilter();
        Commit();

        // [WHEN] Run report General Journal - Test with filtered Gen. Journal Line "L2"
        REPORT.Run(REPORT::"General Journal - Test", true, false, GenJournalLine);

        // [THEN] Report dataset doesn't contain warning for gen. journal line
        // [THEN] Report dataset doesn't contain error text for gen. journal line
        VerifyEmptyValueOfField(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
    end;

    [Test]
    [HandlerFunctions('RHGeneralJournalTestSimple')]
    [Scope('OnPrem')]
    procedure GeneralJournalTestShowsDocBalanceWarningWhenOutOfBalanceDoc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [General Journal - Test] [Balance (LCY)]
        // [SCENARIO 273766] Report "General Journal - Test" shows balance warning when Total Balance is <non-zero> for Document.
        Initialize();

        // [GIVEN] Gen. Journal Batch
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::"Cash Receipts");

        // [GIVEN] Gen. Journal Lines "L1" and "L2" with <blank> Bal. Account, different G/L Accounts and different Invoices "D1" and "D2"
        // [GIVEN] "L1" has Balance (LCY) = 1000; "L2" has Balance (LCY) = -1000;
        // [GIVEN] "L1" and "L2" have same Posting Date
        CreateInvoiceGenJnlLineWithAmount(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, LibraryUtility.GenerateGUID(),
          LibraryRandom.RandDecInRange(100, 200, 2), WorkDate());
        CreateInvoiceGenJnlLineWithAmount(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, LibraryUtility.GenerateGUID(),
          -GenJournalLine.Amount, WorkDate());
        GenJournalLine.SetRecFilter();
        Commit();

        // [WHEN] Run report General Journal - Test with filtered Gen. Journal Line "L2"
        REPORT.Run(REPORT::"General Journal - Test", true, false, GenJournalLine);

        // [THEN] Report dataset contains warning for "L2"
        // [THEN] Report dataset contains error text for "L2": "Invoice "D2" is out of balance by -1000.0".
        VerifyGeneralJournalTestLineErrorText(
          GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.",
          StrSubstNo(InvoiceOutOfBalanceErr, GenJournalLine."Document No.", GenJournalLine."Balance (LCY)"));
    end;

    [Test]
    [HandlerFunctions('RHGeneralJournalTestSimple')]
    [Scope('OnPrem')]
    procedure GeneralJournalTestShowsDocBalanceWarningWhenOutOfBalanceDate()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocNo: Code[20];
    begin
        // [FEATURE] [General Journal - Test] [Balance (LCY)]
        // [SCENARIO 273766] Report "General Journal - Test" shows balance warning when Total Balance is <non-zero> for Posting Date.
        Initialize();
        DocNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Gen. Journal Batch
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::"Cash Receipts");

        // [GIVEN] Gen. Journal Lines "L1" and "L2" with <blank> Bal. Account, different G/L Accounts and different Posting Dates 1/23/20 and 1/24/20
        // [GIVEN] "L1" has Balance (LCY) = 1000; "L2" has Balance (LCY) = -1000;
        // [GIVEN] "L1" and "L2" have same Document Type and Document No.
        CreateInvoiceGenJnlLineWithAmount(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocNo, LibraryRandom.RandDecInRange(100, 200, 2),
          WorkDate());
        CreateInvoiceGenJnlLineWithAmount(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocNo, -GenJournalLine.Amount,
          LibraryRandom.RandDateFrom(WorkDate(), 10));
        GenJournalLine.SetRecFilter();
        Commit();

        // [WHEN] Run report General Journal - Test with filtered Gen. Journal Line "L2"
        REPORT.Run(REPORT::"General Journal - Test", true, false, GenJournalLine);

        // [THEN] Report dataset contains warning for "L2"
        // [THEN] Report dataset contains error text for "L2": "As of 01/24/20, the lines are out of balance by -1000.0."
        VerifyGeneralJournalTestLineErrorText(
          GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.",
          StrSubstNo(DateOutOfBalanceErr, GenJournalLine."Posting Date", GenJournalLine."Balance (LCY)"));
    end;

    [Test]
    [HandlerFunctions('RHGeneralJournalTestSimple')]
    [Scope('OnPrem')]
    procedure GeneralJournalTestShowsDocBalanceWarningWhenOutOfBalanceTotal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocNo: Code[20];
        ExpectedDifference: Decimal;
    begin
        // [FEATURE] [General Journal - Test] [Balance (LCY)]
        // [SCENARIO 273766] Report "General Journal - Test" shows balance warning when Total Balance is <non-zero>.
        Initialize();
        DocNo := LibraryUtility.GenerateGUID();
        ExpectedDifference := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Gen. Journal Batch
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::"Cash Receipts");

        // [GIVEN] Gen. Journal Lines "L1", "L2" and "L3" with <blank> Bal. Account and different G/L Accounts
        // [GIVEN] "L1" has Balance (LCY) = 700, "L2" has Balance (LCY) = 1000; "L3" has Balance (LCY) = -1000;
        // [GIVEN] "L2" and "L3" have same Document Type, Document No and Posting Date, but "L1" has other Document No and Posting Date
        CreateInvoiceGenJnlLineWithAmount(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, LibraryUtility.GenerateGUID(),
          ExpectedDifference, LibraryRandom.RandDateFrom(WorkDate(), 10));
        CreateInvoiceGenJnlLineWithAmount(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocNo, LibraryRandom.RandDecInRange(100, 200, 2),
          WorkDate());
        CreateInvoiceGenJnlLineWithAmount(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocNo, -GenJournalLine.Amount,
          WorkDate());
        GenJournalLine.SetRecFilter();
        Commit();

        // [WHEN] Run report General Journal - Test with filtered Gen. Journal Line "L3"
        REPORT.Run(REPORT::"General Journal - Test", true, false, GenJournalLine);

        // [THEN] Report dataset contains warning for "L3"
        // [THEN] Report dataset contains error text for "L3": "The total of the lines is out of balance by 700.0."
        VerifyGeneralJournalTestLineErrorText(
          GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.",
          StrSubstNo(TotalOutOfBalanceErr, ExpectedDifference));
    end;

    [Test]
    [HandlerFunctions('RHGeneralJournalTestSimple')]
    [Scope('OnPrem')]
    procedure GeneralJournalTestGapNosWarningNotShownWhenReorder()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocNo: Code[20];
    begin
        // [FEATURE] [General Journal - Test] [Document No.]
        // [SCENARIO 273766] Report "General Journal - Test" doesn't show "There is a gap in the number series." warnings when there are no gaps in Document No. values
        Initialize();
        DocNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Gen. Journal Batch with "No Series." = "X"
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::"Cash Receipts");
        GenJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        GenJournalBatch.Modify(true);

        // [GIVEN] Gen. Journal Line "L1" with Bal. Account, Document No. = "X-02" and Amount = 1000.0
        CreateInvoiceGenJnlLineWithDocNoAndBalAccount(
          GenJournalLine, GenJournalBatch, IncStr(DocNo), LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [GIVEN] Gen. Journal Line "L2" with Bal. Account, Document No. = "X-01" and Amount = -1000.0
        CreateInvoiceGenJnlLineWithDocNoAndBalAccount(GenJournalLine, GenJournalBatch, DocNo, -GenJournalLine.Amount);
        GenJournalLine.SetRecFilter();
        Commit();

        // [WHEN] Run report General Journal - Test with filtered Gen. Journal Line "L2"
        REPORT.Run(REPORT::"General Journal - Test", true, false, GenJournalLine);

        // [THEN] Report dataset doesn't contain warning for gen. journal line
        // [THEN] Report dataset doesn't contain error text for gen. journal line
        VerifyEmptyValueOfField(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
    end;

    [Test]
    [HandlerFunctions('RHGeneralJournalTestSimple')]
    [Scope('OnPrem')]
    procedure GeneralJournalTestGapNosWarningNotShownWhenSelectLineWithMaxDocNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocNo: Code[20];
    begin
        // [FEATURE] [General Journal - Test] [Document No.]
        // [SCENARIO 273766] Report "General Journal - Test" doesn't show "There is a gap in the number series." warnings when report is run for one line
        // [SCENARIO 273766] with filtered Gen. Journal Line which has max Document No.
        Initialize();
        DocNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Gen. Journal Batch with "No Series." = "X"
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::"Cash Receipts");
        GenJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        GenJournalBatch.Modify(true);

        // [GIVEN] Gen. Journal Line "L1" with Bal. Account, Document No. = "X-03" and Amount = 1000.0
        CreateInvoiceGenJnlLineWithDocNoAndBalAccount(
          GenJournalLine, GenJournalBatch, IncStr(IncStr(DocNo)), LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [GIVEN] Gen. Journal Line "L2" with Bal. Account, Document No. = "X-01" and Amount = -1000.0
        CreateInvoiceGenJnlLineWithDocNoAndBalAccount(GenJournalLine, GenJournalBatch, DocNo, -GenJournalLine.Amount);
        GenJournalLine.SetRecFilter();
        Commit();

        // [WHEN] Run report General Journal - Test with filtered Gen. Journal Line "L2"
        REPORT.Run(REPORT::"General Journal - Test", true, false, GenJournalLine);

        // [THEN] Report dataset doesn't contain warning for gen. journal line
        // [THEN] Report dataset doesn't contain error text for gen. journal line
        VerifyEmptyValueOfField(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
    end;

    [Test]
    [HandlerFunctions('RHGeneralJournalTestSimple')]
    [Scope('OnPrem')]
    procedure GeneralJournalTestShowsGapNosWarningWhenGapInDocNos()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocNo: Code[20];
    begin
        // [FEATURE] [General Journal - Test] [Document No.]
        // [SCENARIO 273766] Report "General Journal - Test" shows warning "There is a gap in the number series." when there are gaps in Document No. values
        Initialize();
        DocNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Gen. Journal Batch with "No Series." = "X"
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::"Cash Receipts");
        GenJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        GenJournalBatch.Modify(true);

        // [GIVEN] Gen. Journal Line "L1" with Bal. Account, Document No. = "X-03" and Amount = 1000.0
        CreateInvoiceGenJnlLineWithDocNoAndBalAccount(
          GenJournalLine, GenJournalBatch, IncStr(IncStr(DocNo)), LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [GIVEN] Gen. Journal Line "L2" with Bal. Account, Document No. = "X-01" and Amount = -1000.0
        CreateInvoiceGenJnlLineWithDocNoAndBalAccount(GenJournalLine, GenJournalBatch, DocNo, -GenJournalLine.Amount);
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Commit();

        // [WHEN] Run report General Journal - Test
        REPORT.Run(REPORT::"General Journal - Test", true, false, GenJournalLine);

        // [THEN] Report dataset contains warning for "L2"
        // [THEN] Report dataset contains error text for "L2": "There is a gap in the number series."
        VerifyGeneralJournalTestLineErrorText(
          GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.",
          NoSeriesGapWarningMsg);
    end;

    [Test]
    [HandlerFunctions('RHGeneralJournalTestSimple')]
    [Scope('OnPrem')]
    procedure GeneralJournalTestDoesNotIncludeBatchesWithOtherTemplates()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJnlTemplName: Code[10];
    begin
        // [FEATURE] [General Journal - Test]
        // [SCENARIO 273766] When report "General Journal - Test" is run then only filtered batches present in report dataset
        Initialize();

        // [GIVEN] Gen. Journal Batch "B1" with Template = "T1"
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::"Cash Receipts");
        GenJnlTemplName := GenJournalBatch."Journal Template Name";

        // [GIVEN] Gen. Journal Batch "B2" with Template = "T2", rest is copied from "B1"
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalBatch.Validate("Journal Template Name", GenJournalTemplate.Name);
        GenJournalBatch.Insert(true);

        // [GIVEN] Gen. Journal Line with batch "B2"
        CreateInvoiceGenJnlLineWithDocNoAndBalAccount(
          GenJournalLine, GenJournalBatch, LibraryUtility.GenerateGUID(), LibraryRandom.RandDecInRange(1000, 2000, 2));
        GenJournalLine.SetRecFilter();
        Commit();

        // [WHEN] Run report General Journal - Test
        REPORT.Run(REPORT::"General Journal - Test", true, false, GenJournalLine);

        // [THEN] <JnlTmplName_GenJnlBatch> with value "T1" does not present in report dataset
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist(GenJnlTmplNameTok, GenJnlTemplName);

        // [THEN] <JnlTmplName_GenJnlBatch> with value "T2" is in report dataset
        LibraryReportDataset.AssertElementWithValueExists(GenJnlTmplNameTok, GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [HandlerFunctions('RHGeneralJournalTestSimple')]
    [Scope('OnPrem')]
    procedure GeneralJournalTestAllowPostingError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [General Journal - Test]
        // [SCENARIO 290598] When report "General Journal - Test" is run for line with Posting Date out of Allow Posting From setup error is listed in the report
        Initialize();

        // [GIVEN] Set GeneralLedgerSetup."Allow Posting From" = 01.01.2020
        LibraryERM.SetAllowPostingFromTo(CalcDate('<2Y>', WorkDate()), 0D);

        // [GIVEN] Gen. Journal Batch
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::"Cash Receipts");

        // [GIVEN] Gen. Journal Line with Posting Date = 01.01.2018
        CreateInvoiceGenJnlLineWithDocNoAndBalAccount(
          GenJournalLine, GenJournalBatch, LibraryUtility.GenerateGUID(), LibraryRandom.RandDecInRange(1000, 2000, 2));
        GenJournalLine.SetRecFilter();
        Commit();

        // [WHEN] Run report General Journal - Test
        REPORT.Run(REPORT::"General Journal - Test", true, false, GenJournalLine);

        // [THEN] Report dataset contains error text: "The Posting Date is not within your range of allowed posting dates."
        VerifyGeneralJournalTestLineErrorText(
          GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.",
          NotAllowedPostingDateErr);
    end;

    [Test]
    [HandlerFunctions('RHFinanceChargeMemo')]
    [Scope('OnPrem')]
    procedure PrintIssuedFinChargeMemoWithoutAdditionalFeeAccount()
    var
        IssuedFinChargeMemoNo: Code[20];
        CustomerPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Fin. Charge Memo]
        // [SCENARIO 297976] Report "Finance Charge Memo" is printing when Customer Posting Group without Additional Fee Account
        // [GIVEN] Customer Posting Group without Additional Fee Account
        CustomerPostingGroupCode := CreateCustPostingGroupWithoutAddFeeAcc();

        // [GIVEN] Issued Fin. Charge Memo without Additional Fee Account into Posting Setup
        IssuedFinChargeMemoNo := CreateIssuedFinChargeMemo(CustomerPostingGroupCode);

        // [WHEN] Print Issued Fin. Charge Memo
        RunReportFinanceChargeMemo(IssuedFinChargeMemoNo, false, false);

        // [THEN] Issued Fin. Charge Memo is printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('No1_IssuFinChrgMemoHr', IssuedFinChargeMemoNo);
    end;

    [Test]
    [HandlerFunctions('ReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportReminderTotalForIssuedReminderWithBlankTypeLine()
    var
        IssuedRmdrHdr: Record "Issued Reminder Header";
        IssuedRmdrLine: array[3] of Record "Issued Reminder Line";
    begin
        // [SCENARIO 317590] Issued Reminder Lines with blank type does not affect total in report "Reminder".
        Initialize();

        // [GIVEN] Issued Reminder Header.
        LibraryReportDataset.SetFileName(LibraryUtility.GenerateGUID());
        MockIssuedReminder(IssuedRmdrHdr);
        // [GIVEN] Issued Reminder Lines:
        // [GIVEN] Type = "Customer Ledger Entry", Remaining Amount = "A1", Amount = "A2";
        // [GIVEN] Type = " ", Remaining Amount = 0, Amount = 0;
        // [GIVEN] Type = "G/L Account", Remaining Amount = 0, Amount = "A3";
        MockIssuedReminderLine(
          IssuedRmdrLine[1], IssuedRmdrHdr, IssuedRmdrLine[1].Type::"Customer Ledger Entry", LibraryRandom.RandIntInRange(1, 10), LibraryRandom.RandIntInRange(1, 10));
        MockIssuedReminderLine(IssuedRmdrLine[2], IssuedRmdrHdr, IssuedRmdrLine[2].Type::" ", 0, 0);
        MockIssuedReminderLine(IssuedRmdrLine[3], IssuedRmdrHdr, IssuedRmdrLine[3].Type::"G/L Account", 0, LibraryRandom.RandIntInRange(1, 10));

        // [WHEN] Report Reminder is run.
        Commit();
        IssuedRmdrHdr.SetRecFilter();
        REPORT.Run(REPORT::Reminder, true, true, IssuedRmdrHdr);

        // [THEN] Total is equal to "A1" + "A2" + "A3".
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'NNCTotal', IssuedRmdrLine[1]."Remaining Amount" + IssuedRmdrLine[1].Amount + IssuedRmdrLine[3].Amount);
    end;

    [Test]
    [HandlerFunctions('RHBankAccountCheckDetails')]
    [Scope('OnPrem')]
    procedure BankAccountCheckDetailsAmounts()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankAccountNo: Code[20];
        Amount: array[4] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 319616] Report "Bank Account - Check Details" shows right amounts for Amount Printed and Amount Voided columns.
        Initialize();

        // [GIVEN] Bank Account.
        BankAccountNo := LibraryERM.CreateBankAccountNo();

        // [GIVEN] Check Ledger entries with:
        // [GIVEN] Amount = "A1", Entry Status = "Printed";
        // [GIVEN] Amount = "A2", Entry Status = "Printed";
        // [GIVEN] Amount = "A3", Entry Status = "Voided";
        // [GIVEN] Amount = "A4", Entry Status = "Voided";
        for i := 1 to 4 do
            Amount[i] := LibraryRandom.RandDec(10, 2);

        MockCheckLedgerEntry(CheckLedgerEntry, BankAccountNo, Amount[1], CheckLedgerEntry."Entry Status"::Printed);
        MockCheckLedgerEntry(CheckLedgerEntry, BankAccountNo, Amount[2], CheckLedgerEntry."Entry Status"::Printed);
        MockCheckLedgerEntry(CheckLedgerEntry, BankAccountNo, Amount[3], CheckLedgerEntry."Entry Status"::Voided);
        MockCheckLedgerEntry(CheckLedgerEntry, BankAccountNo, Amount[4], CheckLedgerEntry."Entry Status"::Voided);

        // [WHEN] Report "Bank Account - Check Details" is run.
        Commit();
        LibraryVariableStorage.Enqueue(BankAccountNo);
        REPORT.Run(REPORT::"Bank Account - Check Details");

        // [THEN] Sum of AmountPrinted = "A1" + "A2", sum of AmountVoided = "A3" + "A4";
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(Amount[1] + Amount[2], LibraryReportDataset.Sum('AmountPrinted'), '');
        Assert.AreEqual(Amount[3] + Amount[4], LibraryReportDataset.Sum('AmountVoided'), '');
    end;

    [Test]
    [HandlerFunctions('PreviewPostingExchRateAdjustmentReportReqPageHandler,StatisticsMessageHandler')]
    procedure PreviewPostDisabledInExchRateAdjustmentReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JobQueueEntry: Record "Job Queue Entry";
        BankAccountNo: Code[20];
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 319616] Report "Bank Account - Check Details" shows right amounts for Amount Printed and Amount Voided columns.
        Initialize();

        // [GIVEN] Create a Currency With Multiple Exchange Rates.
        CurrencyCode := CreateCurrencyWithMultipleExchangeRates();

        // [GIVEN] Create Bank Account With Currency.
        BankAccountNo := CreateBankAccountWithCurrency(CurrencyCode);

        // [GIVEN] Create And Post General Journal Line With Currency.
        CreateAndPostGenJournalLineWithCurrency(GenJournalLine, BankAccountNo, CurrencyCode);

        // [GIVEN] Store Currency Code.
        LibraryVariableStorage.Enqueue(CurrencyCode);

        // [THEN] Run job queue for Exchange Rate Adjustment and Post adjustments.
        SetAndRunJobQueue(Report::"Exch. Rate Adjustment", JobQueueEntry."Report Output Type"::"None (Processing only)", JobQueueEntry);
    end;

    [Test]
    [HandlerFunctions('VATReconciliationRequestPageHandler')]
    procedure VATReconciliationReportReportsCorrectAmountWhenSameDocumentNo()
    var
        GLAccount: array[3] of Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[4] of Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Amount: array[3] of Decimal;
        DocumentNo: code[20];
        i: Integer;
    begin
        // [SCENARIO 550878] VAT Reconciliation Report Records the correct value for the base amount for all financial entries that have the same Document Number and Posting Date.
        Initialize();

        // [GIVEN] Create VAT Posting Setup With Accounts.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        // [GIVEN] Create three "X, Y and Z" GL Account and Validate Income/Balance and Direct Posting.
        for i := 1 to ArrayLen(GLAccount) do begin
            LibraryERM.CreateGLAccount(GLAccount[i]);
            GLAccount[i].Validate("Income/Balance", GLAccount[i]."Income/Balance"::"Income Statement");
            GLAccount[i].Validate("Direct Posting", true);
            GLAccount[i].Modify(true);
        end;

        // [GIVEN] Validate Gen. Posting Type, VAT Bus. Posting Group and VAT Prod. Posting Group in GL Account "X".
        GLAccount[1].Validate(GLAccount[1]."Gen. Posting Type", GLAccount[1]."Gen. Posting Type"::Sale);
        GLAccount[1].Validate(GLAccount[1]."VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount[1].Validate(GLAccount[1]."VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount[1].Modify(true);

        // [GIVEN] Validate Consol. Credit Acc.,Consol. Debit Acc.,Reconciliation Account in GL Account "Y".
        GLAccount[2].Validate("Consol. Credit Acc.", GLAccount[1]."No.");
        GLAccount[2].Validate("Consol. Debit Acc.", GLAccount[1]."No.");
        GLAccount[2].Validate("Reconciliation Account", true);
        GLAccount[2].Modify(true);

        // [GIVEN] Validate Consol. Credit Acc.,Consol. Debit Acc. in GL Account "Z".
        GLAccount[3].Validate("Consol. Credit Acc.", GLAccount[2]."No.");
        GLAccount[3].Validate("Consol. Debit Acc.", GLAccount[2]."No.");
        GLAccount[3].Modify(true);

        // [GIVEN] Create and Store 3 Amounts.
        Amount[1] := LibraryRandom.RandDec(100, 2);
        Amount[2] := LibraryRandom.RandDec(200, 2);
        Amount[3] := Amount[1] + Amount[2] + Amount[2];

        // [GIVEN] Clear General Journal Line in a Batch.
        ClearGeneralJournalLines(GenJournalBatch);

        // [GIVEN] Create 4 General Journal Lines with different Amounts.
        CreateGeneralJournalLine(GenJournalLine[1], GenJournalBatch, GLAccount[1]."No.", Amount[1]);
        CreateGeneralJournalLine(GenJournalLine[2], GenJournalBatch, GLAccount[1]."No.", Amount[2]);
        CreateGeneralJournalLine(GenJournalLine[3], GenJournalBatch, GLAccount[2]."No.", -Amount[3]);
        CreateGeneralJournalLine(GenJournalLine[4], GenJournalBatch, GLAccount[3]."No.", Amount[2]);

        // [GIVEN] Create a No. Series Code and store it.
        DocumentNo := LibraryERM.CreateNoSeriesCode();
        LibraryVariableStorage.Enqueue(DocumentNo);

        // [GIVEN] Validate Document No. and Posting Date in all General Journal Lines.
        for i := 1 to ArrayLen(GenJournalLine) do begin
            GenJournalLine[i].Validate("Document No.", DocumentNo);
            GenJournalLine[i].Validate("Posting Date", Today());
            GenJournalLine[i].Modify(true);
        end;

        // [GIVEN] Post the General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);

        // [WHEN] Run VAT Reconciliation Report.
        Commit();
        Report.Run(Report::"VAT Reconciliation Report");

        // [THEN] Different Amount exists for same Document No. and posting Date.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('BaseAmountSalesVAT', -Amount[1]);
        LibraryReportDataset.AssertElementWithValueExists('BaseAmountSalesVAT', -Amount[2]);
    end;

    local procedure Initialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Financial Reports II");
        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);

        Clear(LibraryVariableStorage);
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        Clear(LibraryReportValidation);
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        if OriginalWorkdate = 0D then
            OriginalWorkdate := WorkDate();
        WorkDate := OriginalWorkdate;

        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
        end;
        if FeatureKeyUpdateStatus.Get('ReminderTermsCommunicationTexts', CompanyName()) then begin
            FeatureKeyUpdateStatus."Feature Status" := FeatureKeyUpdateStatus."Feature Status"::Disabled;
            FeatureKeyUpdateStatus.Modify();
        end;

        if IsInitialized then
            exit;

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Journal Templ. Name Mandatory" := false;
        GeneralLedgerSetup.Modify();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Financial Reports II");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Financial Reports II");
    end;

    local procedure CreateInvoiceGenJnlLineWithAmount(var GenJournalLine: Record "Gen. Journal Line"; JnlTemplName: Code[10]; JnlBatchName: Code[10]; DocumentNo: Code[20]; Amount: Decimal; PostingDate: Date)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, JnlTemplName, JnlBatchName, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateInvoiceGenJnlLineWithDocNoAndBalAccount(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), Amount);
        GenJournalLine.Validate("Document No.", DocNo);
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
    end;

    local procedure CalculateFinanceChargeMemoDate(DocumentNo: Code[20]; "Code": Code[10]) DocumentDate: Date
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        FinanceChargeTerms.Get(Code);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        DocumentDate := CalcDate('<1D>', CalcDate(FinanceChargeTerms."Due Date Calculation", CustLedgerEntry."Due Date"));
    end;

    local procedure ClearGeneralJournalLines(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure CreateAndPostBankAccountEntry(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Create and Post Bank Account Entry with a Random Amount.
        ClearGeneralJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"Bank Account", CreateBankAccount(), LibraryRandom.RandDec(1000, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", CreateBankAccount());
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Manual Check");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        ClearGeneralJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGenJournalLineWithCurrency(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20]; CurrencyCode: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        ClearGeneralJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGenJournalLineWithDate(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; CustomerNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        ClearGeneralJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGenJournalLineWithExtDocNo(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        ClearGeneralJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("External Document No.", CopyStr(LibraryUtility.GenerateRandomXMLText(35), 1, 35));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePaymentGenLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        ClearGeneralJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(1000, 2));
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        // Create Bank Account with Random Last Statement No.
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccountPostingGroup.FindFirst();
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Validate("Last Statement No.", Format(LibraryRandom.RandInt(10)));
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateBankAccountWithDimension(CurrencyCode: Code[10]): Code[20]
    var
        BankAccountNo: Code[20];
    begin
        BankAccountNo := CreateBankAccountWithCurrency(CurrencyCode);
        UpdateBankAccountDimension(BankAccountNo);
        exit(BankAccountNo);
    end;

    local procedure CreateBankAccountWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateBankRecon(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20])
    begin
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo,
          BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Statement Date", WorkDate());
        BankAccReconciliation.Modify(true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
    begin
        ReminderLevel.SetFilter("Additional Fee (LCY)", '<>%1', 0);
        ReminderLevel.FindFirst();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", ReminderLevel."Reminder Terms Code");
        Customer.Validate("Fin. Charge Terms Code", CreateFinanceChargeTerms());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(VATProdPostingGrp: Code[20]): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGrp);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateReminderTerm(var ReminderTerms: Record "Reminder Terms")
    var
        ReminderLevel: Record "Reminder Level";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTerms.Code);
        ReminderLevel.Validate("Calculate Interest", true);
        ReminderLevel.Modify(true);
    end;

    local procedure CreateCustomerWithReminderSetup(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
    begin
        CreateReminderTerm(ReminderTerms);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", ReminderTerms.Code);
        Customer.Validate("Fin. Charge Terms Code", CreateFinanceChargeTerms());
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCurrencyWithMultipleExchangeRates(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        CreateAndUpdateCurrencyExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateAndPostSalesDocument(VATCalculationType: Enum "Tax Calculation Type"): Code[20]
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATCalculationType);
        LibrarySales.CreateSalesHeader(
            SalesHeader, SalesHeader."Document Type"::Invoice,
            CreateCustomerWithReminderSetup(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCustomerWithDimension(var DimensionValue: Record "Dimension Value"): Code[20]
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, CreateCustomer(), DimensionValue."Dimension Code", DimensionValue.Code);
        exit(DefaultDimension."No.");
    end;

    local procedure CreateCustomerWithCurrencyCode(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateFinanceChargeTerms(): Code[10]
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        // Create Finance Charge Term with Random Interest Rate, Minimum Amount, Additional Amount, Grace Period, Interest Period and
        // Due Date Calculation.
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Rate", LibraryRandom.RandDec(10, 2));
        FinanceChargeTerms.Validate("Additional Fee (LCY)", LibraryRandom.RandDec(1000, 2));
        FinanceChargeTerms.Validate("Interest Period (Days)", LibraryRandom.RandInt(30));
        Evaluate(FinanceChargeTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(20)) + 'D>');
        FinanceChargeTerms.Validate("Post Additional Fee", true);
        FinanceChargeTerms.Validate("Post Interest", true);
        FinanceChargeTerms.Modify(true);
        exit(FinanceChargeTerms.Code);
    end;

    local procedure CreateReminderWithGivenDocNo(DocumentNo: Code[20]; CustomerNo: Code[20]): Code[20]
    var
        ReminderLevel: Record "Reminder Level";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        FindReminderLevel(ReminderLevel, Customer."Reminder Terms Code");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);

        // Calculate Document Date according to Reminder Level's Grace Period and add One day.
        exit(
          CreateReminder(
            CustomerNo, CalcDate('<1D>', CalcDate(ReminderLevel."Grace Period", CustLedgerEntry."Due Date"))));
    end;

    local procedure CreateReminderWithGivenCust(CustomerNo: Code[20]): Code[20]
    var
        ReminderLevel: Record "Reminder Level";
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        FindReminderLevel(ReminderLevel, Customer."Reminder Terms Code");

        // Calculate Document Date according to Reminder Level's Grace Period and add One day.
        exit(
          CreateReminder(
            CustomerNo, CalcDate('<1D>', CalcDate(ReminderLevel."Grace Period", WorkDate()))));
    end;

    local procedure CreateReminderWithInterestAmount(var ReminderHeader: Record "Reminder Header"; VATCalculationType: Enum "Tax Calculation Type")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        ReminderNo: Code[20];
    begin
        SalesInvHeader.Get(CreateAndPostSalesDocument(VATCalculationType));
        ReminderNo := CreateReminderWithGivenDocNo(SalesInvHeader."No.", SalesInvHeader."Sell-to Customer No.");
        ReminderHeader.Get(ReminderNo);
        ReminderHeader.CalcFields("Interest Amount");
    end;

    local procedure CreateReminder(CustomerNo: Code[20]; DocumentDate: Date): Code[20]
    var
        ReminderHeader: Record "Reminder Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry";
        ReminderMake: Codeunit "Reminder-Make";
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Validate("Posting Date", DocumentDate);
        ReminderHeader.Validate("Document Date", DocumentDate);
        ReminderHeader.Modify(true);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        ReminderMake.SuggestLines(ReminderHeader, CustLedgerEntry, false, false, CustLedgEntryLineFeeOn);
        ReminderMake.Code();
        exit(ReminderHeader."No.");
    end;

    local procedure CreateIssuedReminderWithInterestAmount(var IssuedReminderHeader: Record "Issued Reminder Header"; VATCalculationType: Enum "Tax Calculation Type")
    var
        ReminderHeader: Record "Reminder Header";
        IssuedReminderNo: Code[20];
    begin
        CreateReminderWithInterestAmount(ReminderHeader, VATCalculationType);
        IssuedReminderNo := IssueReminderAndGetIssuedNo(ReminderHeader."No.");
        IssuedReminderHeader.Get(IssuedReminderNo);
        IssuedReminderHeader.CalcFields("Interest Amount");
    end;

    local procedure CreateIssuedFinChargeMemo(CustomerPostingGroupCode: Code[20]): Code[20]
    var
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        IssuedFinChargeMemoHeader."No." := LibraryUTUtility.GetNewCode();
        IssuedFinChargeMemoHeader."Customer Posting Group" := CustomerPostingGroupCode;
        IssuedFinChargeMemoHeader.Insert();

        IssuedFinChargeMemoLine."Finance Charge Memo No." := IssuedFinChargeMemoHeader."No.";
        IssuedFinChargeMemoLine."Line No." := LibraryRandom.RandInt(10);
        IssuedFinChargeMemoLine.Insert();
        exit(IssuedFinChargeMemoHeader."No.")
    end;

    local procedure CreateCustPostingGroupWithoutAddFeeAcc(): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup.Validate("Additional Fee Account", '');
        CustomerPostingGroup.Modify(true);
        exit(CustomerPostingGroup.Code);
    end;

    local procedure CreateBankAccReconciliation(BankAccountNo: Code[20]): Code[20]
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        // Create Bank Account Reconciliation and Suggest Line. Update Statement Ending Balance with Zero to generate Warning.
        CreateBankRecon(BankAccReconciliation, BankAccountNo);
        SuggestBankReconLines(BankAccReconciliation);
        BankAccReconciliation.Validate("Statement Ending Balance", 0);
        BankAccReconciliation.Modify(true);
        exit(BankAccReconciliation."Statement No.");
    end;

    local procedure CreateSuggestFinanceChargeMemo(CustomerNo: Code[20]; DocumentNo: Code[20]): Code[20]
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        DocumentDate: Date;
    begin
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, CustomerNo);
        DocumentDate := CalculateFinanceChargeMemoDate(DocumentNo, FinanceChargeMemoHeader."Fin. Charge Terms Code");
        FinanceChargeMemoHeader.Validate("Posting Date", DocumentDate);
        FinanceChargeMemoHeader.Validate("Document Date", DocumentDate);
        FinanceChargeMemoHeader.Modify(true);
        SuggestFinanceChargeMemoLines(FinanceChargeMemoHeader);
        exit(FinanceChargeMemoHeader."No.");
    end;

    local procedure CreateAndUpdateCurrencyExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(10, 2));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", LibraryRandom.RandDec(10, 2));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Adjustment Exch. Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Adjustment Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateGenJnlBatchesWithLines(var GenJnlTemplateName: Code[10]; var FirstGenJnlBatchName: Code[10]; var SecondGenJnlBatchName: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandInt(1000));
        GenJnlTemplateName := GenJournalLine."Journal Template Name";
        FirstGenJnlBatchName := GenJournalLine."Journal Batch Name";
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJnlTemplateName);
        SecondGenJnlBatchName := GenJournalBatch.Name;
        LibraryJournals.CreateGenJournalLine2(GenJournalLine, GenJnlTemplateName, GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          GenJournalLine."Bal. Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo(), LibraryRandom.RandInt(1000));
    end;

    local procedure CreateGeneralJournalWithThreeLines(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNoA: Code[20]; AccountNoB: Code[20]; GLAccountNo: Code[20]; AmountSign: Integer)
    var
        LineAmount: Decimal;
    begin
        LineAmount := AmountSign * LibraryRandom.RandIntInRange(10, 20);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ", AccountType, AccountNoA, LineAmount);

        GenJournalLine.Validate("Bal. Account No.", '');
        GenJournalLine.Modify(true);

        GenJournalLine."Line No." := LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No."));
        GenJournalLine.Validate("Account No.", AccountNoB);
        GenJournalLine.Insert(true);

        GenJournalLine."Line No." := LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No."));
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", GLAccountNo);
        GenJournalLine.Validate(Amount, -LineAmount * 2);
        GenJournalLine.Insert(true);
    end;

    local procedure DisableInvoiceRoundingForCurrency(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        Currency."Invoice Rounding Precision" := 0; // skip validation
        Currency.Modify();
    end;

    local procedure AddReminderLineWithGLType(var ReminderLine: Record "Reminder Line"; ReminderNo: Code[20]; No: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateReminderLine(ReminderLine, ReminderNo, ReminderLine.Type::"G/L Account");
        ReminderLine.Validate("No.", No);
        ReminderLine.Validate(Amount, Amount);
        ReminderLine.Modify(true);
    end;

    local procedure AddFinanceChargeMemoLineWithGLType(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; FinanceChargeMemoNo: Code[20]; No: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateFinanceChargeMemoLine(FinanceChargeMemoLine, FinanceChargeMemoNo, FinanceChargeMemoLine.Type::"G/L Account");
        FinanceChargeMemoLine.Validate("No.", No);
        FinanceChargeMemoLine.Validate(Amount, Amount);
        FinanceChargeMemoLine.Modify(true);
    end;

    local procedure FindAndUpdateGLAccountWithVAT(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        LibraryERM.FindGLAccount(GLAccount);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure FindFinChargeMemoLine(var IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line"; FinanceChargeMemoNo: Code[20]; Type: Option): Decimal
    begin
        IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoNo);
        IssuedFinChargeMemoLine.SetRange(Type, Type);
        IssuedFinChargeMemoLine.FindFirst();
        exit(IssuedFinChargeMemoLine.Amount);
    end;

    local procedure FindIssuedReminderLine(var IssuedReminderLine: Record "Issued Reminder Line"; ReminderNo: Code[20]; ReminderType: Enum "Reminder Line Type")
    begin
        IssuedReminderLine.SetRange("Reminder No.", ReminderNo);
        IssuedReminderLine.SetRange(Type, ReminderType);
        IssuedReminderLine.FindSet();
    end;

    local procedure FindIssuedFinChargeMemoLine(var IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line"; FinChargeMemoNo: Code[20])
    begin
        IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", FinChargeMemoNo);
        IssuedFinChargeMemoLine.FindSet();
    end;

    local procedure FindGLAccount(var GLAccount: Record "G/L Account"; No: Code[20]; DateFilter: Date; DateFilter2: Date)
    begin
        GLAccount.SetRange("No.", No);
        GLAccount.SetRange("Date Filter", DateFilter, DateFilter2);
        GLAccount.FindFirst();
    end;

    local procedure FindReminderLevel(var ReminderLevel: Record "Reminder Level"; ReminderTermsCode: Code[10])
    begin
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTermsCode);
        ReminderLevel.FindFirst();
    end;

    local procedure SumAmountOnIssuedReminderFeeLineWithVAT(ReminderNo: Code[20]; ReminderType: Enum "Reminder Source Type"; VAT: Decimal; var TotalAmount: Decimal; var TotalVATAmount: Decimal)
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        IssuedReminderLine.SetRange("VAT %", VAT);
        FindIssuedReminderLine(IssuedReminderLine, ReminderNo, ReminderType);
        IssuedReminderLine.CalcSums(Amount);
        IssuedReminderLine.CalcSums("VAT Amount");
        TotalAmount := IssuedReminderLine.Amount;
        TotalVATAmount := IssuedReminderLine."VAT Amount";
    end;

    local procedure SumAmountOnIssuedFinChargeMemoLineWithVAT(FinanceChargeMemoNo: Code[20]; VAT: Decimal; var TotalAmount: Decimal; var TotalVATAmount: Decimal)
    var
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
    begin
        IssuedFinChargeMemoLine.SetRange("VAT %", VAT);
        FindIssuedFinChargeMemoLine(IssuedFinChargeMemoLine, FinanceChargeMemoNo);
        IssuedFinChargeMemoLine.CalcSums(Amount);
        IssuedFinChargeMemoLine.CalcSums("VAT Amount");
        TotalAmount := IssuedFinChargeMemoLine.Amount;
        TotalVATAmount := IssuedFinChargeMemoLine."VAT Amount";
    end;

    local procedure GetFinanceChargeMemoLine(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; FinanceChargeMemoNo: Code[20]; Type: Option)
    begin
        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoNo);
        FinanceChargeMemoLine.SetRange(Type, Type);
        FinanceChargeMemoLine.FindFirst();
    end;

    local procedure GetCustAddFeeAmount(CustomerNo: Code[20]): Decimal
    var
        ReminderLevel: Record "Reminder Level";
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        ReminderLevel.SetRange("Reminder Terms Code", Customer."Reminder Terms Code");
        ReminderLevel.FindFirst();
        exit(ReminderLevel."Additional Fee (LCY)");
    end;

    local procedure GetRemitPaymentsMsg(IssuedReminderNo: Code[20]; Amount: Decimal): Text
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderText: Record "Reminder Text";
        Text: Text;
    begin
        IssuedReminderHeader.Get(IssuedReminderNo);
        ReminderText.SetRange("Reminder Terms Code", IssuedReminderHeader."Reminder Terms Code");
        ReminderText.SetRange("Reminder Level", 1);
        ReminderText.SetRange(Position, 1);
        ReminderText.FindFirst();
        // Replace '%7' with '%1'
        Text := ConvertStr(ReminderText.Text, '7', '1');
        exit(StrSubstNo(Text, Amount));
    end;

    local procedure IssueAndGetFinChargeMemoNo(No: Code[20]) IssuedDocNo: Code[20]
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        NoSeries: Codeunit "No. Series";
    begin
        FinanceChargeMemoHeader.Get(No);
        IssuedDocNo := NoSeries.PeekNextNo(FinanceChargeMemoHeader."Issuing No. Series");
        IssueFinChargeMemo(FinanceChargeMemoHeader);
    end;

    local procedure IssueFinChargeMemo(FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        FinChrgMemoIssue: Codeunit "FinChrgMemo-Issue";
    begin
        FinChrgMemoIssue.Set(FinanceChargeMemoHeader, false, FinanceChargeMemoHeader."Document Date");
        LibraryERM.RunFinChrgMemoIssue(FinChrgMemoIssue);
    end;

    local procedure IssueReminder(ReminderHeader: Record "Reminder Header")
    var
        ReminderIssue: Codeunit "Reminder-Issue";
    begin
        ReminderIssue.Set(ReminderHeader, false, ReminderHeader."Document Date");
        LibraryERM.RunReminderIssue(ReminderIssue);
    end;

    local procedure IssueReminderAndGetIssuedNo(ReminderNo: Code[20]) IssuedReminderNo: Code[20]
    var
        ReminderHeader: Record "Reminder Header";
        NoSeries: Codeunit "No. Series";
    begin
        ReminderHeader.Get(ReminderNo);
        IssuedReminderNo := NoSeries.PeekNextNo(ReminderHeader."Issuing No. Series");
        IssueReminder(ReminderHeader);
    end;

    local procedure MockCheckLedgerEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountNo: Code[20]; EntryAmount: Decimal; EntryStatus: Option)
    var
        CheckLedgerEntry2: Record "Check Ledger Entry";
        NextCheckEntryNo: Integer;
    begin
        CheckLedgerEntry2.Reset();
        if CheckLedgerEntry2.FindLast() then
            NextCheckEntryNo := CheckLedgerEntry2."Entry No." + 1
        else
            NextCheckEntryNo := 1;

        CheckLedgerEntry.Init();
        CheckLedgerEntry."Entry No." := NextCheckEntryNo;
        CheckLedgerEntry."Bank Account No." := BankAccountNo;
        CheckLedgerEntry.Amount := EntryAmount;
        CheckLedgerEntry."Entry Status" := EntryStatus;
        CheckLedgerEntry.Insert(true);
    end;

    local procedure MockIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        IssuedReminderHeader.Init();
        IssuedReminderHeader."No." :=
          LibraryUtility.GenerateRandomCode(IssuedReminderHeader.FieldNo("No."), DATABASE::"Issued Reminder Header");
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup."Additional Fee Account" := '';
        CustomerPostingGroup.Modify();
        IssuedReminderHeader."Customer Posting Group" := CustomerPostingGroup.Code;
        IssuedReminderHeader."Due Date" := LibraryRandom.RandDate(LibraryRandom.RandIntInRange(10, 100));
        IssuedReminderHeader.Insert();
    end;

    local procedure MockIssuedReminderLine(var IssuedReminderLine: Record "Issued Reminder Line"; IssuedReminderHeader: Record "Issued Reminder Header"; IssuedReminderLineType: Enum "Reminder Line Type"; RemainingAmount: Decimal; LineAmount: Decimal)
    begin
        IssuedReminderLine.Init();
        IssuedReminderLine."Reminder No." := IssuedReminderHeader."No.";
        IssuedReminderLine."Line No." := LibraryUtility.GetNewRecNo(IssuedReminderLine, IssuedReminderLine.FieldNo("Line No."));
        IssuedReminderLine."Line Type" := IssuedReminderLine."Line Type"::"Reminder Line";
        IssuedReminderLine."Due Date" := IssuedReminderHeader."Due Date";
        IssuedReminderLine."Remaining Amount" := RemainingAmount;
        IssuedReminderLine.Amount := LineAmount;
        IssuedReminderLine.Type := IssuedReminderLineType;
        IssuedReminderLine.Insert();
    end;

    local procedure OpenReminderStatisticsPage(var ReminderStatisticsPage: TestPage "Reminder Statistics"; ReminderHeaderNo: Code[20])
    var
        ReminderPage: TestPage Reminder;
    begin
        ReminderPage.OpenEdit();
        ReminderPage.FILTER.SetFilter("No.", ReminderHeaderNo);
        ReminderStatisticsPage.Trap();
        ReminderPage.Statistics.Invoke();
    end;

    local procedure OpenIssuedReminderStatisticsPage(var IssuedReminderStatistics: TestPage "Issued Reminder Statistics"; IssuedReminderNo: Code[20])
    var
        IssuedReminder: TestPage "Issued Reminder";
    begin
        IssuedReminder.OpenEdit();
        IssuedReminder.FILTER.SetFilter("No.", IssuedReminderNo);
        IssuedReminderStatistics.Trap();
        IssuedReminder.Statistics.Invoke();
    end;

    local procedure CreateAndIssueReminderWithCurrencyAndVATFee(): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
    begin
        // Create General Journal Line with Currency Code.
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomerWithCurrencyCode(), LibraryRandom.RandDec(1000, 2)); // Using Random value for Amount.
        DisableInvoiceRoundingForCurrency(GenJournalLine."Currency Code");

        // Create Reminder, add a line for the reminder with fee include VAT. Issued the Reminder.
        ReminderNo := CreateReminderWithGivenDocNo(GenJournalLine."Document No.", GenJournalLine."Account No.");
        AddReminderLineWithGLType(ReminderLine, ReminderNo, FindAndUpdateGLAccountWithVAT(), LibraryRandom.RandDec(100, 2));
        exit(IssueReminderAndGetIssuedNo(ReminderNo));
    end;

    local procedure CreateAndIssueFinChargeMemoWithCurrencyAndVATFee(): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeMemoNo: Code[20];
    begin
        // Create General Journal Line with Currency Code.
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomerWithCurrencyCode(), LibraryRandom.RandDec(1000, 2)); // Using Random value for Amount.
        DisableInvoiceRoundingForCurrency(GenJournalLine."Currency Code");

        // Create Finance Charge Memo, add a line for the Finance Charge Memo with fee include VAT. Issued the Finance Charge Memo.
        FinanceChargeMemoNo := CreateSuggestFinanceChargeMemo(GenJournalLine."Account No.", GenJournalLine."Document No.");
        AddFinanceChargeMemoLineWithGLType(
          FinanceChargeMemoLine, FinanceChargeMemoNo, FindAndUpdateGLAccountWithVAT(), LibraryRandom.RandDec(100, 2));
        exit(IssueAndGetFinChargeMemoNo(FinanceChargeMemoNo));
    end;

    local procedure PostGenLinesCustomPostingDate(var GenJournalLine: Record "Gen. Journal Line")
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        ClearGeneralJournalLines(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate(Indentation, LibraryRandom.RandInt(5));  // Set Random for Indendation.
        GLAccount.Modify(true);

        // Taking 1000 for multiplication with Dividing Rounding Factor.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(1000, 2) * 1000);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(1000, 2) * 1000);
        GenJournalLine.Validate("Posting Date", CalcDate('<-1Y>', WorkDate()));  // Take Previous Year Date.
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure SuggestBankReconLines(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccount: Record "Bank Account";
        SuggestBankAccReconLines: Report "Suggest Bank Acc. Recon. Lines";
    begin
        SuggestBankAccReconLines.SetStmt(BankAccReconciliation);
        BankAccount.SetRange("No.", BankAccReconciliation."Bank Account No.");
        SuggestBankAccReconLines.SetTableView(BankAccount);
        SuggestBankAccReconLines.InitializeRequest(WorkDate(), WorkDate(), true);  // Set TRUE for Include Checks Option.
        SuggestBankAccReconLines.UseRequestPage(false);
        SuggestBankAccReconLines.Run();
    end;

    local procedure SuggestFinanceChargeMemoLines(FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        SuggestFinChargeMemoLines: Report "Suggest Fin. Charge Memo Lines";
    begin
        FinanceChargeMemoHeader.SetRange("No.", FinanceChargeMemoHeader."No.");
        SuggestFinChargeMemoLines.SetTableView(FinanceChargeMemoHeader);
        SuggestFinChargeMemoLines.UseRequestPage(false);
        SuggestFinChargeMemoLines.Run();
    end;

    local procedure UpdateBankAccountDimension(BankAccountNo: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Bank Account", BankAccountNo, Dimension.Code, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);
    end;

    local procedure UpdateCustomerPostingGroup(No: Code[20]; NewAddFeeAccountNo: Code[20]) SavedAddFeeAccountNo: Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(No);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        SavedAddFeeAccountNo := CustomerPostingGroup."Additional Fee Account";
        CustomerPostingGroup.Validate("Additional Fee Account", NewAddFeeAccountNo);
        CustomerPostingGroup.Modify(true);
    end;

    local procedure UpdateVATSpecInLCYGeneralLedgerSetup(VATSpecificationInLCY: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Print VAT specification in LCY", VATSpecificationInLCY);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyTrialBalancePreviousYearReportWithBlankLines(NoOfBlankLines: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        ActualRowQty: Integer;
    begin
        Initialize();
        WorkDate := CalcDate('<+1Y>', WorkDate());
        PostGenLinesCustomPostingDate(GenJournalLine);

        GLAccount.Get(GenJournalLine."Account No.");
        GLAccount."No. of Blank Lines" := NoOfBlankLines;
        GLAccount.Modify();

        RunReportTrialBalancePreviousYear(GenJournalLine."Account No.", WorkDate());

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_GLAccount', GenJournalLine."Account No.");
        ActualRowQty := 0;
        while LibraryReportDataset.GetNextRow() do
            ActualRowQty += 1;

        Assert.AreEqual(NoOfBlankLines, ActualRowQty - 1, BlankLinesQtyErr);
    end;

    local procedure VerifyBankAccountCheckDetails(GenJournalLine: Record "Gen. Journal Line")
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.SetRange('Check_Ledger_Entry__Check_Date_', Format(WorkDate()));
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Check_Ledger_Entry__Check_Date_', Format(WorkDate()));

        LibraryReportDataset.AssertCurrentRowValueEquals('Check_Ledger_Entry__Bal__Account_No__', GenJournalLine."Account No.");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Check_Ledger_Entry__Entry_Status_', Format(CheckLedgerEntry."Entry Status"::Posted));
        LibraryReportDataset.AssertCurrentRowValueEquals('Check_Ledger_Entry_Amount', GenJournalLine.Amount);
    end;

    local procedure VerifyBankAccReconTest(GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryReportDataset.LoadDataSetFile();

        // Verify Header
        LibraryReportDataset.AssertElementWithValueExists('HeaderError1', Format(WarningMsg));

        // Verify Lines
        LibraryReportDataset.SetRange('Bank_Acc__Reconciliation_Line__Transaction_Date_', Format(WorkDate()));
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Bank_Acc__Reconciliation_Line__Transaction_Date_', Format(WorkDate()));
        LibraryReportDataset.AssertCurrentRowValueEquals('Bank_Acc__Reconciliation_Line__Applied_Amount_', -GenJournalLine.Amount);

        // Verify Totals
        LibraryReportDataset.Reset();
        Assert.AreEqual(-GenJournalLine.Amount, LibraryReportDataset.Sum('Bank_Acc__Reconciliation_Line__Applied_Amount_'),
          StrSubstNo(ValidationErr, GenJournalLine.FieldCaption(Amount), -GenJournalLine.Amount));
        Assert.AreEqual(-GenJournalLine.Amount, LibraryReportDataset.Sum('Bank_Acc__Reconciliation_Line__Statement_Amount_'),
          StrSubstNo(ValidationErr, GenJournalLine.FieldCaption(Amount), -GenJournalLine.Amount));
    end;

    local procedure VerifyBankLedgerEntryExist(BankAccountNo: Code[20])
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        BankAccLedgEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccLedgEntry.SetRange("Document No.", DocumentNo);
        Assert.IsFalse(BankAccLedgEntry.IsEmpty, AdjustExchangeErr);
    end;

    local procedure VerifyDimensionsOnReport(DimensionValue: Record "Dimension Value")
    var
        ExpectedValue: Text;
    begin
        LibraryReportDataset.LoadDataSetFile();
        ExpectedValue := StrSubstNo(HeaderDimensionTxt, DimensionValue."Dimension Code", DimensionValue.Code);
        LibraryReportDataset.AssertElementWithValueExists('DimText', ExpectedValue);
    end;

    local procedure VerifyGeneralJournalTest(GenJournalLine: Record "Gen. Journal Line")
    begin
        // Verify Saved Report's Data.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('PostingDate_GenJnlLine', Format(GenJournalLine."Posting Date"));
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'PostingDate_GenJnlLine', Format(GenJournalLine."Posting Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('DocType_GenJnlLine', Format(GenJournalLine."Document Type"));
        LibraryReportDataset.AssertCurrentRowValueEquals('DocNo_GenJnlLine', GenJournalLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('AccountType_GenJnlLine', Format(GenJournalLine."Account Type"));
        LibraryReportDataset.AssertCurrentRowValueEquals('AccountNo_GenJnlLine', GenJournalLine."Account No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('AccName', GenJournalLine.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals('Description_GenJnlLine', GenJournalLine.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals('GenPostType_GenJnlLine', Format(GenJournalLine."Gen. Posting Type"));
        LibraryReportDataset.AssertCurrentRowValueEquals('GenBusPosGroup_GenJnlLine', GenJournalLine."Gen. Bus. Posting Group");
        LibraryReportDataset.AssertCurrentRowValueEquals('GenProdPostGroup_GenJnlLine', GenJournalLine."Gen. Prod. Posting Group");
        LibraryReportDataset.AssertCurrentRowValueEquals('BalAccNo_GenJnlLine', GenJournalLine."Bal. Account No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount_GenJnlLine', GenJournalLine.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('BalanceLCY_GenJnlLine', GenJournalLine."Balance (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('AmountLCY', GenJournalLine.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('BalanceLCY', GenJournalLine."Balance (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('JnlTmplName_GenJnlLine', GenJournalLine."Journal Template Name");
        LibraryReportDataset.AssertElementWithValueExists('JnlBatchName_GenJnlLine', GenJournalLine."Journal Batch Name");
    end;

    local procedure VerifyFinanceChargeMemo(No: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        AddnlFeeAmount: Decimal;
        LineAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        LineAmount := FindFinChargeMemoLine(IssuedFinChargeMemoLine, No, IssuedFinChargeMemoLine.Type::"Customer Ledger Entry");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocDt_IssuFinChrgMemoLine', Format(IssuedFinChargeMemoLine."Document Date"));
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'DocDt_IssuFinChrgMemoLine', Format(IssuedFinChargeMemoLine."Document Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('DocNo_IssuFinChrgMemoLine', IssuedFinChargeMemoLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt_IssuFinChrgMemoLine', IssuedFinChargeMemoLine.Amount);
        AddnlFeeAmount := FindFinChargeMemoLine(IssuedFinChargeMemoLine, No, IssuedFinChargeMemoLine.Type::"G/L Account");
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('Desc_IssuFinChrgMemoLine', AddnlFeeLabelTxt);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Desc_IssuFinChrgMemoLine', AddnlFeeLabelTxt);
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt_IssuFinChrgMemoLine', IssuedFinChargeMemoLine.Amount);
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('TotalText', StrSubstNo(TotalTxt, GeneralLedgerSetup."LCY Code"));
        while LibraryReportDataset.GetNextRow() do;
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmount', LineAmount + AddnlFeeAmount);
    end;

    local procedure VerifyFinanceChargeMemoTest(GenJournalLine: Record "Gen. Journal Line"; No: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        Variant: Variant;
        LineAmount: Decimal;
        AddnlFeeAmount: Decimal;
        TotalAmt: Decimal;
    begin
        GeneralLedgerSetup.Get();
        GetFinanceChargeMemoLine(FinanceChargeMemoLine, No, FinanceChargeMemoLine.Type::"Customer Ledger Entry");
        LineAmount := FinanceChargeMemoLine.Amount;
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Finance_Charge_Memo_Line__Document_Type_', Format(GenJournalLine."Document Type"));
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Finance_Charge_Memo_Line__Document_Type_', Format(GenJournalLine."Document Type"));
        LibraryReportDataset.AssertCurrentRowValueEquals('Finance_Charge_Memo_Line__Original_Amount_',
          FinanceChargeMemoLine."Original Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('Finance_Charge_Memo_Line__Remaining_Amount_',
          FinanceChargeMemoLine."Remaining Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('Finance_Charge_Memo_Line_Amount', FinanceChargeMemoLine.Amount);
        GetFinanceChargeMemoLine(FinanceChargeMemoLine, No, FinanceChargeMemoLine.Type::"G/L Account");
        AddnlFeeAmount := FinanceChargeMemoLine.Amount;
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('Finance_Charge_Memo_Line_Description', AddnlFeeLabelTxt);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Finance_Charge_Memo_Line_Description', AddnlFeeLabelTxt);
        LibraryReportDataset.AssertCurrentRowValueEquals('Finance_Charge_Memo_Line_Amount', FinanceChargeMemoLine.Amount);
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('TotalText', StrSubstNo(TotalTxt, GeneralLedgerSetup."LCY Code"));
        LibraryReportDataset.SetRange('Finance_Charge_Memo_Line_Description', AddnlFeeLabelTxt);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'TotalText', StrSubstNo(TotalTxt, GeneralLedgerSetup."LCY Code"));
        LibraryReportDataset.GetElementValueInCurrentRow('TotalAmount', Variant);
        TotalAmt := Variant;
        if TotalAmt <> 0 then
            LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmount', LineAmount + AddnlFeeAmount);
    end;

    local procedure VerifyFinChrgMemoTestVATEntry(FinanceChargeMemoNo: Code[20])
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        // Use Precision to take Decimal Value upto 2 Decimal Places.
        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoNo);
        FinanceChargeMemoLine.SetFilter("VAT %", '>0');
        FinanceChargeMemoLine.FindSet();
        LibraryReportDataset.LoadDataSetFile();

        repeat
            LibraryReportDataset.SetRange('VATAmountLine__VAT_Base_', FinanceChargeMemoLine.Amount);
            if LibraryReportDataset.GetNextRow() then begin
                LibraryReportDataset.AssertCurrentRowValueEquals('VATAmountLine__VAT___', FinanceChargeMemoLine."VAT %");
                LibraryReportDataset.AssertCurrentRowValueEquals(
                  'VATAmountLine__Amount_Including_VAT_',
                  FinanceChargeMemoLine.Amount + FinanceChargeMemoLine."VAT Amount");
            end;
        until FinanceChargeMemoLine.Next() = 0;
    end;

    local procedure VerifyFinChrgMemoVATEntry(FinanceChargeMemoNo: Code[20])
    var
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        Amount: Variant;
        AmountIncludingVAT: Variant;
    begin
        // Use Precision to take Decimal Value upto 2 Decimal Places.
        IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoNo);
        IssuedFinChargeMemoLine.SetFilter("VAT %", '>0');
        IssuedFinChargeMemoLine.FindSet();
        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.Reset();
        repeat
            LibraryReportDataset.SetRange('VATAmtSpecCaption', VATAmtSpecLabelTxt);
            LibraryReportDataset.SetRange('VatAmtLineVAT', Format(IssuedFinChargeMemoLine."VAT %"));
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFoundErr, 'VatAmtLineVAT', Format(IssuedFinChargeMemoLine."VAT %"));
            LibraryReportDataset.FindCurrentRowValue('VALVATBase', Amount);
            Assert.AreNearlyEqual(
              IssuedFinChargeMemoLine.Amount,
              Amount, LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(ValidationErr, VATBaseLabelTxt, IssuedFinChargeMemoLine.Amount));
            LibraryReportDataset.FindCurrentRowValue('ValVatBaseValVatAmt', AmountIncludingVAT);
            Assert.AreNearlyEqual(
              IssuedFinChargeMemoLine.Amount + IssuedFinChargeMemoLine."VAT Amount", AmountIncludingVAT,
              LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(ValidationErr, AmtInclVATLabelTxt, IssuedFinChargeMemoLine.Amount + IssuedFinChargeMemoLine."VAT Amount"));
        until IssuedFinChargeMemoLine.Next() = 0;
    end;

    local procedure VerifyInteractionLogEntry(DocumentType: Enum "Interaction Log Entry Document Type"; DocumentNo: Code[20])
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.SetRange("Document Type", DocumentType);
        InteractionLogEntry.SetRange("Document No.", DocumentNo);
        InteractionLogEntry.FindFirst();
    end;

    local procedure VerifyReminderTest(GenJournalLine: Record "Gen. Journal Line"; No: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        ReminderLevel: Record "Reminder Level";
    begin
        LibraryReportDataset.LoadDataSetFile();

        ReminderHeader.Get(No);
        ReminderHeader.CalcFields("Remaining Amount");
        ReminderHeader.CalcFields("Interest Amount");
        CustomerPostingGroup.Get(ReminderHeader."Customer Posting Group");

        LibraryReportDataset.SetRange('Reminder_Line__Document_Type_', Format(ReminderLine."Document Type"::Invoice));
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Reminder_Line__Document_Type_', Format(ReminderLine."Document Type"::Invoice));
        LibraryReportDataset.AssertCurrentRowValueEquals('Reminder_Line__Document_No__', GenJournalLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Reminder_Line__Original_Amount_', GenJournalLine.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('Reminder_Line__Remaining_Amount_', ReminderHeader."Remaining Amount");

        FindReminderLevel(ReminderLevel, ReminderHeader."Reminder Terms Code");
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('Reminder_Line__No__', CustomerPostingGroup."Additional Fee Account");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Reminder_Line__No__', CustomerPostingGroup."Additional Fee Account");
        LibraryReportDataset.AssertCurrentRowValueEquals('Remaining_Amount____ReminderInterestAmount____VAT_Amount_',
          ReminderLevel."Additional Fee (LCY)")
    end;

    local procedure VerifyInterestOnReminderReport(InterestAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Interest', InterestAmount);
    end;

    local procedure VerifyReminderTestVATEntry(ReminderNo: Code[20])
    var
        ReminderLine: Record "Reminder Line";
    begin
        // Use Precision Value with FORMAT to generate output with two Decimal Places.
        LibraryReportDataset.LoadDataSetFile();

        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetFilter("VAT %", '>0');
        ReminderLine.FindSet();
        repeat
            LibraryReportDataset.SetRange('VATAmountLine__VAT___', ReminderLine."VAT %");
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFoundErr, 'VATAmountLine__VAT___', ReminderLine."VAT %");
            LibraryReportDataset.AssertCurrentRowValueEquals('VATAmountLine__VAT_Base_', ReminderLine.Amount);
            LibraryReportDataset.AssertCurrentRowValueEquals('VATAmountLine__Amount_Including_VAT_',
              ReminderLine.Amount + ReminderLine."VAT Amount");
        until ReminderLine.Next() = 0;
    end;

    local procedure VerifyReminderReport(No: Code[20])
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        IssuedReminderLine.SetRange("Reminder No.", No);
        IssuedReminderLine.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocDate_IssuedReminderLine', Format(IssuedReminderLine."Document Date"));
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'DocDate_IssuedReminderLine', Format(IssuedReminderLine."Document Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('DocNo_IssuedReminderLine', IssuedReminderLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt_IssuedReminderLine', IssuedReminderLine."Original Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('RemAmt_IssuedReminderLine', IssuedReminderLine."Remaining Amount");
    end;

    local procedure VerifyInterestAmountOnReminderTestReport(VATCalculationType: Enum "Tax Calculation Type")
    var
        ReminderHeader: Record "Reminder Header";
    begin
        // Verify interest amount on Reminder Test Report.

        // Setup: Create Reminder.
        Initialize();
        CreateReminderWithInterestAmount(ReminderHeader, VATCalculationType);
        LibraryVariableStorage.Enqueue(ReminderHeader."No.");
        LibraryVariableStorage.Enqueue(false);

        // Excercise: Run Reminder Test Report.
        Commit();
        REPORT.Run(REPORT::"Reminder - Test");

        // Verify: Verifying interest amount on Reminder Test Report.
        VerifyInterestOnReminderReport(ReminderHeader."Interest Amount");
    end;

    local procedure VerifyInterestAmountOnReminderReport(VATCalculationType: Enum "Tax Calculation Type")
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        // Setup: Create Issued Reminder.
        Initialize();
        CreateIssuedReminderWithInterestAmount(IssuedReminderHeader, VATCalculationType);
        LibraryVariableStorage.Enqueue(IssuedReminderHeader."No.");

        // Exercise: Run Reminder Report.
        Commit();
        REPORT.Run(REPORT::Reminder);

        // Verify: Verifying interest amount on Reminder Report.
        VerifyInterestOnReminderReport(IssuedReminderHeader."Interest Amount");
    end;

    local procedure VerifyReminderVATAmountSpecification(ReminderNo: Code[20])
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        CurrExchRate: Record "Currency Exchange Rate";
        IssuedReminderLine: Record "Issued Reminder Line";
        CurrFactor: Decimal;
        TotalAmount: Decimal;
        TotalVATAmount: Decimal;
        AmountIncludeVAT: Decimal;
        VATBase: Decimal;
    begin
        IssuedReminderHeader.Get(ReminderNo);
        CurrFactor := CurrExchRate.ExchangeRate(IssuedReminderHeader."Posting Date", IssuedReminderHeader."Currency Code");

        // Use Precision to take Decimal Value upto 2 Decimal Places.
        FindIssuedReminderLine(IssuedReminderLine, ReminderNo, IssuedReminderLine.Type::"G/L Account");
        LibraryReportDataset.LoadDataSetFile();
        repeat
            SumAmountOnIssuedReminderFeeLineWithVAT(
              ReminderNo, IssuedReminderLine.Type::"G/L Account", IssuedReminderLine."VAT %", TotalAmount, TotalVATAmount);
            AmountIncludeVAT := TotalAmount + TotalVATAmount;
            VATBase := AmountIncludeVAT / (1 + IssuedReminderLine."VAT %" / 100);

            // Verify "VAT Base" and "VAT Amount" in VAT Amount Specification Caption.
            VerifyVATAmountSpecificationOnReminderReport(Format(IssuedReminderLine."VAT %"), VATBase, AmountIncludeVAT - VATBase);

            // Verify "VAT Base" and "VAT Amount" in VAT Amount Specification in GBP Caption.
            VerifyVATAmountSpecificationInGBPOnReminderReport(
              Format(IssuedReminderLine."VAT %"), VATBase / CurrFactor, (AmountIncludeVAT - VATBase) / CurrFactor);
        until IssuedReminderLine.Next() = 0;
    end;

    local procedure VerifyFinanceChargeMemoVATAmountSpecInGBP(FinanceChargeMemoNo: Code[20])
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        CurrExchRate: Record "Currency Exchange Rate";
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        CurrFactor: Decimal;
        TotalAmount: Decimal;
        TotalVATAmount: Decimal;
        AmountIncludeVAT: Decimal;
        VATBase: Decimal;
    begin
        IssuedFinChargeMemoHeader.Get(FinanceChargeMemoNo);
        CurrFactor := CurrExchRate.ExchangeRate(
            IssuedFinChargeMemoHeader."Posting Date", IssuedFinChargeMemoHeader."Currency Code");

        // Use Precision to take Decimal Value upto 2 Decimal Places.
        FindIssuedFinChargeMemoLine(IssuedFinChargeMemoLine, FinanceChargeMemoNo);
        LibraryReportDataset.LoadDataSetFile();
        repeat
            SumAmountOnIssuedFinChargeMemoLineWithVAT(
              FinanceChargeMemoNo, IssuedFinChargeMemoLine."VAT %", TotalAmount, TotalVATAmount);
            AmountIncludeVAT := TotalAmount + TotalVATAmount;
            VATBase := AmountIncludeVAT / (1 + IssuedFinChargeMemoLine."VAT %" / 100);

            // Verify "VAT Base" and "VAT Amount" in VAT Amount Specification in GBP Caption.
            VerifyVATAmountSpecInGBPOnFinanceChargeMemoReport(
              Format(IssuedFinChargeMemoLine."VAT %"), VATBase / CurrFactor, (AmountIncludeVAT - VATBase) / CurrFactor);
        until IssuedFinChargeMemoLine.Next() = 0;
    end;

    local procedure VerifyVATAmountSpecificationOnReminderReport(VAT: Text[50]; VATBase: Decimal; TotalVATAmount: Decimal)
    var
        Amount: Variant;
        VATAmount: Variant;
    begin
        LibraryReportDataset.SetRange('VATAmtSpecCaption', VATAmtSpecLabelTxt);
        LibraryReportDataset.SetRange('VATAmtLineVAT', VAT);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), StrSubstNo(RowNotFoundErr, 'VATAmtLineVAT', VAT));
        LibraryReportDataset.FindCurrentRowValue('VALVATBase', Amount);
        Assert.AreNearlyEqual(
          VATBase, Amount, LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(ValidationErr, VATBaseLabelTxt, VATBase));
        LibraryReportDataset.FindCurrentRowValue('VALVATAmount', VATAmount);
        Assert.AreNearlyEqual(
          TotalVATAmount, VATAmount, LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(ValidationErr, VATAmtLbl, TotalVATAmount));
    end;

    local procedure VerifyVATAmountSpecificationInGBPOnReminderReport(VAT: Text[50]; VATBase: Decimal; TotalVATAmount: Decimal)
    var
        Amount: Variant;
        VATAmount: Variant;
    begin
        LibraryReportDataset.SetRange('VALSpecLCYHeader', VATAmtSpecLCYLbl);
        LibraryReportDataset.SetRange('VATAmtLineVATCtrl107', VAT);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), StrSubstNo(RowNotFoundErr, 'VATAmtLineVATCtrl107', VAT));
        LibraryReportDataset.FindCurrentRowValue('VALVATBaseLCY', Amount);
        Assert.AreNearlyEqual(
          VATBase, Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationErr, VATBaseLabelTxt, VATBase));
        LibraryReportDataset.FindCurrentRowValue('VALVATAmountLCY', VATAmount);
        Assert.AreNearlyEqual(
          TotalVATAmount, VATAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationErr, VATAmtLbl, TotalVATAmount));
    end;

    local procedure VerifyVATAmountSpecInGBPOnFinanceChargeMemoReport(VAT: Text[50]; VATBase: Decimal; TotalVATAmount: Decimal)
    var
        Amount: Variant;
        VATAmount: Variant;
    begin
        LibraryReportDataset.SetRange('ValspecLCYHdr', VATAmtSpecLCYLbl);
        LibraryReportDataset.SetRange('VatAmtLnVat1', VAT);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), StrSubstNo(RowNotFoundErr, 'VatAmtLnVat1', VAT));
        LibraryReportDataset.FindCurrentRowValue('ValvataBaseLCY', Amount);
        Assert.AreNearlyEqual(
          VATBase, Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationErr, VATBaseLabelTxt, VATBase));
        LibraryReportDataset.FindCurrentRowValue('ValvatamountLCY', VATAmount);
        Assert.AreNearlyEqual(
          TotalVATAmount, VATAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationErr, VATAmtLbl, TotalVATAmount));
    end;

    local procedure VerifyReminderReportLastLineIsPleaseRemitYourPayment(Amount: Decimal; CustomerNo: Code[20]; IssuedReminderNo: Code[20])
    var
        Variant: Variant;
        Row: Integer;
        ElementValue: Text;
    begin
        LibraryReportDataset.LoadDataSetFile();
        Row :=
          LibraryReportDataset.FindRow(
            'Desc1_IssuedReminderLine',
            GetRemitPaymentsMsg(IssuedReminderNo, Amount + GetCustAddFeeAmount(CustomerNo)));
        LibraryReportDataset.MoveToRow(Row + 1);
        if LibraryReportDataset.GetNextRow() then
            repeat
                if LibraryReportDataset.CurrentRowHasElement('Desc1_IssuedReminderLine') then begin
                    LibraryReportDataset.GetElementValueInCurrentRow('Desc1_IssuedReminderLine', Variant);
                    Evaluate(ElementValue, Variant);
                    Assert.IsTrue(StrLen(ElementValue) = 0, ReminderReportLastLineErr);
                end;
            until not LibraryReportDataset.GetNextRow();
    end;

    local procedure VerifyEmptyValueOfField(GenJnlTemplateName: Text; GenJnlBatchName: Text; LineNo: Integer)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(GenJnlTemplateNameTok, GenJnlTemplateName);
        LibraryReportDataset.SetRange(GenJnlBatchNameTok, GenJnlBatchName);
        LibraryReportDataset.SetRange(LineNoTok, LineNo);
        LibraryReportDataset.GetNextRow();
        repeat
            Assert.IsFalse(LibraryReportDataset.CurrentRowHasElement(WarningCaptionTok), StrSubstNo(WarningErrorErr, LineNo));
            Assert.IsFalse(LibraryReportDataset.CurrentRowHasElement(ErrorTextNumberTok), WarningErrorErr);
        until not LibraryReportDataset.GetNextRow();
    end;

    local procedure VerifyGeneralJournalTestLineErrorText(GenJnlTemplateName: Text; GenJnlBatchName: Text; LineNo: Integer; ExpectedErrorText: Text)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(GenJnlTemplateNameTok, GenJnlTemplateName);
        LibraryReportDataset.SetRange(GenJnlBatchNameTok, GenJnlBatchName);
        LibraryReportDataset.SetRange(LineNoTok, LineNo);
        LibraryReportDataset.GetLastRow();
        Assert.IsTrue(LibraryReportDataset.CurrentRowHasElement(WarningCaptionTok), StrSubstNo(WarningErrorErr, LineNo));
        Assert.IsTrue(LibraryReportDataset.CurrentRowHasElement(ErrorTextNumberTok), ExpectedErrorText);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account",
            AccountNo,
            Amount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExchRateAdjustmentReportReqPageHandler(var ExchRateAdjustment: TestRequestPage "Exch. Rate Adjustment")
    var
        "Code": Variant;
    begin
        CurrentSaveValuesId := REPORT::"Exch. Rate Adjustment";
        LibraryVariableStorage.Dequeue(Code);
        ExchRateAdjustment.StartingDate.SetValue(WorkDate());
        ExchRateAdjustment.EndingDate.SetValue(CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(3)), WorkDate()));
        ExchRateAdjustment.DocumentNo.SetValue(LibraryUTUtility.GetNewCode());
        ExchRateAdjustment.CurrencyFilter.SetFilter(Code, Code);
        LibraryVariableStorage.Enqueue(ExchRateAdjustment.DocumentNo.Value);
        ExchRateAdjustment.PreviewPost.SetValue(false);
        ExchRateAdjustment.OK().Invoke();
    end;

    local procedure RunReportReminder(IssuedReminderNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(IssuedReminderNo);
        Commit();
        REPORT.Run(REPORT::Reminder);
    end;

    local procedure RunReportFinanceChargeMemo(FinanceChargeMemoNo: Code[20]; ShowInternalInfo: Boolean; LogInteraction: Boolean)
    begin
        LibraryVariableStorage.Enqueue(FinanceChargeMemoNo);
        LibraryVariableStorage.Enqueue(ShowInternalInfo);
        LibraryVariableStorage.Enqueue(LogInteraction);
        Commit();
        REPORT.Run(REPORT::"Finance Charge Memo");
    end;

    local procedure RunReportFinanceChargeMemoTest(FinanceChargeMemoNo: Code[20]; ShowDimension: Boolean)
    begin
        LibraryVariableStorage.Enqueue(FinanceChargeMemoNo);
        LibraryVariableStorage.Enqueue(ShowDimension);
        Commit();
        REPORT.Run(REPORT::"Finance Charge Memo - Test");
    end;

    local procedure RunReportReceivablesPayables(StartingDate: Variant; NoOfPeriods: Integer; PeriodLength: DateFormula)
    begin
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(NoOfPeriods);
        LibraryVariableStorage.Enqueue(PeriodLength);
        Commit();
        REPORT.Run(REPORT::"Receivables-Payables");
    end;

    local procedure RunReportGeneralJournalTest(JournalTemplateName: Code[20]; JournalBatchName: Code[20]; ShowDimension: Boolean)
    begin
        LibraryVariableStorage.Enqueue(JournalTemplateName);
        LibraryVariableStorage.Enqueue(JournalBatchName);
        LibraryVariableStorage.Enqueue(ShowDimension);
        Commit();
        REPORT.Run(REPORT::"General Journal - Test");
    end;

    local procedure RunReportTrialBalancePreviousYear(GLAccountNo: Code[20]; DateFilter: Date)
    begin
        LibraryVariableStorage.Enqueue(GLAccountNo);
        LibraryVariableStorage.Enqueue(DateFilter);
        Commit();
        REPORT.Run(REPORT::"Trial Balance/Previous Year");
    end;

    local procedure RunReportBankAccDetailTrialBal(BankAccountNo: Code[20]; DateFilter: Date)
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.SetRange("No.", BankAccountNo);
        BankAccount.SetRange("Date Filter", DateFilter);
        REPORT.Run(REPORT::"Bank Acc. - Detail Trial Bal.", true, false, BankAccount);
    end;

    local procedure SetAndRunJobQueue(ReportID: Integer; OutputType: Enum "Job Queue Report Output Type"; var JobQueueEntry: Record "Job Queue Entry")
    var
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := ReportID;
        JobQueueEntry."Report Output Type" := OutputType;
        JobQueueEntry.Description := Format(ReportID);
        JobQueueEntry."Run in User Session" := true;
        JobQueueEntry.Insert(true);
        Commit();

        JobQueueEntry.RunReportRequestPage();
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHBankaccRecon(var BankAccReconTest: TestRequestPage "Bank Acc. Recon. - Test")
    var
        StatemenNo: Variant;
        BalAccNo: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Bank Acc. Recon. - Test";
        LibraryVariableStorage.Dequeue(BalAccNo);
        LibraryVariableStorage.Dequeue(StatemenNo);

        BankAccReconTest."Bank Acc. Reconciliation".SetFilter("Bank Account No.", BalAccNo);
        BankAccReconTest."Bank Acc. Reconciliation".SetFilter("Statement No.", StatemenNo);
        BankAccReconTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHBankAccountCheckDetails(var BankAccountCheckDetails: TestRequestPage "Bank Account - Check Details")
    var
        BankAccountNo: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Bank Account - Check Details";
        LibraryVariableStorage.Dequeue(BankAccountNo);

        BankAccountCheckDetails."Bank Account".SetFilter("No.", BankAccountNo);
        BankAccountCheckDetails.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHReminderTest(var ReminderTest: TestRequestPage "Reminder - Test")
    var
        ReminderNo: Variant;
        ShowDimensions: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Reminder - Test";
        LibraryVariableStorage.Dequeue(ReminderNo);
        LibraryVariableStorage.Dequeue(ShowDimensions);

        ReminderTest."Reminder Header".SetFilter("No.", ReminderNo);
        ReminderTest.ShowDimensions.SetValue(ShowDimensions);
        ReminderTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHReminder(var Reminder: TestRequestPage Reminder)
    begin
        CurrentSaveValuesId := REPORT::Reminder;
        Reminder."Issued Reminder Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        Reminder.ShowNotDueAmounts.SetValue(false);
        Reminder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFinanceChargeMemo(var FinanceChargeMemo: TestRequestPage "Finance Charge Memo")
    var
        IssuedFinChargeMemoNo: Variant;
        ShowInternalInfo: Variant;
        LogInteraction: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Finance Charge Memo";
        LibraryVariableStorage.Dequeue(IssuedFinChargeMemoNo);
        LibraryVariableStorage.Dequeue(ShowInternalInfo);
        LibraryVariableStorage.Dequeue(LogInteraction);

        FinanceChargeMemo."Issued Fin. Charge Memo Header".SetFilter("No.", IssuedFinChargeMemoNo);
        FinanceChargeMemo.ShowInternalInformation.SetValue(ShowInternalInfo);
        FinanceChargeMemo.LogInteraction.SetValue(LogInteraction);
        FinanceChargeMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFinanceChargeMemoTest(var FinanceChargeMemoTest: TestRequestPage "Finance Charge Memo - Test")
    var
        FinChargeMemoNo: Variant;
        ShowDimension: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Finance Charge Memo - Test";
        LibraryVariableStorage.Dequeue(FinChargeMemoNo);
        LibraryVariableStorage.Dequeue(ShowDimension);

        FinanceChargeMemoTest."Finance Charge Memo Header".SetFilter("No.", FinChargeMemoNo);
        FinanceChargeMemoTest.ShowDimensions.SetValue(ShowDimension);
        FinanceChargeMemoTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHReceivablesPayables(var ReceivablesPayables: TestRequestPage "Receivables-Payables")
    var
        StartingDate: Variant;
        NoOfPeriods: Variant;
        PeriodLength: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Receivables-Payables";
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(NoOfPeriods);
        LibraryVariableStorage.Dequeue(PeriodLength);
        ReceivablesPayables.StartDate.SetValue(StartingDate);
        ReceivablesPayables.NoOfPeriods.SetValue(NoOfPeriods);
        ReceivablesPayables.PeriodLength.SetValue(PeriodLength);
        ReceivablesPayables.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHGeneralJournalTest(var GeneralJournalTest: TestRequestPage "General Journal - Test")
    var
        JournalTemplateName: Variant;
        JournalBatchName: Variant;
        ShowDimension: Variant;
    begin
        CurrentSaveValuesId := REPORT::"General Journal - Test";
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        LibraryVariableStorage.Dequeue(ShowDimension);
        GeneralJournalTest."Gen. Journal Line".SetFilter("Journal Template Name", JournalTemplateName);
        GeneralJournalTest."Gen. Journal Line".SetFilter("Journal Batch Name", JournalBatchName);
        GeneralJournalTest.ShowDim.SetValue(ShowDimension);
        GeneralJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHGeneralJournalTestSimple(var GeneralJournalTest: TestRequestPage "General Journal - Test")
    begin
        GeneralJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHTrialBalancePreviousYear(var TrialBalancePreviousYear: TestRequestPage "Trial Balance/Previous Year")
    var
        DateFilter: Variant;
        GLAccountNo: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Trial Balance/Previous Year";
        LibraryVariableStorage.Dequeue(GLAccountNo);
        LibraryVariableStorage.Dequeue(DateFilter);
        TrialBalancePreviousYear."G/L Account".SetFilter("No.", GLAccountNo);
        TrialBalancePreviousYear."G/L Account".SetFilter("Date Filter", Format(DateFilter));
        TrialBalancePreviousYear.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ExchRateWasAdjustedTxt, Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHGenJournalTest(var GeneralJournalTest: TestRequestPage "General Journal - Test")
    begin
        CurrentSaveValuesId := REPORT::"General Journal - Test";
        GeneralJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHBankAccDetailTrialBalance(var BankAccDetailTrialBalance: TestRequestPage "Bank Acc. - Detail Trial Bal.")
    begin
        CurrentSaveValuesId := REPORT::"Bank Acc. - Detail Trial Bal.";
        BankAccDetailTrialBalance.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHBankAccDetailTrialBalanceXML(var BankAccDetailTrialBalance: TestRequestPage "Bank Acc. - Detail Trial Bal.")
    begin
        CurrentSaveValuesId := REPORT::"Bank Acc. - Detail Trial Bal.";
        BankAccDetailTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderRequestPageHandler(var Reminder: TestRequestPage Reminder)
    begin
        Reminder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure PreviewPostingExchRateAdjustmentReportReqPageHandler(var ExchRateAdjustment: TestRequestPage "Exch. Rate Adjustment")
    begin
        Assert.AreEqual(ExchRateAdjustment.PreviewPost.AsBoolean(), false, PreviewPostingErr);

        ExchRateAdjustment.StartingDate.SetValue(WorkDate());
        ExchRateAdjustment.EndingDate.SetValue(CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(3)), WorkDate()));
        ExchRateAdjustment.DocumentNo.SetValue(LibraryUTUtility.GetNewCode());
        ExchRateAdjustment.CurrencyFilter.SetFilter(Code, LibraryVariableStorage.DequeueText());
        ExchRateAdjustment.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure VATReconciliationRequestPageHandler(var VATReconciliationReport: TestRequestPage "VAT Reconciliation Report")
    begin
        VATReconciliationReport.ShowDetails.SetValue(true);
        VATReconciliationReport.ShowTransWithoutVAT.SetValue(true);
        VATReconciliationReport.GLEntry.SetFilter("Posting Date", Format(Today()));
        VATReconciliationReport.GLEntry.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        VATReconciliationReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;
}
