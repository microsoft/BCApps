codeunit 141012 "UT REP General Ledger"
{
    // Test for feature REPORTS GL - Reports General Ledger.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        FileManagement: Codeunit "File Management";
        AmountCap: Label 'Amount_1_';
        CreditAmountGLEntryCap: Label 'CreditAmount_GLEntry';
        DialogErr: Label 'Dialog';
        DebitAmountGLEntryCap: Label 'DebitAmount_GLEntry';
        EliminationAmountCap: Label 'EliminationAmount';
        FiscalYearBalanceCap: Label 'FiscalYearBalance';
        FiscalYearTxt: Label 'For the Fiscal Year:';
        GLFilterCap: Label 'GLFilter';
        GLAccountBalanceAtDateCap: Label 'G_L_Account__Balance_at_Date_';
        GLAccNetChangeCap: Label 'GLAccNetChange';
        GLBalanceCap: Label 'GLBalance';
        GLFilterTxt: Label '%1: %2';
        GLEntryFilterCap: Label 'GLEntryFilter';
        PeriodTxt: Label 'Period';
        SubTitleCap: Label 'SubTitle';
        SubTitleFilterTxt: Label '%1 %2';
        TitleFilterTxt: Label '%1 %2..%3';
        LibraryUtility: Codeunit "Library - Utility";
        GLEntryBalAccountNoTok: Label 'G_L_Entry__Bal__Account_No__';
        GLEntrySourceTypeTok: Label 'G_L_Entry__Source_Type_';
        SourceNameTok: Label 'SourceName';
        Sum1Tok: Label 'Sum1';
        Sum2Tok: Label 'Sum2';

    [Test]
    [HandlerFunctions('AccountBalancesByGIFICodeAsOfDateRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportBalanceAsOfDateAccBalancesByGIFICodeError()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10004 Account Balances by GIFI Code.
        // Setup.
        Initialize();

        // Exercise.
        asserterror REPORT.Run(REPORT::"Account Balances by GIFI Code");

        // Verify: Verify Error Code, Actual error - You must enter an As Of Date.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('AccountBalancesByGIFICodeRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccountBalancesByGIFICode()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - GLAccount Trigger of Report ID - 10004 Account Balances by GIFI Code.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        GLAccount."GIFI Code" := CreateGIFICode();
        GLAccount.Modify();
        CreateGLEntry(GLEntry, GLAccount."No.", '', '', GLEntry."Bal. Account Type");

        // Exercise.
        RunReportWithApplicationAreaDisabled(REPORT::"Account Balances by GIFI Code");  // Opens AccountBalancesByGIFICodeRequestPageHandler.

        // Verify: Verify Subtitle and GIFI Code is updated on Report Account Balances by GIFI Code.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Subtitle', StrSubstNo(SubTitleFilterTxt, 'As Of', WorkDate()));
        LibraryReportDataset.AssertElementWithValueExists('GIFICode_GLAccount', GLAccount."GIFI Code");
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalanceStartingDateRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportStartingDateConsolidatedTrialBalanceError()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10007 Consolidated Trial Balance.

        // Setup: Test to verify Actual Error Code: Please enter the Starting date for the consolidation period.
        Initialize();
        OnPreReportConsolidationDateConsolidatedTrialBalance(REPORT::"Consolidated Trial Balance", 0D);  // Starting Date - 0D.
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalanceStartingDateRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportEndingDateConsolidatedTrialBalanceError()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10007 Consolidated Trial Balance.

        // Setup: Test to verify Actual Error Code: Please enter the ending date for the consolidation period.
        Initialize();
        OnPreReportConsolidationDateConsolidatedTrialBalance(REPORT::"Consolidated Trial Balance", WorkDate());  // Starting Date - WORKDATE.
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalance4StartingDateRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportStartingDateConsolidatedTrialBalance4Error()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10008 Consolidated Trial Balance (4).

        // Setup: Test to verify Actual Error Code: Please enter the Starting date for the consolidation period.
        Initialize();
        OnPreReportConsolidationDateConsolidatedTrialBalance(REPORT::"Consolidated Trial Balance (4)", 0D);  // Starting Date - 0D.
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalance4StartingDateRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportEndingDateConsolidatedTrialBalance4Error()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10008 Consolidated Trial Balance (4).

        // Setup: Test to verify Actual Error Code: Please enter the ending date for the consolidation period.
        Initialize();
        OnPreReportConsolidationDateConsolidatedTrialBalance(REPORT::"Consolidated Trial Balance (4)", WorkDate());  // Starting Date - WORKDATE.
    end;

    local procedure OnPreReportConsolidationDateConsolidatedTrialBalance(ReportID: Integer; StartingDate: Date)
    begin
        // Enqueue Required inside ConsolidatedTrialBalanceConsolidatedDateRequestPageHandler.
        LibraryVariableStorage.Enqueue(StartingDate);

        // Exercise: Run Report Consolidated Trial Balance or Consolidated Trial Balance (4) with Starting Date - 0D and Starting Date - WORKDATE and Ending Date - 0D.
        asserterror RunReportWithApplicationAreaDisabled(ReportID);  // Opens ConsolidatedTrialBalanceStartingDateRequestPageHandler or ConsolidatedTrialBalance4StartingDateRequestPageHandler.

        // Verify: Verify Error Code, Actual error: Starting Date or Ending date for the consolidation period.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportConsolidatedTrialBalance()
    var
        GLAccount: Record "G/L Account";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10007 Consolidated Trial Balance.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);

        // Exercise: Run Report - Consolidated Trial Balance with Filter on G/L Account.
        RunReportWithApplicationAreaDisabled(REPORT::"Consolidated Trial Balance");  // Opens ConsolidatedTrialBalanceRequestPageHandler.

        // Verify: Verify Filters of G/L Account and SubTitle is updated on Report Consolidated Trial Balance.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLFilterCap, StrSubstNo(GLFilterTxt, GLAccount.FieldCaption("No."), GLAccount."No."));
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, StrSubstNo('%1: %2..%3', PeriodTxt, WorkDate(), WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalanceUseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportSubTitleConsolidatedTrialBalance()
    var
        GLAccount: Record "G/L Account";
        CurrencyDescription: Text[30];
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10007 Consolidated Trial Balance.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CurrencyDescription := UpdateGLSetupAdditionalReportingCurrency();

        // Exercise: Run Report - Consolidated Trial Balance with Filter on G/L Account.
        RunReportWithApplicationAreaDisabled(REPORT::"Consolidated Trial Balance");  // Opens ConsolidatedTrialBalanceUseAddRptCurrRequestPageHandler.

        // Verify: Verify SubTitle is updated on Report Consolidated Trial Balance.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, StrSubstNo('%1: %2..%3  %4 %5%6', PeriodTxt, WorkDate(), WorkDate(), '(using', CurrencyDescription, ')'));
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalanceUseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAddCurrChangeConsolidatedTrialBalance()
    begin
        // Purpose of the test is to validate Business Unit -OnAfterGetRecord Trigger of Report ID - 10007 Consolidated Trial Balance.

        // Setup: Test to verify AmountCap is updated with Additional Currency Amount when UseAdditionalReportingCurrency - TRUE on ConsolidatedTrialBalanceUseAddRptCurrRequestPageHandler.
        Initialize();
        OnAfterGetRecordBusinessUnitConsolidatedTrialBalance(1);  // Fraction value - 1, when AmountsInWhole1000s - FALSE;
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalanceInThousandsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordInThousandsConsolidatedTrialBalance()
    begin
        // Purpose of the test is to validate Business Unit -OnAfterGetRecord Trigger of Report ID - 10007 Consolidated Trial Balance.

        // Setup: Test to verify AmountCap is updated with Additional Currency Amount divided by 1000 when AmountsInWhole1000s - TRUE on ConsolidatedTrialBalanceInThousandsRequestPageHandler.
        Initialize();
        OnAfterGetRecordBusinessUnitConsolidatedTrialBalance(1000);  // Fraction value - 1000, when AmountsInWhole1000s - TRUE;
    end;

    local procedure OnAfterGetRecordBusinessUnitConsolidatedTrialBalance(Fraction: Integer)
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLEntry, GLAccount."No.", '', CreateBusinessUnit(), GLEntry."Bal. Account Type");
        UpdateGLSetupAdditionalReportingCurrency();

        // Exercise.
        RunReportWithApplicationAreaDisabled(REPORT::"Consolidated Trial Balance");  // Opens ConsolidatedTrialBalanceUseAddRptCurrRequestPageHandler.

        // Verify: Verify Additional-Currency Net Change and Additional-Currency Balance at Date of G/L Account is updated on report Consolidated Trial Balance.
        GLAccount.CalcFields("Additional-Currency Net Change", "Add.-Currency Balance at Date");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLAccNetChangeCap, GLAccount."Additional-Currency Net Change" / Fraction);
        LibraryReportDataset.AssertElementWithValueExists(GLBalanceCap, GLAccount."Add.-Currency Balance at Date" / Fraction);
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordNetChangeBusUnitConsolidatedTrialBalance()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate Business Unit -OnAfterGetRecord Trigger of Report ID - 10007 Consolidated Trial Balance.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLEntry, GLAccount."No.", '', CreateBusinessUnit(), GLEntry."Bal. Account Type");

        // Exercise.
        RunReportWithApplicationAreaDisabled(REPORT::"Consolidated Trial Balance");  // Opens ConsolidatedTrialBalanceRequestPageHandler.

        // Verify: Verify Net Change and Balance at Date of G/L Account is updated on report Consolidated Trial Balance.
        GLAccount.CalcFields("Net Change", "Balance at Date");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLAccNetChangeCap, GLAccount."Net Change");
        LibraryReportDataset.AssertElementWithValueExists(GLBalanceCap, GLAccount."Balance at Date");
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalanceUseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordEliminationAmtConsolidatedTrialBalance()
    begin
        // Purpose of the test is to validate ConsolidCounter -OnAfterGetRecord Trigger of Report ID - 10007 Consolidated Trial Balance.

        // Setup: Test to verify Additional-Currency Net Change is updated as Elimination Amount on Report Consolidated Trial Balance.
        Initialize();
        OnAfterGetRecordAmtConsolidatedTrialBalance(1);  // Fraction value - 1, when AmountsInWhole1000s - FALSE;
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalanceInThousandsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAmtInThousandsConsolidatedTrialBalance()
    begin
        // Purpose of the test is to validate ConsolidCounter -OnAfterGetRecord Trigger of Report ID - 10007 Consolidated Trial Balance.

        // Setup: Test to verify Additional-Currency Net Change in Thousands is updated when AmountsInWhole1000s - TRUE on ConsolidatedTrialBalanceInThousandsRequestPageHandler.
        Initialize();
        OnAfterGetRecordAmtConsolidatedTrialBalance(1000);  // Fraction value - 1000, when AmountsInWhole1000s - TRUE;
    end;

    local procedure OnAfterGetRecordAmtConsolidatedTrialBalance(Fraction: Integer)
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLEntry, GLAccount."No.", '', '', GLEntry."Bal. Account Type");
        UpdateGLSetupAdditionalReportingCurrency();

        // Exercise.
        RunReportWithApplicationAreaDisabled(REPORT::"Consolidated Trial Balance");
        // Opens ConsolidatedTrialBalanceUseAddRptCurrRequestPageHandler or ConsolidatedTrialBalanceInThousandsRequestPageHandler and set AmountsInWhole1000s - TRUE on second one.

        // Verify: Verify Additional-Currency Net Change in Thousands is updated as Elimination Amount on Report Consolidated Trial Balance.
        GLAccount.CalcFields("Additional-Currency Net Change");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(EliminationAmountCap, GLAccount."Additional-Currency Net Change" / Fraction);
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordNetChangeAmtConsolidatedTrialBalance()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate ConsolidCounter -OnAfterGetRecord Trigger of Report ID - 10007 Consolidated Trial Balance.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLEntry, GLAccount."No.", '', '', GLEntry."Bal. Account Type");

        // Exercise.
        RunReportWithApplicationAreaDisabled(REPORT::"Consolidated Trial Balance");  // Opens ConsolidatedTrialBalanceRequestPageHandler.

        // Verify: Verify Net Change is updated as Elimination Amount on Report Consolidated Trial Balance.
        GLAccount.CalcFields("Net Change");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(EliminationAmountCap, GLAccount."Net Change");
    end;

    [Test]
    [HandlerFunctions('GLRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLRegister()
    var
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
        SourceCode: Record "Source Code";
    begin
        // Purpose of the test is to validate G/L Register -OnAfterGetRecord Trigger of Report ID - 10019  G/L Register.
        // Setup.
        Initialize();
        CreateSourceCode(SourceCode);
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLEntry, GLAccount."No.", '', '', GLEntry."Bal. Account Type");
        CreateGLRegister(SourceCode.Code, GLEntry."Entry No.");

        // Exercise.
        REPORT.Run(REPORT::"G/L Register");  // Opens GLRegisterRequestPageHandler.

        // Verify: Verify Filter, Debit Amount, Credit Amount and SourceCodeText is updated on Report ID - G/L Register.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLEntryFilterCap, StrSubstNo(GLFilterTxt, GLEntry.FieldCaption("G/L Account No."), GLAccount."No."));
        LibraryReportDataset.AssertElementWithValueExists('G_L_Entry__Debit_Amount_', GLEntry."Debit Amount");
        LibraryReportDataset.AssertElementWithValueExists('G_L_Entry__Credit_Amount_', GLEntry."Credit Amount");
        LibraryReportDataset.AssertElementWithValueExists('SourceCodeText', StrSubstNo(GLFilterTxt, SourceCode.TableCaption(), SourceCode.Code));
    end;

    [Test]
    [HandlerFunctions('GLRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLEntryCustomerGLRegister()
    var
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate G/L Entry -OnAfterGetRecord Trigger of Report ID - 10019 G/L Register.

        // Setup: Test to verify Source Name and Source Type is updated with Customer on Report G/L Register.
        Initialize();
        OnAfterGetRecordGLEntryBalAccountTypeGLRegister(CreateCustomer(), GLEntry."Bal. Account Type"::Customer);
    end;

    [Test]
    [HandlerFunctions('GLRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLEntryVendorGLRegister()
    var
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate G/L Entry -OnAfterGetRecord Trigger of Report ID - 10019 G/L Register.

        // Setup: Test to verify Source Name and Source Type is updated with Vendor on Report G/L Register.
        OnAfterGetRecordGLEntryBalAccountTypeGLRegister(CreateVendor(), GLEntry."Bal. Account Type"::Vendor);
    end;

    [Test]
    [HandlerFunctions('GLRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLEntryFixedAssetGLRegister()
    var
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate G/L Entry -OnAfterGetRecord Trigger of Report ID - 10019 G/L Register.

        // Setup: Test to verify Source Name and Source Type is updated with Fixed Asset on Report G/L Register.
        Initialize();
        OnAfterGetRecordGLEntryBalAccountTypeGLRegister(CreateFixedAsset(), GLEntry."Bal. Account Type"::"Fixed Asset");
    end;

    [Test]
    [HandlerFunctions('GLRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLEntryBankAccGLRegister()
    var
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate G/L Entry -OnAfterGetRecord Trigger of Report ID - 10019 G/L Register.

        // Setup: Test to verify Source Name and Source Type is updated with Bank Account on Report G/L Register.
        Initialize();
        OnAfterGetRecordGLEntryBalAccountTypeGLRegister(CreateBankAccount(), GLEntry."Bal. Account Type"::"Bank Account");
    end;

    [TransactionModel(TransactionModel::AutoRollback)]
    local procedure OnAfterGetRecordGLEntryBalAccountTypeGLRegister(BalAccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type")
    var
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO 381127] Source Name contains a value if Customer/Vendor.Name has length = 50
        // Create G/L Account, G/L Entry with different Balance Account Types and create G/L Register.
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLEntry, GLAccount."No.", BalAccountNo, '', BalAccountType);
        CreateGLRegister('', GLEntry."Entry No.");

        // Exercise.
        REPORT.Run(REPORT::"G/L Register");  // Opens GLRegisterRequestPageHandler.

        // Verify: Verify Source Name and Source Type is updated with different Balance Account Types of G/L Entry on Report G/L Register.
        VerifySourceOnGLRegisterReport(
          GetAccountName(BalAccountNo, GLEntry."Bal. Account Type"),
          Format(GLEntry."Bal. Account Type"),
          GLEntry."Debit Amount",
          GLEntry."Credit Amount",
          BalAccountNo);
    end;

    [Test]
    [HandlerFunctions('GLRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLEntryICPartnerGLRegister()
    var
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
        ICPartnerCode: Code[20];
    begin
        // [SCENARIO 381127] Source Name contains a value if "IC Partner".Name has length = 50
        // Purpose of the test is to validate G/L Entry -OnAfterGetRecord Trigger of Report ID - 10019 G/L Register.
        // Setup.
        Initialize();
        ICPartnerCode := CreateICPartner();
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLEntry, GLAccount."No.", ICPartnerCode, '', GLEntry."Bal. Account Type"::"IC Partner");
        GLEntry."IC Partner Code" := ICPartnerCode;
        GLEntry.Modify();
        CreateGLRegister('', GLEntry."Entry No.");

        // Exercise.
        REPORT.Run(REPORT::"G/L Register");  // Opens GLRegisterRequestPageHandler.

        // Verify: Verify Source Name and Source Type is updated with IC Partner on Report G/L Register.
        VerifySourceOnGLRegisterReport(
          GetAccountName(GLEntry."Bal. Account No.", GLEntry."Bal. Account Type"::"IC Partner"),
          Format(GLEntry."Bal. Account Type"::"IC Partner"),
          GLEntry."Debit Amount",
          GLEntry."Credit Amount",
          GLEntry."Bal. Account No.");
    end;

    [Test]
    [HandlerFunctions('GeneralLedgerWorksheetUseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportGeneralLedgerWorksheet()
    var
        GLAccount: Record "G/L Account";
        CurrencyDescription: Text[30];
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10018 General Ledger Worksheet.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CurrencyDescription := UpdateGLSetupAdditionalReportingCurrency();

        // Exercise.
        REPORT.Run(REPORT::"General Ledger Worksheet");  // Opens GeneralLedgerWorksheetUseAddRptCurrRequestPageHandler

        // Verify: Verify Filters of G/L Account and Subtitle is updated on Report General Ledger Worksheet.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLFilterCap, StrSubstNo(GLFilterTxt, GLAccount.FieldCaption("No."), GLAccount."No."));
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, StrSubstNo(SubTitleFilterTxt, 'Amounts are in', CurrencyDescription));
    end;

    [Test]
    [HandlerFunctions('GeneralLedgerWorksheetUseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccountCreditsGenLedgWorksheet()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate G/L Account -OnAfterGetRecord Trigger of Report ID - 10018 General Ledger Worksheet.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        UpdateGLSetupAdditionalReportingCurrency();
        CreateGLEntry(GLEntry, GLAccount."No.", '', '', GLEntry."Bal. Account Type");
        UpdateGLEntryAdditionalCurrencyAmount(GLEntry);

        // Exercise.
        REPORT.Run(REPORT::"General Ledger Worksheet");  // Opens GeneralLedgerWorksheetUseAddRptCurrRequestPageHandler.

        // Verify: Verify Balance at Date and TotalCredits on Report General Ledger Worksheet.
        GLAccount.CalcFields("Add.-Currency Balance at Date");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLAccountBalanceAtDateCap, GLAccount."Add.-Currency Balance at Date");
        LibraryReportDataset.AssertElementWithValueExists('TotalCredits', -GLAccount."Add.-Currency Balance at Date");
    end;

    [Test]
    [HandlerFunctions('GeneralLedgerWorksheetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccountDebitsGenLedgWorksheet()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate G/L Account -OnAfterGetRecord Trigger of Report ID - 10018 General Ledger Worksheet.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLEntry, GLAccount."No.", '', '', GLEntry."Bal. Account Type");
        UpdateGLEntryAdditionalCurrencyAmount(GLEntry);

        // Exercise.
        REPORT.Run(REPORT::"General Ledger Worksheet");  // Opens GeneralLedgerWorksheetRequestPageHandler.

        // Verify: Verify Balance at Date and TotalDebits on Report General Ledger Worksheet.
        GLAccount.CalcFields("Balance at Date");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLAccountBalanceAtDateCap, GLAccount."Balance at Date");
        LibraryReportDataset.AssertElementWithValueExists('TotalDebits', GLAccount."Balance at Date");
    end;

    [Test]
    [HandlerFunctions('BudgetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportBudget()
    var
        GLAccount: Record "G/L Account";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10001 Budget.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);

        // Exercise.
        REPORT.Run(REPORT::Budget);  // Opens BudgetRequestPageHandler.

        // Verify: Verify Filters of G/L Account and Subtitle on Report Budget.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLFilterCap, StrSubstNo(GLFilterTxt, GLAccount.FieldCaption("No."), GLAccount."No."));
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, GLAccount.FieldCaption("Budget Filter") + ': ' + 'All Budgets');
    end;

    [Test]
    [HandlerFunctions('ChartOfAccountsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccountChartOfAccounts()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate G/L Account -OnAfterGetRecord Trigger of Report ID - 10002 Chart of Accounts.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLEntry, GLAccount."No.", '', '', GLEntry."Bal. Account Type");

        // Exercise.
        REPORT.Run(REPORT::"Chart of Accounts");  // Opens ChartOfAccountsRequestPageHandler.

        // Verify: Verify Filters of G/L Account, Account Type and Balance at Date on Report Chart of Accounts.
        GLAccount.CalcFields("Balance at Date");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLFilterCap, StrSubstNo(GLFilterTxt, GLAccount.FieldCaption("No."), GLAccount."No."));
        LibraryReportDataset.AssertElementWithValueExists('G_L_Account___Balance_at_Date_', GLAccount."Balance at Date");
        LibraryReportDataset.AssertElementWithValueExists('G_L_Account___Account_Type_', Format(GLAccount."Account Type"));
    end;

    [Test]
    [HandlerFunctions('ClosingTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportFiscalYearStartDateClosingTrialBalanceError()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10003 Closing Trial Balance.
        // Setup.
        Initialize();
        LibraryVariableStorage.Enqueue('Test');  // Using Test to avoid Queue Underflow. Value is not important for test.
        LibraryVariableStorage.Enqueue(0D);  // Required inside ClosingTrialBalanceRequestPageHandler.

        // Exercise.
        asserterror REPORT.Run(REPORT::"Closing Trial Balance");  // Opens ClosingTrialBalanceRequestPageHandler.

        // Verify: Verify Error Code, Actual error: Enter the starting date for the fiscal year.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('ClosingTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccountFilterClosingTrialBal()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate G/L Account -OnAfterGetRecord Trigger of Report ID - 10003 Closing Trial Balance.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLEntry, GLAccount."No.", '', '', GLEntry."Bal. Account Type"::"Bank Account");
        UpdateGLEntryPostingDate(GLEntry);
        LibraryVariableStorage.Enqueue(GLEntry."Posting Date");  // Required inside ClosingTrialBalanceRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Closing Trial Balance");  // Opens ClosingTrialBalanceRequestPageHandler.

        // Verify: Verify Filters of G/L Account, Subtitle and FiscalYearBalance on Report Closing Trial Balance.
        GLAccount.CalcFields("Net Change");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLFilterCap, StrSubstNo(GLFilterTxt, GLAccount.FieldCaption("No."), GLAccount."No."));
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, StrSubstNo(TitleFilterTxt, FiscalYearTxt, GLEntry."Posting Date", CalcDate('<+CY>', GLEntry."Posting Date")));
        LibraryReportDataset.AssertElementWithValueExists(FiscalYearBalanceCap, GLAccount."Net Change");
    end;

    [Test]
    [HandlerFunctions('ClosingTrialBalanceUseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccountSubTitleClosingTrialBal()
    var
        GLAccount: Record "G/L Account";
        AccountingPeriod: Record "Accounting Period";
        CurrencyDescription: Text[30];
    begin
        // Purpose of the test is to validate G/L Account -OnAfterGetRecord Trigger of Report ID - 10003 Closing Trial Balance.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        AccountingPeriod.FindFirst();
        CurrencyDescription := UpdateGLSetupAdditionalReportingCurrency();
        LibraryVariableStorage.Enqueue(AccountingPeriod."Starting Date"); // Required inside ClosingTrialBalanceUseAddRptCurrRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Closing Trial Balance");  // Opens ClosingTrialBalanceUseAddRptCurrRequestPageHandler.

        // Verify: Verify SubTitle is updated with Currency Description of General Ledger Setup on Report Closing Trial Balance.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, StrSubstNo('%1 %2..%3  %4 %5%6', FiscalYearTxt, AccountingPeriod."Starting Date", CalcDate('<+CY>', AccountingPeriod."Starting Date"), '(using', CurrencyDescription, ')'));
    end;

    [Test]
    [HandlerFunctions('ClosingTrialBalanceUseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccountFiscalYearBalClosingTrialBal()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate G/L Account -OnAfterGetRecord Trigger of Report ID - 10003 Closing Trial Balance.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLEntry, GLAccount."No.", CreateBusinessUnit(), '', GLEntry."Bal. Account Type");
        UpdateGLEntryPostingDate(GLEntry);
        UpdateGLSetupAdditionalReportingCurrency();
        LibraryVariableStorage.Enqueue(GLEntry."Posting Date");  // Required inside ClosingTrialBalanceUseAddRptCurrRequestPageHandler.

        // Exercise:
        REPORT.Run(REPORT::"Closing Trial Balance");  // Opens ClosingTrialBalanceUseAddRptCurrRequestPageHandler.

        // Verify: Verify Fiscal Year Balance on Report Closing Trial Balance.
        GLAccount.CalcFields("Additional-Currency Net Change");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(FiscalYearBalanceCap, GLAccount."Additional-Currency Net Change");
    end;

    [Test]
    [HandlerFunctions('CrossReferenceByAccountNoRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLEntryCrossReferenceByAccountNo()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate G/L Entry -OnAfterGetRecord Trigger of Report ID - 10009 Cross Reference by Account No.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLEntry, GLAccount."No.", '', '', GLEntry."Bal. Account Type"::"Bank Account");

        // Exercise.
        REPORT.Run(REPORT::"Cross Reference by Account No.");  // Opens CrossReferenceByAccountNoRequestPageHandler.

        // Verify: Verify Filters of G/L Entry, Debit amount and Credit Amount is updated on Report Cross Reference by Account No.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLEntryFilterCap, StrSubstNo(GLFilterTxt, GLEntry.FieldCaption("G/L Account No."), GLAccount."No."));
        LibraryReportDataset.AssertElementWithValueExists(DebitAmountGLEntryCap, GLEntry."Debit Amount");
        LibraryReportDataset.AssertElementWithValueExists(CreditAmountGLEntryCap, GLEntry."Credit Amount");
    end;

    [Test]
    [HandlerFunctions('CurrencyBalancesRecPayRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCurrencyCurrencyBalancesRecPay()
    var
        Currency: Record Currency;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Purpose of the test is to validate Currency -OnAfterGetRecord Trigger of Report ID - 10017 Currency Balances - Rec./Pay.
        // Setup.
        Initialize();
        CurrencyExchangeRate.FindFirst();
        CreateDetailedCustomerLedgerEntries(DetailedCustLedgEntry, CurrencyExchangeRate."Currency Code");
        CreateDetailedVendorLedgerEntries(DetailedVendorLedgEntry, CurrencyExchangeRate."Currency Code");

        // Exercise.
        LibraryVariableStorage.Enqueue(CurrencyExchangeRate."Currency Code");  // Required inside CurrencyBalancesRecPayRequestPageHandler.
        REPORT.Run(REPORT::"Currency Balances - Rec./Pay.");  // Opens CurrencyBalancesRecPayRequestPageHandler.

        // Verify: Verify Currency Filter, Vendor Balance and Customer Balance on Report Currency Balances - Rec./Pay.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CurFilter', StrSubstNo('%1: %2', Currency.FieldCaption(Code), CurrencyExchangeRate."Currency Code"));
        LibraryReportDataset.AssertElementWithValueExists('VendorBalance_Currency', -DetailedVendorLedgEntry.Amount);
        LibraryReportDataset.AssertElementWithValueExists('VendorBalanceLCY_Currency', -DetailedVendorLedgEntry."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('CustBalance_Currency', DetailedCustLedgEntry.Amount);
        LibraryReportDataset.AssertElementWithValueExists('CustBalanceLCY_Currency', DetailedCustLedgEntry."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('CurValueReceivables', Round(CurrencyExchangeRate.ExchangeAmtFCYToFCY(CurrencyExchangeRate."Starting Date", CurrencyExchangeRate."Currency Code", '', DetailedCustLedgEntry.Amount)));
        LibraryReportDataset.AssertElementWithValueExists('CurValuePayables', Round(CurrencyExchangeRate.ExchangeAmtFCYToFCY(CurrencyExchangeRate."Starting Date", CurrencyExchangeRate."Currency Code", '', -DetailedVendorLedgEntry.Amount)));
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalance4UseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportSubTitleConsolidatedTrialBal4()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        AmountType: Option "Net Change",Balance;
        CurrencyDescription: Text[30];
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10008 Consolidated Trial Balance (4).
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLEntry, GLAccount."No.", '', CreateBusinessUnit(), GLEntry."Bal. Account Type");
        CurrencyDescription := UpdateGLSetupAdditionalReportingCurrency();

        // Exercise.
        LibraryVariableStorage.Enqueue(AmountType::"Net Change");  // Required inside ConsolidatedTrialBalance4UseAddRptCurrRequestPageHandler.
        RunReportWithApplicationAreaDisabled(REPORT::"Consolidated Trial Balance (4)");  // Opens ConsolidatedTrialBalance4UseAddRptCurrRequestPageHandler.

        // Verify: Verify SubTitle is updated on Report Consolidated Trial Balance (4).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, StrSubstNo('%1 %2%3', '(amounts are in', CurrencyDescription, ')'));
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalance4RequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportConsolidatedTrialBal4()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        AmountType: Option "Net Change",Balance;
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10008 Consolidated Trial Balance (4).
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLEntry, GLAccount."No.", '', CreateBusinessUnit(), GLEntry."Bal. Account Type");

        // Exercise.
        LibraryVariableStorage.Enqueue(AmountType::"Net Change");  // Required inside ConsolidatedTrialBalance4UseAddRptCurrRequestPageHandler.
        RunReportWithApplicationAreaDisabled(REPORT::"Consolidated Trial Balance (4)");  // Opens ConsolidatedTrialBalance4UseAddRptCurrRequestPageHandler.

        // Verify: Verify Filters of G/L Account and SubTitle is updated on Report Consolidated Trial Balance (4).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLFilterCap, StrSubstNo(GLFilterTxt, GLAccount.FieldCaption("No."), GLAccount."No."));
        LibraryReportDataset.AssertElementWithValueExists('MainTitle', StrSubstNo(TitleFilterTxt, 'Consolidated Trial Balance for', WorkDate(), WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalance4UseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAddCurrChangeConsolidatedTrialBal4()
    begin
        // Purpose of the test is to validate G/L Account -OnAfterGetRecord Trigger of Report ID - 10008 Consolidated Trial Balance (4).

        // Setup: Test to verify AmountCap is updated with Additional Currency Amount when UseAdditionalReportingCurrency - TRUE on ConsolidatedTrialBalance4UseAddRptCurrRequestPageHandler.
        Initialize();
        OnAfterGetRecordGLAccountAmtConsolidatedTrialBal4(CreateBusinessUnit(), AmountCap, 1);  // Fraction value - 1, when AmountsInWhole1000s - FALSE;
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalance4InThousandsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordInThousandsConsolidatedTrialBal4()
    begin
        // Purpose of the test is to validate G/L Account -OnAfterGetRecord Trigger of Report ID - 10008 Consolidated Trial Balance (4).

        // Setup: Test to verify AmountCap is updated with Additional Currency Amount divided by 1000s when AmountsInWhole1000s - TRUE on ConsolidatedTrialBalance4InThousandsRequestPageHandler.
        Initialize();
        OnAfterGetRecordGLAccountAmtConsolidatedTrialBal4(CreateBusinessUnit(), AmountCap, 1000);  // Fraction value - 1000, when AmountsInWhole1000s - TRUE;
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalance4UseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordEliminationAmtConsolidatedTrialBal4()
    begin
        // Purpose of the test is to validate G/L Account -OnAfterGetRecord Trigger of Report ID - 10008 Consolidated Trial Balance (4).

        // Setup: Test to verify EliminationAmountCap is updated with Additional Currency Amount when UseAdditionalReportingCurrency - TRUE on ConsolidatedTrialBalance4UseAddRptCurrRequestPageHandler.
        Initialize();
        OnAfterGetRecordGLAccountAmtConsolidatedTrialBal4('', EliminationAmountCap, 1);  // Fraction value - 1, when AmountsInWhole1000s - FALSE;
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalance4InThousandsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAmtInThousandsConsolidatedTrialBal4()
    begin
        // Purpose of the test is to validate G/L Account -OnAfterGetRecord Trigger of Report ID - 10008 Consolidated Trial Balance (4).

        // Setup: Test to verify EliminationAmountCap is updated with Additional Currency Amount divided by 1000s when AmountsInWhole1000s - TRUE on ConsolidatedTrialBalance4InThousandsRequestPageHandler.
        Initialize();
        OnAfterGetRecordGLAccountAmtConsolidatedTrialBal4('', EliminationAmountCap, 1000);  // Fraction value - 1000, when AmountsInWhole1000s - TRUE;
    end;

    local procedure OnAfterGetRecordGLAccountAmtConsolidatedTrialBal4(BusinessUnitCode: Code[20]; AmountCaption: Text; Fraction: Integer)
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        AmountType: Option "Net Change",Balance;
    begin
        CreateGLAccount(GLAccount);
        CreateBusinessUnit();
        CreateGLEntry(GLEntry, GLAccount."No.", '', BusinessUnitCode, GLEntry."Bal. Account Type");
        UpdateGLSetupAdditionalReportingCurrency();

        // Exercise.
        LibraryVariableStorage.Enqueue(AmountType::"Net Change");  // Required inside ConsolidatedTrialBalance4InThousandsRequestPageHandler.
        RunReportWithApplicationAreaDisabled(REPORT::"Consolidated Trial Balance (4)");  // Opens and set AmountsInWhole1000s - TRUE on ConsolidatedTrialBalance4InThousandsRequestPageHandler.

        // Verify: Verify Additional-Currency Net Change of G/L Account is updated in Thousands on report Consolidated Trial Balance (4).
        GLAccount.CalcFields("Additional-Currency Net Change");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(AmountCaption, GLAccount."Additional-Currency Net Change" / Fraction);
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalance4RequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordNetChangeBusUnitConsolidatedTrialBal4()
    begin
        // Purpose of the test is to validate G/L Account -OnAfterGetRecord Trigger of Report ID - 10008 Consolidated Trial Balance (4).

        // Setup: Test to verify AmountCap is updated with Net Change.
        Initialize();
        OnAfterGetRecordNetChangeConsolidatedTrialBal4(CreateBusinessUnit(), AmountCap);
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalance4RequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordNetChangeAmtConsolidatedTrialBal4()
    begin
        // Purpose of the test is to validate G/L Account -OnAfterGetRecord Trigger of Report ID - 10008 Consolidated Trial Balance (4).

        // Setup: Test to verify Net Change is updated as Elimination Amount on Report Consolidated Trial Balance (4).
        Initialize();
        OnAfterGetRecordNetChangeConsolidatedTrialBal4('', EliminationAmountCap);
    end;

    local procedure OnAfterGetRecordNetChangeConsolidatedTrialBal4(BusinessUnitCode: Code[10]; AmountCaption: Text)
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        AmountType: Option "Net Change",Balance;
    begin
        CreateGLAccount(GLAccount);
        CreateBusinessUnit();  // Business Unit Required to avoid Report Break.
        CreateGLEntry(GLEntry, GLAccount."No.", '', BusinessUnitCode, GLEntry."Bal. Account Type");

        // Exercise.
        LibraryVariableStorage.Enqueue(AmountType::"Net Change");  // Required inside ConsolidatedTrialBalance4RequestPageHandler.
        RunReportWithApplicationAreaDisabled(REPORT::"Consolidated Trial Balance (4)");  // Opens ConsolidatedTrialBalance4RequestPageHandler.

        // Verify: Verify Net Change is updated as Elimination Amount on Report Consolidated Trial Balance (4).
        GLAccount.CalcFields("Net Change");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(AmountCaption, GLAccount."Net Change");
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalance4UseAddRptCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordEliminationAmtTypeBalConsolidatedTrialBal4()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        AmountType: Option "Net Change",Balance;
    begin
        // Purpose of the test is to validate G/L Account -OnAfterGetRecord Trigger of Report ID - 10008 Consolidated Trial Balance (4).
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateBusinessUnit();  // Business Unit Required to avoid Report Break.
        CreateGLEntry(GLEntry, GLAccount."No.", '', '', GLEntry."Bal. Account Type");
        UpdateGLSetupAdditionalReportingCurrency();

        // Exercise.
        LibraryVariableStorage.Enqueue(AmountType::Balance);  // Required inside ConsolidatedTrialBalance4UseAddRptCurrRequestPageHandler.
        RunReportWithApplicationAreaDisabled(REPORT::"Consolidated Trial Balance (4)");  // Opens ConsolidatedTrialBalance4UseAddRptCurrRequestPageHandler.

        // Verify: Verify Additional-Currency Balance At Date is updated as Elimination Amount on Report Consolidated Trial Balance (4).
        GLAccount.CalcFields("Add.-Currency Balance at Date");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(EliminationAmountCap, GLAccount."Add.-Currency Balance at Date");
    end;

    [Test]
    [HandlerFunctions('ConsolidatedTrialBalance4RequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordNetChangeTypeBalConsolidatedTrialBal4()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        AmountType: Option "Net Change",Balance;
    begin
        // Purpose of the test is to validate G/L Account -OnAfterGetRecord Trigger of Report ID - 10008 Consolidated Trial Balance (4).
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateBusinessUnit();  // Business Unit Required to avoid Report Break.
        CreateGLEntry(GLEntry, GLAccount."No.", '', CreateBusinessUnit(), GLEntry."Bal. Account Type");

        // Exercise.
        LibraryVariableStorage.Enqueue(AmountType::Balance);  // Required inside ConsolidatedTrialBalance4RequestPageHandler.
        RunReportWithApplicationAreaDisabled(REPORT::"Consolidated Trial Balance (4)");  // Opens ConsolidatedTrialBalance4RequestPageHandler.

        // Verify: Verify Balance At Date of G/L Account is updated on report Consolidated Trial Balance (4).
        GLAccount.CalcFields("Balance at Date");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Amount_2_', GLAccount."Balance at Date");
    end;

    [Test]
    [HandlerFunctions('CrossReferenceBySourceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLEntryCrossReferenceBySource()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        SourceCode: Record "Source Code";
        GLRegister: Record "G/L Register";
    begin
        // Purpose of the test is to validate G/L Entry -OnAfterGetRecord Trigger of Report ID - 10010 Cross Reference by Source.
        // Setup.
        Initialize();
        CreateSourceCode(SourceCode);
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLEntry, GLAccount."No.", '', '', GLEntry."Bal. Account Type");
        CreateGLRegister(SourceCode.Code, GLEntry."Entry No.");

        // Exercise.
        LibraryVariableStorage.Enqueue(Format(GLEntry."Entry No."));  // Required inside CrossReferenceBySourceRequestPageHandler.
        REPORT.Run(REPORT::"Cross Reference by Source");  // Opens CrossReferenceBySourceRequestPageHandler.

        // Verify: Verify Filters of G/L Entry, Debit amount and Credit Amount is updated on Report Cross Reference by Account No.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TableCaptionGLRegFilter', StrSubstNo('%1: %2: %3', GLRegister.TableCaption(), GLRegister.FieldCaption("From Entry No."), GLEntry."Entry No."));
        LibraryReportDataset.AssertElementWithValueExists(DebitAmountGLEntryCap, GLEntry."Debit Amount");
        LibraryReportDataset.AssertElementWithValueExists(CreditAmountGLEntryCap, GLEntry."Credit Amount");
    end;

    [Test]
    [HandlerFunctions('PrintCashApplicationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintCashApplication()
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 333888] Report "Cash Appliction" can be printed without RDLC rendering errors
        Initialize();

        // [WHEN] Report "Cash Application" is being printed to PDF
        Report.Run(Report::"Cash Application");
        // [THEN] No RDLC rendering errors
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount.Totaling := GLAccount."No.";
        GLAccount.Insert();
        LibraryVariableStorage.Enqueue(GLAccount."No.");  // Required inside multiple RequestPageHandlers
    end;

    local procedure CreateBusinessUnit(): Code[10]
    var
        BusinessUnit: Record "Business Unit";
    begin
        BusinessUnit.Code := LibraryUTUtility.GetNewCode10();
        BusinessUnit.Consolidate := true;
        BusinessUnit.Insert();
        exit(BusinessUnit.Code);
    end;

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; BalAccountNo: Code[20]; BusinessUnitCode: Code[20]; BalAccountType: Enum "Gen. Journal Account Type")
    var
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."Source Type" := GLEntry."Source Type"::" ";
        GLEntry."IC Partner Code" := LibraryUTUtility.GetNewCode();
        GLEntry."Bal. Account Type" := BalAccountType;
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Bal. Account No." := BalAccountNo;
        GLEntry."Business Unit Code" := BusinessUnitCode;
        GLEntry.Amount := LibraryRandom.RandDec(10, 2);
        GLEntry."Additional-Currency Amount" := LibraryRandom.RandDec(10, 2);
        GLEntry."Debit Amount" := LibraryRandom.RandDec(10, 2);
        GLEntry."Credit Amount" := LibraryRandom.RandDec(10, 2);
        GLEntry."Posting Date" := WorkDate();
        GLEntry.Insert();
    end;

    local procedure CreateGLRegister(SourceCode: Code[10]; GLEntryNo: Integer)
    var
        GLRegister2: Record "G/L Register";
        GLRegister: Record "G/L Register";
    begin
        GLRegister2.FindLast();
        GLRegister."No." := GLRegister2."No." + 1;
        GLRegister."From Entry No." := GLEntryNo;
        GLRegister."To Entry No." := GLEntryNo;
        GLRegister."Source Code" := SourceCode;
        GLRegister.Insert();
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

    local procedure CreateGIFICode(): Code[10]
    var
        GIFICode: Record "GIFI Code";
    begin
        GIFICode.Code := LibraryUTUtility.GetNewCode10();
        GIFICode.Insert();
        exit(GIFICode.Code);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        LibraryUtility.FillFieldMaxText(Vendor, Vendor.FieldNo(Name));
        exit(Vendor."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        LibraryUtility.FillFieldMaxText(Customer, Customer.FieldNo(Name));
        exit(Customer."No.");
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount.Insert();
        LibraryUtility.FillFieldMaxText(BankAccount, BankAccount.FieldNo(Name));
        exit(BankAccount."No.");
    end;

    local procedure CreateICPartner(): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Code := LibraryUTUtility.GetNewCode();
        ICPartner.Insert();
        LibraryUtility.FillFieldMaxText(ICPartner, ICPartner.FieldNo(Name));
        exit(ICPartner.Code);
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset."No." := LibraryUTUtility.GetNewCode();
        FixedAsset.Insert();
        LibraryUtility.FillFieldMaxText(FixedAsset, FixedAsset.FieldNo(Description));
        exit(FixedAsset."No.");
    end;

    local procedure CreateSourceCode(var SourceCode: Record "Source Code")
    begin
        SourceCode.Code := LibraryUTUtility.GetNewCode10();
        SourceCode.Insert();
    end;

    local procedure CreateCustomerLedgerEntry(): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry2.FindLast();
        CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry.Insert();
        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure CreateVendorLedgerEntry(): Integer
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry2.FindLast();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry.Insert();
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure CreateDetailedCustomerLedgerEntries(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CurrencyCode: Code[10])
    var
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry2.FindLast();
        DetailedCustLedgEntry."Entry No." := DetailedCustLedgEntry2."Entry No." + 1;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CreateCustomerLedgerEntry();
        DetailedCustLedgEntry."Currency Code" := CurrencyCode;
        DetailedCustLedgEntry.Amount := LibraryRandom.RandDec(10, 2);
        DetailedCustLedgEntry."Amount (LCY)" := LibraryRandom.RandDec(10, 2);
        DetailedCustLedgEntry.Insert(true);
    end;

    local procedure CreateDetailedVendorLedgerEntries(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; CurrencyCode: Code[10])
    var
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry2.FindLast();
        DetailedVendorLedgEntry."Entry No." := DetailedVendorLedgEntry2."Entry No." + 1;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := CreateVendorLedgerEntry();
        DetailedVendorLedgEntry."Currency Code" := CurrencyCode;
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDec(10, 2);
        DetailedVendorLedgEntry."Amount (LCY)" := LibraryRandom.RandDec(10, 2);
        DetailedVendorLedgEntry.Insert(true);
    end;

    local procedure GetAccountName(AccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"): Text
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        FixedAsset: Record "Fixed Asset";
        ICPartner: Record "IC Partner";
        BankAccount: Record "Bank Account";
    begin
        case AccountType of
            AccountType::Customer:
                begin
                    Customer.Get(AccountNo);
                    exit(Customer.Name);
                end;
            AccountType::Vendor:
                begin
                    Vendor.Get(AccountNo);
                    exit(Vendor.Name);
                end;
            AccountType::"Fixed Asset":
                begin
                    FixedAsset.Get(AccountNo);
                    exit(FixedAsset.Description);
                end;
            AccountType::"IC Partner":
                begin
                    ICPartner.Get(AccountNo);
                    exit(ICPartner.Name);
                end;
            AccountType::"Bank Account":
                begin
                    BankAccount.Get(AccountNo);
                    exit(BankAccount.Name);
                end;
        end;
    end;

    local procedure UpdateGLSetupAdditionalReportingCurrency(): Text[30]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CreateCurrency();
        GeneralLedgerSetup.Modify();
        exit(GeneralLedgerSetup."Additional Reporting Currency");
    end;

    local procedure UpdateGLEntryPostingDate(var GLEntry: Record "G/L Entry")
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.FindFirst();
        GLEntry."Posting Date" := AccountingPeriod."Starting Date";
        GLEntry.Modify();
    end;

    local procedure UpdateGLEntryAdditionalCurrencyAmount(var GLEntry: Record "G/L Entry")
    begin
        GLEntry."Additional-Currency Amount" := -LibraryRandom.RandDec(10, 2);
        GLEntry.Modify();
    end;

    local procedure SaveAsXMLConsolidatedTrialBalanceReport(ConsolidatedTrialBalance: TestRequestPage "Consolidated Trial Balance")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ConsolidatedTrialBalance."G/L Account".SetFilter("No.", No);
        ConsolidatedTrialBalance.StartingDate.SetValue(WorkDate());
        ConsolidatedTrialBalance.EndingDate.SetValue(WorkDate());
        ConsolidatedTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure SaveAsXMLGeneralLedgerWorksheetReport(GeneralLedgerWorksheet: TestRequestPage "General Ledger Worksheet")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        GeneralLedgerWorksheet."G/L Account".SetFilter("No.", No);
        GeneralLedgerWorksheet.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure SaveAsXMLConsolidatedTrialBalance4Report(ConsolidatedTrialBalance4: TestRequestPage "Consolidated Trial Balance (4)")
    var
        No: Variant;
        AmountType: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(AmountType);
        ConsolidatedTrialBalance4."G/L Account".SetFilter("No.", No);
        ConsolidatedTrialBalance4.StartingDate.SetValue(WorkDate());
        ConsolidatedTrialBalance4.EndingDate.SetValue(WorkDate());
        ConsolidatedTrialBalance4.Show.SetValue(AmountType);
        ConsolidatedTrialBalance4.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure SaveAsXMLClosingTrialBalanceReport(ClosingTrialBalance: TestRequestPage "Closing Trial Balance")
    var
        No: Variant;
        FiscalYearStartingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(FiscalYearStartingDate);
        ClosingTrialBalance."G/L Account".SetFilter("No.", No);
        ClosingTrialBalance.FiscalYearStartingDate.SetValue(FiscalYearStartingDate);
        ClosingTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure VerifySourceOnGLRegisterReport(SourceName: Variant; GLEntrySourceType: Variant; DebitAmount: Variant; CreditAmount: Variant; GLEntryBalAccountNo: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SourceNameTok, SourceName);
        LibraryReportDataset.AssertElementWithValueExists(GLEntrySourceTypeTok, GLEntrySourceType);
        LibraryReportDataset.AssertElementWithValueExists(GLEntryBalAccountNoTok, GLEntryBalAccountNo);
        LibraryReportDataset.AssertElementWithValueExists(Sum1Tok, DebitAmount);
        LibraryReportDataset.AssertElementWithValueExists(Sum2Tok, CreditAmount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountBalancesByGIFICodeRequestPageHandler(var AccountBalancesByGIFICode: TestRequestPage "Account Balances by GIFI Code")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        AccountBalancesByGIFICode.BalanceAsOfDate.SetValue(WorkDate());
        AccountBalancesByGIFICode."G/L Account".SetFilter("No.", No);
        AccountBalancesByGIFICode.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountBalancesByGIFICodeAsOfDateRequestPageHandler(var AccountBalancesByGIFICode: TestRequestPage "Account Balances by GIFI Code")
    begin
        AccountBalancesByGIFICode.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidatedTrialBalanceStartingDateRequestPageHandler(var ConsolidatedTrialBalance: TestRequestPage "Consolidated Trial Balance")
    var
        StartingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        ConsolidatedTrialBalance.StartingDate.SetValue(StartingDate);
        ConsolidatedTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidatedTrialBalanceRequestPageHandler(var ConsolidatedTrialBalance: TestRequestPage "Consolidated Trial Balance")
    begin
        SaveAsXMLConsolidatedTrialBalanceReport(ConsolidatedTrialBalance);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidatedTrialBalanceUseAddRptCurrRequestPageHandler(var ConsolidatedTrialBalance: TestRequestPage "Consolidated Trial Balance")
    begin
        ConsolidatedTrialBalance.UseAdditionalReportingCurrency.SetValue(true);
        SaveAsXMLConsolidatedTrialBalanceReport(ConsolidatedTrialBalance);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidatedTrialBalanceInThousandsRequestPageHandler(var ConsolidatedTrialBalance: TestRequestPage "Consolidated Trial Balance")
    begin
        ConsolidatedTrialBalance.AmountsInWhole1000s.SetValue(true);
        ConsolidatedTrialBalance.UseAdditionalReportingCurrency.SetValue(true);
        SaveAsXMLConsolidatedTrialBalanceReport(ConsolidatedTrialBalance);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLRegisterRequestPageHandler(var GLRegister: TestRequestPage "G/L Register")
    var
        GLAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(GLAccountNo);
        GLRegister.IncludeAccountDesc.SetValue(true);
        GLRegister."G/L Entry".SetFilter("G/L Account No.", GLAccountNo);
        GLRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GeneralLedgerWorksheetUseAddRptCurrRequestPageHandler(var GeneralLedgerWorksheet: TestRequestPage "General Ledger Worksheet")
    begin
        GeneralLedgerWorksheet.UseAdditionalReportingCurrency.SetValue(true);
        SaveAsXMLGeneralLedgerWorksheetReport(GeneralLedgerWorksheet);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GeneralLedgerWorksheetRequestPageHandler(var GeneralLedgerWorksheet: TestRequestPage "General Ledger Worksheet")
    begin
        SaveAsXMLGeneralLedgerWorksheetReport(GeneralLedgerWorksheet);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BudgetRequestPageHandler(var Budget: TestRequestPage Budget)
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        Budget."G/L Account".SetFilter("No.", No);
        Budget.StartingPeriodDate.SetValue('P');  // Value of Starting Period Date on Report Budget.
        Budget.AmountsIn1000s.SetValue(true);
        Budget.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ChartOfAccountsRequestPageHandler(var ChartOfAccounts: TestRequestPage "Chart of Accounts")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ChartOfAccounts."G/L Account".SetFilter("No.", No);
        ChartOfAccounts.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ClosingTrialBalanceRequestPageHandler(var ClosingTrialBalance: TestRequestPage "Closing Trial Balance")
    begin
        SaveAsXMLClosingTrialBalanceReport(ClosingTrialBalance);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ClosingTrialBalanceUseAddRptCurrRequestPageHandler(var ClosingTrialBalance: TestRequestPage "Closing Trial Balance")
    begin
        ClosingTrialBalance.UseAdditionalReportingCurrency.SetValue(true);
        SaveAsXMLClosingTrialBalanceReport(ClosingTrialBalance);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CrossReferenceByAccountNoRequestPageHandler(var CrossReferenceByAccountNo: TestRequestPage "Cross Reference by Account No.")
    var
        GLAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(GLAccountNo);
        CrossReferenceByAccountNo."G/L Entry".SetFilter("G/L Account No.", GLAccountNo);
        CrossReferenceByAccountNo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CrossReferenceBySourceRequestPageHandler(var CrossReferenceBySource: TestRequestPage "Cross Reference by Source")
    var
        FromEntryNo: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(FromEntryNo);
        CrossReferenceBySource."G/L Register".SetFilter("From Entry No.", FromEntryNo);
        CrossReferenceBySource.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CurrencyBalancesRecPayRequestPageHandler(var CurrencyBalancesRecPay: TestRequestPage "Currency Balances - Rec./Pay.")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        CurrencyBalancesRecPay.Currency.SetFilter(Code, Code);
        CurrencyBalancesRecPay.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure RunReportWithApplicationAreaDisabled(ReportNumber: Integer)
    begin
        LibraryApplicationArea.DisableApplicationAreaSetup();
        REPORT.Run(ReportNumber);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidatedTrialBalance4StartingDateRequestPageHandler(var ConsolidatedTrialBalance4: TestRequestPage "Consolidated Trial Balance (4)")
    var
        StartingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        ConsolidatedTrialBalance4.StartingDate.SetValue(StartingDate);
        ConsolidatedTrialBalance4.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidatedTrialBalance4RequestPageHandler(var ConsolidatedTrialBalance4: TestRequestPage "Consolidated Trial Balance (4)")
    begin
        SaveAsXMLConsolidatedTrialBalance4Report(ConsolidatedTrialBalance4);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidatedTrialBalance4UseAddRptCurrRequestPageHandler(var ConsolidatedTrialBalance4: TestRequestPage "Consolidated Trial Balance (4)")
    begin
        ConsolidatedTrialBalance4.UseAdditionalReportingCurrency.SetValue(true);
        SaveAsXMLConsolidatedTrialBalance4Report(ConsolidatedTrialBalance4);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidatedTrialBalance4InThousandsRequestPageHandler(var ConsolidatedTrialBalance4: TestRequestPage "Consolidated Trial Balance (4)")
    begin
        ConsolidatedTrialBalance4.AmountsInWhole1000s.SetValue(true);
        ConsolidatedTrialBalance4.UseAdditionalReportingCurrency.SetValue(true);
        SaveAsXMLConsolidatedTrialBalance4Report(ConsolidatedTrialBalance4);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintCashApplicationRequestPageHandler(var CashApplication: TestRequestPage "Cash Application")
    begin
        CashApplication.PaymentDate.SetValue(WorkDate());
        CashApplication.LastDueDate.SetValue(WorkDate());
        CashApplication.SaveAsPdf(FileManagement.ServerTempFileName('.pdf'));
    end;
}

