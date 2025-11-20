codeunit 139317 "Company Consol. Wizard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Company Creation Wizard]
        IsInitialized := false;
    end;

    var
        Company: Record Company;
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
#if not CLEAN25
        SpecifyCompanyNameErr: Label 'To continue, you must specify a name for the company.';
        SpecifyBusinessUnitCodeTxt: Label 'Enter a Business Unit Code.';
#endif
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        NewCompanyName: Text[30];
        ConsolidatedCompanyName: Text[30];
        Text004Err: Label 'Enter the starting date for the consolidation period.';
        Text005Err: Label 'Enter the ending date for the consolidation period.';
        GLEntryErrTagTok: Label 'ErrorText_Number__Control23';
        GLEntryDimensionErr: Label 'G/L Entry %1: The %2 must be %3 for %4 %5 for %6 %7. Currently it''s %8.', Comment = '%1 = G/L Entry No., %2 = "Dimension value code" caption, %3 = expected "Dimension value code" value, %4 = "Dimension code" caption, %5 = "Dimension Code" value, %6 = Table caption (Vendor), %7 = Table value (XYZ), %8 = current "Dimension value code" value';
#if not CLEAN25
        EmptyCompanyNameErr: Label 'You must choose a company.';
#endif
        Text017Txt: Label '%1 %2 in %3 has a %4 %5 that doesn''t exist in %6.', Comment = '%1=Field caption for Dimension Code field.;%2=Dimension Code value.;%3=Current Company Name value.;%4=Field caption for Consolidation Code.;%5=Consolidation Code value.;%6=Current Company name.';
        IsInitialized: Boolean;

