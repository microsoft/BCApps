codeunit 134833 "Amount AutoFormat Currency"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Any: Codeunit "Any";
        LibraryAssert: Codeunit "Library Assert";
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized: Boolean;

    [HandlerFunctions('SessionSettingsHandler')]
    [Test]
    procedure TestAutoformatNeverShow()
    var
        AmountAutoFormatCurrency: Record "Amount AutoFormat Currency";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        AmountAutoFormatCurrencyTestPage: TestPage "Amount AutoFormat Currency";
    begin
        // [Scenario] A decimal control with AutoFormatType = 1, and AutoFormatExpression = ''
        // [Given] General Ledger Setup with Show Currency = Never
        Initialize();
        GeneralLedgerSetup := SetShowCurrencyNever();
        Currency := CreateFCYCurrency(enum::"Currency Symbol Position"::"Before Amount");
        AmountAutoFormatCurrency := CreateAmountFormatCurrencyTestRecord(Currency.Code);

        // [When] Running the page with AutoFormatExpression = ''
        AmountAutoFormatCurrencyTestPage.Trap();
        Page.Run(Page::"Amount AutoFormat Currency", AmountAutoFormatCurrency);
        AmountAutoFormatCurrencyTestPage.GoToRecord(AmountAutoFormatCurrency);

        // [Then] the values are formatted correctly
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1LCY, GeneralLedgerSetup."Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1LCY.Value(), 'The return value for Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2LCY.Value(), 'The return value for Unit-Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4LCY, GeneralLedgerSetup."Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4LCY.Value(), 'The return value for Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5LCY.Value(), 'The return value for Unit-Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1FCY, Currency."Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1FCY.Value(), 'The return value for Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2FCY, Currency."Unit-Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2FCY.Value(), 'The return value for Unit-Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4FCY, Currency."Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4FCY.Value(), 'The return value for Amount FCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5FCY, Currency."Unit-Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5FCY.Value(), 'The return value for Unit-Amount FCY (No Currency) is not correctly formatted');
    end;

    [HandlerFunctions('SessionSettingsHandler')]
    [Test]
    procedure TestAutoformatShowFCYSymbolOnlyBeforeAmount()
    var
        AmountAutoFormatCurrency: Record "Amount AutoFormat Currency";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        AmountAutoFormatCurrencyTestPage: TestPage "Amount AutoFormat Currency";
    begin
        // [Scenario] A decimal control with AutoFormatType = 1, and AutoFormatExpression = ''
        // [Given] General Ledger Setup with Show Currency = Never
        Initialize();
        GeneralLedgerSetup := SetShowCurrencyFCYSymbolOnly();
        Currency := CreateFCYCurrency(enum::"Currency Symbol Position"::"Before Amount");
        AmountAutoFormatCurrency := CreateAmountFormatCurrencyTestRecord(Currency.Code);

        // [When] Running the page with AutoFormatExpression = ''
        AmountAutoFormatCurrencyTestPage.Trap();
        Page.Run(Page::"Amount AutoFormat Currency", AmountAutoFormatCurrency);
        AmountAutoFormatCurrencyTestPage.GoToRecord(AmountAutoFormatCurrency);

        // [Then] the values are formatted correctly
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1LCY, GeneralLedgerSetup."Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1LCY.Value(), 'The return value for Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2LCY.Value(), 'The return value for Unit-Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4LCY, GeneralLedgerSetup."Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4LCY.Value(), 'The return value for Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5LCY.Value(), 'The return value for Unit-Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1FCY, Currency."Amount Decimal Places", Currency.Symbol, Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1FCY.Value(), 'The return value for Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2FCY, Currency."Unit-Amount Decimal Places", Currency.Symbol, Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2FCY.Value(), 'The return value for Unit-Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4FCY, Currency."Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4FCY.Value(), 'The return value for Amount FCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5FCY, Currency."Unit-Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5FCY.Value(), 'The return value for Unit-Amount FCY (No Currency) is not correctly formatted');
    end;

    [HandlerFunctions('SessionSettingsHandler')]
    [Test]
    procedure TestAutoformatShowFCYSymbolOnlyAfterAmount()
    var
        AmountAutoFormatCurrency: Record "Amount AutoFormat Currency";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        AmountAutoFormatCurrencyTestPage: TestPage "Amount AutoFormat Currency";
    begin
        // [Scenario] A decimal control with AutoFormatType = 1, and AutoFormatExpression = ''
        // [Given] General Ledger Setup with Show Currency = Never
        Initialize();
        GeneralLedgerSetup := SetShowCurrencyFCYSymbolOnly();
        Currency := CreateFCYCurrency(enum::"Currency Symbol Position"::"After Amount");
        AmountAutoFormatCurrency := CreateAmountFormatCurrencyTestRecord(Currency.Code);

        // [When] Running the page with AutoFormatExpression = ''
        AmountAutoFormatCurrencyTestPage.Trap();
        Page.Run(Page::"Amount AutoFormat Currency", AmountAutoFormatCurrency);
        AmountAutoFormatCurrencyTestPage.GoToRecord(AmountAutoFormatCurrency);

        // [Then] the values are formatted correctly
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1LCY, GeneralLedgerSetup."Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1LCY.Value(), 'The return value for Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2LCY.Value(), 'The return value for Unit-Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4LCY, GeneralLedgerSetup."Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4LCY.Value(), 'The return value for Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5LCY.Value(), 'The return value for Unit-Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1FCY, Currency."Amount Decimal Places", Currency.Symbol, Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1FCY.Value(), 'The return value for Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2FCY, Currency."Unit-Amount Decimal Places", Currency.Symbol, Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2FCY.Value(), 'The return value for Unit-Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4FCY, Currency."Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4FCY.Value(), 'The return value for Amount FCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5FCY, Currency."Unit-Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5FCY.Value(), 'The return value for Unit-Amount FCY (No Currency) is not correctly formatted');
    end;

    [HandlerFunctions('SessionSettingsHandler')]
    [Test]
    procedure TestAutoformatShowLCYFCYSymbolOnlyBeforeAmount()
    var
        AmountAutoFormatCurrency: Record "Amount AutoFormat Currency";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        AmountAutoFormatCurrencyTestPage: TestPage "Amount AutoFormat Currency";
    begin
        // [Scenario] A decimal control with AutoFormatType = 1, and AutoFormatExpression = ''
        // [Given] General Ledger Setup with Show Currency = Never
        Initialize();
        GeneralLedgerSetup := SetShowCurrencyLCYandFCYSymbol();
        Currency := CreateFCYCurrency(enum::"Currency Symbol Position"::"Before Amount");
        AmountAutoFormatCurrency := CreateAmountFormatCurrencyTestRecord(Currency.Code);

        // [When] Running the page with AutoFormatExpression = ''
        AmountAutoFormatCurrencyTestPage.Trap();
        Page.Run(Page::"Amount AutoFormat Currency", AmountAutoFormatCurrency);
        AmountAutoFormatCurrencyTestPage.GoToRecord(AmountAutoFormatCurrency);

        // [Then] the values are formatted correctly
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1LCY, GeneralLedgerSetup."Amount Decimal Places", GeneralLedgerSetup."Local Currency Symbol", GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1LCY.Value(), 'The return value for Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", GeneralLedgerSetup."Local Currency Symbol", GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2LCY.Value(), 'The return value for Unit-Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4LCY, GeneralLedgerSetup."Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4LCY.Value(), 'The return value for Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5LCY.Value(), 'The return value for Unit-Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1FCY, Currency."Amount Decimal Places", Currency.Symbol, Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1FCY.Value(), 'The return value for Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2FCY, Currency."Unit-Amount Decimal Places", Currency.Symbol, Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2FCY.Value(), 'The return value for Unit-Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4FCY, Currency."Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4FCY.Value(), 'The return value for Amount FCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5FCY, Currency."Unit-Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5FCY.Value(), 'The return value for Unit-Amount FCY (No Currency) is not correctly formatted');
    end;

    [HandlerFunctions('SessionSettingsHandler')]
    [Test]
    procedure TestAutoformatShowLCYandFCYSymbolOnlyAfterAmount()
    var
        AmountAutoFormatCurrency: Record "Amount AutoFormat Currency";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        AmountAutoFormatCurrencyTestPage: TestPage "Amount AutoFormat Currency";
    begin
        // [Scenario] A decimal control with AutoFormatType = 1, and AutoFormatExpression = ''
        // [Given] General Ledger Setup with Show Currency = Never
        Initialize();
        GeneralLedgerSetup := SetShowCurrencyLCYandFCYSymbol();
        Currency := CreateFCYCurrency(enum::"Currency Symbol Position"::"After Amount");
        AmountAutoFormatCurrency := CreateAmountFormatCurrencyTestRecord(Currency.Code);

        // [When] Running the page with AutoFormatExpression = ''
        AmountAutoFormatCurrencyTestPage.Trap();
        Page.Run(Page::"Amount AutoFormat Currency", AmountAutoFormatCurrency);
        AmountAutoFormatCurrencyTestPage.GoToRecord(AmountAutoFormatCurrency);

        // [Then] the values are formatted correctly
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1LCY, GeneralLedgerSetup."Amount Decimal Places", GeneralLedgerSetup."Local Currency Symbol", GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1LCY.Value(), 'The return value for Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", GeneralLedgerSetup."Local Currency Symbol", GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2LCY.Value(), 'The return value for Unit-Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4LCY, GeneralLedgerSetup."Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4LCY.Value(), 'The return value for Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5LCY.Value(), 'The return value for Unit-Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1FCY, Currency."Amount Decimal Places", Currency.Symbol, Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1FCY.Value(), 'The return value for Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2FCY, Currency."Unit-Amount Decimal Places", Currency.Symbol, Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2FCY.Value(), 'The return value for Unit-Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4FCY, Currency."Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4FCY.Value(), 'The return value for Amount FCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5FCY, Currency."Unit-Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5FCY.Value(), 'The return value for Unit-Amount FCY (No Currency) is not correctly formatted');
    end;

    [HandlerFunctions('SessionSettingsHandler')]
    [Test]
    procedure TestAutoformatShowFCYCodeOnlyBeforeAmount()
    var
        AmountAutoFormatCurrency: Record "Amount AutoFormat Currency";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        AmountAutoFormatCurrencyTestPage: TestPage "Amount AutoFormat Currency";
    begin
        // [Scenario] A decimal control with AutoFormatType = 1, and AutoFormatExpression = ''
        // [Given] General Ledger Setup with Show Currency = Never
        Initialize();
        GeneralLedgerSetup := SetShowCurrencyFCYCodeOnly();
        Currency := CreateFCYCurrency(enum::"Currency Symbol Position"::"Before Amount");
        AmountAutoFormatCurrency := CreateAmountFormatCurrencyTestRecord(Currency.Code);

        // [When] Running the page with AutoFormatExpression = ''
        AmountAutoFormatCurrencyTestPage.Trap();
        Page.Run(Page::"Amount AutoFormat Currency", AmountAutoFormatCurrency);
        AmountAutoFormatCurrencyTestPage.GoToRecord(AmountAutoFormatCurrency);

        // [Then] the values are formatted correctly
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1LCY, GeneralLedgerSetup."Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1LCY.Value(), 'The return value for Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2LCY.Value(), 'The return value for Unit-Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4LCY, GeneralLedgerSetup."Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4LCY.Value(), 'The return value for Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5LCY.Value(), 'The return value for Unit-Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1FCY, Currency."Amount Decimal Places", Currency."ISO Code", Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1FCY.Value(), 'The return value for Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2FCY, Currency."Unit-Amount Decimal Places", Currency."ISO Code", Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2FCY.Value(), 'The return value for Unit-Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4FCY, Currency."Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4FCY.Value(), 'The return value for Amount FCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5FCY, Currency."Unit-Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5FCY.Value(), 'The return value for Unit-Amount FCY (No Currency) is not correctly formatted');
    end;

    [HandlerFunctions('SessionSettingsHandler')]
    [Test]
    procedure TestAutoformatShowFCYCodeOnlyAfterAmount()
    var
        AmountAutoFormatCurrency: Record "Amount AutoFormat Currency";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        AmountAutoFormatCurrencyTestPage: TestPage "Amount AutoFormat Currency";
    begin
        // [Scenario] A decimal control with AutoFormatType = 1, and AutoFormatExpression = ''
        // [Given] General Ledger Setup with Show Currency = Never
        Initialize();
        GeneralLedgerSetup := SetShowCurrencyFCYCodeOnly();
        Currency := CreateFCYCurrency(enum::"Currency Symbol Position"::"After Amount");
        AmountAutoFormatCurrency := CreateAmountFormatCurrencyTestRecord(Currency.Code);

        // [When] Running the page with AutoFormatExpression = ''
        AmountAutoFormatCurrencyTestPage.Trap();
        Page.Run(Page::"Amount AutoFormat Currency", AmountAutoFormatCurrency);
        AmountAutoFormatCurrencyTestPage.GoToRecord(AmountAutoFormatCurrency);

        // [Then] the values are formatted correctly
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1LCY, GeneralLedgerSetup."Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1LCY.Value(), 'The return value for Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2LCY.Value(), 'The return value for Unit-Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4LCY, GeneralLedgerSetup."Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4LCY.Value(), 'The return value for Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5LCY.Value(), 'The return value for Unit-Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1FCY, Currency."Amount Decimal Places", Currency."ISO Code", Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1FCY.Value(), 'The return value for Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2FCY, Currency."Unit-Amount Decimal Places", Currency."ISO Code", Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2FCY.Value(), 'The return value for Unit-Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4FCY, Currency."Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4FCY.Value(), 'The return value for Amount FCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5FCY, Currency."Unit-Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5FCY.Value(), 'The return value for Unit-Amount FCY (No Currency) is not correctly formatted');
    end;

    [HandlerFunctions('SessionSettingsHandler')]
    [Test]
    procedure TestAutoformatShowLCYandFCYCodeBeforeAmount()
    var
        AmountAutoFormatCurrency: Record "Amount AutoFormat Currency";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        AmountAutoFormatCurrencyTestPage: TestPage "Amount AutoFormat Currency";
    begin
        // [Scenario] A decimal control with AutoFormatType = 1, and AutoFormatExpression = ''
        // [Given] General Ledger Setup with Show Currency = Never
        Initialize();
        GeneralLedgerSetup := SetShowCurrencyLCYandFCYCode();
        Currency := CreateFCYCurrency(enum::"Currency Symbol Position"::"Before Amount");
        AmountAutoFormatCurrency := CreateAmountFormatCurrencyTestRecord(Currency.Code);

        // [When] Running the page with AutoFormatExpression = ''
        AmountAutoFormatCurrencyTestPage.Trap();
        Page.Run(Page::"Amount AutoFormat Currency", AmountAutoFormatCurrency);
        AmountAutoFormatCurrencyTestPage.GoToRecord(AmountAutoFormatCurrency);

        // [Then] the values are formatted correctly
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1LCY, GeneralLedgerSetup."Amount Decimal Places", GeneralLedgerSetup."LCY Code", GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1LCY.Value(), 'The return value for Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", GeneralLedgerSetup."LCY Code", GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2LCY.Value(), 'The return value for Unit-Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4LCY, GeneralLedgerSetup."Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4LCY.Value(), 'The return value for Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5LCY.Value(), 'The return value for Unit-Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1FCY, Currency."Amount Decimal Places", Currency."ISO Code", Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1FCY.Value(), 'The return value for Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2FCY, Currency."Unit-Amount Decimal Places", Currency."ISO Code", Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2FCY.Value(), 'The return value for Unit-Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4FCY, Currency."Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4FCY.Value(), 'The return value for Amount FCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5FCY, Currency."Unit-Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5FCY.Value(), 'The return value for Unit-Amount FCY (No Currency) is not correctly formatted');
    end;

    [HandlerFunctions('SessionSettingsHandler')]
    [Test]
    procedure TestAutoformatShowLCYandFCYCodeAfterAmount()
    var
        AmountAutoFormatCurrency: Record "Amount AutoFormat Currency";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        AmountAutoFormatCurrencyTestPage: TestPage "Amount AutoFormat Currency";
    begin
        // [Scenario] A decimal control with AutoFormatType = 1, and AutoFormatExpression = ''
        // [Given] General Ledger Setup with Show Currency = Never
        Initialize();
        GeneralLedgerSetup := SetShowCurrencyLCYandFCYCode();
        Currency := CreateFCYCurrency(enum::"Currency Symbol Position"::"After Amount");
        AmountAutoFormatCurrency := CreateAmountFormatCurrencyTestRecord(Currency.Code);

        // [When] Running the page with AutoFormatExpression = ''
        AmountAutoFormatCurrencyTestPage.Trap();
        Page.Run(Page::"Amount AutoFormat Currency", AmountAutoFormatCurrency);
        AmountAutoFormatCurrencyTestPage.GoToRecord(AmountAutoFormatCurrency);

        // [Then] the values are formatted correctly
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1LCY, GeneralLedgerSetup."Amount Decimal Places", GeneralLedgerSetup."LCY Code", GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1LCY.Value(), 'The return value for Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", GeneralLedgerSetup."LCY Code", GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2LCY.Value(), 'The return value for Unit-Amount LCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4LCY, GeneralLedgerSetup."Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4LCY.Value(), 'The return value for Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5LCY, GeneralLedgerSetup."Unit-Amount Decimal Places", '', GeneralLedgerSetup."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5LCY.Value(), 'The return value for Unit-Amount LCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case1FCY, Currency."Amount Decimal Places", Currency."ISO Code", Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case1FCY.Value(), 'The return value for Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case2FCY, Currency."Unit-Amount Decimal Places", Currency."ISO Code", Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case2FCY.Value(), 'The return value for Unit-Amount FCY is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case4FCY, Currency."Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case4FCY.Value(), 'The return value for Amount FCY (No Currency) is not correctly formatted');
        LibraryAssert.AreEqual(FormatValue(AmountAutoFormatCurrency.Case5FCY, Currency."Unit-Amount Decimal Places", '', Currency."Currency Symbol Position"), AmountAutoFormatCurrencyTestPage.Case5FCY.Value(), 'The return value for Unit-Amount FCY (No Currency) is not correctly formatted');
    end;

    [HandlerFunctions('SessionSettingsHandler')]
    [Test]
    procedure ResetSetup_NotATest()
    var
        SessionSettings: SessionSettings;
    begin
        // if a test fails, it leaves the General Ledger Setup in an unknown state. Other tests can't handle showing the currency, so this fake test is to ensure te setup is reset so failures appear here only and not in other unrelated tests.
        SetShowCurrencyNever();
        SessionSettings.RequestSessionUpdate(false);
    end;

    procedure Initialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SessionSettings: SessionSettings;
    begin
        SessionSettings.RequestSessionUpdate(false);

        if IsInitialized then
            exit;
        IsInitialized := true;

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."LCY Code" = '' then
            GeneralLedgerSetup."LCY Code" := 'LCY';
        if GeneralLedgerSetup."Local Currency Symbol" = '' then
            GeneralLedgerSetup."Local Currency Symbol" := '~';
        GeneralLedgerSetup.Modify();
    end;

    local procedure SetShowCurrencyNever() GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Show Currency" := GeneralLedgerSetup."Show Currency"::Never;
        GeneralLedgerSetup.Modify();
    end;

    local procedure SetShowCurrencyFCYSymbolOnly() GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Show Currency" := GeneralLedgerSetup."Show Currency"::"FCY Symbol Only";
        GeneralLedgerSetup.Modify();
    end;

    local procedure SetShowCurrencyLCYandFCYSymbol() GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Show Currency" := GeneralLedgerSetup."Show Currency"::"LCY and FCY Symbol";
        GeneralLedgerSetup.Modify();
    end;

    local procedure SetShowCurrencyFCYCodeOnly() GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Show Currency" := GeneralLedgerSetup."Show Currency"::"FCY Currency Code Only";
        GeneralLedgerSetup.Modify();
    end;

    local procedure SetShowCurrencyLCYandFCYCode() GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Show Currency" := GeneralLedgerSetup."Show Currency"::"LCY and FCY Currency Code";
        GeneralLedgerSetup.Modify();
    end;

    local procedure CreateAmountFormatCurrencyTestRecord(CurrencyCode: Code[10]) AmountAutoFormatCurrency: Record "Amount AutoFormat Currency"
    begin
        AmountAutoFormatCurrency.DeleteAll();
        AmountAutoFormatCurrency.Case1LCY := Any.DecimalInRange(1000, 5);
        AmountAutoFormatCurrency.Case2LCY := Any.DecimalInRange(1000, 5);
        AmountAutoFormatCurrency.Case4LCY := Any.DecimalInRange(1000, 5);
        AmountAutoFormatCurrency.Case5LCY := Any.DecimalInRange(1000, 5);
        AmountAutoFormatCurrency.Case1FCY := Any.DecimalInRange(1000, 5);
        AmountAutoFormatCurrency.Case2FCY := Any.DecimalInRange(1000, 5);
        AmountAutoFormatCurrency.Case4FCY := Any.DecimalInRange(1000, 5);
        AmountAutoFormatCurrency.Case5FCY := Any.DecimalInRange(1000, 5);
        AmountAutoFormatCurrency."Currency Code" := CurrencyCode;
        AmountAutoFormatCurrency.Insert(true);
    end;

    local procedure CreateFCYCurrency(CurrencySymbolPosition: Enum "Currency Symbol Position") Currency: Record "Currency"
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithRounding());
        Currency.Symbol := '$';
        Currency."Currency Symbol Position" := CurrencySymbolPosition;
        Currency."ISO Code" := 'ABC';
        Currency.Modify(true);
    end;

    local procedure FormatValue(value: Decimal; DecimalPlaces: Text[5]; CurrencyText: Text[10]; CurrencySymbolPosition: Enum "Currency Symbol Position") Result: Text[30]
    begin
#pragma warning disable AA0217
        if CurrencyText = '' then
            exit(Format(value, 0, StrSubstNo('<Precision,%1><Standard Format,0>', DecimalPlaces)));

        case CurrencySymbolPosition of
            CurrencySymbolPosition::"Before Amount":
                Result := StrSubstNo('%2 %1', Format(value, 0, StrSubstNo('<Precision,%1><Standard Format,0>', DecimalPlaces)), CurrencyText);
            CurrencySymbolPosition::"After Amount":
                Result := StrSubstNo('%1 %2', Format(value, 0, StrSubstNo('<Precision,%1><Standard Format,0>', DecimalPlaces)), CurrencyText);
        end;
#pragma warning restore AA0217
    end;

    [SessionSettingsHandler]
    procedure SessionSettingsHandler(var SessionSettings: SessionSettings): boolean
    begin
        exit(true);
    end;
}