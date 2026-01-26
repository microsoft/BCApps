codeunit 144168 "ERM Company Information"
{
    //  1. Test to verify Company Information on the Report - Account Book Print When GL Account is Balance Statement.
    //  2. Test to verify Company Information on the Report - Account Book Print When GL Account is Income Statement.
    //  3. Test to verify Company Information on the Report - Account Book Print when Date filter applied.
    //  4. Test is to verify error message on Report - Account Book Print when Date Filter is blank.
    // 
    // Covers Test Cases for WI - 345128
    // -------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                             TFS ID
    // -------------------------------------------------------------------------------------------------------
    // AccountBookPrintWithIncomeStatement, AccountBookPrintWithBalanceSheet
    // AccountBookPrintWithDateFilter, AccountBookPrintWithBlankDateFilterError                        266292

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DateFilterErr: Label 'Specify a filter for the Date Filter field in the G/L Account table.';
        LibraryRandom: Codeunit "Library - Random";
        CurrentSaveValuesId: Integer;
        SpecialCharactersUsageErr: Label 'You cannot use special characters in Italian bank account numbers.';

    [Test]
    [HandlerFunctions('AccountBookPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccountBookPrintWithBalanceSheet()
    var
        GLAccount: Record "G/L Account";
    begin
        // Test to verify Company Information on the Report - Account Book Print when GL Account is Balance Sheet.
        CompanyInformationOnAccountBookPrint(GLAccount."Income/Balance"::"Balance Sheet");
    end;

    [Test]
    [HandlerFunctions('AccountBookPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccountBookPrintWithIncomeStatement()
    var
        GLAccount: Record "G/L Account";
    begin
        // Test to verify Company Information on the Report - Account Book Print when GL Account is Income Statement.
        CompanyInformationOnAccountBookPrint(GLAccount."Income/Balance"::"Income Statement");
    end;

    local procedure CompanyInformationOnAccountBookPrint(IncomeBalance: Enum "G/L Account Report Type")
    var
        GLAccountNo: Code[20];
    begin
        // Setup: Create G/L Account. Create and post General Journal Line.
        Initialize();
        GLAccountNo := CreateGLAccount(IncomeBalance);
        CreateAndPostGeneralJournalLine(GLAccountNo);
        EnqueueValuesForRequestPageHandler(GLAccountNo, WorkDate());  // Enqueue values for AccountBookPrintRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Account Book Sheet - Print");

        // Verify: Verify Company Information and GL Account No. on Report - Account Book Sheet - Print.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('G_L_Account_No_', GLAccountNo);
        VerifyCompanyInformation();
    end;

    [Test]
    [HandlerFunctions('AccountBookPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccountBookPrintWithDateFilter()
    begin
        // Test to verify Company Information on the Report - Account Book Print when Date Filter applied.
        // Setup: Enqueue values for AccountBookPrintRequestPageHandler.
        Initialize();
        EnqueueValuesForRequestPageHandler('', WorkDate());  // G/L Account No. as blank.

        // Exercise.
        REPORT.Run(REPORT::"Account Book Sheet - Print");

        // Verify: Verify Company Information on Report - Account Book Sheet - Print.
        LibraryReportDataset.LoadDataSetFile();
        VerifyCompanyInformation();
    end;

    [Test]
    [HandlerFunctions('AccountBookPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccountBookPrintWithBlankDateFilterError()
    begin
        // Test is to verify error message on Report - Account Book Print when Date Filter is blank.
        // Setup: Enqueue value for AccountBookPrintRequestPageHandler.
        Initialize();
        EnqueueValuesForRequestPageHandler('', 0D);  // G/L Account No. and Date Filter as blank.

        // Exercise.
        asserterror REPORT.Run(REPORT::"Account Book Sheet - Print");

        // Verify: Verify error on Report - Account Book Sheet - Print.
        Assert.ExpectedError(DateFilterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetSpecialCharactersInBankAccountNoForItalianIBAN()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO 262564] User is not able to enter special characters in Bank Account No. field if IBAN has Italian format

        // [GIVEN] Fill in IBAN field of Company Information table with Italian format value
        CompanyInformation.Init();
        CompanyInformation.IBAN := 'IT24S1234522224222344322223';

        // [WHEN] Validating Bank Account No. by 123-456-78 value
        asserterror CompanyInformation.Validate("Bank Account No.", '123-456-78');

        // [THEN] Error "You cannot use special characters in Italian bank account numbers." appears
        Assert.ExpectedError(SpecialCharactersUsageErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetItalianIBANForSpecialCharactersInBankAccountNo()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO 262564] User is not able to set IBAN field to Italian format if Bank Account No. field has special characters

        // [GIVEN] Bank Account No. by 123-456-78 value
        CompanyInformation.Init();
        CompanyInformation."Bank Account No." := '123-456-78';

        // [WHEN] Validatinf IBAN with Italian format value IT24S1234522224222344322223
        asserterror CompanyInformation.Validate(IBAN, 'IT24S1234522224222344322223');

        // [THEN] Error "You cannot use special characters in Italian bank account numbers." appears
        Assert.ExpectedError(SpecialCharactersUsageErr);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        DeleteObjectOptionsIfNeeded();

        // Needed to close any write transactions before running report.
        Commit();
    end;

    local procedure CreateAndPostGeneralJournalLine(GLAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, LibraryRandom.RandDec(100, 2));  // Using random value for Amount.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGLAccount(IncomeBalance: Enum "G/L Account Report Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
    begin
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", IncomeBalance);
        GLAccount.Validate("Business Unit Filter", BusinessUnit.Code);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure EnqueueValuesForRequestPageHandler(GLAccountNo: Code[20]; DateFilter: Date)
    begin
        LibraryVariableStorage.Enqueue(GLAccountNo);
        LibraryVariableStorage.Enqueue(DateFilter);
    end;

    local procedure VerifyCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibraryReportDataset.AssertElementWithValueExists('CompAddr_1_', CompanyInformation.Name);
        LibraryReportDataset.AssertElementWithValueExists('CompAddr_2_', CompanyInformation.Address);
        LibraryReportDataset.AssertElementWithValueExists('CompAddr_4_', CompanyInformation.City);
        LibraryReportDataset.AssertElementWithValueExists('CompAddr_3_', CompanyInformation."Post Code");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountBookPrintRequestPageHandler(var AccountBookSheetPrint: TestRequestPage "Account Book Sheet - Print")
    var
        No: Variant;
        DateFilter: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Account Book Sheet - Print";
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        AccountBookSheetPrint."G/L Account".SetFilter("No.", No);
        AccountBookSheetPrint."G/L Account".SetFilter("Date Filter", Format(DateFilter));
        AccountBookSheetPrint.ProgressiveBalance.SetValue(true);
        AccountBookSheetPrint.ShowAmountsInAddReportingCurrency.SetValue(true);
        AccountBookSheetPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure DeleteObjectOptionsIfNeeded()
    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
    begin
        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);
    end;
}

