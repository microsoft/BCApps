codeunit 134275 "Currency UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Currency]
    end;

    var
        Assert: Codeunit Assert;
        ASCIILetterErr: Label 'must contain ASCII letters only';
        NumericErr: Label 'must contain numbers only';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [Scope('OnPrem')]
    procedure T100_ISOCodeIs3ASCIIChars()
    var
        Currency: Record Currency;
    begin
        // [FEATURE] [ISO Code]
        // [SCENARIO] Allowed "ISO Code" can be blank or must contain 3 ASCII letters
        asserterror Currency.Validate("ISO Code", CopyStr('EUEU', 1, 4));
        Assert.ExpectedError('is 4, but it must be less than or equal to 3 characters');

        asserterror Currency.Validate("ISO Code", 'EU');
        Assert.ExpectedError('is 2, but it must be equal to 3 characters');

        asserterror Currency.Validate("ISO Code", 'EU1');
        Assert.ExpectedError(ASCIILetterErr);

        asserterror Currency.Validate("ISO Code", 'E U');
        Assert.ExpectedError(ASCIILetterErr);

        Currency.Validate("ISO Code", 'eUr');
        Currency.TestField("ISO Code", 'EUR');

        Currency.Validate("ISO Code", '');
        Currency.TestField("ISO Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T110_ISONumericCodeIs3Numbers()
    var
        Currency: Record Currency;
    begin
        // [FEATURE] [ISO Code]
        // [SCENARIO] Allowed "ISO Numeric Code" can be blank or must contain 3 numbers
        asserterror Currency.Validate("ISO Numeric Code", CopyStr('1234', 1, 4));
        Assert.ExpectedError('is 4, but it must be less than or equal to 3 characters');

        asserterror Currency.Validate("ISO Numeric Code", '12');
        Assert.ExpectedError('is 2, but it must be equal to 3 characters');

        asserterror Currency.Validate("ISO Numeric Code", '1 3');
        Assert.ExpectedError(NumericErr);

        asserterror Currency.Validate("ISO Numeric Code", 'EU0');
        Assert.ExpectedError(NumericErr);

        Currency.Validate("ISO Numeric Code", '001');
        Currency.TestField("ISO Numeric Code", '001');

        Currency.Validate("ISO Numeric Code", '');
        Currency.TestField("ISO Numeric Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T120_ISOCodesEditableInCurrencyList()
    var
        Currency: Record Currency;
        Currencies: TestPage Currencies;
    begin
        // [FEATURE] [ISO Code] [UI]
        // [SCENARIO] "ISO Code" and "ISO Numeric Code" are editable on the Currencies page
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] Country 'A', where "ISO Code" is 'YYY', "ISO Numeric Code" is '001'
        Currency.Init();
        Currency.Code := 'A';
        Currency."ISO Code" := 'YYY';
        Currency."ISO Numeric Code" := '001';
        Currency.Insert();

        // [GIVEN] Open Country/Region list page, where both "ISO Code" and "ISO Numeric Code" are editable
        Currencies.OpenEdit();
        Currencies.FILTER.SetFilter(Code, 'A');
        Assert.IsTrue(Currencies."ISO Code".Editable(), 'ISO Code.EDITABLE');
        Assert.IsTrue(Currencies."ISO Numeric Code".Editable(), 'ISO Numeric Code.EDITABLE');
        // [WHEN] set "ISO Code" is 'ZZ', "ISO Numeric Code" is '999' on the page
        Currencies."ISO Code".SetValue('ZZZ');
        Currencies."ISO Numeric Code".SetValue('999');
        Currencies.Close();

        // [THEN] Country 'A', where "ISO Code" is 'ZZZ', "ISO Numeric Code" is '999'
        Currency.Find();
        Currency.TestField("ISO Code", 'ZZZ');
        Currency.TestField("ISO Numeric Code", '999');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T121_ISOCodesEditableInCurrencyCard()
    var
        Currency: Record Currency;
        CurrencyCard: TestPage "Currency Card";
    begin
        // [FEATURE] [ISO Code] [UI]
        // [SCENARIO] "ISO Code" and "ISO Numeric Code" are editable on the Currency Card page
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] Country 'B', where "ISO Code" is 'YYY', "ISO Numeric Code" is '001'
        Currency.Init();
        Currency.Code := 'B';
        Currency."ISO Code" := 'YYY';
        Currency."ISO Numeric Code" := '001';
        Currency.Insert();

        // [GIVEN] Open Country/Region list page, where both "ISO Code" and "ISO Numeric Code" are editable
        CurrencyCard.OpenEdit();
        CurrencyCard.FILTER.SetFilter(Code, 'B');
        Assert.IsTrue(CurrencyCard."ISO Code".Editable(), 'ISO Code.EDITABLE');
        Assert.IsTrue(CurrencyCard."ISO Numeric Code".Editable(), 'ISO Numeric Code.EDITABLE');
        // [WHEN] set "ISO Code" is 'ZZ', "ISO Numeric Code" is '999' on the page
        CurrencyCard."ISO Code".SetValue('ZZZ');
        CurrencyCard."ISO Numeric Code".SetValue('999');
        CurrencyCard.Close();

        // [THEN] Country 'B', where "ISO Code" is 'ZZZ', "ISO Numeric Code" is '999'
        Currency.Find();
        Currency.TestField("ISO Code", 'ZZZ');
        Currency.TestField("ISO Numeric Code", '999');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFailedInsetWithBlankCode()
    var
        Currency: Record Currency;
    begin
        // [SCENARIO] Insert Currency with blank Code
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Create Currency with blank Code
        Currency.Init();
        Currency.Description := LibraryRandom.RandText(MaxStrLen(Currency.Description));

        // [WHEN] Insert record
        asserterror Currency.Insert(true);

        // [THEN] The TestField Error was shown
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [HandlerFunctions('ForeignCurrencyBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ForeignCurrencyBalanceReportShowsBalanceAccordingToDateFilterApplied()
    var
        GenJournalLine, GenJournalLine2 : Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        ForeignCurrencyBalanceReport: Report "Foreign Currency Balance";
        BankAccountNo: Code[20];
        CurrencyCode: Code[10];
        PostingDate: Date;
    begin
        // [SCENARIO 539070] Foreign Currency Balance Report shows Balance according to Date Filter applied on request page.

        // [GIVEN] Create Currency Code.
        CurrencyCode := CreateCurrencyAndExchangeRate();

        // [GIVEN] Create Bank Account.
        BankAccountNo := CreateBankAccountWithCurrency(CurrencyCode);

        // [GIVEN] Create GL Account.
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Clear Gen. Journal Lines.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        // [GIVEN] Create Gen. Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account",
            GLAccount."No.",
            LibraryRandom.RandIntInRange(300, 300));

        // [GIVEN] Validate Bal. Account Type, Bal. Account No. and Currency Code in Gen. Journal Line.
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);

        // [GIVEN] Post Gen. Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Generate and save Posting Date in a Variable.
        PostingDate := CalcDate('<-2M>', WorkDate());

        // [GIVEN] Create Random Currency Rate.
        CreateRandomExchangeRate(CurrencyCode, PostingDate);

        // [GIVEN] Create Gen. Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine2,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ",
            GenJournalLine2."Account Type"::"G/L Account",
            GLAccount."No.",
            LibraryRandom.RandIntInRange(200, 200));

        // [GIVEN] Validate Bal. Account Type, Bal. Account No. and Currency Code in Gen. Journal Line.
        GenJournalLine2.Validate("Posting Date", PostingDate);
        GenJournalLine2.Validate("Bal. Account Type", GenJournalLine2."Bal. Account Type"::"Bank Account");
        GenJournalLine2.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine2.Validate("Currency Code", CurrencyCode);
        GenJournalLine2.Modify(true);

        // [GIVEN] Post Gen. Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);

        // [GIVEN] Run Foreign Currency Balance Report.
        Clear(ForeignCurrencyBalanceReport);
        Currency.SetRange(Code, CurrencyCode);
        ForeignCurrencyBalanceReport.SetTableView(Currency);
        Commit();
        LibraryVariableStorage.Enqueue(PostingDate);
        ForeignCurrencyBalanceReport.Run();

        // [WHEN] Find Bank Account Ledger Entry.
        BankAccountLedgerEntry.SetRange("Posting Date", PostingDate);
        BankAccountLedgerEntry.SetRange("Document No.", GenJournalLine2."Document No.");
        BankAccountLedgerEntry.FindFirst();

        // [THEN] CalcTotalBalance of Foreign Currency Balance Report is equal to Amount of Bank Account Ledger Entry.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CalcTotalBalance', BankAccountLedgerEntry.Amount);
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Residual Losses Account", Currency."Residual Gains Account");
        Currency.Validate("Realized G/L Gains Account", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized G/L Losses Account", Currency."Realized G/L Gains Account");
        Currency.Modify(true);

        CreateRandomExchangeRate(Currency.Code, WorkDate());
        exit(Currency.Code);
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

    local procedure CreateRandomExchangeRate(CurrencyCode: Code[10]; StartingDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if not CurrencyExchangeRate.Get(CurrencyCode, StartingDate) then begin
            CurrencyExchangeRate.Init();
            CurrencyExchangeRate.Validate("Currency Code", CurrencyCode);
            CurrencyExchangeRate.Validate("Starting Date", StartingDate);
            CurrencyExchangeRate.Insert(true);

            CurrencyExchangeRate.Validate("Exchange Rate Amount", 100 * LibraryRandom.RandInt(4));
            CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");

            CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 2 * CurrencyExchangeRate."Exchange Rate Amount");
            CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
            CurrencyExchangeRate.Modify(true);
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ForeignCurrencyBalanceRequestPageHandler(var ForeignCurrencyBalanceReport: TestRequestPage "Foreign Currency Balance")
    begin
        ForeignCurrencyBalanceReport.Currency.SetFilter("Date Filter", Format(LibraryVariableStorage.DequeueDate()));
        ForeignCurrencyBalanceReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

