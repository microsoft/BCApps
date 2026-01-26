codeunit 144074 "ERM Fiscal Year France"
{
    // 1. Check error message while posting General Journal Line while Posting Date is from Fiscally Closed Fiscal Year.
    // 2. Check error message while posting General Journal Line while Posting Date is from Fiscally Closed Fiscal Period.
    // 
    // Covers Test Cases for WI - 344839
    // --------------------------------------------------------------------------
    // Test Function Name                                      TFS ID
    // --------------------------------------------------------------------------
    // PostingDateOutsideAllowedPostingDateRangeError      151340, 152024
    // PostingDateInFiscallyClosedPeriodError              151792, 151745,151746

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Accounting Period]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        PostingDateErr: Label 'Posting Date is not within your range of allowed posting dates in Gen. Journal Line Journal Template Name=''%1'',Journal Batch Name=''%2'',Line No.=''%3''.', Comment = '%1: Field Value;%2: Field Value2;%3: Field Value3';
        ModifyPostingRangeErr: Label 'you must first modify the fields Allow Posting From and Allow Posting To';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        AccPeriodMustNotExistErr: Label 'Accounting period must not exist';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostingDateOutsideAllowedPostingDateRangeError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check error message while posting General Journal Line while Posting Date is from Fiscally Closed Fiscal Year.
        // Setup.
        FiscallyCloseFiscalYear();

        // Exercise.
        asserterror CreateAndPostGeneralJournalLine(GenJournalLine);

        // Verify: Verify Error that Posting Date is not Allowed Posting Range.
        Assert.ExpectedError(
          StrSubstNo(PostingDateErr, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostingDateInFiscallyClosedPeriodError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check error message while posting General Journal Line while Posting Date is from Fiscally Closed Fiscal Period.
        // Setup.
        FiscallyCloseFiscalPeriod();

        // Exercise.
        asserterror CreateAndPostGeneralJournalLine(GenJournalLine);

        // Verify: Verify Error that Posting Date is not Allowed Posting Range.
        Assert.ExpectedError(
          StrSubstNo(PostingDateErr, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountingPeriodValidateNewFiscalYearInAllowedPeriodFails()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // [FEATURE] [Allowed Posting Period]
        // [SCENARIO 273709] "New Fiscal Year" in accounting period can be changed from TRUE to FALSE when allowed posting period is outside of this period

        Initialize();

        // [GIVEN] Two fiscal years: 2020-01-01..2020-12-31 and 2021-01-01..2021-12-31
        CreateAccountingPeriods();
        FindNewFiscalYear(AccountingPeriod);

        // [GIVEN] "Allow Posting From" in General Ledger Setup is 2021-01-01
        UpdateGLSetupAllowPostingFrom(AccountingPeriod."Starting Date");

        // [WHEN] Change the "New Fiscal Year" field to FALSE
        AccountingPeriod.FindLast();
        asserterror AccountingPeriod.Validate("New Fiscal Year", false);

        // [THEN] Error: Allow Posting From and Allow Posting To must be outside of the year being deleted
        Assert.ExpectedError(ModifyPostingRangeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAccountingPeriodInAllowedPeriodFails()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // [FEATURE] [Allowed Posting Period]
        // [SCENARIO 273709] Accounting period can be deleted when allowed posting period is outside of this period

        Initialize();

        // [GIVEN] Two fiscal years: 2020-01-01..2020-12-31 and 2021-01-01..2021-12-31
        CreateAccountingPeriods();
        FindNewFiscalYear(AccountingPeriod);

        // [GIVEN] "Allow Posting From" in General Ledger Setup is 2021-01-01
        UpdateGLSetupAllowPostingFrom(AccountingPeriod."Starting Date");

        // [WHEN] Delete the accounting period
        AccountingPeriod.FindLast();
        asserterror AccountingPeriod.Delete(true);

        // [THEN] Error: Allow Posting From and Allow Posting To must be outside of the year being deleted
        Assert.ExpectedError(ModifyPostingRangeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountingPeriodValidateNewFiscalYearOutsideAllowedPeriodSucceeds()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // [FEATURE] [Allowed Posting Period]
        // [SCENARIO 273709] "New Fiscal Year" in accounting period can be changed from TRUE to FALSE when allowed posting period is outside of this period

        Initialize();

        // [GIVEN] Two fiscal years: 2020-01-01..2020-12-31 and 2021-01-01..2021-12-31
        CreateAccountingPeriods();

        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.FindFirst();

        // [GIVEN] "Allow Posting From" in General Ledger Setup is 2020-01-01
        UpdateGLSetupAllowPostingFrom(AccountingPeriod."Starting Date");

        // [WHEN] Change the "New Fiscal Year" field to FALSE
        AccountingPeriod.FindLast();
        AccountingPeriod.Validate("New Fiscal Year", false);

        // [THEN] Average cost account settings are reset to default values
        AccountingPeriod.TestField("Average Cost Calc. Type", AccountingPeriod."Average Cost Calc. Type"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAccountingPeriodOutsideAllowedPeriodSucceeds()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // [FEATURE] [Allowed Posting Period]
        // [SCENARIO 273709] Accounting period can be deleted when allowed posting period is outside of this period

        Initialize();

        // [GIVEN] Two fiscal years: 2020-01-01..2020-12-31 and 2021-01-01..2021-12-31
        CreateAccountingPeriods();

        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.FindFirst();

        // [GIVEN] "Allow Posting From" in General Ledger Setup is 2020-01-01
        UpdateGLSetupAllowPostingFrom(AccountingPeriod."Starting Date");

        // [WHEN] Delete the accounting period
        AccountingPeriod.FindLast();
        AccountingPeriod.Delete(true);

        // [THEN] Accounting period is deleted
        Assert.IsFalse(AccountingPeriod.Find(), AccPeriodMustNotExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateNotAllowedInFiscallyCloseYear()
    var
        AccountingPeriod: Record "Accounting Period";
        GLSetup: Record "General Ledger Setup";
        FiscalYearFiscalClose: Codeunit "Fiscal Year-FiscalClose";
    begin
        // [SCENARIO 436804] Expect the error message at Field-"Allow Posting From" in General Ledger Setup when Fiscally Close Year.
        Initialize();

        // [GIVEN] Two fiscal years: 2020-01-01..2020-12-31 and 2021-01-01..2021-12-31
        CreateAccountingPeriods();

        // [GIVEN] Close the fiscal year in accounting period.
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange(Closed, true);
        if AccountingPeriod.FindFirst() then
            FiscalYearFiscalClose.Run(AccountingPeriod);

        // [WHEN] Modify "Allow Posting From" in General Ledger Setup as 2021-01-01
        // [THEN] Expect the error from Field "Allow Posting From" in General Ledger Setup
        asserterror GLSetup.Validate("Allow Posting From", GetFirstAccountingPeriodDate(true));
    end;

    [Test]
    procedure VerifyAllowPostingRangeinCloseFiscalYear()
    var
        AccountingPeriod: Record "Accounting Period";
        FiscalYearFiscalClose: Codeunit "Fiscal Year-FiscalClose";
        UserSetup: Record "User Setup";
    begin
        // [SCENARIO 454771] Expect the error message at Field-"Allow Posting From" and "Allow Posting To"in User Setup when Fiscally Close Year.
        Initialize();

        // [GIVEN] Two fiscal years: 2020-01-01..2020-12-31 and 2021-01-01..2021-12-31
        CreateAccountingPeriods();

        // [GIVEN] Close the fiscal year in accounting period.
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange(Closed, true);
        if AccountingPeriod.FindFirst() then
            FiscalYearFiscalClose.Run(AccountingPeriod);

        // [GIVEN] Create User Setup 
        LibraryTimeSheet.CreateUserSetup(UserSetup, false);

        // [VERIFY] Validate Allow Posting From and To field giving error on Close fiscal year
        asserterror UserSetup.Validate("Allow Posting From", GetFirstAccountingPeriodDate(true));
        asserterror UserSetup.Validate("Allow Posting To", GetFirstAccountingPeriodDate(true));
    end;

    [Test]
    procedure AllowPostingFromAndToFieldInUserSetuSetBlank()
    var
        AccountingPeriod: Record "Accounting Period";
        UserSetup: array[2] of Record "User Setup";
    begin
        // [SCENARIO 610095] Allow Posting From and To field in User Setup can be set blank.
        Initialize();

        // [GIVEN] Create a fiscal year.
        CreateAccountingPeriods();

        FindNewFiscalYear(AccountingPeriod);

        // [GIVEN] Create User Setup 
        LibraryTimeSheet.CreateUserSetup(UserSetup[1], false);

        // [GIVEN] Set Allow Posting From to first Accounting Period Date date.
        UserSetup[1].Validate("Allow Posting From", AccountingPeriod."Starting Date");
        UserSetup[1].Modify(true);

        // [GIVEN] Get the same User Setup record in another variable.
        UserSetup[2].Get(UserSetup[1]."User ID");

        // [THEN] Validate Allow Posting From to blank date.
        UserSetup[1].Validate("Allow Posting From", 0D);
        UserSetup[1].Modify(true);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        IsInitialized := true;
    end;

    local procedure CreateAccountingPeriods()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.DeleteAll();
        LibraryFiscalYear.CreateFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();
    end;

    local procedure CreateAndPostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(100, 2));  // Random Amount.
        GenJournalLine.Validate("Posting Date", GetFirstAccountingPeriodDate(true));
        GenJournalLine.Validate("VAT Reporting Date", GetFirstAccountingPeriodDate(false));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure FindNewFiscalYear(var AccountingPeriod: Record "Accounting Period")
    begin
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange("Date Locked", false);
        AccountingPeriod.FindFirst();
    end;

    local procedure FiscallyCloseFiscalYear()
    var
        AccountingPeriods: TestPage "Accounting Periods";
    begin
        AccountingPeriods.OpenView();
        AccountingPeriods."F&iscally Close Year".Invoke();
        AccountingPeriods.Close();
    end;

    local procedure FiscallyCloseFiscalPeriod()
    var
        AccountingPeriods: TestPage "Accounting Periods";
    begin
        AccountingPeriods.OpenView();
        AccountingPeriods.FILTER.SetFilter(Closed, Format(true));
        AccountingPeriods.FILTER.SetFilter("Fiscally Closed", Format(false));
        AccountingPeriods.CloseFiscalPeriod.Invoke();
        AccountingPeriods.Close();
    end;

    local procedure GetFirstAccountingPeriodDate(FiscallyClosed: Boolean): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.SetRange("Fiscally Closed", FiscallyClosed);
        AccountingPeriod.FindFirst();
        exit(AccountingPeriod."Starting Date");
    end;

    local procedure UpdateGLSetupAllowPostingFrom(AllowPostingFromDate: Date)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Allow Posting From" := AllowPostingFromDate;
        GLSetup.Modify();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