#if not CLEAN25
    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyCompanyCreatedWhenWizardCompleted()
    var
        BusinessUnit: Record "Business Unit";
        CompanyConsolidationWizard: TestPage "Company Consolidation Wizard";
    begin
        // [GIVEN] Create a New company used for Business Unit
        Initialize();
        NewCompanyName := CreateCompany();

        // [WHEN] New consolidated company and 1 business unit is created
        ConsolidatedCompanyName := LibraryUtility.GenerateRandomCode(Company.FieldNo(Name), DATABASE::Company);
        RunConsolidationWizardToCompletion(CompanyConsolidationWizard, NewCompanyName, ConsolidatedCompanyName);
        CompanyConsolidationWizard.ActionFinish.Invoke();

        // [THEN] Verify new consolidated company is created and business units are created.
        Assert.IsTrue(Company.Get(ConsolidatedCompanyName), 'The new company was not created');
        Assert.IsFalse(IsNullGuid(Company.Id), 'An Id was not created for the new company');

        BusinessUnit.ChangeCompany(ConsolidatedCompanyName);
        Assert.IsTrue(BusinessUnit.FindFirst(), 'Business Unit has not been created.');
    end;

    [Test]
    [HandlerFunctions('PickCompanyModalHandler,HandleReportRequestPage')]
    [Scope('OnPrem')]
    procedure VerifyBusinessUnitsCreateWithExistingCompany()
    var
        BusinessUnit: Record "Business Unit";
        CompanyConsolidationWizard: TestPage "Company Consolidation Wizard";
    begin
        // [GIVEN] Create a New company used for Business Unit
        Initialize();
        NewCompanyName := CreateCompany();
        ConsolidatedCompanyName := CreateCompany();
        PopulateConsolidationAccounts();

        // [WHEN] New consolidated company and 1 business unit is created
        RunConsolidationWizardToCompletionExistingCompany(CompanyConsolidationWizard, NewCompanyName, ConsolidatedCompanyName);
        LibraryVariableStorage.Enqueue('');
        CompanyConsolidationWizard.ActionFinish.Invoke();

        // [THEN] Verify new consolidated company is created and business units are created.
        Assert.IsTrue(Company.Get(ConsolidatedCompanyName), 'The new company was not created');
        Assert.IsFalse(IsNullGuid(Company.Id), 'An Id was not created for the new company');

        BusinessUnit.ChangeCompany(ConsolidatedCompanyName);
        Assert.IsTrue(BusinessUnit.FindFirst(), 'Business Unit has not been created.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyErrorWithExistingCompany()
    var
        CompanyConsolidationWizard: TestPage "Company Consolidation Wizard";
    begin
        // [GIVEN] Create a New company used for Business Unit
        Initialize();
        NewCompanyName := CreateCompany();
        ConsolidatedCompanyName := CreateCompany();
        PopulateConsolidationAccounts();

        // [WHEN] New consolidated company and 1 business unit is created
        RunConsolidationWizardExistingCompanyNoCompanyEntered(CompanyConsolidationWizard);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WizardStopsWhenCompanyNameNotSpecified()
    var
        CompanyConsolidationWizard: TestPage "Company Consolidation Wizard";
    begin
        // [GIVEN] An openend company creation wizard on the Basic information page
        Initialize();
        CompanyConsolidationWizard.Trap();
        PAGE.Run(PAGE::"Company Consolidation Wizard");
        CompanyConsolidationWizard.ActionNext.Invoke(); // Welcome
        CompanyConsolidationWizard.ActionNext.Invoke(); // Choose to create company

        // [WHEN] No company name is entered and next is pressed
        asserterror CompanyConsolidationWizard.ActionNext.Invoke(); // Basic Information

        // [THEN] An error message is thrown, preventing the user from continuing
        Assert.ExpectedError(SpecifyCompanyNameErr);
        CompanyConsolidationWizard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WizardStopsWhenBusinessCodeNotSpecified()
    var
        CompanyConsolidationWizard: TestPage "Company Consolidation Wizard";
    begin
        // [GIVEN] Create a New company used for Business Unit
        Initialize();

        CompanyConsolidationWizard.Trap();
        PAGE.Run(PAGE::"Company Consolidation Wizard");

        CompanyConsolidationWizard.ActionNext.Invoke(); // Welcome page
        CompanyConsolidationWizard.ActionNext.Invoke(); // Choose to create company
        CompanyConsolidationWizard.CompanyName.SetValue('NEWCOMPANY');
        CompanyConsolidationWizard.CompanyData.SetValue(1); // Set to None to avoid lengthy data import
        CompanyConsolidationWizard.ActionNext.Invoke(); // Basic Information page
        CompanyConsolidationWizard.ActionNext.Invoke(); // Choose Source Companies

        // [WHEN] A Business Unit Code is not entered
        asserterror CompanyConsolidationWizard.ActionNext.Invoke();
        // [THEN] An error is given stating "Enter a Business Unit Code."
        Assert.ExpectedError(SpecifyBusinessUnitCodeTxt);
        CompanyConsolidationWizard.Close();
    end;
#endif

    [Test]
    [HandlerFunctions('ConsolidationTestReportHandlerAllFieldsEntered')]
    [Scope('OnPrem')]
    procedure PrintGLAccountInConsolidationTestReport()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 372262] "G/L Account No." should be printed in "Consolidation - Test Database" report if related G/L Entry exists

        Initialize();
        // [GIVEN] G/L Account = "X" with Consolidation Setup and posted G/L Entry
        CreateGLAccountWithConsolidationSetup(GLAccount);
        InsertGLEntry(GLAccount."No.");

        // [WHEN] Run "Consolidation - Test" report
        LibraryVariableStorage.Enqueue('');
        RunConsolidationTestReport();

        // [THEN] G/L Account = "X" is printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('G_L_Account__No__', GLAccount."No."));
    end;

    [Test]
    [HandlerFunctions('ConsolidationTestReportHandlerAllFieldsEntered')]
    [Scope('OnPrem')]
    procedure PrintGLAccountInConsolidationTestReportBusinessUnitNoStartingDate()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 372262] "G/L Account No." should be printed in "Consolidation - Test Database" report if related G/L Entry exists

        Initialize();
        // [GIVEN] G/L Account = "X" with Consolidation Setup and posted G/L Entry
        CreateGLAccountWithConsolidationSetup(GLAccount);
        InsertGLEntry(GLAccount."No.");

        // [WHEN] Run "Consolidation - Test Database" report
        LibraryVariableStorage.Enqueue('');
        RunConsolidationTestReportBUNoStartingDate();
    end;

    [Test]
    [HandlerFunctions('ConsolidationTestReportHandlerAllFieldsEntered')]
    [Scope('OnPrem')]
    procedure PrintGLAccountInConsolidationTestReportBusinessUnitNoEndingDate()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 372262] "G/L Account No." should be printed in "Consolidation - Test Database" report if related G/L Entry exists

        Initialize();
        // [GIVEN] G/L Account = "X" with Consolidation Setup and posted G/L Entry
        CreateGLAccountWithConsolidationSetup(GLAccount);
        InsertGLEntry(GLAccount."No.");

        // [WHEN] Run "Consolidation - Test Database" report
        LibraryVariableStorage.Enqueue('');
        RunConsolidationTestReportBUNoEndingDate();
    end;

    [Test]
    [HandlerFunctions('ConsolidationTestReportHandlerAllFieldsEntered')]
    [Scope('OnPrem')]
    procedure PrintGLAccountInConsolidationTestReportBusinessUnitStartDateGreaterEndDate()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 372262] "G/L Account No." should be printed in "Consolidation - Test Database" report if related G/L Entry exists

        Initialize();
        // [GIVEN] G/L Account = "X" with Consolidation Setup and posted G/L Entry
        CreateGLAccountWithConsolidationSetup(GLAccount);
        InsertGLEntry(GLAccount."No.");

        // [WHEN] Run "Consolidation - Test Database" report
        LibraryVariableStorage.Enqueue('');
        RunConsolidationTestReportBUStartingDateGreaterThanEndingDate();
    end;

    // TODO: Bug should not depend on ERM Consolidation
    procedure PrintGLAccountInConsolidationTestReportDimensions()
    var
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
        DimSetEntry: Record "Dimension Set Entry";
        DimSetID: Integer;
        GLEntryNo: Integer;
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 372262] "G/L Account No." should be printed in "Consolidation - Test Database" report if related G/L Entry exists

        Initialize();
        // [GIVEN] G/L Account = "X" with Consolidation Setup and posted G/L Entry
        CreateGLAccountWithConsolidationSetup(GLAccount);

        //ERMConsolidation.CreateBusinessUnit(BusinessUnit, BusinessUnit."Data Source"::"Local Curr. (LCY)");
        Commit();

        CreateSelectedDimension(DefaultDimension, DimSetID, GLAccount."No.");
        // [GIVEN] G/L Entry "GLE": "GLE"."G/L Account" = "X", "GLE".BusinessUnit = "BU", "GLE".Dimension Set = "DS"
        // GLEntryNo := ERMConsolidation.InsertGLEntryWithBusinessUnit(GLAccount."No.", BusinessUnit.Code, DimSetID);

        // [WHEN] Run "Consolidation - Test Database" report
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Code");
        RunConsolidationTestReport();

        // [THEN] G/L Account = "X" is printed
        LibraryDimension.FindDimensionSetEntry(DimSetEntry, DimSetID);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists(
          GLEntryErrTagTok,
          StrSubstNo(
            GLEntryDimensionErr, GLEntryNo, DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension."Dimension Value Code", DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code", GLAccount.TableCaption, GLAccount."No.", DimSetEntry."Dimension Value Code"));
    end;

    [Test]
    [HandlerFunctions('ConsolidationTestReportHandlerNoStartingDate')]
    [Scope('OnPrem')]
    procedure PrintGLAccountInConsolidationTestReportNoStartingDate()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 372262] "G/L Account No." should be printed in "Consolidation - Test Database" report if related G/L Entry exists

        Initialize();
        // [GIVEN] G/L Account = "X" with Consolidation Setup and posted G/L Entry
        CreateGLAccountWithConsolidationSetup(GLAccount);
        InsertGLEntry(GLAccount."No.");

        // [WHEN] Run "Consolidation - Test Database" report
        LibraryVariableStorage.Enqueue('');
        asserterror RunConsolidationTestReport();
        Assert.ExpectedError(Text004Err);
    end;

    [Test]
    [HandlerFunctions('ConsolidationTestReportHandlerNoEndingDate')]
    [Scope('OnPrem')]
    procedure PrintGLAccountInConsolidationTestReportNoEndingDate()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 372262] "G/L Account No." should be printed in "Consolidation - Test Database" report if related G/L Entry exists

        Initialize();
        // [GIVEN] G/L Account = "X" with Consolidation Setup and posted G/L Entry
        CreateGLAccountWithConsolidationSetup(GLAccount);
        InsertGLEntry(GLAccount."No.");

        // [WHEN] Run "Consolidation - Test Database" report
        LibraryVariableStorage.Enqueue('');
        asserterror RunConsolidationTestReport();
        Assert.ExpectedError(Text005Err);
    end;

    // TODO: Bug should not depend on ERM Consolidation
    procedure PrintGLAccountInConsolidationTestReportDimensionsError()
    var
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
        DimSetID: Integer;
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 372262] "G/L Account No." should be printed in "Consolidation - Test Database" report if related G/L Entry exists

        Initialize();
        // [GIVEN] G/L Account = "X" with Consolidation Setup and posted G/L Entry
        CreateGLAccountWithConsolidationSetup(GLAccount);

        // ERMConsolidation.CreateBusinessUnit(BusinessUnit, BusinessUnit."Data Source"::"Local Curr. (LCY)");
        Commit();

        CreateSelectedDimension(DefaultDimension, DimSetID, GLAccount."No.");
        // [GIVEN] G/L Entry "GLE": "GLE"."G/L Account" = "X", "GLE".BusinessUnit = "BU", "GLE".Dimension Set = "DS"
        // ERMConsolidation.InsertGLEntryWithBusinessUnit(GLAccount."No.", BusinessUnit.Code, DimSetID);

        // [WHEN] Run "Consolidation - Test Database" report
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Code");
        // [THEN] Error is shown
        RunConsolidationTestReportWithDimensionError(DefaultDimension."Dimension Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BusinessUnitFactorsWithCurrencyExchangeRateTableSetToBusinessUnit()
    var
        BusinessUnit: Record "Business Unit";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [Business Unit] [UT]
        // [SCENARIO 298231] When Business Unit's "Currency Exchange Rate Table" is set to "Business Unit" Income and Balance Currency Factors are calculated from Business Unit's Currency table
        Initialize();

        // [GIVEN] Company 'New'
        NewCompanyName := CreateCompany();

        // [GIVEN] Currency 'C' with Currency Code 'CC' in Company 'New'
        ExchangeRate := LibraryRandom.RandDec(10, 1);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRate, ExchangeRate);
        Currency.ChangeCompany(NewCompanyName);
        Currency.Init();
        Currency.Validate(Code, CurrencyCode);
        Currency.Insert(true);

        // [GIVEN] "LCY Code" is set to Currency Code 'CC' in original company
        LibraryERM.SetLCYCode(CurrencyCode);

        // [GIVEN] Exchange rate for Currency 'C' in Company 'New'
        CurrencyExchangeRate.ChangeCompany(NewCompanyName);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRate);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandIntInRange(2, 5));
        CurrencyExchangeRate.Modify(true);

        // [GIVEN] Business Unit with "Company Name" set to 'New' Company's name and Currency code set to 'CC'
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        BusinessUnit.Validate("Company Name", CompanyName);
        BusinessUnit.Validate("Currency Code", CurrencyCode);

        // [WHEN] Business Unit's "Currency Exchange Rate Table" is set to "Business Unit"
        BusinessUnit.Validate("Currency Exchange Rate Table", BusinessUnit."Currency Exchange Rate Table"::"Business Unit");
        BusinessUnit.Modify(true);

        // [THEN] Income and Balance Currency Factors are are calculated from Business Unit's Currency table Exchange Rate
        Assert.AreEqual(Round(1 / ExchangeRate), Round(BusinessUnit."Income Currency Factor"), '');
        Assert.AreEqual(Round(1 / ExchangeRate), Round(BusinessUnit."Balance Currency Factor"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BusinessUnitFactorsWithCurrencyExchangeRateTableSetToLocal()
    var
        BusinessUnit: Record "Business Unit";
        CurrencyCode: Code[10];
        ExchangeRateAmount: Decimal;
    begin
        // [FEATURE] [Business Unit] [UT]
        // [SCENARIO 298231] When Business Unit's "Currency Exchange Rate Table" is set to "Local" Income and Balance Currency Factors are calculated from current Company Currency table
        Initialize();

        // [GIVEN] Exchange rate for Currency
        ExchangeRateAmount := LibraryRandom.RandDec(10, 1);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRateAmount, ExchangeRateAmount);
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        BusinessUnit.Validate("Currency Code", CurrencyCode);

        // [WHEN] Business Unit's "Currency Exchange Rate Table" is set to "Local"
        BusinessUnit.Validate("Currency Exchange Rate Table", BusinessUnit."Currency Exchange Rate Table"::"Local");
        BusinessUnit.Modify(true);

        // [THEN] Income and Balance Currency Factors are are calculated from current Company's Currency table Exchange Rate
        Assert.AreEqual(ExchangeRateAmount, BusinessUnit."Income Currency Factor", '');
        Assert.AreEqual(ExchangeRateAmount, BusinessUnit."Balance Currency Factor", '');
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure Initialize()
    begin
        if NewCompanyName <> '' then
            DeleteCompany(NewCompanyName);
        if ConsolidatedCompanyName <> '' then
            DeleteCompany(ConsolidatedCompanyName);
        LibraryVariableStorage.Clear();

        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        IsInitialized := true;
    end;

#if not CLEAN25
    local procedure RunConsolidationWizardToCompletion(var CompanyConsolidationWizard: TestPage "Company Consolidation Wizard"; BusinessUnit: Text[30]; NewCompanyName: Text[30])
    var
        ConsolidationAccount: Record "Consolidation Account";
    begin
        CompanyConsolidationWizard.Trap();
        PAGE.Run(PAGE::"Company Consolidation Wizard");

        CompanyConsolidationWizard.ActionNext.Invoke(); // Welcome page
        CompanyConsolidationWizard.ActionNext.Invoke(); // Choose to create company
        CompanyConsolidationWizard.CompanyName.SetValue(NewCompanyName);
        CompanyConsolidationWizard.CompanyData.SetValue(1); // Set to None to avoid lengthy data import
        CompanyConsolidationWizard.ActionNext.Invoke(); // Basic Information page
        SelectCreatedCompanyForBusUnit(BusinessUnit);
        CompanyConsolidationWizard.ActionNext.Invoke(); // Choose Source Companies
        Assert.IsFalse(CompanyConsolidationWizard.ActionBack.Enabled(), 'Back should not be enabled');
        Assert.IsFalse(ConsolidationAccount.FindFirst(), 'Consolidation Account should have no accounts as we set CompanyData to None');
        CompanyConsolidationWizard.Code.SetValue('1');
        CompanyConsolidationWizard.ActionNext.Invoke(); // Set up consolidated company
        CompanyConsolidationWizard.ActionNext.Invoke(); // Set up consolidated company page 2
        Assert.IsFalse(CompanyConsolidationWizard.ActionBack.Enabled(), 'Back should not be enabled at the end of the wizard');
        Assert.IsFalse(CompanyConsolidationWizard.ActionNext.Enabled(), 'Next should not be enabled at the end of the wizard');
    end;

    local procedure RunConsolidationWizardToCompletionExistingCompany(var CompanyConsolidationWizard: TestPage "Company Consolidation Wizard"; BusinessUnit: Text[30]; NewCompanyName: Text[30])
    var
        ConsolidationAccount: Record "Consolidation Account";
    begin
        CompanyConsolidationWizard.Trap();
        PAGE.Run(PAGE::"Company Consolidation Wizard");

        CompanyConsolidationWizard.ActionNext.Invoke(); // Welcome page
        CompanyConsolidationWizard.SelectCompanyOption.SetValue(1);
        CompanyConsolidationWizard.ActionNext.Invoke(); // Choose to use existing company
        LibraryVariableStorage.Enqueue(NewCompanyName); // for PickCompanyModalHandler
        CompanyConsolidationWizard."Select Company".AssistEdit();
        CompanyConsolidationWizard.ActionNext.Invoke(); // Select Company
        SelectCreatedCompanyForBusUnit(BusinessUnit);
        Assert.IsFalse(ConsolidationAccount.FindFirst(), 'Consolidation Account should not be created');
        CompanyConsolidationWizard.ActionNext.Invoke(); // Choose Source Companies
        Assert.IsFalse(CompanyConsolidationWizard.ActionBack.Enabled(), 'Back should not be enabled');
        CompanyConsolidationWizard.Code.SetValue('1');
        Assert.IsTrue(ConsolidationAccount.FindFirst(), 'Consolidation Account should be created');
        // [THEN] Account should exist in the ConsolidationAccount table
        Assert.IsTrue(ConsolidationAccount.Get('10100'), 'Account should exist');
        CompanyConsolidationWizard.ActionNext.Invoke(); // Set up consolidated company
        CompanyConsolidationWizard.ActionNext.Invoke(); // Set up consolidated company page 2
        Assert.IsFalse(CompanyConsolidationWizard.ActionBack.Enabled(), 'Back should notbe enabled at the end of the wizard');
        Assert.IsFalse(CompanyConsolidationWizard.ActionNext.Enabled(), 'Next should not be enabled at the end of the wizard');
    end;

    local procedure RunConsolidationWizardExistingCompanyNoCompanyEntered(var CompanyConsolidationWizard: TestPage "Company Consolidation Wizard")
    begin
        CompanyConsolidationWizard.Trap();
        PAGE.Run(PAGE::"Company Consolidation Wizard");

        CompanyConsolidationWizard.ActionNext.Invoke(); // Welcome page
        CompanyConsolidationWizard.SelectCompanyOption.SetValue(1);
        CompanyConsolidationWizard.ActionNext.Invoke(); // Choose to use existing company
        asserterror CompanyConsolidationWizard.ActionNext.Invoke();
        Assert.ExpectedError(EmptyCompanyNameErr);
        CompanyConsolidationWizard.Close();
    end;
#endif

    local procedure CreateGLAccountWithConsolidationSetup(var GLAccount: Record "G/L Account")
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Consol. Debit Acc.", LibraryERM.CreateGLAccountNo());
        GLAccount.Validate("Consol. Credit Acc.", LibraryERM.CreateGLAccountNo());
        GLAccount.Modify(true);
    end;

    local procedure InsertGLEntry(GLAccNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry."G/L Account No." := GLAccNo;
        GLEntry."Posting Date" := WorkDate();
        GLEntry.Insert();
        exit(GLEntry."Entry No.");
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure SelectCreatedCompanyForBusUnit(NewCreatedBusUnit: Text[30])
    var
        BusinessUnitSetup: Record "Business Unit Setup";
    begin
        BusinessUnitSetup.Reset();
        if BusinessUnitSetup.Find('-') then
            repeat
                if BusinessUnitSetup."Company Name" <> NewCreatedBusUnit then begin
                    BusinessUnitSetup.Include := false;
                    BusinessUnitSetup.Modify();
                end;
            until BusinessUnitSetup.Next() = 0;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateCompany() NewCompanyName: Text[30]
    begin
        NewCompanyName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Company.Name)), 1, MaxStrLen(Company.Name));
        Company.LockTable(true);
        Company.Name := NewCompanyName;
        Company.Insert(true);
        Commit();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure DeleteCompany(CompanyName: Text[30])
    begin
        Company.SetRange(Name, CompanyName);
        if Company.FindFirst() then
            Company.Delete();
    end;

    [Scope('OnPrem')]
    procedure PopulateConsolidationAccounts()
    begin
        InsertData('10100', 'Checking account', 1, true);
        InsertData('10200', 'Savings account', 1, true);
        InsertData('10300', 'Petty Cash', 1, true);
        InsertData('10400', 'Accounts Receivable', 1, true);
        InsertData('10500', 'Prepaid Rent', 1, true);
        InsertData('10600', 'Prepaid Insurance', 1, true);
        InsertData('10700', 'Inventory', 1, true);
        InsertData('10800', 'Equipment', 1, true);
        InsertData('10900', 'Accumulated Depreciation', 1, true);
        InsertData('20100', 'Accounts Payable', 0, true);
        InsertData('20200', 'Purchase Discounts', 0, false);
        InsertData('20300', 'Purchase Returns & Allowances', 0, false);
        InsertData('20400', 'Deferred Revenue', 0, false);
        InsertData('20500', 'Credit Cards', 0, false);
        InsertData('20600', 'Sales Tax Payable', 0, false);
        InsertData('20700', 'Accrued Salaries & Wages', 0, true);
        InsertData('20800', 'Federal Withholding Payable', 0, true);
        InsertData('20900', 'State Withholding Payable', 0, true);
        InsertData('21000', 'FICA Payable', 0, true);
        InsertData('21100', 'Medicare Payable', 0, true);
        InsertData('21200', 'FUTA Payable', 0, true);
        InsertData('21300', 'SUTA Payable', 0, true);
        InsertData('21400', 'Employee Benefits Payable', 0, true);
        InsertData('21500', 'Vacation Compensation Payable', 0, true);
        InsertData('21600', 'Garnishment Payable', 0, true);
        InsertData('21700', 'Federal Income Taxes Payable', 0, true);
        InsertData('21800', 'State Income Tax Payable', 0, true);
        InsertData('21900', 'Notes Payable', 0, true);
        InsertData('30100', 'Capital Stock', 0, true);
        InsertData('30200', 'Retained Earnings', 0, true);
        InsertData('30300', 'Distributions to Shareholders', 0, true);
        InsertData('40000', 'INCOME STATEMENT', 0, true);
        InsertData('40001', 'INCOME', 0, true);
        InsertData('40100', 'Income, Services', 0, true);
        InsertData('40200', 'Income, Product Sales', 0, false);
        InsertData('40300', 'Sales Discounts', 0, false);
        InsertData('40400', 'Sales Returns & Allowances', 0, false);
        InsertData('40500', 'Interest Income', 0, true);
        InsertData('40990', 'TOTAL INCOME', 0, true);
        InsertData('50100', 'Cost of Materials', 1, false);
        InsertData('50200', 'Cost of Labor', 1, false);
        InsertData('60001', 'EXPENSES', 1, true);
        InsertData('60100', 'Rent Expense', 1, true);
        InsertData('60200', 'Advertising Expense', 1, true);
        InsertData('60300', 'Interest Expense', 1, true);
        InsertData('60400', 'Bank Charges and Fees', 1, true);
        InsertData('60500', 'Processing Fees', 1, true);
        InsertData('60600', 'Bad Debt Expense', 1, true);
        InsertData('60700', 'Salaries Expense', 1, true);
        InsertData('60800', 'Payroll Tax Expense', 1, true);
        InsertData('60900', 'Workers Compensation ', 1, true);
        InsertData('61000', 'Health & Dental Insurance Expense', 1, true);
        InsertData('61100', 'Life Insurance Expense', 1, true);
        InsertData('61200', 'Repairs and Maintenance Expense', 1, true);
        InsertData('61300', 'Utilities Expense', 1, true);
        InsertData('61400', 'Office Supplies Expense', 1, true);
        InsertData('61500', 'Miscellaneous Expense', 1, true);
        InsertData('61600', 'Depreciation, Equipment', 1, false);
        InsertData('61700', 'Federal Income Tax Expense', 1, true);
        InsertData('61800', 'State Income Tax Expense', 1, true);
        InsertData('61900', 'Rounding', 1, true);
        InsertData('61990', 'TOTAL EXPENSES', 1, true);
    end;

    local procedure InsertData(AccountNo: Code[20]; AccountName: Text[50]; IncomeBalance: Option; DirectPosting: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount.ChangeCompany(ConsolidatedCompanyName);
        GLAccount."No." := AccountNo;
        GLAccount.Name := AccountName;
        GLAccount."Direct Posting" := DirectPosting;
        GLAccount."Income/Balance" := "G/L Account Report Type".FromInteger(IncomeBalance);
        GLAccount.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVATBusinessPostingGroup(var VATBusinessPostingGroup: Record "VAT Business Posting Group")
    begin
        VATBusinessPostingGroup.Init();
        VATBusinessPostingGroup.ChangeCompany(ConsolidatedCompanyName);
        VATBusinessPostingGroup.Validate(
          Code,
          CopyStr(LibraryUtility.GenerateRandomCode(VATBusinessPostingGroup.FieldNo(Code), DATABASE::"VAT Business Posting Group"),
            1, LibraryUtility.GetFieldLength(DATABASE::"VAT Business Posting Group", VATBusinessPostingGroup.FieldNo(Code))));

        // Validating Code as Name because value is not important.
        VATBusinessPostingGroup.Validate(Description, VATBusinessPostingGroup.Code);
        VATBusinessPostingGroup.Insert(true);
    end;

    local procedure CreateBusinessUnit(var BusinessUnit: Record "Business Unit"; DataSource: Option)
    begin
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        BusinessUnit.Validate("Company Name", CompanyName);
        BusinessUnit.Validate("Residual Account", LibraryERM.CreateGLAccountNo());
        BusinessUnit.Validate("Data Source", DataSource);
        BusinessUnit.Modify(true);
    end;

    local procedure CreateBusinessUnitEmptyStartingDate(var BusinessUnit: Record "Business Unit"; DataSource: Option)
    begin
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        BusinessUnit.Validate("Company Name", CompanyName);
        BusinessUnit.Validate("Residual Account", LibraryERM.CreateGLAccountNo());
        BusinessUnit.Validate("Data Source", DataSource);
        BusinessUnit."Starting Date" := 0D;
        BusinessUnit."Ending Date" := WorkDate();
        BusinessUnit.Modify(true);
    end;

    local procedure CreateBusinessUnitEmptyEndingDate(var BusinessUnit: Record "Business Unit"; DataSource: Option)
    begin
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        BusinessUnit.Validate("Company Name", CompanyName);
        BusinessUnit.Validate("Residual Account", LibraryERM.CreateGLAccountNo());
        BusinessUnit.Validate("Data Source", DataSource);
        BusinessUnit."Starting Date" := WorkDate();
        BusinessUnit."Ending Date" := 0D;
        BusinessUnit.Modify(true);
    end;

    local procedure CreateBusinessUnitStartingDateGreaterThanEndingDate(var BusinessUnit: Record "Business Unit"; DataSource: Option)
    begin
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        BusinessUnit.Validate("Company Name", CompanyName);
        BusinessUnit.Validate("Residual Account", LibraryERM.CreateGLAccountNo());
        BusinessUnit.Validate("Data Source", DataSource);
        BusinessUnit."Starting Date" := WorkDate();
        BusinessUnit."Ending Date" := WorkDate() - 10;
        BusinessUnit.Modify(true);
    end;

    local procedure CreateSelectedDimension(var DefaultDimension: Record "Default Dimension"; var DimSetID: Integer; GLAccountCode: Code[20])
    var
        DimensionValueRec: Record "Dimension Value";
        SelectedDimensionRec: Record "Selected Dimension";
        DimensionSelectionBufferRec: Record "Dimension Selection Buffer";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValueRec);
        LibraryDimension.CreateDefaultDimension(DefaultDimension,
          DATABASE::"G/L Account", GLAccountCode, DimensionValueRec."Dimension Code", DimensionValueRec.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Same Code");
        DefaultDimension.Modify(true);
        LibraryDimension.CreateDimensionValue(DimensionValueRec, DefaultDimension."Dimension Code");
        Commit();
        DimSetID := LibraryDimension.CreateDimSet(0, DimensionValueRec."Dimension Code", DimensionValueRec.Code);
        SelectedDimensionRec.Init();
        LibraryDimension.CreateSelectedDimension(SelectedDimensionRec, 3,
          REPORT::"Consolidation - Test", '', DefaultDimension."Dimension Code");
        DimensionSelectionBufferRec.Init();
        DimensionSelectionBufferRec.Selected := true;
        DimensionSelectionBufferRec.Code := SelectedDimensionRec."Dimension Code";
        DimensionSelectionBufferRec.Insert();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure UpdateDimension(CompanyName: Text[30]; DimensionCode: Code[20])
    var
        Dimension: Record Dimension;
    begin
        Dimension.ChangeCompany(CompanyName);
        Dimension.SetRange(Code, DimensionCode);
        if Dimension.FindFirst() then begin
            Dimension."Consolidation Code" := 'TEST';
            Dimension.Modify();
        end;
    end;

    local procedure RunConsolidationTestReport()
    var
        BusinessUnit: Record "Business Unit";
    begin
        CreateBusinessUnit(BusinessUnit, BusinessUnit."Data Source"::"Local Curr. (LCY)");
        Commit();
        REPORT.Run(REPORT::"Consolidation - Test", true, false, BusinessUnit);
    end;

    local procedure RunConsolidationTestReportBUNoStartingDate()
    var
        BusinessUnit: Record "Business Unit";
    begin
        CreateBusinessUnitEmptyStartingDate(BusinessUnit, BusinessUnit."Data Source"::"Local Curr. (LCY)");
        Commit();
        REPORT.Run(REPORT::"Consolidation - Test", true, false, BusinessUnit);
    end;

    local procedure RunConsolidationTestReportBUNoEndingDate()
    var
        BusinessUnit: Record "Business Unit";
    begin
        CreateBusinessUnitEmptyEndingDate(BusinessUnit, BusinessUnit."Data Source"::"Local Curr. (LCY)");
        Commit();
        REPORT.Run(REPORT::"Consolidation - Test", true, false, BusinessUnit);
    end;

    local procedure RunConsolidationTestReportBUStartingDateGreaterThanEndingDate()
    var
        BusinessUnit: Record "Business Unit";
    begin
        CreateBusinessUnitStartingDateGreaterThanEndingDate(BusinessUnit, BusinessUnit."Data Source"::"Local Curr. (LCY)");
        Commit();
        REPORT.Run(REPORT::"Consolidation - Test", true, false, BusinessUnit);
    end;

    local procedure RunConsolidationTestReportWithDimensionError(DimensionCode: Code[20])
    var
        BusinessUnit: Record "Business Unit";
    begin
        CreateBusinessUnit(BusinessUnit, BusinessUnit."Data Source"::"Local Curr. (LCY)");
        UpdateDimension(BusinessUnit."Company Name", DimensionCode);
        Commit();
        REPORT.Run(REPORT::"Consolidation - Test", true, false, BusinessUnit);
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(LibraryReportDataset.FindRow('ErrorText_Number_', StrSubstNo(
              Text017Txt,
              'Dimension Code', DimensionCode, BusinessUnit."Company Name",
              'Consolidation Code', 'TEST',
              BusinessUnit."Company Name")), 0, 'Row should be 0');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure HandleReportRequestPage(var handler: TestRequestPage "Consolidation - Test")
    begin
        handler.CopyDimensions.SetValue(LibraryVariableStorage.DequeueText());
        handler.Cancel().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickCompanyModalHandler(var AccessibleCompanies: TestPage "Accessible Companies")
    var
        CompanyNameToPick: Text;
    begin
        CompanyNameToPick := LibraryVariableStorage.DequeueText(); // should be set from test
        AccessibleCompanies.GotoKey(CompanyNameToPick);
        Assert.IsFalse(AccessibleCompanies.SetupStatus.Editable(), 'SetupStatus.EDITABLE');
        LibraryVariableStorage.Enqueue(AccessibleCompanies.SetupStatus.AsInteger());
        AccessibleCompanies.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickDimModalHandler(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    var
        DimNameToPick: Text;
    begin
        DimNameToPick := LibraryVariableStorage.DequeueText(); // should be set from test
        DimensionSelectionMultiple.GotoKey(DimNameToPick);
        Assert.IsTrue(DimensionSelectionMultiple.Selected.Editable(), 'Selected NOT EDITABLE');
        DimensionSelectionMultiple.Selected.SetValue(true);
        DimensionSelectionMultiple.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidationTestReportHandlerAllFieldsEntered(var ConsolidationTest: TestRequestPage "Consolidation - Test")
    begin
        ConsolidationTest.StartingDate.SetValue(WorkDate());
        ConsolidationTest.EndingDate.SetValue(WorkDate());
        ConsolidationTest.CopyDimensions.SetValue(LibraryVariableStorage.DequeueText());
        ConsolidationTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidationTestReportHandlerAllFieldsEnteredDim(var ConsolidationTest: TestRequestPage "Consolidation - Test")
    begin
        ConsolidationTest.StartingDate.SetValue(WorkDate());
        ConsolidationTest.EndingDate.SetValue(WorkDate());
        LibraryVariableStorage.Enqueue(LibraryVariableStorage.DequeueText()); // should be set from test
        ConsolidationTest.CopyDimensions.AssistEdit();
        ConsolidationTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidationTestReportHandlerNoStartingDate(var ConsolidationTest: TestRequestPage "Consolidation - Test")
    begin
        ConsolidationTest.StartingDate.SetValue(0D);
        ConsolidationTest.EndingDate.SetValue(WorkDate());
        ConsolidationTest.CopyDimensions.SetValue(LibraryVariableStorage.DequeueText());
        ConsolidationTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidationTestReportHandlerNoEndingDate(var ConsolidationTest: TestRequestPage "Consolidation - Test")
    begin
        ConsolidationTest.StartingDate.SetValue(WorkDate());
        ConsolidationTest.EndingDate.SetValue(0D);
        ConsolidationTest.CopyDimensions.SetValue(LibraryVariableStorage.DequeueText());
        ConsolidationTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

