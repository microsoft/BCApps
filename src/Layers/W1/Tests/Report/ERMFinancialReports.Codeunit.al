codeunit 134982 "ERM Financial Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports]
        IsInitialized := false;
    end;

    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        FileManagement: Codeunit "File Management";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        ReportErr: Label '%1 must be %2 in Report.', Locked = true;
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2.', Comment = '%1=Field Caption,%2=Field Value;';
        RowMustNotExistErr: Label 'Row Must Not Exist';
        FiscalYearStartingDateErr: Label 'Enter the starting date for the fiscal year.';
        FileNameNotEnabledErr: Label 'The FileName value on the request form should be enabled';
        FileNameNotEditableErr: Label 'The FileName value on the request form should be editable';
        FileNameNotPersistedErr: Label 'The FileName value on the request form should be persisted between successive invocations of the report.';
        FilePathTxt: Label 'TestFileName';
        BlankLinesQtyErr: Label 'Wrong blank lines quantity in dataset.';
        SourceBalanceErr: Label 'Source Currency Balance Must be 0';
        JournalLineCreatedMsg: Label 'The journal lines have successfully been created.';
        SourceCurrencyCodeErr: Label 'Source Currency Amount should not be zero after reversing and closing income statement.';
        CurrentSaveValuesId: Integer;
        G_L_Register_NoLbl: Label 'G_L_Register_No';
        G_L_Entry_Document_NoLbl: Label 'G_L_Entry_Document_No';
        G_L_Entry_G_L_Account_NoLbl: Label 'G_L_Entry_G_L_Account_No';
        G_L_Register_From_Entry_NoLbl: Label 'G_L_Register_From_Entry_No';
        G_L_Register_To_Entry_NoLbl: Label 'G_L_Register_To_Entry_No';
        G_L_Entry_Document_TypeLbl: Label 'G_L_Entry_Document_Type';
        G_L_Entry_AmountLbl: Label 'G_L_Entry_Amount';
        G_L_Entry_Entry_NoLbl: Label 'G_L_Entry_Entry_No';
        G_L_Entry_Source_CodeLbl: Label 'G_L_Entry_Source_Code';
        G_L_Entry_Source_NoLbl: Label 'G_L_Entry_Source_No';
        G_L_Entry_System_Created_EntryLbl: Label 'G_L_Entry_System_Created_Entry';
        G_L_Entry_Posting_DateLbl: Label 'G_L_Entry_Posting_Date';
        G_L_Entry_Document_DateLbl: Label 'G_L_Entry_Document_Date';

    [Test]
    [HandlerFunctions('RHDetailTrialBalance')]
    [Scope('OnPrem')]
    procedure DetailTrialBalanceDateRange()
    begin
        DetailTrialBalanceDateRangeShared(StrSubstNo('%1..', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('RHDetailTrialBalance')]
    [Scope('OnPrem')]
    procedure DetailTrialBalanceDateFilter()
    begin
        DetailTrialBalanceDateRangeShared(StrSubstNo('>%1', WorkDate() - 1));
    end;

    local procedure DetailTrialBalanceDateRangeShared(DateFilter: Text[30])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        // Validate Detail Trial Balance Report when setting a date range or date filter.

        // Setup: Create and post General Journal Lines.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", 1);
        GenJournalLine."Posting Date" -= 1; // the day before WORKDATE
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise. Save Detail Trial Balance Report for the G/L Account Created.
        RunDetailTrialBalanceReport(GenJournalLine."Account No.", false, false, false, false, DateFilter);

        // Verify: Verify Amounts on Detail Trial Balance Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo_GLEntry', GenJournalLine."Document No.");
        if LibraryReportDataset.GetNextRow() then begin
            LibraryReportDataset.AssertCurrentRowValueEquals('StartBalance', 1);
            LibraryReportDataset.AssertCurrentRowValueEquals('DebitAmount_GLEntry', 1);
            LibraryReportDataset.AssertCurrentRowValueEquals('GLBalance', 2);
        end else
            Error(ReportErr, GenJournalLine.FieldCaption(Amount), 1);
    end;

    [Test]
    [HandlerFunctions('RHDetailTrialBalance')]
    [Scope('OnPrem')]
    procedure DetailTrialBalanceExclReverse()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        // Validate Detail Trial Balance Report when Print Reversed Entry option is false.

        // Setup: Create and post General Journal Line.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise. Save Detail Trial Balance Report for the G/L Account Created.
        RunDetailTrialBalanceReport(GenJournalLine."Account No.", false, false, false, false, '');

        // Verify: Verify Amounts on Detail Trial Balance Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo_GLEntry', GenJournalLine."Document No.");
        if LibraryReportDataset.GetNextRow() then
            LibraryReportDataset.AssertCurrentRowValueEquals('DebitAmount_GLEntry', GenJournalLine.Amount)
        else
            Error(ReportErr, GenJournalLine.FieldCaption(Amount), GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,RHDetailTrialBalance')]
    [Scope('OnPrem')]
    procedure DetailTrialBalanceInclReverse()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Validate Detail Trial Balance Report when Print Reversed Entry option is True.

        // Setup: Create and post General Journal Line and Reverse the Entry.
        Initialize();

        PostGenJournalLineAndReversTransaction(GenJournalLine);

        // Exercise. Save Detail Trial Balance Report for the G/L Account Created.
        RunDetailTrialBalanceReport(GenJournalLine."Account No.", false, false, true, false, '');

        // Verify: Verify Amounts on Detail Trial Balance Report after Entries has been reversed.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo_GLEntry', GenJournalLine."Document No.");
        LibraryReportDataset.AssertElementWithValueExists('DebitAmount_GLEntry', GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('DebitAmount_GLEntry', -GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,RHDetailTrialBalance')]
    [Scope('OnPrem')]
    procedure DetailTrialBalanceCorrections()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Validate Detail Trial Balance Report when Print only Correction Entry option is True.

        // Setup: Create and post General Journal Line and Reverse the Entry.
        Initialize();

        PostGenJournalLineAndReversTransaction(GenJournalLine);

        // Exercise. Save Detail Trial Balance Report for the G/L Account Created.
        RunDetailTrialBalanceReport(GenJournalLine."Account No.", false, false, true, true, '');

        // Verify: Verify GLBalance in Detail Trial Balance Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyDetailTrialBalanceReport(GenJournalLine, 'GLBalance');
    end;

    [Test]
    [HandlerFunctions('RHDetailTrialBalanceWithDateFilter')]
    [Scope('OnPrem')]
    procedure DetailTrialBalanceExcludeGLAcc()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        // Validate Error in Detail Trial Balance Report when Exclude G/L Account that have Balance Only True.

        // Setup: Create and post General Journal Line.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise. Save Detail Trial Balance Report for the G/L Account Created.
        TrialBalanceReportDateFilter(GenJournalLine."Account No.", true, false, false, false, GenJournalLine."Posting Date");

        // Verify: Verify Error in Detail Trial Balance Report when Exclude G/L Account that have Balance Only True.
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), RowMustNotExistErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,RHDetailTrialBalance')]
    [Scope('OnPrem')]
    procedure DetailTrialBalanceCloseEntry()
    var
        Date: Record Date;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Validate Trial Balance Report when Print Closing Entry Within the Period is True.

        // Setup: Create and post General Journal Line.
        Initialize();
        CreateIncomeStatementGenJnlLine(GenJournalLine, Date);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Run Close Income Statement Batch Report.
        RunCloseIncomeStatementReport(GenJournalLine, NormalDate(Date."Period End"), false);
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise. Save Detail Trial Balance Report for the G/L Account Created.
        RunDetailTrialBalanceReport(GenJournalLine."Account No.", false, true, false, false, '');

        // Verify: Verify Credit Amount in Detail Trial Balance Report when Print Closing Entry Within the Period is True.
        LibraryReportDataset.LoadDataSetFile();
        VerifyDetailTrialBalanceReport(GenJournalLine, 'CreditAmount_GLEntry');
    end;

    [Test]
    [HandlerFunctions('RHBankLedgerEntry')]
    [Scope('OnPrem')]
    procedure BankLedgerEntryWithoutReversal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Validate Bank Acc. Detail Trial Balance Report when Print Reverse Entry option is false.

        // Setup.
        Initialize();
        CreateUpdateAndPostGenJnlLine(GenJournalLine);

        // Exercise: Save Bank Acc. Detail Trial Balance Report.
        BankAccDetailTrialBalReport(GenJournalLine."Bal. Account No.", false, false);

        // Verify: Verify Balance(LCY) in Bank Acc. Detail Trial Balance Report when Print Reverse Entry option is false.
        LibraryReportDataset.LoadDataSetFile();
        VerifyBankLedgerEntry(GenJournalLine, 'BankAccBalanceLCY');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,RHBankLedgerEntry')]
    [Scope('OnPrem')]
    procedure BankLedgerEntryWithReversal()
    var
        ReversalEntry: Record "Reversal Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Validate Bank Acc. Detail Trial Balance Report when Print Reverse Entry option is True.

        // Setup.
        Initialize();
        CreateUpdateAndPostGenJnlLine(GenJournalLine);
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(FindGLEntry(GenJournalLine."Document No."));

        // Exercise: Save Bank Acc. Detail Trial Balance Report.
        BankAccDetailTrialBalReport(GenJournalLine."Bal. Account No.", false, true);

        // Verify: Verify Amount(LCY) in Bank Acc. Detail Trial Balance Report when Print Reverse Entry option is True.
        LibraryReportDataset.LoadDataSetFile();
        VerifyBankLedgerEntry(GenJournalLine, 'EntryAmtLcy_BankAccLedg');
    end;

    [Test]
    [HandlerFunctions('RHAccTrialBalance')]
    [Scope('OnPrem')]
    procedure AccTrialBalanceExcludeGLAcc()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Validate Error in Bank Acc. Detail Trial Balance Report when Exclude G/L Account that have Balance Only True.

        // Setup.
        Initialize();
        CreateUpdateAndPostGenJnlLine(GenJournalLine);

        // Exercise. Save Bank Acc. Detail Trial Balance Report.
        BankAccTrialReportDateFilter(GenJournalLine."Bal. Account No.", true, false, GenJournalLine."Posting Date");

        // Verify: Verify Error in Detail Trial Balance Report when Exclude G/L Account that have Balance Only True.
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), RowMustNotExistErr);
    end;

    [Test]
    [HandlerFunctions('RHCheckBankAccReconciliation')]
    [Scope('OnPrem')]
    procedure CheckBankAccReconciliation()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliation2: Record "Bank Acc. Reconciliation";
        BankAccReconTest: Report "Bank Acc. Recon. - Test";
    begin
        // Verify the Bank Reconciliation Test Report.

        // Setup.
        Initialize();
        PostCheck(GenJournalLine);
        CreateSuggestedBankReconc(BankAccReconciliation, GenJournalLine."Bal. Account No.");
        Clear(BankAccReconTest);
        BankAccReconciliation2.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliation2.SetRange("Bank Account No.", GenJournalLine."Bal. Account No.");
        BankAccReconciliation2.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconTest.SetTableView(BankAccReconciliation2);
        Commit();
        BankAccReconTest.Run();

        // Verify: Verify Statement Amount in Bank Reconciliation Test Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Bank_Acc__Reconciliation_Line__Document_No__', GenJournalLine."Document No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Bank_Acc__Reconciliation_Line__Document_No__', GenJournalLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Bank_Acc__Reconciliation_Line__Statement_Amount_', -GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetWithoutOption')]
    [Scope('OnPrem')]
    procedure FixedAssetWithoutOption()
    var
        FixedAssetDetails: Report "Fixed Asset - Details";
    begin
        // Verify Error on Fixed Asset Detail Report when no option is set.

        // Setup.
        Clear(FixedAssetDetails);

        // Exercise: Save Fixed Asset Detail Report.
        asserterror FixedAssetDetails.Run();

        // Verify: Verify error on Fixed Asset Detail Report when no option is set.
        Assert.ExpectedErrorCannotFind(Database::"Depreciation Book");
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetDetails')]
    [Scope('OnPrem')]
    procedure FixedAssetWithoutReversal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Fixed Asset Detail Report when Print Reverse Entries option is false.

        // Setup.
        Initialize();
        CreateAndPostFAGenJournalLine(GenJournalLine, GenJournalLine."FA Posting Type"::"Acquisition Cost");

        // Exercise: Save Fixed Asset Detail Report.
        FixedAssetDetailReport(GenJournalLine."Account No.", GenJournalLine."Depreciation Book Code", false, false);

        // Verify: Verify Amount on Fixed Asset Detail Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('FA_Ledger_Entry__Document_No__', GenJournalLine."Document No.");
        if LibraryReportDataset.GetNextRow() then
            LibraryReportDataset.AssertCurrentRowValueEquals('FA_Ledger_Entry_Amount', GenJournalLine.Amount)
        else
            Error(ReportErr, GenJournalLine.FieldCaption(Amount), GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,RHFixedAssetDetails')]
    [Scope('OnPrem')]
    procedure FixedAssetWithReversal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Fixed Asset Detail Report when Print Reverse Entries option is True.

        // Setup.
        Initialize();
        CreateAndPostFAGenJournalLine(GenJournalLine, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        ReverseFALedgerEntry(GenJournalLine."Document No.");

        // Exercise: Save Fixed Asset Detail Report.
        FixedAssetDetailReport(GenJournalLine."Account No.", GenJournalLine."Depreciation Book Code", false, true);

        // Verify: Verify Amounts on Fixed Asset Detail Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('FA_Ledger_Entry_Amount', GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('FA_Ledger_Entry_Amount', -GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('RHMaintenanceDetailsWithOutOption')]
    [Scope('OnPrem')]
    procedure MaintenanceDetailWithoutOption()
    var
        MaintenanceDetails: Report "Maintenance - Details";
    begin
        // Verify Error on Maintenance Details Report when no option is set.

        // Setup.
        Initialize();
        Clear(MaintenanceDetails);
        Commit();

        // Exercise: Save Maintenance Detail Report.
        asserterror MaintenanceDetails.Run();

        // Verify: Verify error on Maintenance Detail Report when no option is set.
        Assert.ExpectedErrorCannotFind(Database::"Depreciation Book");
    end;

    [Test]
    [HandlerFunctions('RHMaintenanceDetails')]
    [Scope('OnPrem')]
    procedure MaintenanceWithoutReversal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Maintenance Details Report when Print Reversed Entries option is false.

        // Setup.
        Initialize();
        CreateAndPostFAGenJournalLine(GenJournalLine, GenJournalLine."FA Posting Type"::Maintenance);

        // Exercise: Save Maintenance Details Report.
        RunMaintenanceDetailsReport(GenJournalLine."Account No.", GenJournalLine."Depreciation Book Code", false);

        // Verify: Verify Amount, FA Postind Date and User ID on Maintenance Details Report when Print Reversed Entries option is false.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Maintenance_Ledger_Entry__Document_No__', GenJournalLine."Document No.");
        if LibraryReportDataset.GetNextRow() then begin
            LibraryReportDataset.AssertCurrentRowValueEquals('Maintenance_Ledger_Entry_Amount', GenJournalLine.Amount);
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Maintenance_Ledger_Entry__Posting_Date_', Format(GenJournalLine."Posting Date"));
        end else
            Error(ReportErr, GenJournalLine.FieldCaption(Amount), GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,RHMaintenanceDetails')]
    [Scope('OnPrem')]
    procedure MaintenanceWithReversal()
    var
        FixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        MaintenanceDetails: Report "Maintenance - Details";
    begin
        // Verify Maintenance Details Report when Print Reversed Entries option is True.

        // Setup.
        Initialize();
        CreateAndPostFAGenJournalLine(GenJournalLine, GenJournalLine."FA Posting Type"::Maintenance);
        ReverseMaintenanceLedgerEntry(GenJournalLine."Document No.");

        // Exercise: Save Maintenance Details Report.
        Clear(MaintenanceDetails);
        MaintenanceDetails.InitializeRequest(GenJournalLine."Depreciation Book Code", false, true);
        FixedAsset.SetRange("No.", GenJournalLine."Account No.");
        MaintenanceDetails.SetTableView(FixedAsset);
        Commit();
        MaintenanceDetails.Run();
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("Bal. Account Type", GenJournalLine."Bal. Account Type");
        GLEntry.FindLast();

        // Verify: Verify Amount on Maintenance Details Report when Print Reversed Entries option is True.
        LibraryReportDataset.LoadDataSetFile();
        VerifyMaintenanceLedgerEntryAmount(
          'Maintenance_Ledger_Entry__Document_No__', GenJournalLine."Document No.", GenJournalLine.Amount);
        VerifyMaintenanceLedgerEntryAmount(
          'Maintenance_Ledger_Entry__G_L_Entry_No__', Format(GLEntry."Entry No."), -GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('RHVATVIESDeclarationTaxAuth')]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationAddCurrTrue()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [VAT- VIES Declaration Tax Auth]
        // [SCENARIO] Verify VAT VIES Declaration Tax Auth. Report when Include Additional Currency Amount option is True.

        // Setup: Create Currency, update General Ledger Setup and find a Customer whose Country/Region Code and VAT Registration No is not
        // Blank.
        Initialize();
        LibraryERM.SetAddReportingCurrency(CreateCurrencyAndExchangeRate());
        FindCustomerVATRegistration(Customer);
        CreateAndPostSalesInvoice(Customer."No.");

        // Exercise: Save VAT VIES Declaration Tax Auth. Report.
        VATVIESDeclarationTaxReport(Customer."VAT Registration No.", true);

        // Verify: Verify Total Value of Item Supplied on VAT VIES Declaration Tax Auth. Report.
        VerifyTotalValueofItemSupplies(-CalculateAdditionalCurrBase(Customer."VAT Registration No."));
    end;

    [Test]
    [HandlerFunctions('RHVATVIESDeclarationTaxAuth')]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationAddCurrFalse()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [VAT- VIES Declaration Tax Auth]
        // [SCENARIO] Verify VAT VIES Declaration Tax Auth. Report when Include Additional Currency Amount option is False.

        // Setup: Create Currency, update General Ledger Setup and find a Customer whose Country/Region Code and VAT Registration No is not
        // Blank.
        Initialize();
        LibraryERM.SetAddReportingCurrency(CreateCurrencyAndExchangeRate());
        FindCustomerVATRegistration(Customer);
        CreateAndPostSalesInvoice(Customer."No.");

        // Exercise: Save VAT VIES Declaration Tax Auth. Report.
        VATVIESDeclarationTaxReport(Customer."VAT Registration No.", false);

        // Verify: Verify Total Value of Item Supplied on VAT VIES Declaration Tax Auth. Report.
        VerifyTotalValueofItemSupplies(-CalculateBase(Customer."VAT Registration No."));
    end;

    [Test]
    [HandlerFunctions('RHChartOfAccount')]
    [Scope('OnPrem')]
    procedure ChartOfAccount()
    var
        GLAccount: Record "G/L Account";
    begin
        // Verify Chart Of Account Report.

        // Setup: Create and post General Journal Line.
        Initialize();
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        // Exercise. Save Chart Of Account Report for the G/L Account Created.
        ChartOfAccountsReport(GLAccount."No.");

        // Verify: Verify Chart Of Account Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyChartOfAccountReport(GLAccount);
    end;


    [Test]
    [HandlerFunctions('RHGLDocumentNos')]
    [Scope('OnPrem')]
    procedure GLDocumentNos()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify G/L Document Nos Report.

        // Setup: Create and post General Journal Line With Random values.
        Initialize();
        CreateAndPostGenLine(GenJournalLine);

        // Exercise. Save G/L Document Nos Report.
        GLDocumentNosReport(GenJournalLine."Document No.");

        // Verify: Verify G/L Document Nos Report.
        VerifyGLDocumentNosReport(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('RHGLRegisterReport')]
    [Scope('OnPrem')]
    procedure GLRegister()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegister: Record "G/L Register";
    begin
        // Verify GL Register Report.

        // Setup: Create and post General Journal Line With Random values.
        Initialize();
        CreateAndPostGenLine(GenJournalLine);
        GLRegister.FindLast();

        // Exercise. Save GL Register Report.
        GLRegisterReport(GLRegister."No.");

        // Verify: Verify GL Register Report.
        VerifyGLRegisterReport(GenJournalLine, GLRegister."No.");
    end;

    [Test]
    [HandlerFunctions('RHTrialBalance')]
    [Scope('OnPrem')]
    procedure TrialBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostGenLineAndRunTrialBalance(GenJournalLine, 0);

        // Verify: Verify Trial Balance Report.
        VerifyTrialBalanceReport(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('RHTrialBalance')]
    [Scope('OnPrem')]
    procedure TrialBalance_GLAccountWithNewPage_PageBreakGroupChangedAfterGLAcc()
    var
        GenJournalLine1: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        Initialize();
        CreateAndPostGenLine(GenJournalLine1);
        CreateAndPostGenLine(GenJournalLine2);

        GLAccount.Get(GenJournalLine1."Account No.");
        GLAccount.Validate("New Page", true);
        GLAccount.Modify(true);

        TrialBalanceReport(GenJournalLine1."Account No." + '|' + GenJournalLine2."Account No.");

        LibraryReportDataset.LoadDataSetFile();
        VerifyTrialBalanceReportWithPageBreakGroup(GenJournalLine1, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('RHTrialBalance')]
    [Scope('OnPrem')]
    procedure TrialBalance_GLAccountWithBlankLines_BlankLinesExistsInDataset()
    begin
        VerifyTrialBalanceReportWithBlankLines(LibraryRandom.RandInt(5) + 1);
    end;

    [Test]
    [HandlerFunctions('RHTrialBalance')]
    [Scope('OnPrem')]
    procedure TrialBalance_GLAccountWithBlankLine_OnlyOneBlankLineExistsInDataset()
    begin
        VerifyTrialBalanceReportWithBlankLines(1);
    end;

    [Test]
    [HandlerFunctions('RHTrialBalance')]
    [Scope('OnPrem')]
    procedure TrialBalance_GLAccountWithNoBlankLines_NoBlankLinesExistsInDataset()
    begin
        VerifyTrialBalanceReportWithBlankLines(0);
    end;

    [Test]
    [HandlerFunctions('RHTrialBalanceBudget')]
    [Scope('OnPrem')]
    procedure TrialBalanceBudget()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BudgetAtDate: Decimal;
    begin
        // Verify Trial Balance Budget Report.

        // Setup: Create and post General Journal Line With Random values.
        Initialize();
        CreateAndPostGenLine(GenJournalLine);
        BudgetAtDate := CreateGLBudgetEntry(GenJournalLine."Account No.", GenJournalLine."Posting Date");

        // Exercise. Save Trial Balance Budget Report.
        TrialBalanceBudgetReport(GenJournalLine."Account No.", GenJournalLine."Posting Date");

        // Verify: Verify Trial Balance Budget Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyTrialBalanceBudgetReport(GenJournalLine, BudgetAtDate);
    end;


    [Test]
    [HandlerFunctions('RHClosingTrialBalance')]
    [Scope('OnPrem')]
    procedure ClosingTrialBalanceNoOption()
    var
        ClosingTrialBalance: Report "Closing Trial Balance";
    begin
        // Check Closing Trial Balance with No Option

        // Setup.
        Initialize();

        // Exercise. Try to Save Closing Trial Balance Report without any Option.
        Clear(ClosingTrialBalance);
        ClosingTrialBalance.InitializeRequest(0D, false);
        Commit();
        asserterror ClosingTrialBalance.Run();

        // Verify: Verify Error during Save of Closing Trial Balance Report when No option was selected.
        Assert.ExpectedError(FiscalYearStartingDateErr);
    end;

    [Test]
    [HandlerFunctions('RHClosingTrialBalance')]
    [Scope('OnPrem')]
    procedure ClosingTrialBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        // Check Closing Trial Balance with Fiscal Year.

        // Setup: Create and post General Journal Line with New GL Account with Random Values.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", LibraryFiscalYear.GetFirstPostingDate(false));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Save and Verify Closing Trial Balance Report.
        SaveVerifyClosingTrialBalance(GenJournalLine, GenJournalLine.Amount, false);
    end;

    [Test]
    [HandlerFunctions('RHClosingTrialBalance')]
    [Scope('OnPrem')]
    procedure ClosingTrialBalanceFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        CurrencyCode: Code[10];
        FCYAmount: Decimal;
    begin
        // Check Closing Trial Balance with Fiscal Year and FCY.

        // Setup: Create and post General Journal Line with New GL Account and Add additional Currency.
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", LibraryFiscalYear.GetFirstPostingDate(false));
        GenJournalLine.Modify(true);

        FCYAmount := Round(LibraryERM.ConvertCurrency(GenJournalLine.Amount, '', CurrencyCode, WorkDate()));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Save and Verify Closing Trial Balance Report with Amount LCY option.
        SaveVerifyClosingTrialBalance(GenJournalLine, FCYAmount, true);
    end;

    [Test]
    [HandlerFunctions('RHReconcileCustandVendAccs')]
    [Scope('OnPrem')]
    procedure ReconcileCustandVendAccsReport()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        ReconcileCustAndVendAccs: Report "Reconcile Cust. and Vend. Accs";
        TotalAmount: Decimal;
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // Check Reconcile Cust. and Ven. Account Report with Posted Sales Invoice.

        // Setup: Create and post Sales Invoice with New Customer.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateAndPostSalesInvoice(CustomerNo);
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        TotalAmount := FindDetailedCustLedgerEntryAmount(GLAccountNo, Customer."Customer Posting Group");

        // Exercise.
        Clear(ReconcileCustAndVendAccs);
        GLAccount.SetRange("No.", GLAccountNo);
        GLAccount.SetRange("Date Filter", WorkDate());
        GLAccount.FindFirst();
        ReconcileCustAndVendAccs.SetTableView(GLAccount);
        Commit();
        ReconcileCustAndVendAccs.Run();

        // Verify: Verify Saved Report Data.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_GLAccount', GLAccountNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'No_GLAccount', GLAccountNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('Name_GLAccount', GLAccount.Name);

        LibraryReportDataset.SetRange('GetTableName', Customer.FieldCaption("Customer Posting Group"));
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'GetTableName', Customer.FieldCaption("Customer Posting Group"));
        LibraryReportDataset.AssertCurrentRowValueEquals('ReconCustVendBufferPostingGroup', Customer."Customer Posting Group");
        LibraryReportDataset.AssertCurrentRowValueEquals('AccountType', CustomerPostingGroup.FieldCaption("Receivables Account"));
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount', TotalAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('GLAccountTableCaption', GLAccount.TableCaption + ': ' + GLAccount.GetFilters);
    end;

    [Test]
    [HandlerFunctions('RHImportConsolidationFromFile')]
    [Scope('OnPrem')]
    procedure ImportConsolidationFromFileRequestPage()
    var
        ImportConsolidationFromFile: Report "Import Consolidation from File";
    begin
        ImportConsolidationFromFile.SetParameters("Business Unit File Format"::"Version 3.70 or Earlier (.txt)", FilePathTxt, '10000');
        ImportConsolidationFromFile.Run();
    end;

    [Test]
    [HandlerFunctions('RHExportConsolidationToFile')]
    [Scope('OnPrem')]
    procedure ExportConsolidationToFileRequestPage()
    var
        ExportConsolidationToFile: Report "Export Consolidation";
    begin
        ExportConsolidationToFile.InitializeRequest(1, FilePathTxt);
        ExportConsolidationToFile.Run();
    end;

    [Test]
    [HandlerFunctions('ExportConsolidationRequesPageHandler')]
    [Scope('OnPrem')]
    procedure ExportConsolidationFile()
    begin
        // Setup: Create GL Accounts with 20 length of Consolidate Acccounts.
        Initialize();
        CreateGLAccountWithConsolidateAccount();

        // Excercise: Run the Export Consolidate Report.
        Commit();
        REPORT.Run(REPORT::"Export Consolidation");

        // Verify: Verifying that Export Consolidation report exporting the consolidation file without any error.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementWithGlobalDimensions()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SelectedDimension: Record "Selected Dimension";
        AllObj: Record AllObj;
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        Date: Record Date;
        GenJournalLine: Record "Gen. Journal Line";
        DimSetID: Integer;
    begin
        // [SCENARIO 378328] When Close Income Statement with dimensions then values for Global dimensions are transferred to the General Journal
        Initialize();

        // [GIVEN] Posted Income Statement Journal line with global dimensions "D1" and "D2"
        CreateIncomeStatementGenJnlLine(GenJournalLine, Date);
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateSelectedDimension(SelectedDimension, AllObj."Object Type"::Report,
          REPORT::"Close Income Statement", '', GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateSelectedDimension(SelectedDimension, AllObj."Object Type"::Report,
          REPORT::"Close Income Statement", '', GeneralLedgerSetup."Global Dimension 2 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue1, GeneralLedgerSetup."Global Dimension 1 Code");
        DimSetID := LibraryDimension.CreateDimSet(0, DimensionValue1."Dimension Code", DimensionValue1.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue2, GeneralLedgerSetup."Global Dimension 2 Code");
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue2."Dimension Code", DimensionValue2.Code);
        GenJournalLine."Dimension Set ID" := DimSetID;
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run Close Income Statement Report with selected Dimensions
        RunCloseIncomeStatementReport(GenJournalLine, NormalDate(Date."Period End"), false);

        // [THEN] Created Gen. Journal Line has Dimension 1 = "D1", Dimension 2 = "D2"
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetRange("Account No.", GenJournalLine."Account No.");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue1.Code);
        GenJournalLine.TestField("Shortcut Dimension 2 Code", DimensionValue2.Code);
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementWithZeroEndDateRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RunCloseIncomeStatementReportWithoutClosedFiscalYears()
    var
        AccountingPeriod: Record "Accounting Period";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Report] [Close Income Statement] [Fiscal Year]
        // [SCENARIO 205272] If there are no closed Fiscal Years, then REP 94 - "Close Income Statement" throws the error message "No closed fiscal year exists."

        // [GIVEN] No closed Fiscal Years
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.ModifyAll("Date Locked", false);

        // [WHEN] RUN REP 94 - "Close Income Statement"
        GenJournalLine.Init();
        asserterror RunCloseIncomeStatementReport(GenJournalLine, 0D, true);

        // [THEN] Error message "No closed fiscal year exists." appears
        Assert.ExpectedError('No closed fiscal year exists.');
    end;

    [Test]
    [HandlerFunctions('RHVATVIESDeclarationTaxAuth')]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationSkipsCountryFromCompanyInformation()
    var
        Customer: array[2] of Record Customer;
    begin
        // [FEATURE] [VAT- VIES Declaration Tax Auth]
        // [SCENARIO 219223] VAT VIES Decalrarion report doesn't show VAT entries with Country Code matching CompanyInformation."Country Code".
        Initialize();

        // [GIVEN] Two Customers "C1" and "C2" with Country Codes "CN1" and "CN2" respectively.
        LibrarySales.CreateCustomerWithVATRegNo(Customer[1]);
        LibrarySales.CreateCustomerWithVATRegNo(Customer[2]);

        // [GIVEN] "CN1" and "CN2" are set as "EU Country/Region".
        UpdateEUCountryRegion(Customer[1]."Country/Region Code");
        UpdateEUCountryRegion(Customer[2]."Country/Region Code");

        // [GIVEN] "CN2" is set as CompanyInformation."Country/Region Code".
        UpdateCompanyInfoCountryRegion(Customer[2]."Country/Region Code");

        // [GIVEN] Mock two VAT entries for "C1" and "C2".
        MockVATEntryForCustomer(Customer[1]);
        MockVATEntryForCustomer(Customer[2]);

        // [WHEN] VAT VIES Declaration report "VIES" executed for all Customers entries.
        VATVIESDeclarationTaxReport('', false);

        // [THEN] "VIES" results contains entries for "CN1" and contains no entries for "CN2".
        VerifyCountryCodeInVATVIES(Customer[1]."Country/Region Code", Customer[2]."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESDeclDiskFiltering()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        Customer: array[3] of Record Customer;
        FileName: Text[1024];
        Index: Integer;
    begin
        // [FEATURE] [VAT- VIES Declaration Disk]
        // [SCENARIO 257109] Report "VAT- VIES Declaration Disk" respects "Bill-to/Pay-to No." and "Country/Region Code" filters
        Initialize();

        LibraryERM.SetBillToSellToVATCalc(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");

        // [GIVEN] Customers "C1", "C2" and "C3", having Country/Region Codes "CR1", "CR2" and "CR3" respectfully
        // [GIVEN] VAT Entries "V1", "V2" and "V3" for "C1", "C2" and "C3" respectfully, all having "Posting Date" = 01/02/2018
        for Index := 1 to ArrayLen(Customer) do begin
            LibrarySales.CreateCustomerWithVATRegNo(Customer[Index]);
            UpdateEUCountryRegion(Customer[Index]."Country/Region Code");
            MockVATEntryForCustomer(Customer[Index]);
        end;

        VATEntry.SetFilter("Bill-to/Pay-to No.", '%1|%2', Customer[1]."No.", Customer[2]."No.");
        VATEntry.SetFilter("Country/Region Code", Customer[2]."Country/Region Code");
        VATEntry.SetRange("Posting Date", WorkDate());
        VATEntry.SetRange("VAT Reporting Date", WorkDate());
        Commit();

        // [WHEN] Run report "VAT- VIES Declaration Disk" with "Bill-to/Pay-to No." = "C1"|"C2", "Country/Region Code" = "CR2" and Posting Date = 01/02/2018
        RunVATVIESDeclarationDisk(VATEntry, FileName);

        // [THEN] VAT Entry "V1" has "Internal Ref. No." = <blank>
        VerifyInternalRefNoVATEntry(Customer[1]."No.", '');

        // [THEN] VAT Entry "V2" has "Internal Ref. No." = INCSTR(FORMAT(01/02/2018,4,2) + '000000') = INCSTR('0102' + '000000') = '0102000001'
        VerifyInternalRefNoVATEntry(Customer[2]."No.", IncStr(Format(WorkDate(), 4, 2) + '000000'));

        // [THEN] VAT Entry "V3" has "Internal Ref. No." = <blank>
        VerifyInternalRefNoVATEntry(Customer[3]."No.", '');

        FileManagement.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('RHDetailTrialBalance')]
    [Scope('OnPrem')]
    procedure DetailTrialBalanceExtDocNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Detail Trial Balance]
        // [SCENARIO 262729] External Document No. is included in report Detail Trial Balance.

        // [GIVEN] Create and post General Journal Line with External Document No.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("External Document No.", CopyStr(LibraryUtility.GenerateRandomXMLText(35), 1, 35));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Save Detail Trial Balance Report for the G/L Account Created.
        RunDetailTrialBalanceReport(GenJournalLine."Account No.", false, false, false, false, '');

        // [THEN] Verify External Document No. on Detail Trial Balance Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo_GLEntry', GenJournalLine."Document No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ExtDocNo_GLEntry', GenJournalLine."External Document No.")
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetDetailsExcel')]
    [Scope('OnPrem')]
    procedure FixedAssetDetailsPrintHeader()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Fixed Asset]
        // [SCENARIO 282740] Report "Fixed Asset - Details" prints header fields when "New Page per Asset" unchecked

        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Created Depreciation Book
        // [GIVEN] Created Fixed Asset
        // [GIVEN] Gen. Journal Line for Fixed Asset acquisition created and posted
        CreateAndPostFAGenJournalLine(GenJournalLine, GenJournalLine."FA Posting Type"::"Acquisition Cost");

        // [WHEN] Run Report "Fixed Asset - Details" with "New Page per Asset" unchecked
        FixedAssetDetailReport(GenJournalLine."Account No.", GenJournalLine."Depreciation Book Code", false, false);

        // [THEN] Report header fields are printed
        ValidateFixedAssetDetailsReportHeader(GenJournalLine."Depreciation Book Code");
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetDetailsExcel')]
    [Scope('OnPrem')]
    procedure FixedAssetDetailsPrintHeaderNewPagePerAsset()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Fixed Asset]
        // [SCENARIO 282740] Report "Fixed Asset - Details" prints header fields when "New Page per Asset" checked

        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Created Depreciation Book
        // [GIVEN] Created Fixed Asset
        // [GIVEN] Gen. Journal Line for Fixed Asset acquisition created and posted
        CreateAndPostFAGenJournalLine(GenJournalLine, GenJournalLine."FA Posting Type"::"Acquisition Cost");

        // [WHEN] Run Report "Fixed Asset - Details" with "New Page per Asset" checked
        FixedAssetDetailReport(GenJournalLine."Account No.", GenJournalLine."Depreciation Book Code", true, false);

        // [THEN] Report header fields are printed
        ValidateFixedAssetDetailsReportHeader(GenJournalLine."Depreciation Book Code");
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESDeclDiskSellToCustomerWithoutVATAndCountry()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        BillToCustomer: Record Customer;
        SellToCustomer: Record Customer;
        FileName: Text[1024];
    begin
        // [FEATURE] [VAT- VIES Declaration Disk]
        // [SCENARIO 300180] Export "VAT- VIES Declaration Disk" when Sell-To Customer does not have VAT Registration No. and Country/Region Code
        Initialize();

        // [GIVEN] "Bill-to/Sell-to VAT Calc." = "Sell-to/Buy-from No." in General Ledger Setup
        LibraryERM.SetBillToSellToVATCalc(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");

        // [GIVEN] Customer "SellCust" has Country/Region Code = 'BE' and VAT Registration No. = 'BE123456789'
        // [GIVEN] Customer "BillCust" without VAT Registration No. and Country/Region Code
        CreateCustomerWithSimpleBillToCust(SellToCustomer, BillToCustomer);

        // [GIVEN] Sales Invoice is posted with "SellCust" and "BillCust" as Sell-to Customer and Bill-to Customer respectively
        CreateAndPostSalesInvoice(SellToCustomer."No.");

        VATEntry.SetRange("Bill-to/Pay-to No.", BillToCustomer."No.");
        VATEntry.SetRange("Posting Date", WorkDate());
        VATEntry.SetRange("VAT Reporting Date", WorkDate());

        // [WHEN] Run report "VAT- VIES Declaration Disk" with "Bill-to/Pay-to No." = "BillCust"
        RunVATVIESDeclarationDisk(VATEntry, FileName);

        // [THEN] Country/Region Code is exported as 'BE' and VAT Registration No. as 'BE123456789'
        Assert.AreNotEqual(
          '', LibraryTextFileValidation.FindLineContainingValue(FileName, 27, 2, CopyStr(SellToCustomer."Country/Region Code", 1, 2)), '');
        Assert.AreNotEqual(
          '', LibraryTextFileValidation.FindLineContainingValue(FileName, 29, 10, CopyStr(SellToCustomer."VAT Registration No.", 1, 10)), '');

        FileManagement.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESDeclDiskSellToCustomerCheck()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        BillToCustomer: Record Customer;
        SellToCustomer: Record Customer;
        FileName: Text[1024];
    begin
        // [FEATURE] [VAT- VIES Declaration Disk]
        // [SCENARIO 300180] Report "VAT- VIES Declaration Disk" checks Sell-To Customer when "Sell-to/Buy-from No." is set on General Ledger Setup
        Initialize();

        // [GIVEN] "Bill-to/Sell-to VAT Calc." = "Sell-to/Buy-from No." in General Ledger Setup
        LibraryERM.SetBillToSellToVATCalc(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");

        // [GIVEN] Customer "SellCust" has Country/Region Code = 'BE' and VAT Registration No. = 'BE123456789'
        // [GIVEN] Customer "BillCust" without VAT Registration No. and Country/Region Code used as Bill-To Customer for "SellCust"
        CreateCustomerWithSimpleBillToCust(SellToCustomer, BillToCustomer);

        // [GIVEN] Sales Invoice is posted with "SellCust" and "BillCust" as Sell-to Customer and Bill-to Customer respectively
        CreateAndPostSalesInvoice(SellToCustomer."No.");

        // [GIVEN] Customer "SellCust" is updated with blank Country/Region Code
        SellToCustomer."Country/Region Code" := '';
        SellToCustomer.Modify();

        VATEntry.SetRange("Bill-to/Pay-to No.", BillToCustomer."No.");
        VATEntry.SetRange("Posting Date", WorkDate());
        VATEntry.SetRange("VAT Reporting Date", WorkDate());

        // [WHEN] Run report "VAT- VIES Declaration Disk" with "Bill-to/Pay-to No." = "BillCust"
        Commit();
        asserterror RunVATVIESDeclarationDisk(VATEntry, FileName);

        // [THEN] Error raised about Country/Region Code must have a value in "SellCust"
        Assert.ExpectedTestFieldError(SellToCustomer.FieldCaption("Country/Region Code"), '');
    end;

    [Test]
    [HandlerFunctions('RHDetailTrialBalanceExcel')]
    procedure DetailTrialBalance_PrintOnlyOnePerPage_False()
    var
        AccountNoFilter: Text[50];
    begin
        // [SCENARIO 357809] If PrintOnlyOnePerPage is False, there should not be page breakes between G/L Accounts
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] 2 G/L Accounts with posted GenJournalLine
        AccountNoFilter := StrSubstNo('%1|%2', CreateGLAccountWithEntry(), CreateGLAccountWithEntry());

        // [WHEN] Invoke Detail Trial Balance report for that 2 G/L Accounts only, PrintOnlyOnePerPage is no.
        LibraryVariableStorage.Enqueue(AccountNoFilter);
        LibraryVariableStorage.Enqueue(false);
        Commit();
        REPORT.Run(REPORT::"Detail Trial Balance");

        // [THEN] There should be only 1 worksheet in excel
        LibraryReportValidation.OpenExcelFile();
        Assert.AreEqual(1, LibraryReportValidation.CountWorksheets(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RHDetailTrialBalanceExcel')]
    procedure DetailTrialBalance_PrintOnlyOnePerPage_True()
    var
        AccountNoFilter: Text[50];
    begin
        // [SCENARIO 357809] If PrintOnlyOnePerPage is True, there should be page breakes between G/L Accounts
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] 2 G/L Accounts with posted GenJournalLine
        AccountNoFilter := StrSubstNo('%1|%2', CreateGLAccountWithEntry(), CreateGLAccountWithEntry());

        // [WHEN] Invoke Detail Trial Balance report for that 2 G/L Accounts only, PrintOnlyOnePerPage is yes.
        LibraryVariableStorage.Enqueue(AccountNoFilter);
        LibraryVariableStorage.Enqueue(true);
        Commit();
        REPORT.Run(REPORT::"Detail Trial Balance");

        // [THEN] There should be 2 worksheet in excel - one per each account
        LibraryReportValidation.OpenExcelFile();
        Assert.AreEqual(2, LibraryReportValidation.CountWorksheets(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESDeclDiskPostdateFiltering()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        FileName: Text[1024];
    begin
        // [FEATURE] [VAT- VIES Declaration Disk] [Date Filter]
        // [SCENARIO 387684] Report "VAT- VIES Declaration Disk" respects "Posting Date" filters
        Initialize();

        // [GIVEN] Customers "C1" and "C2", having Country/Region Codes "CR1" and "CR2" respectfully
        // [GIVEN] VAT Entries "V1" and "V2" for "C1" and "C2", with "Posting Date" = 01/02/2018 and 01/02/2017 respectfully
        LibraryERM.SetBillToSellToVATCalc(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");
        LibrarySales.CreateCustomerWithVATRegNo(Customer1);
        UpdateEUCountryRegion(Customer1."Country/Region Code");
        MockVATEntryWithPostingDateForCustomer(Customer1, WorkDate());
        LibrarySales.CreateCustomerWithVATRegNo(Customer2);
        UpdateEUCountryRegion(Customer2."Country/Region Code");
        MockVATEntryWithPostingDateForCustomer(Customer2, WorkDate() + 1);

        // [WHEN] Run report "VAT- VIES Declaration Disk" with "Bill-to/Pay-to No." = "C1"|"C2" and Posting Date = 01/02/2018
        VATEntry.SetFilter("Bill-to/Pay-to No.", '%1|%2', Customer1."No.", Customer2."No.");
        VATEntry.SetRange("Posting Date", WorkDate());
        VATEntry.SetRange("VAT Reporting Date", WorkDate());
        Commit();
        RunVATVIESDeclarationDisk(VATEntry, FileName);

        // [THEN] VAT Entry "V1" has "Internal Ref. No." = INCSTR(FORMAT(01/02/2018,4,2) + '000000') = INCSTR('0102' + '000000') = '0102000001'
        VerifyInternalRefNoVATEntry(Customer1."No.", IncStr(Format(WorkDate(), 4, 2) + '000000'));

        // [THEN] VAT Entry "V2" has "Internal Ref. No." = <blank>
        VerifyInternalRefNoVATEntry(Customer2."No.", '');

        FileManagement.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESDeclDiskVATtAdjmtSellToCustomerInGLForBillToCust()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
        CustomerBillTo: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntryPmt: Record "Cust. Ledger Entry";
        FileName: Text[1024];
    begin
        // [FEATURE] [VAT- VIES Declaration Disk] [VAT Adjustment]
        // [SCENARIO 406070] "VAT- VIES Declaration Disk" with "Sell-to/Buy-from No." in G/l Setup and VAT Adjustment for Bill-to Customer
        Initialize();

        // [GIVEN] "Bill-to/Sell-to VAT Calc." = "Sell-to/Buy-from No." in G/L Setup
        LibraryERM.SetBillToSellToVATCalc(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);

        // [GIVEN] Customer "Cust1", Bill-to Customer = "Cust2" with Payment Discount Terms
        CreateVATPostingSetup(VATPostingSetup);
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        UpdateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        UpdateEUCountryRegion(Customer."Country/Region Code");
        LibrarySales.CreateCustomerWithVATRegNo(CustomerBillTo);
        UpdateCustomer(CustomerBillTo, VATPostingSetup."VAT Bus. Posting Group");
        UpdateEUCountryRegion(CustomerBillTo."Country/Region Code");
        Customer.Validate("Bill-to Customer No.", CustomerBillTo."No.");
        Customer.Modify(true);

        // [GIVEN] Sales Invoice is posted on 01-01-21 with Amount = 1000, Pmt. Discount Possible = 20, Pmt. Discount Date = 05-01-21
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          CreatePostSalesInvoice(Customer."No.", VATPostingSetup."VAT Prod. Posting Group"));
        CustLedgerEntry.CalcFields(Amount);

        // [GIVEN] Payment is posted 05-01-21 and applied on 03-01-21 with Amount = -980
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntryPmt, CustLedgerEntryPmt."Document Type"::Payment,
          CreatePostPayment(CustomerBillTo."No.", -CustLedgerEntry.Amount + CustLedgerEntry."Remaining Pmt. Disc. Possible"));
        PostCustomerApplicationOnDate(CustLedgerEntry, CustLedgerEntryPmt, CustLedgerEntry."Pmt. Discount Date" - 1);

        // [WHEN] Run report "VAT- VIES Declaration Disk"
        VATEntry.SetRange("Bill-to/Pay-to No.", CustomerBillTo."No.");
        VATEntry.SetRange("Posting Date", CustLedgerEntry."Posting Date", CustLedgerEntry."Pmt. Discount Date");
        VATEntry.SetRange("VAT Reporting Date", CustLedgerEntry."Posting Date", CustLedgerEntry."Pmt. Discount Date");
        RunVATVIESDeclarationDisk(VATEntry, FileName);

        // [THEN] Value with amount 980 is exported in VAT VIES Declaration file at possion 41 with length 15
        CustLedgerEntry.CalcFields(Amount);
        Assert.AreEqual(
          FormatZerolValue(Format(Round(CustLedgerEntry.Amount - CustLedgerEntry."Original Pmt. Disc. Possible", 1, '<')), 15),
          LibraryTextFileValidation.ReadValueFromLine(FileName, 3, 41, 15), '');

        FileManagement.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESDeclDiskVATtAdjmtSellToCustomerInGLForSellToCust()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntryPmt: Record "Cust. Ledger Entry";
        FileName: Text[1024];
    begin
        // [FEATURE] [VAT- VIES Declaration Disk]

        // [SCENARIO 406070] "VAT- VIES Declaration Disk" with "Sell-to/Buy-from No." in G/l Setup and VAT Adjustment for Bill-to Customer
        Initialize();

        // [GIVEN] "Bill-to/Sell-to VAT Calc." = "Sell-to/Buy-from No." in G/L Setup
        LibraryERM.SetBillToSellToVATCalc(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);

        // [GIVEN] Customer with Payment Discount Terms
        CreateVATPostingSetup(VATPostingSetup);
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        UpdateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        UpdateEUCountryRegion(Customer."Country/Region Code");

        // [GIVEN] Sales Invoice is posted on 01-01-21 with Amount = 1000, Pmt. Discount Possible = 20, Pmt. Discount Date = 05-01-21
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          CreatePostSalesInvoice(Customer."No.", VATPostingSetup."VAT Prod. Posting Group"));
        CustLedgerEntry.CalcFields(Amount);

        // [GIVEN] Payment is posted 05-01-21 and applied on 03-01-21 with Amount = -980
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntryPmt, CustLedgerEntryPmt."Document Type"::Payment,
          CreatePostPayment(Customer."No.", -CustLedgerEntry.Amount + CustLedgerEntry."Remaining Pmt. Disc. Possible"));
        PostCustomerApplicationOnDate(CustLedgerEntry, CustLedgerEntryPmt, CustLedgerEntry."Pmt. Discount Date" - 1);

        // [WHEN] Run report "VAT- VIES Declaration Disk"
        VATEntry.SetRange("Bill-to/Pay-to No.", Customer."No.");
        VATEntry.SetRange("Posting Date", CustLedgerEntry."Posting Date", CustLedgerEntry."Pmt. Discount Date");
        VATEntry.SetRange("VAT Reporting Date", CustLedgerEntry."Posting Date", CustLedgerEntry."Pmt. Discount Date");
        RunVATVIESDeclarationDisk(VATEntry, FileName);

        // [THEN] Value with amount 980 is exported in VAT VIES Declaration file at possion 41 with length 15
        CustLedgerEntry.CalcFields(Amount);
        Assert.AreEqual(
          FormatZerolValue(Format(Round(CustLedgerEntry.Amount - CustLedgerEntry."Original Pmt. Disc. Possible", 1, '<')), 15),
          LibraryTextFileValidation.ReadValueFromLine(FileName, 3, 41, 15), '');

        FileManagement.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CloseIncomeStatementRequestPageHandler')]
    procedure CloseIncomeStatementWithNotClosingSourceCurrencyAmount()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        CurrencyCode: Code[10];
        DocNo: Code[20];
    begin
        // [SCENARIO 563552] G/L Currency revaluation is not closing of source currency amounts.
        Initialize();

        // [GIVEN] Previous Fiscal Year Closed, New Fiscal Year Created and Closed
        LibraryFiscalYear.CloseFiscalYear();
        ExecuteUIHandler();
        LibraryFiscalYear.CreateFiscalYear();
        LibraryFiscalYear.CloseFiscalYear();

        // [GIVEN] Created New Currency Code
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Created 2 New  GL Account
        GLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        GLAccount.Modify(true);
        GLAccount2.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        GLAccount2.Validate("Income/Balance", GLAccount2."Income/Balance"::"Income Statement");
        GLAccount2.Modify(true);

        // [GIVEN] Created GenJournalTemplate And GenJournalBatch
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
        GenJournalBatch.Modify(true);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        // [GIVEN] Created And Post General journal Lines For 2 New Created GL Accounts
        CreateAndPostGenJnlLineWithCurrencyCode(GenJournalLine, GLAccount."No.", GLAccount2."No.", CurrencyCode, LibraryFiscalYear.GetLastPostingDate(true), GenJournalBatch);

        // [WHEN] Run "Close Income Statement" for Generating General Journals
        DocNo := LibraryRandom.RandText(10);
        CloseIncomeStatementWithoutBusinessUnit(GenJournalLine, DocNo);

        // [WHEN] Post General Journal Lines That Created From "Close Income Statement"
        FindGenJournalLine(GenJournalLine2, GenJournalBatch, DocNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);

        // [THEN] New Created Both GL Account "Source Currency Balance" Should be Zero
        GLAccount.CalcFields("Source Currency Balance");
        GLAccount2.CalcFields("Source Currency Balance");
        Assert.AreEqual(0, GLAccount."Source Currency Balance", SourceBalanceErr);
        Assert.AreEqual(0, GLAccount2."Source Currency Balance", SourceBalanceErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure SourceCurrencyAmountHasValueWhenClosingIncomeStatementAfterReversal()
    var
        AccountingPeriod: Record "Accounting Period";
        Currency: array[3] of Record Currency;
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GLRegister: Record "G/L Register";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        ReversalEntry: Record "Reversal Entry";
        CloseIncomeStatement: Report "Close Income Statement";
    begin
        // [SCENARIO 580078] G/L Currency revaluation is not closing of source currency amounts.
        Initialize();

        // [GIVEN] Create three Currencies with Exchange Rates.
        Currency[1].Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDecInDecimalRange(0.85, 0.85, 2), LibraryRandom.RandDecInDecimalRange(0.85, 0.85, 2)));
        Currency[2].Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDecInDecimalRange(0.75, 0.75, 2), LibraryRandom.RandDecInDecimalRange(0.75, 0.75, 2)));
        Currency[3].Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDecInDecimalRange(0.95, 0.95, 2), LibraryRandom.RandDecInDecimalRange(0.95, 0.95, 2)));

        // [GIVEN] Create LCY Code.
        LibraryERM.SetLCYCode(Currency[1].Code);

        // [GIVEN] Additional Reporting Currency is set in General Ledger Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := Currency[2].Code;
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create an Item with Unit Price.]
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        Item.Modify(true);

        // [GIVEN] Create and Post Sales Invoices for Customer in different Currencies.
        CreateAndPostSalesInvoice(Customer."No.", Item."No.", Currency[1].Code);
        CreateAndPostSalesInvoice(Customer."No.", Item."No.", Currency[2].Code);
        CreateAndPostSalesInvoice(Customer."No.", Item."No.", Currency[3].Code);

        // [GIVEN] Find Genral Posting Setup for Customer and Item.
        GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");

        // [GIVEN] Close Fiscal Year.
        LibraryFiscalYear.CloseFiscalYear();

        // [GIVEN] Create a G/L Account for Income Statement.
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);

        // [GIVEN] Create General Journal Line for G/L Account.
        CreateGeneralJournalLine(
            GenJournalLine,
            GenJournalLine."Account Type"::"G/L Account",
            GLAccount."No.",
            LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Modify(true);

        // [GIVEN] Run "Close Income Statement" for G/L Account.
        LibraryERM.FindGLAccount(GLAccount);
        CloseIncomeStatement.InitializeRequestTest(AccountingPeriod.GetFiscalYearEndDate(WorkDate()), GenJournalLine, GLAccount, true);
        CloseIncomeStatement.UseRequestPage(false);
        CloseIncomeStatement.Run();

        // [GIVEN] Find the Last GL Register Entry and reverse it.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");

        // [GIVEN] Remove the Additional Reporting Currency in General Ledger Setup.
        GeneralLedgerSetup.Validate("Additional Reporting Currency", '');
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Close Income Statement again for G/L Account.
        CloseIncomeStatement.InitializeRequestTest(AccountingPeriod.GetFiscalYearEndDate(WorkDate()), GenJournalLine, GLAccount, true);
        CloseIncomeStatement.UseRequestPage(false);
        CloseIncomeStatement.Run();

        // [WHEN] Post General Journal Line created by Close Income Statement.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Source Currency Amount in G/L Entry is not zero.
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("Source Currency Code", Currency[2].Code);
        GLEntry.SetRange("G/L Account No.", GeneralPostingSetup."Sales Account");
        GLEntry.FindLast();
        Assert.AreNotEqual(0, GLEntry."Source Currency Amount", SourceCurrencyCodeErr);
    end;

    [Test]
    [HandlerFunctions('RHReconcileCustandVendAccs')]
    procedure ReconcileCustVendAccounts_MultiplePostingGroups()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CustomerPostingGroup: array[2] of Record "Customer Posting Group";
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: array[3] of Record "G/L Account";
        ReconcileCustAndVendAccs: Report "Reconcile Cust. and Vend. Accs";
        Amount1, Amount2 : Decimal;
        WorkdateTxt: Text[30];
    begin
        // [SCENARIO 601857] Report Reconcile Customer and Vendor Accounts shows wrong amounts when multiple posting groups are used
        Initialize();

        // [GIVEN] Enable Allow Multiple Posting Groups
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Allow Multiple Posting Groups", true);
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] Create two Customer Posting Groups with different Receivables Accounts
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup[1]);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup[2]);
        LibrarySales.CreateAltCustomerPostingGroup(CustomerPostingGroup[1].Code, CustomerPostingGroup[2].Code);

        // [GIVEN] Create a customer with one of the posting groups and enable multiple posting groups
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Customer Posting Group", CustomerPostingGroup[1].Code);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify(true);

        // [GIVEN] Create General Journal Batch
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);

        // [GIVEN] Post payment 1 with first posting group
        Amount1 := -1 * LibraryRandom.RandDec(1000, 2);
        LibraryERM.CreateGLAccount(GLAccount[1]);
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer,
            Customer."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account",
            GLAccount[1]."No.",
            Amount1);
        GenJournalLine.Validate("Posting Group", CustomerPostingGroup[1].Code);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Post payment 2 with second posting group
        Amount2 := -1 * LibraryRandom.RandDec(2000, 2);
        LibraryERM.CreateGLAccount(GLAccount[2]);
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer,
            Customer."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account",
            GLAccount[2]."No.",
            Amount2);
        GenJournalLine.Validate("Posting Group", CustomerPostingGroup[2].Code);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run the Reconcile Cust. And Vend. Accounts report with DateFilter as Workdate
        WorkdateTxt := Format(WorkDate());
        Clear(ReconcileCustAndVendAccs);
        GLAccount[3].SetRange("Date Filter", WorkDate());
        GLAccount[3].FindFirst();
        ReconcileCustAndVendAccs.SetTableView(GLAccount[3]);
        Commit();
        ReconcileCustAndVendAccs.Run();

        // [THEN] Verify: Amounts are distributed to correct G/L accounts
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_GLAccount', CustomerPostingGroup[1]."Receivables Account");
        LibraryReportDataset.AssertElementWithValueExists('No_GLAccount', CustomerPostingGroup[2]."Receivables Account");
        LibraryReportDataset.AssertElementWithValueExists('Amount', Amount1);
        LibraryReportDataset.AssertElementWithValueExists('Amount', Amount2);
    end;

    [Test]
    [HandlerFunctions('AuditTrailReportRequestPageHandler')]
    procedure VerifyAuditTrailReportShowsGLEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegister: Record "G/L Register";
    begin
        // [SCENARIO 565665] Verify Audit Trail report dataset contains G/L Entries.
        Initialize();

        // [GIVEN] Create and Post General Journal Line.
        CreateAndPostGenLine(GenJournalLine);

        // [GIVEN] Find "G/L Register".
        GLRegister.FindLast();

        // [GIVEN] Save the transaction.
        Commit();

        // [WHEN] Run Audit Trail report.
        RunAuditTrailReport(GLRegister."No.");

        // [THEN] Verify Audit Trail report dataset contains  G/L Entry.
        VerifyAuditTrailReport(GenJournalLine, GLRegister);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryReportValidation: Codeunit "Library - Report Validation";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Financial Reports");

        // Lazy Setup.
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Financial Reports");

        LibraryERMCountryData.UpdateGenJournalTemplate();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Financial Reports");
    end;

    local procedure MockVATEntryWithPostingDateForCustomer(Customer: Record Customer; PostingDate: Date)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Posting Date" := PostingDate;
        VATEntry."VAT Reporting Date" := PostingDate;
        VATEntry."Bill-to/Pay-to No." := Customer."No.";
        VATEntry."VAT Registration No." := Customer."VAT Registration No.";
        VATEntry."Country/Region Code" := Customer."Country/Region Code";
        VATEntry.Base := LibraryRandom.RandDecInRange(10, 20, 2);
        VATEntry.Insert();
    end;

    local procedure CreateAndPostGenLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure BankAccDetailTrialBalReport(BalanceAccountNo: Code[20]; ExcludeAccBalanceOnly: Boolean; PrintReversedEntries: Boolean)
    var
        BankAccount: Record "Bank Account";
        BankAccDetailTrialBal: Report "Bank Acc. - Detail Trial Bal.";
    begin
        Clear(BankAccDetailTrialBal);
        BankAccount.SetRange("No.", BalanceAccountNo);
        BankAccDetailTrialBal.SetTableView(BankAccount);
        BankAccDetailTrialBal.InitializeRequest(false, ExcludeAccBalanceOnly, PrintReversedEntries);
        Commit();
        BankAccDetailTrialBal.Run();
    end;

    local procedure BankAccTrialReportDateFilter(BalanceAccountNo: Code[20]; ExcludeAccBalanceOnly: Boolean; PrintReversedEntries: Boolean; PostingDate: Date)
    var
        BankAccount: Record "Bank Account";
        BankAccDetailTrialBal: Report "Bank Acc. - Detail Trial Bal.";
    begin
        Clear(BankAccDetailTrialBal);
        BankAccount.SetRange("No.", BalanceAccountNo);

        // Using 1 and 2 to set Date Filter for two consecutive months.
        BankAccount.SetRange("Date Filter", CalcDate('<1M>', PostingDate), CalcDate('<2M>', PostingDate));
        BankAccDetailTrialBal.SetTableView(BankAccount);
        BankAccDetailTrialBal.InitializeRequest(false, ExcludeAccBalanceOnly, PrintReversedEntries);
        Commit();
        BankAccDetailTrialBal.Run();
    end;

    local procedure BankAccRecSum(BankAccReconciliation: Record "Bank Acc. Reconciliation") "Sum": Decimal
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindSet();
        repeat
            Sum += BankAccReconciliationLine."Statement Amount";
        until BankAccReconciliationLine.Next() = 0;
    end;

    local procedure CreateAndPostGenLineAndRunTrialBalance(var GenJournalLine: Record "Gen. Journal Line"; NoOfBlankLines: Integer)
    var
        GLAccount: Record "G/L Account";
    begin
        Initialize();
        CreateAndPostGenLine(GenJournalLine);

        GLAccount.Get(GenJournalLine."Account No.");
        GLAccount."No. of Blank Lines" := NoOfBlankLines;
        GLAccount.Modify();

        TrialBalanceReport(GenJournalLine."Account No.");

        // Verify: Verify Trial Balance Report.
        LibraryReportDataset.LoadDataSetFile();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
    begin
        // Create Customer with Application Method Apply to Oldest and attach Payment Terms to it.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Modify(true);
        UpdateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        exit(Customer."No.");
    end;

    local procedure UpdateCustomer(var Customer: Record Customer; VATBusPostGr: Code[20])
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostGr);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithSimpleBillToCust(var SellToCustomer: Record Customer; var BillToCustomer: Record Customer)
    begin
        LibrarySales.CreateCustomerWithVATRegNo(SellToCustomer);
        UpdateEUCountryRegion(SellToCustomer."Country/Region Code");
        LibrarySales.CreateCustomer(BillToCustomer);
        SellToCustomer.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SellToCustomer.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", AccountType, AccountNo, Amount);
    end;

    local procedure CreateIncomeStatementGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var Date: Record Date)
    var
        GLAccount: Record "G/L Account";
    begin
        Date.SetRange("Period Type", Date."Period Type"::Month);
        Date.SetRange("Period Start", LibraryFiscalYear.GetLastPostingDate(true));
        Date.FindFirst();

        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", Date."Period Start");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateUpdateAndPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        Customer: Record Customer;
    begin
        // Create Customer and Create and post General Journal Line and use Random Number Generator for Amount.
        LibrarySales.CreateCustomer(Customer);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", -LibraryRandom.RandDec(5, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", CreateBankAccount());
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateSuggestedBankReconc(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20])
    begin
        CreateBankReconciliation(BankAccReconciliation, BankAccountNo);
        SuggestBankRecLines(BankAccReconciliation);

        // Balance Bank Account Reconciliation.
        BankAccReconciliation.Validate(
          "Statement Ending Balance", BankAccReconciliation."Balance Last Statement" + BankAccRecSum(BankAccReconciliation));
        BankAccReconciliation.Modify(true);
    end;

    local procedure CreateBankReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20])
    begin
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo,
          BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Statement Date", WorkDate());
        BankAccReconciliation.Modify(true);
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccountPostingGroup.FindFirst();
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Validate("Last Statement No.", Format(LibraryRandom.RandInt(10)));
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreatePostSalesInvoice(CustomerNo: Code[20]; VATProdPostGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostGroup);
        GLAccount.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        SalesLine.Modify(true);
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostFAGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; FAPostingType: Enum "Gen. Journal Line FA Posting Type")
    var
        DepreciationBookCode: Code[10];
    begin
        // Create General Journal Line for Fixed Asset and Post with random values.
        DepreciationBookCode := CreateDepreciationBook();
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"Fixed Asset",
          CreateFixedAsset(DepreciationBookCode), LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostPayment(CustomerNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateFixedAsset(DepreciationBookCode: Code[10]): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
    begin
        FAPostingGroup.FindFirst();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Modify(true);
        exit(FixedAsset."No.");
    end;

    local procedure CreateDepreciationBook(): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Maintenance", true);
        DepreciationBook.Modify(true);
        exit(DepreciationBook.Code);
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", Currency."Residual Gains Account");
        Currency.Validate("Realized G/L Gains Account", GLAccount."No.");
        Currency.Validate("Realized G/L Losses Account", Currency."Realized G/L Gains Account");
        Currency.Modify(true);

        // Create Currency Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CalculateAdditionalCurrBase(VATRegistrationNo: Text[20]) TotalAdditionalCurrencyBase: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, VATRegistrationNo);
        repeat
            TotalAdditionalCurrencyBase += VATEntry."Additional-Currency Base";
        until VATEntry.Next() = 0;
    end;

    local procedure CalculateBase(VATRegistrationNo: Text[20]) TotalBase: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, VATRegistrationNo);
        repeat
            TotalBase += VATEntry.Base;
        until VATEntry.Next() = 0;
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]) DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure ChartOfAccountsReport(No: Code[20])
    var
        GLAccount: Record "G/L Account";
        ChartOfAccounts: Report "Chart of Accounts";
    begin
        Clear(ChartOfAccounts);
        GLAccount.SetRange("No.", No);
        ChartOfAccounts.SetTableView(GLAccount);
        Commit();
        ChartOfAccounts.Run();
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(10, 20));
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);
    end;

    local procedure FindDetailedCustLedgerEntryAmount(var GLAccountNo: Code[20]; CustomerPostingGroupCode: Code[20]): Decimal
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustAccAmount: Decimal;
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        GLAccountNo := CustomerPostingGroup."Receivables Account";
        Customer.SetCurrentKey("Customer Posting Group");
        Customer.SetRange("Customer Posting Group", CustomerPostingGroupCode);
        if Customer.FindSet() then
            repeat
                DetailedCustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
                DetailedCustLedgEntry.SetRange("Customer No.", Customer."No.");
                DetailedCustLedgEntry.SetRange("Posting Date", WorkDate());
                DetailedCustLedgEntry.CalcSums("Amount (LCY)");
                CustAccAmount := CustAccAmount + DetailedCustLedgEntry."Amount (LCY)";
            until Customer.Next() = 0;
        exit(CustAccAmount);
    end;


    local procedure GLDocumentNosReport(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        GLDocumentNos: Report "G/L Document Nos.";
    begin
        Clear(GLDocumentNos);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLDocumentNos.SetTableView(GLEntry);
        GLDocumentNos.Run();
    end;

    local procedure GLRegisterReport(RegisterNo: Integer)
    var
        GLRegister: Record "G/L Register";
        GLRegisterReport: Report "G/L Register";
    begin
        Clear(GLRegisterReport);
        GLRegister.SetRange("No.", RegisterNo);
        GLRegisterReport.SetTableView(GLRegister);
        GLRegisterReport.Run();
    end;

    local procedure TrialBalanceReport(GLAccountNoFilter: Code[250])
    var
        GLAccount: Record "G/L Account";
        TrialBalance: Report "Trial Balance";
    begin
        Clear(TrialBalance);
        GLAccount.SetFilter("No.", GLAccountNoFilter);
        TrialBalance.SetTableView(GLAccount);
        Commit();
        TrialBalance.Run();
    end;

    local procedure TrialBalanceBudgetReport(GLAccountNo: Code[20]; PostingDate: Date)
    var
        GLAccount: Record "G/L Account";
        TrialBalanceBudget: Report "Trial Balance/Budget";
    begin
        Clear(TrialBalanceBudget);
        GLAccount.SetRange("No.", GLAccountNo);
        GLAccount.SetFilter("Date Filter", '%1..%2', PostingDate, PostingDate);
        TrialBalanceBudget.SetTableView(GLAccount);
        Commit();
        TrialBalanceBudget.Run();
    end;

    local procedure CreateGLBudgetEntry(GLAccountNo: Code[20]; BudgetDate: Date): Decimal
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Take Random Amount for GL Budget Entry.
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, BudgetDate, GLAccountNo, GLBudgetName.Name);
        GLBudgetEntry.Validate(Amount, LibraryRandom.RandInt(100));
        GLBudgetEntry.Modify(true);
        exit(GLBudgetEntry.Amount);
    end;

    local procedure CreateGLAccountWithConsolidateAccount()
    var
        GLAccount: Record "G/L Account";
        LibraryUTUtility: Codeunit "Library UT Utility";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Consol. Debit Acc.", LibraryUTUtility.GetNewCode());
        GLAccount.Validate("Consol. Credit Acc.", LibraryUTUtility.GetNewCode());
        GLAccount.Modify(true);
    end;

    local procedure MockVATEntryForCustomer(Customer: Record Customer)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Posting Date" := WorkDate();
        VATEntry."VAT Reporting Date" := WorkDate();
        VATEntry."Bill-to/Pay-to No." := Customer."No.";
        VATEntry."VAT Registration No." := Customer."VAT Registration No.";
        VATEntry."Country/Region Code" := Customer."Country/Region Code";
        VATEntry.Base := LibraryRandom.RandDecInRange(10, 20, 2);
        VATEntry.Insert();
    end;

    local procedure FindGLEntry(DocumentNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindLast();
        exit(GLEntry."Transaction No.");
    end;

    local procedure FixedAssetDetailReport(No: Code[20]; DepreciationBookCode: Code[10]; PrintOnlyOnePerPage: Boolean; IncludeReverseEntries: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetDetails: Report "Fixed Asset - Details";
    begin
        Clear(FixedAssetDetails);
        FixedAssetDetails.InitializeRequest(DepreciationBookCode, PrintOnlyOnePerPage, IncludeReverseEntries);
        FixedAsset.SetRange("No.", No);
        FixedAssetDetails.SetTableView(FixedAsset);
        Commit();
        FixedAssetDetails.Run();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; VATRegistrationNo: Text[20])
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.SetRange("Posting Date", WorkDate());
        VATEntry.SetFilter("VAT Registration No.", VATRegistrationNo);
        VATEntry.FindSet();
    end;

    local procedure FindCustomerVATRegistration(var Customer: Record Customer)
    var
        CountryRegion: Record "Country/Region";
    begin
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        CountryRegion.Get(Customer."Country/Region Code");
        CountryRegion.Validate("EU Country/Region Code", CountryRegion.Code);
        CountryRegion.Modify(true);
    end;

    local procedure FormatZerolValue(Str: Text; Length: Integer): Text
    begin
        exit(
          PadStr('', Length - StrLen(Str), '0') + Str);
    end;

    local procedure PostCheck(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Find General Journal Template and Batch for posting checks.
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.FindFirst();

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("No. Series", '');
        GenJournalBatch.Modify(true);

        // Generate General Journal line.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"Bank Account",
          CreateBankAccount(), LibraryRandom.RandDec(1000, 2));
        GenJournalLine.Validate(
          "Document No.", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", CreateBankAccount());
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Manual Check");
        GenJournalLine.Modify(true);

        // Post the check
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostCustomerApplicationOnDate(var CustLedgerEntry: Record "Cust. Ledger Entry"; var CustLedgerEntryPmt: Record "Cust. Ledger Entry"; ApplicationDate: Date)
    var
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
    begin
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntryPmt);
        ApplyUnapplyParameters."Document No." := CustLedgerEntryPmt."Document No.";
        ApplyUnapplyParameters."Posting Date" := ApplicationDate;
        CustEntryApplyPostedEntries.Apply(CustLedgerEntryPmt, ApplyUnapplyParameters);
    end;

    local procedure PostGenJournalLineAndReversTransaction(var GenJournalLine: Record "Gen. Journal Line")
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(FindGLEntry(GenJournalLine."Document No."));
    end;

    local procedure RunVATVIESDeclarationDisk(var VATEntry: Record "VAT Entry"; var FileName: Text[1024])
    var
        VATVIESDeclarationDisk: Report "VAT- VIES Declaration Disk";
    begin
        Clear(VATVIESDeclarationDisk);
        VATVIESDeclarationDisk.InitializeRequest(true);
        VATVIESDeclarationDisk.SetTableView(VATEntry);
        VATVIESDeclarationDisk.RunModal();
        FileName := VATVIESDeclarationDisk.GetFileName();
    end;

    local procedure RunDetailTrialBalanceReport(No: Code[20]; ExcludeGLBalanceOnly: Boolean; PrintClosingEntry: Boolean; PrintReverseEnteries: Boolean; PrintOnlyCorrections: Boolean; DateFilter: Text[30])
    begin
        LibraryVariableStorage.Enqueue(No);
        LibraryVariableStorage.Enqueue(ExcludeGLBalanceOnly);
        LibraryVariableStorage.Enqueue(PrintClosingEntry);
        LibraryVariableStorage.Enqueue(PrintReverseEnteries);
        LibraryVariableStorage.Enqueue(PrintOnlyCorrections);
        LibraryVariableStorage.Enqueue(DateFilter);
        Commit();
        REPORT.Run(REPORT::"Detail Trial Balance");
    end;

    local procedure RunCloseIncomeStatementReport(GenJournalLine: Record "Gen. Journal Line"; EndDate: Date; CallUserRequestPage: Boolean)
    var
        GLAccount: Record "G/L Account";
        CloseIncomeStatement: Report "Close Income Statement";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        CloseIncomeStatement.InitializeRequestTest(EndDate, GenJournalLine, GLAccount, true);
        CloseIncomeStatement.UseRequestPage(CallUserRequestPage);
        CloseIncomeStatement.Run();
    end;

    local procedure ReverseFALedgerEntry(DocumentNo: Code[20])
    var
        FALedgerEntry: Record "FA Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        FALedgerEntry.SetRange("Document No.", DocumentNo);
        FALedgerEntry.FindFirst();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(FALedgerEntry."Transaction No.");
    end;

    local procedure ReverseMaintenanceLedgerEntry(DocumentNo: Code[20])
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        MaintenanceLedgerEntry.SetRange("Document No.", DocumentNo);
        MaintenanceLedgerEntry.FindFirst();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(MaintenanceLedgerEntry."Transaction No.");
    end;

    local procedure RunMaintenanceDetailsReport(No: Code[20]; DepreciationBookCode: Code[10]; PrintReverseEntries: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        MaintenanceDetails: Report "Maintenance - Details";
    begin
        Clear(MaintenanceDetails);
        MaintenanceDetails.InitializeRequest(DepreciationBookCode, false, PrintReverseEntries);
        FixedAsset.SetRange("No.", No);
        MaintenanceDetails.SetTableView(FixedAsset);
        MaintenanceDetails.Run();
    end;

    local procedure SaveVerifyClosingTrialBalance(GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; AmountLCY: Boolean)
    var
        GLAccount: Record "G/L Account";
        ClosingTrialBalance: Report "Closing Trial Balance";
    begin
        // Exercise. Save Detail Trial Balance Report for the G/L Account Created.
        Clear(ClosingTrialBalance);
        GLAccount.SetRange("No.", GenJournalLine."Account No.", GenJournalLine."Bal. Account No.");
        ClosingTrialBalance.SetTableView(GLAccount);
        ClosingTrialBalance.InitializeRequest(GenJournalLine."Posting Date", AmountLCY);
        Commit();
        ClosingTrialBalance.Run();

        // Verify: Verify Amounts on Detail Trial Balance Report. Customized Formual required to Increase the Date.
        LibraryReportDataset.LoadDataSetFile();
        VerifyColumnValues(GenJournalLine."Account No.", Amount, 'FiscalYearBalance');
        VerifyColumnValues(GenJournalLine."Bal. Account No.", Amount, 'NegFiscalYearBalance');
        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists('PeriodText',
          StrSubstNo('Period: %1..%2', GenJournalLine."Posting Date",
            Format(CalcDate('<30D+11M>', GenJournalLine."Posting Date"))));
    end;


    local procedure SuggestBankRecLines(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccount: Record "Bank Account";
        SuggestBankAccReconLines: Report "Suggest Bank Acc. Recon. Lines";
    begin
        SuggestBankAccReconLines.SetStmt(BankAccReconciliation);
        SuggestBankAccReconLines.SetTableView(BankAccount);
        SuggestBankAccReconLines.InitializeRequest(WorkDate(), WorkDate(), false);
        SuggestBankAccReconLines.UseRequestPage(false);
        SuggestBankAccReconLines.Run();
    end;

    local procedure TrialBalanceReportDateFilter(No: Code[20]; ExcludeGLBalanceOnly: Boolean; PrintClosingEntry: Boolean; PrintReverseEnteries: Boolean; PrintOnlyCorrections: Boolean; PostingDate: Date)
    var
        GLAccount: Record "G/L Account";
        DetailTrialBalance: Report "Detail Trial Balance";
    begin
        Clear(DetailTrialBalance);
        GLAccount.SetRange("No.", No);

        // Using 1 and 2 to set Date Filter for two consecutive months.
        GLAccount.SetRange("Date Filter", CalcDate('<1M>', PostingDate), CalcDate('<2M>', PostingDate));
        DetailTrialBalance.SetTableView(GLAccount);
        DetailTrialBalance.InitializeRequest(false, ExcludeGLBalanceOnly, PrintClosingEntry, PrintReverseEnteries, PrintOnlyCorrections);
        Commit();
        DetailTrialBalance.Run();
    end;

    local procedure UpdateEUCountryRegion(CountryCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryCode);
        CountryRegion."EU Country/Region Code" := CountryRegion.Code;
        CountryRegion."VAT Scheme" := LibraryUtility.GenerateGUID();
        CountryRegion.Modify();
    end;

    local procedure UpdateCompanyInfoCountryRegion(CountryCode: Code[10])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Country/Region Code", CountryCode);
        CompanyInformation.Modify(true);
    end;

    local procedure VerifyColumnValues(AccountNo: Code[20]; ExpectedAmount: Decimal; FiscalYearBalance: Text[30])
    begin
        LibraryReportDataset.SetRange('No_GLAccount', AccountNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'No_GLAccount', AccountNo);
        LibraryReportDataset.AssertCurrentRowValueEquals(FiscalYearBalance, ExpectedAmount);
    end;

    local procedure VATVIESDeclarationTaxReport(CustomerVATRegistrationNo: Text[20]; IncludeAdditionalCurrAmount: Boolean)
    var
        VATVIESDeclarationTaxAuth: Report "VAT- VIES Declaration Tax Auth";
    begin
        Clear(VATVIESDeclarationTaxAuth);
        VATVIESDeclarationTaxAuth.InitializeRequest(IncludeAdditionalCurrAmount, WorkDate(), WorkDate(), CustomerVATRegistrationNo);
        Commit();
        VATVIESDeclarationTaxAuth.Run();
    end;

    local procedure VerifyChartOfAccountReport(GLAccount: Record "G/L Account")
    begin
        LibraryReportDataset.SetRange('G_L_Account___No__', GLAccount."No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'G_L_Account___No__', GLAccount."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('G_L_Account___Gen__Bus__Posting_Group_', GLAccount."Gen. Bus. Posting Group");
        LibraryReportDataset.AssertCurrentRowValueEquals('G_L_Account___Gen__Prod__Posting_Group_', GLAccount."Gen. Prod. Posting Group");
    end;

    local procedure VerifyGLDocumentNosReport(GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('GLEntry__Document_No__', GenJournalLine."Document No.");
        if LibraryReportDataset.GetNextRow() then begin
            LibraryReportDataset.AssertCurrentRowValueEquals('GLEntry__Document_No__', Format(GenJournalLine."Document No."));
            LibraryReportDataset.AssertCurrentRowValueEquals('GLEntry__Posting_Date_', Format(GenJournalLine."Posting Date"));
            LibraryReportDataset.AssertCurrentRowValueEquals('GLEntry__G_L_Account_No__', Format(GenJournalLine."Account No."))
        end else
            Error(ReportErr, GenJournalLine.FieldCaption("Document No."), GenJournalLine."Document No.");
    end;

    local procedure VerifyGLRegisterReport(GenJournalLine: Record "Gen. Journal Line"; GLRegisterNo: Integer)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('G_L_Register__No__', GLRegisterNo);
        LibraryReportDataset.SetRange('G_L_Entry__Document_No__', GenJournalLine."Document No.");
        if LibraryReportDataset.GetNextRow() then begin
            LibraryReportDataset.AssertCurrentRowValueEquals('G_L_Entry__Document_No__', GenJournalLine."Document No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('G_L_Entry__G_L_Account_No__', GenJournalLine."Account No.")
        end else
            Error(ReportErr, GenJournalLine.FieldCaption("Document No."), GenJournalLine."Document No.");
    end;

    local procedure VerifyMaintenanceLedgerEntryAmount(RowCaption: Text; RowValue: Text; Amount: Decimal)
    begin
        LibraryReportDataset.SetRange(RowCaption, RowValue);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, RowCaption, RowValue);
        LibraryReportDataset.AssertCurrentRowValueEquals('Maintenance_Ledger_Entry_Amount', Amount);
    end;

    local procedure VerifyTrialBalanceReport(GenJournalLine: Record "Gen. Journal Line")
    begin
        VerifyTrialBalanceReportField(GenJournalLine, 'G_L_Account___Net_Change_', GenJournalLine."Debit Amount");
    end;

    local procedure VerifyTrialBalanceReportWithPageBreakGroup(GenJournalLine1: Record "Gen. Journal Line"; GenJournalLine2: Record "Gen. Journal Line")
    begin
        VerifyTrialBalanceReportField(GenJournalLine1, 'PageGroupNo', 0);
        VerifyTrialBalanceReportField(GenJournalLine2, 'PageGroupNo', 1);
    end;

    local procedure VerifyTrialBalanceReportField(GenJournalLine: Record "Gen. Journal Line"; DataSetField: Text; Value: Decimal)
    begin
        LibraryReportDataset.SetRange('G_L_Account_No_', GenJournalLine."Account No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'G_L_Account_No_', GenJournalLine."Account No.");
        LibraryReportDataset.AssertCurrentRowValueEquals(DataSetField, Value);
    end;

    local procedure VerifyTrialBalanceReportWithBlankLines(NoOfBlankLines: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        ActualRowQty: Integer;
    begin
        CreateAndPostGenLineAndRunTrialBalance(GenJournalLine, NoOfBlankLines);

        LibraryReportDataset.SetRange('G_L_Account_No_', GenJournalLine."Account No.");
        ActualRowQty := 0;
        while LibraryReportDataset.GetNextRow() do
            ActualRowQty += 1;

        Assert.AreEqual(NoOfBlankLines, ActualRowQty - 1, BlankLinesQtyErr);
    end;

    local procedure VerifyTrialBalanceBudgetReport(GenJournalLine: Record "Gen. Journal Line"; BudgetAtDate: Decimal)
    begin
        LibraryReportDataset.SetRange('G_L_Account_No_', GenJournalLine."Account No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'G_L_Account_No_', GenJournalLine."Account No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('G_L_Account___Net_Change_', GenJournalLine."Debit Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('GLAcc2__Budget_at_Date_', BudgetAtDate);
    end;

    local procedure VerifyDetailTrialBalanceReport(GenJournalLine: Record "Gen. Journal Line"; Amount: Text[30])
    begin
        LibraryReportDataset.SetRange('DocumentNo_GLEntry', GenJournalLine."Document No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'DocumentNo_GLEntry', GenJournalLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals(Amount, -GenJournalLine.Amount);
    end;

    local procedure VerifyBankLedgerEntry(GenJournalLine: Record "Gen. Journal Line"; Amount: Text[30])
    begin
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'DocNo_BankAccLedg', GenJournalLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals(Amount, -GenJournalLine.Amount);
    end;

    local procedure VerifyTotalValueofItemSupplies(ExpectedAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalValueofItemSupplies', ExpectedAmount);
    end;

    local procedure VerifyCountryCodeInVATVIES(CountryCodeExists: Code[10]; CountryCodeNotExists: Code[10])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CountryRegionCode', CountryCodeExists);
        LibraryReportDataset.AssertElementWithValueNotExist('CountryRegionCode', CountryCodeNotExists);
    end;

    local procedure VerifyInternalRefNoVATEntry(CustNo: Code[20]; InternalRefNo: Text[30])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", CustNo);
        VATEntry.FindFirst();
        VATEntry.TestField("Internal Ref. No.", InternalRefNo);
    end;

    local procedure ValidateFixedAssetDetailsReportHeader(DepreciationBookCode: Code[10])
    begin
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(1, 1, 'Fixed Asset - Details');
        LibraryReportValidation.VerifyCellValue(1, 13, Format(Today, 0, 4));
        LibraryReportValidation.VerifyCellValue(2, 1, StrSubstNo('Depreciation Book: %1', DepreciationBookCode));
        LibraryReportValidation.VerifyCellValue(2, 15, 'Page');
        LibraryReportValidation.VerifyCellValue(2, 17, '1'); // verify page number visibility
        LibraryReportValidation.VerifyCellValue(4, 1, COMPANYPROPERTY.DisplayName());
        LibraryReportValidation.VerifyCellValue(4, 12, UserId);
    end;

    local procedure CreateGLAccountWithEntry(): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GLAccount."No.");
    end;

    local procedure CloseIncomeStatementWithoutBusinessUnit(GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20])
    var
        Date: Record Date;
    begin
        // Run the Close Income Statement Batch Job.
        Date.SetRange("Period Type", Date."Period Type"::Month);
        Date.SetRange("Period Start", LibraryFiscalYear.GetLastPostingDate(true));
        Date.FindFirst();

        RunCloseIncomeStatement(GenJournalLine, NormalDate(Date."Period End"), DocumentNo);
    end;

    local procedure CreateAndPostGenJnlLineWithCurrencyCode(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; GLAccountNo2: Code[20]; CurrencyCode: Code[10]; PostingDate: Date; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, GenJournalLine."Account Type"::"G/L Account", GLAccountNo2, LibraryRandom.RandDecInRange(1, 1000, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure FindGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocNo: Code[20])
    begin
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetRange("Document No.", DocNo);
        GenJournalLine.FindSet();
    end;

    local procedure RunCloseIncomeStatement(GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; DocumentNo: Code[20])
    begin
        // Enqueue values for CloseIncomeStatementRequestPageHandler.
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(DocumentNo);

        Commit();  // commit requires to run report.
        Report.Run(Report::"Close Income Statement");
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully in ES.
        Message(JournalLineCreatedMsg);
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]; ItemNo: Code[20]; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(1));

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure RunAuditTrailReport(RegisterNo: Integer)
    var
        GLRegister: Record "G/L Register";
        AuditTrailReport: Report "Audit Trail";
    begin
        GLRegister.SetRange("No.", RegisterNo);
        AuditTrailReport.SetTableView(GLRegister);
        AuditTrailReport.Run();
    end;

    local procedure VerifyAuditTrailReport(GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register")
    var
        GLEntry: Record "G/L Entry";
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(G_L_Register_NoLbl, GLRegister."No.");
        LibraryReportDataset.SetRange(G_L_Entry_Document_NoLbl, GenJournalLine."Document No.");
        if LibraryReportDataset.GetNextRow() then begin
            GLEntry.Get(GLRegister."From Entry No.");

            LibraryReportDataset.AssertCurrentRowValueEquals(G_L_Entry_Document_NoLbl, GenJournalLine."Document No.");
            LibraryReportDataset.AssertCurrentRowValueEquals(G_L_Entry_G_L_Account_NoLbl, GenJournalLine."Account No.");
            LibraryReportDataset.AssertCurrentRowValueEquals(G_L_Register_From_Entry_NoLbl, GLRegister."From Entry No.");
            LibraryReportDataset.AssertCurrentRowValueEquals(G_L_Register_To_Entry_NoLbl, GLRegister."To Entry No.");
            LibraryReportDataset.AssertCurrentRowValueEquals(G_L_Entry_Document_TypeLbl, Format(GenJournalLine."Document Type"));
            LibraryReportDataset.AssertCurrentRowValueEquals(G_L_Entry_G_L_Account_NoLbl, Format(GLEntry."G/L Account No."));
            LibraryReportDataset.AssertCurrentRowValueEquals(G_L_Entry_AmountLbl, GLEntry.Amount);
            LibraryReportDataset.AssertCurrentRowValueEquals(G_L_Entry_Entry_NoLbl, GLEntry."Entry No.");
            LibraryReportDataset.AssertCurrentRowValueEquals(G_L_Entry_Source_CodeLbl, GLEntry."Source Code");
            LibraryReportDataset.AssertCurrentRowValueEquals(G_L_Entry_Source_NoLbl, GLEntry."Source No.");
            LibraryReportDataset.AssertCurrentRowValueEquals(G_L_Entry_System_Created_EntryLbl, GLEntry."System-Created Entry");
            LibraryReportDataset.AssertCurrentRowValueEquals(G_L_Entry_Posting_DateLbl, Format(GLEntry."Posting Date"));
            LibraryReportDataset.AssertCurrentRowValueEquals(G_L_Entry_Document_DateLbl, Format(GLEntry."Document Date"));
        end else
            Error(ReportErr, GenJournalLine.FieldCaption("Document No."), GenJournalLine."Document No.");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Handler for confirmation messages, always send positive reply.
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Just for Handle the Message.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHBankLedgerEntry(var BankAccDetailTrialBal: TestRequestPage "Bank Acc. - Detail Trial Bal.")
    begin
        CurrentSaveValuesId := REPORT::"Bank Acc. - Detail Trial Bal.";
        BankAccDetailTrialBal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCheckBankAccReconciliation(var BankAccReconTest: TestRequestPage "Bank Acc. Recon. - Test")
    begin
        CurrentSaveValuesId := REPORT::"Bank Acc. Recon. - Test";
        BankAccReconTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHChartOfAccount(var ChartofAccounts: TestRequestPage "Chart of Accounts")
    begin
        CurrentSaveValuesId := REPORT::"Chart of Accounts";
        ChartofAccounts.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHClosingTrialBalance(var ClosingTrialBalance: TestRequestPage "Closing Trial Balance")
    begin
        CurrentSaveValuesId := REPORT::"Closing Trial Balance";
        ClosingTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHDetailTrialBalance(var DetailTrialBalance: TestRequestPage "Detail Trial Balance")
    var
        No: Variant;
        ExcludeGLBalanceOnly: Variant;
        PrintClosingEntry: Variant;
        PrintReverseEnteries: Variant;
        PrintOnlyCorrections: Variant;
        DateFilter: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Detail Trial Balance";
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(ExcludeGLBalanceOnly);
        LibraryVariableStorage.Dequeue(PrintClosingEntry);
        LibraryVariableStorage.Dequeue(PrintReverseEnteries);
        LibraryVariableStorage.Dequeue(PrintOnlyCorrections);
        LibraryVariableStorage.Dequeue(DateFilter);
        DetailTrialBalance."G/L Account".SetFilter("No.", No);
        if Format(DateFilter) <> '' then
            DetailTrialBalance."G/L Account".SetFilter("Date Filter", DateFilter);
        DetailTrialBalance.NewPageperGLAcc.SetValue(false);
        DetailTrialBalance.ExcludeGLAccsHaveBalanceOnly.SetValue(ExcludeGLBalanceOnly);
        DetailTrialBalance.InclClosingEntriesWithinPeriod.SetValue(PrintClosingEntry);
        DetailTrialBalance.IncludeReversedEntries.SetValue(PrintReverseEnteries);
        DetailTrialBalance.PrintCorrectionsOnly.SetValue(PrintOnlyCorrections);
        DetailTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHGLDocumentNos(var GLDocumentNos: TestRequestPage "G/L Document Nos.")
    begin
        CurrentSaveValuesId := REPORT::"G/L Document Nos.";
        GLDocumentNos.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHGLRegisterReport(var GLRegisterReport: TestRequestPage "G/L Register")
    begin
        CurrentSaveValuesId := REPORT::"G/L Register";
        GLRegisterReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAccTrialBalance(var BankAccDetailTrialBal: TestRequestPage "Bank Acc. - Detail Trial Bal.")
    begin
        CurrentSaveValuesId := REPORT::"Bank Acc. - Detail Trial Bal.";
        BankAccDetailTrialBal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFixedAssetDetails(var FixedAssetDetails: TestRequestPage "Fixed Asset - Details")
    begin
        CurrentSaveValuesId := REPORT::"Fixed Asset - Details";
        if FixedAssetDetails.Editable then;
        FixedAssetDetails.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
        Sleep(200);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFixedAssetDetailsExcel(var FixedAssetDetails: TestRequestPage "Fixed Asset - Details")
    begin
        CurrentSaveValuesId := REPORT::"Fixed Asset - Details";
        if FixedAssetDetails.Editable then;
        FixedAssetDetails.SaveAsExcel(LibraryReportValidation.GetFileName());
        Sleep(200);
    end;


    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHMaintenanceDetails(var MaintenanceDetails: TestRequestPage "Maintenance - Details")
    begin
        CurrentSaveValuesId := REPORT::"Maintenance - Details";
        MaintenanceDetails.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHDetailTrialBalanceWithDateFilter(var DetailTrialBalance: TestRequestPage "Detail Trial Balance")
    begin
        CurrentSaveValuesId := REPORT::"Detail Trial Balance";
        DetailTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHTrialBalance(var TrialBalance: TestRequestPage "Trial Balance")
    begin
        CurrentSaveValuesId := REPORT::"Trial Balance";
        TrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHTrialBalanceBudget(var TrialBalanceBudget: TestRequestPage "Trial Balance/Budget")
    begin
        CurrentSaveValuesId := REPORT::"Trial Balance/Budget";
        TrialBalanceBudget.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHReconcileCustandVendAccs(var ReconcileCustandVendAccs: TestRequestPage "Reconcile Cust. and Vend. Accs")
    begin
        CurrentSaveValuesId := REPORT::"Reconcile Cust. and Vend. Accs";
        ReconcileCustandVendAccs.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFixedAssetWithoutOption(var FixedAssetDetails: TestRequestPage "Fixed Asset - Details")
    begin
        CurrentSaveValuesId := REPORT::"Fixed Asset - Details";
        FixedAssetDetails.DepreciationBook.SetValue('');
        FixedAssetDetails.IncludeReversedEntries.SetValue(false);
        FixedAssetDetails.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHMaintenanceDetailsWithOutOption(var MaintenanceDetails: TestRequestPage "Maintenance - Details")
    begin
        CurrentSaveValuesId := REPORT::"Maintenance - Details";
        MaintenanceDetails.DepreciationBook.SetValue('');
        MaintenanceDetails.IncludeReversedEntries.SetValue(false);
        MaintenanceDetails.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVATVIESDeclarationTaxAuth(var VATVIESDeclarationTaxAuth: TestRequestPage "VAT- VIES Declaration Tax Auth")
    begin
        CurrentSaveValuesId := REPORT::"VAT- VIES Declaration Tax Auth";
        VATVIESDeclarationTaxAuth.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHImportConsolidationFromFile(var ImportConsolidationFromFile: TestRequestPage "Import Consolidation from File")
    begin
        CurrentSaveValuesId := REPORT::"Import Consolidation from File";
        Assert.IsTrue(ImportConsolidationFromFile.FileNameControl.Enabled(), FileNameNotEnabledErr);
        Assert.IsTrue(ImportConsolidationFromFile.FileNameControl.Editable(), FileNameNotEditableErr);
        Assert.AreEqual(Format(FilePathTxt), ImportConsolidationFromFile.FileNameControl.Value, FileNameNotPersistedErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHExportConsolidationToFile(var ExportConsolidation: TestRequestPage "Export Consolidation")
    begin
        CurrentSaveValuesId := REPORT::"Export Consolidation";
        Assert.IsTrue(ExportConsolidation.ClientFileNameControl.Enabled(), FileNameNotEnabledErr);
        Assert.IsTrue(ExportConsolidation.ClientFileNameControl.Editable(), FileNameNotEditableErr);
        Assert.AreEqual(Format(FilePathTxt), ExportConsolidation.ClientFileNameControl.Value, FileNameNotPersistedErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportConsolidationRequesPageHandler(var ExportConsolidation: TestRequestPage "Export Consolidation")
    begin
        CurrentSaveValuesId := REPORT::"Export Consolidation";
        ExportConsolidation.StartDate.SetValue(WorkDate());
        ExportConsolidation.EndDate.SetValue(WorkDate());
        ExportConsolidation.ClientFileNameControl.SetValue(LibraryReportDataset.GetParametersFileName());
        ExportConsolidation.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementWithZeroEndDateRequestPageHandler(var CloseIncomeStatement: TestRequestPage "Close Income Statement")
    begin
        CloseIncomeStatement.InventoryPeriodClosed.SetValue(0D);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATVIESDeclDiskRequestPageHandler(var VATVIESDeclarationDisk: TestRequestPage "VAT- VIES Declaration Disk")
    begin
        VATVIESDeclarationDisk.UseAmtsInAddCurr.Value();
        VATVIESDeclarationDisk.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHDetailTrialBalanceExcel(var DetailTrialBalance: TestRequestPage "Detail Trial Balance")
    var
        AccountNoFilter: Variant;
        PrintOnlyOnePerPage: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Detail Trial Balance";
        LibraryVariableStorage.Dequeue(AccountNoFilter);
        LibraryVariableStorage.Dequeue(PrintOnlyOnePerPage);

        DetailTrialBalance."G/L Account".SetFilter("No.", AccountNoFilter);
        DetailTrialBalance.NewPageperGLAcc.SetValue(PrintOnlyOnePerPage);

        DetailTrialBalance.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    procedure CloseIncomeStatementRequestPageHandler(var CloseIncomeStatement: TestRequestPage "Close Income Statement")
    begin
        CloseIncomeStatement.FiscalYearEndingDate.SetValue(LibraryVariableStorage.DequeueDate()); // Fiscal Year Ending Date
        CloseIncomeStatement.GenJournalTemplate.SetValue(LibraryVariableStorage.DequeueText()); // Gen. Journal Template
        CloseIncomeStatement.GenJournalBatch.SetValue(LibraryVariableStorage.DequeueText()); // Gen. Journal Batch
        CloseIncomeStatement.DocumentNo.SetValue(LibraryVariableStorage.DequeueText()); // Document No.
        CloseIncomeStatement.RetainedEarningsAcc.SetValue(''); // Retained Earnings Acc.
        CloseIncomeStatement.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure AuditTrailReportRequestPageHandler(var AuditTrail: TestRequestPage "Audit Trail")
    begin
        AuditTrail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
