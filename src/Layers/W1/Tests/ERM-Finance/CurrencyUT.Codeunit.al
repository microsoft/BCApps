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
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CurrencyCodeShouldNotBeClearedErr: Label 'Currency Code should not be cleared when Currency Id is blank';

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

    [Test]
    [Scope('OnPrem')]
    procedure ValidateCurrencyIdWithDifferentCurrencyUpdatesCurrencyCode()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 615384] When Currency Id is validated with an empty GUID, the existing Currency Code must not be cleared

        // [GIVEN] A customer "C" with Currency Code set and Currency Id blank
        LibraryERM.CreateCurrency(Currency);
        LibrarySales.CreateCustomer(Customer);
        Customer."Currency Code" := Currency.Code;
        Customer.Modify(false);

        // [WHEN] Currency Id is validated with an empty GUID
        Customer.Validate("Currency Id", EmptyGuid);

        // [THEN] Currency Code remains unchanged
        Assert.AreEqual(Currency.Code, Customer."Currency Code", CurrencyCodeShouldNotBeClearedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyCardShowsSmallestRoundingPrecisions()
    var
        Currency: Record Currency;
        CurrencyCard: TestPage "Currency Card";
    begin
        // [FEATURE] [AI test 0.3] [Currency] [UI]
        // [SCENARIO 413] The currency card retains and displays the smallest five-decimal rounding precisions.
        Initialize();

        // [GIVEN] Currency "C" with the smallest rounding precisions and two-decimal amount formatting.
        CreateCurrencyWithTwoDecimalAmounts(Currency, 0.00001);

        // [WHEN] The stored currency is opened on the card.
        CurrencyCard.OpenView();
        CurrencyCard.GoToRecord(Currency);

        // [THEN] Stored and displayed precisions retain all five decimal places.
        VerifyRoundingPrecisions(
            Currency, 0.00001, CurrencyCard."Amount Rounding Precision".Value(),
            CurrencyCard."Invoice Rounding Precision".Value());
        CurrencyCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyCardShowsFiveDecimalRoundingPrecisions()
    var
        Currency: Record Currency;
        CurrencyCard: TestPage "Currency Card";
    begin
        // [FEATURE] [AI test 0.3] [Currency] [UI]
        // [SCENARIO 413] The currency card displays nontrivial five-decimal rounding precisions independently of amount formatting.
        Initialize();

        // [GIVEN] Currency "C" with five-decimal rounding precisions and two-decimal amount formatting.
        CreateCurrencyWithTwoDecimalAmounts(Currency, 0.12345);

        // [WHEN] The stored currency is opened on the card.
        CurrencyCard.OpenView();
        CurrencyCard.GoToRecord(Currency);

        // [THEN] Stored and displayed precisions retain all five decimal places.
        VerifyRoundingPrecisions(
            Currency, 0.12345, CurrencyCard."Amount Rounding Precision".Value(),
            CurrencyCard."Invoice Rounding Precision".Value());
        CurrencyCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrenciesShowsSmallestRoundingPrecisions()
    var
        Currency: Record Currency;
        Currencies: TestPage Currencies;
    begin
        // [FEATURE] [AI test 0.3] [Currency] [UI]
        // [SCENARIO 413] The currencies list retains and displays the smallest five-decimal rounding precisions.
        Initialize();

        // [GIVEN] Currency "C" with the smallest rounding precisions and two-decimal amount formatting.
        CreateCurrencyWithTwoDecimalAmounts(Currency, 0.00001);

        // [WHEN] The stored currency is opened on the list.
        Currencies.OpenView();
        Currencies.GoToRecord(Currency);

        // [THEN] Stored and displayed precisions retain all five decimal places.
        VerifyRoundingPrecisions(
            Currency, 0.00001, Currencies."Amount Rounding Precision".Value(),
            Currencies."Invoice Rounding Precision".Value());
        Currencies.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrenciesShowsFiveDecimalRoundingPrecisions()
    var
        Currency: Record Currency;
        Currencies: TestPage Currencies;
    begin
        // [FEATURE] [AI test 0.3] [Currency] [UI]
        // [SCENARIO 413] The currencies list displays nontrivial five-decimal rounding precisions independently of amount formatting.
        Initialize();

        // [GIVEN] Currency "C" with five-decimal rounding precisions and two-decimal amount formatting.
        CreateCurrencyWithTwoDecimalAmounts(Currency, 0.12345);

        // [WHEN] The stored currency is opened on the list.
        Currencies.OpenView();
        Currencies.GoToRecord(Currency);

        // [THEN] Stored and displayed precisions retain all five decimal places.
        VerifyRoundingPrecisions(
            Currency, 0.12345, Currencies."Amount Rounding Precision".Value(),
            Currencies."Invoice Rounding Precision".Value());
        Currencies.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyCardKeepsTwoDecimalRoundingPrecisions()
    var
        Currency: Record Currency;
        CurrencyCard: TestPage "Currency Card";
    begin
        // [FEATURE] [AI test 0.3] [Currency] [UI]
        // [SCENARIO 413] The currency card continues to display ordinary rounding precisions with two decimal places.
        Initialize();

        // [GIVEN] Currency "C" with two-decimal amount formatting.
        CreateCurrencyWithTwoDecimalAmounts(Currency, 0.01);

        // [WHEN] Both rounding precisions are entered and the card is reopened.
        EnterRoundingPrecisionsOnCurrencyCard(Currency, CurrencyCard, 0.05);

        // [THEN] Two-decimal values are retained without adding unnecessary decimal places.
        VerifyRoundingPrecisions(
            Currency, 0.05, CurrencyCard."Amount Rounding Precision".Value(),
            CurrencyCard."Invoice Rounding Precision".Value());
        CurrencyCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrenciesKeepsTwoDecimalRoundingPrecisions()
    var
        Currency: Record Currency;
        Currencies: TestPage Currencies;
    begin
        // [FEATURE] [AI test 0.3] [Currency] [UI]
        // [SCENARIO 413] The currencies list continues to display ordinary rounding precisions with two decimal places.
        Initialize();

        // [GIVEN] Currency "C" with two-decimal amount formatting.
        CreateCurrencyWithTwoDecimalAmounts(Currency, 0.01);

        // [WHEN] Both rounding precisions are entered and the list is reopened.
        EnterRoundingPrecisionsOnCurrencies(Currency, Currencies, 0.05);

        // [THEN] Two-decimal values are retained without adding unnecessary decimal places.
        VerifyRoundingPrecisions(
            Currency, 0.05, Currencies."Amount Rounding Precision".Value(),
            Currencies."Invoice Rounding Precision".Value());
        Currencies.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyCardRejectsIncompatibleInvoicePrecision()
    var
        Currency: Record Currency;
        CurrencyCard: TestPage "Currency Card";
    begin
        // [FEATURE] [AI test 0.3] [Currency] [UI]
        // [SCENARIO 413] Invoice precision on the currency card must remain a multiple of amount precision.
        Initialize();

        // [GIVEN] Currency "C" with an amount rounding precision of 0.05.
        CreateCurrencyWithTwoDecimalAmounts(Currency, 0.05);
        CurrencyCard.OpenEdit();
        CurrencyCard.GoToRecord(Currency);

        // [WHEN] An incompatible invoice rounding precision is entered.
        asserterror CurrencyCard."Invoice Rounding Precision".SetValue(Format(0.03));

        // [THEN] The existing rounding compatibility validation rejects the value.
        VerifyIncompatibleInvoicePrecisionError();
        CurrencyCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrenciesRejectsIncompatibleInvoicePrecision()
    var
        Currency: Record Currency;
        Currencies: TestPage Currencies;
    begin
        // [FEATURE] [AI test 0.3] [Currency] [UI]
        // [SCENARIO 413] Invoice precision on the currencies list must remain a multiple of amount precision.
        Initialize();

        // [GIVEN] Currency "C" with an amount rounding precision of 0.05.
        CreateCurrencyWithTwoDecimalAmounts(Currency, 0.05);
        Currencies.OpenEdit();
        Currencies.GoToRecord(Currency);

        // [WHEN] An incompatible invoice rounding precision is entered.
        asserterror Currencies."Invoice Rounding Precision".SetValue(Format(0.03));

        // [THEN] The existing rounding compatibility validation rejects the value.
        VerifyIncompatibleInvoicePrecisionError();
        Currencies.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyCardRetainsEnteredFiveDecimalPrecisions()
    var
        Currency: Record Currency;
        CurrencyCard: TestPage "Currency Card";
    begin
        // [FEATURE] [AI test 0.3] [Currency] [UI]
        // [SCENARIO 413] Five-decimal rounding precisions entered on the card persist after reopening.
        Initialize();

        // [GIVEN] Currency "C" with two-decimal amount formatting.
        CreateCurrencyWithTwoDecimalAmounts(Currency, 0.01);

        // [WHEN] The smallest rounding precisions are entered and the card is reopened.
        EnterRoundingPrecisionsOnCurrencyCard(Currency, CurrencyCard, 0.00001);

        // [THEN] Both fields retain their full stored and displayed precision.
        VerifyRoundingPrecisions(
            Currency, 0.00001, CurrencyCard."Amount Rounding Precision".Value(),
            CurrencyCard."Invoice Rounding Precision".Value());
        CurrencyCard.Close();

        // [WHEN] Nontrivial five-decimal rounding precisions are entered and the card is reopened.
        EnterRoundingPrecisionsOnCurrencyCard(Currency, CurrencyCard, 0.12345);

        // [THEN] Both fields retain their full stored and displayed precision.
        VerifyRoundingPrecisions(
            Currency, 0.12345, CurrencyCard."Amount Rounding Precision".Value(),
            CurrencyCard."Invoice Rounding Precision".Value());
        CurrencyCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrenciesRetainsEnteredFiveDecimalPrecisions()
    var
        Currency: Record Currency;
        Currencies: TestPage Currencies;
    begin
        // [FEATURE] [AI test 0.3] [Currency] [UI]
        // [SCENARIO 413] Five-decimal rounding precisions entered on the list persist after reopening.
        Initialize();

        // [GIVEN] Currency "C" with two-decimal amount formatting.
        CreateCurrencyWithTwoDecimalAmounts(Currency, 0.01);

        // [WHEN] The smallest rounding precisions are entered and the list is reopened.
        EnterRoundingPrecisionsOnCurrencies(Currency, Currencies, 0.00001);

        // [THEN] Both fields retain their full stored and displayed precision.
        VerifyRoundingPrecisions(
            Currency, 0.00001, Currencies."Amount Rounding Precision".Value(),
            Currencies."Invoice Rounding Precision".Value());
        Currencies.Close();

        // [WHEN] Nontrivial five-decimal rounding precisions are entered and the list is reopened.
        EnterRoundingPrecisionsOnCurrencies(Currency, Currencies, 0.12345);

        // [THEN] Both fields retain their full stored and displayed precision.
        VerifyRoundingPrecisions(
            Currency, 0.12345, Currencies."Amount Rounding Precision".Value(),
            Currencies."Invoice Rounding Precision".Value());
        Currencies.Close();
    end;

    local procedure Initialize()
    begin
        LibraryApplicationArea.EnableFoundationSetup();
    end;

    local procedure CreateCurrencyWithTwoDecimalAmounts(var Currency: Record Currency; RoundingPrecision: Decimal)
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Amount Decimal Places", '2:2');
        Currency.Validate("Amount Rounding Precision", RoundingPrecision);
        Currency.Validate("Invoice Rounding Precision", RoundingPrecision);
        Currency.Modify(true);
        Currency.Get(Currency.Code);
    end;

    local procedure EnterRoundingPrecisionsOnCurrencyCard(var Currency: Record Currency; var CurrencyCard: TestPage "Currency Card"; RoundingPrecision: Decimal)
    begin
        CurrencyCard.OpenEdit();
        CurrencyCard.GoToRecord(Currency);
        CurrencyCard."Amount Rounding Precision".SetValue(Format(RoundingPrecision));
        CurrencyCard."Invoice Rounding Precision".SetValue(Format(RoundingPrecision));
        CurrencyCard.Close();
        Currency.Get(Currency.Code);
        CurrencyCard.OpenView();
        CurrencyCard.GoToRecord(Currency);
    end;

    local procedure EnterRoundingPrecisionsOnCurrencies(var Currency: Record Currency; var Currencies: TestPage Currencies; RoundingPrecision: Decimal)
    begin
        Currencies.OpenEdit();
        Currencies.GoToRecord(Currency);
        Currencies."Amount Rounding Precision".SetValue(Format(RoundingPrecision));
        Currencies."Invoice Rounding Precision".SetValue(Format(RoundingPrecision));
        Currencies.Close();
        Currency.Get(Currency.Code);
        Currencies.OpenView();
        Currencies.GoToRecord(Currency);
    end;

    local procedure VerifyRoundingPrecisions(Currency: Record Currency; RoundingPrecision: Decimal; AmountPrecisionText: Text; InvoicePrecisionText: Text)
    var
        ExpectedPrecisionText: Text;
    begin
        Assert.AreEqual('2:2', Currency."Amount Decimal Places", 'Ordinary amount formatting must remain unchanged.');
        Assert.AreEqual(
            RoundingPrecision, Currency."Amount Rounding Precision",
            'Amount rounding precision must be stored without losing decimals.');
        Assert.AreEqual(
            RoundingPrecision, Currency."Invoice Rounding Precision",
            'Invoice rounding precision must be stored without losing decimals.');
        ExpectedPrecisionText := Format(RoundingPrecision, 0, '<Precision,2:5><Standard Format,0>');
        Assert.AreEqual(
            ExpectedPrecisionText + ' / ' + ExpectedPrecisionText, AmountPrecisionText + ' / ' + InvoicePrecisionText,
            'Amount / Invoice rounding precision must display up to five decimals.');
    end;

    local procedure VerifyIncompatibleInvoicePrecisionError()
    begin
        Assert.ExpectedError(StrSubstNo('must be rounded to the nearest %1', Format(0.05)));
        Assert.ExpectedErrorCode('TestValidation');
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

