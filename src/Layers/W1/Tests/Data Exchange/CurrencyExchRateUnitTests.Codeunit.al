codeunit 134276 "Currency Exch. Rate Unit Tests"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Data Exch." = id;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Currency Exchange Rate]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPaymentFormat: Codeunit "Library - Payment Format";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        Initialized: Boolean;
        LongURLExampleTxt: Label 'http://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.xchange where pair in ("USDEUR", "USDJPY", "USDBGN", "USDCZK", "USDDKK", "USDGBP", "USDHUF", "USDLTL", "USDLVL", "USDPLN", "USDRON", "USDSEK", "USDCHF", "USDNOK", "USDHRK", "USDRUB", "USDTRY", "USDAUD", "USDBRL", "USDCAD", "USDCNY", "USDHKD", "USDIDR", "USDILS", "USDINR", "USDKRW", "USDMXN", "USDMYR", "USDNZD", "USDPHP", "USDSGD", "USDTHB", "USDZAR", "USDISK")&env=store://datatables.org/alltableswithkeys', Locked = true;
        URLWithLocalCharactersExampleTxt: Label 'http://ko.wikipedia.org/wiki/%EC%9C%84%ED%82%A4%EB%B0%B1%EA%B3%BC%3a%EB%8C%80%EB%AC%B8', Locked = true;
        NoSyncCurrencyExchangeRatesSetupErr: Label 'There are no active Currency Exchange Rate Sync. Setup records.';
        DefualtExchangeRateAmount: Decimal;
        NumberOfCurrencies: Integer;
        FieldNotMappedErr: Label 'Mandatory field %1 is not mapped. Map the field by choosing Field Mapping in the Currency Exchange Rate Sync. Setup window.', Comment = '%1 - Field Caption';

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingAndGettingURL()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        URL: Text;
        ExpectedText: Text;
    begin
        // Setup
        Initialize();

        CreateCurrencyExchRateSyncSetup(CurrExchRateUpdateSetup, URLWithLocalCharactersExampleTxt);
        CurrExchRateUpdateSetup.GetWebServiceURL(URL);
        ExpectedText := URLWithLocalCharactersExampleTxt;
        Assert.AreEqual(ExpectedText, URL, 'Url is not as expected');

        // Test changing the URL
        CurrExchRateUpdateSetup.SetWebServiceURL(LongURLExampleTxt);
        CurrExchRateUpdateSetup.GetWebServiceURL(URL);
        ExpectedText := LongURLExampleTxt;
        Assert.AreEqual(ExpectedText, URL, 'Url is not as expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRunningWithoutActiveCurrencySetup()
    begin
        // Setup
        Initialize();

        // Execute
        asserterror CODEUNIT.Run(CODEUNIT::"Update Currency Exchange Rates");

        // Verify
        Assert.ExpectedError(NoSyncCurrencyExchangeRatesSetupErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCurrencyCodeIsMandatoryField()
    var
        DataExch: Record "Data Exch.";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        Currency: Record Currency;
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
    begin
        // Setup
        Initialize();

        CreateCurrencyExchangeDataExchangeSetup(DataExchLineDef);
        MapMandatoryFields(DataExchLineDef);
        CreateCurrencies(Currency, TempCurrencyExchangeRate, WorkDate(), NumberOfCurrencies);
        CreateDataExchangeTestData(DataExch, DataExchLineDef, TempCurrencyExchangeRate);

        DataExchFieldMapping.SetRange("Field ID", TempCurrencyExchangeRate.FieldNo("Currency Code"));
        DataExchFieldMapping.FindFirst();
        DataExchFieldMapping.Delete(true);

        // Execute
        asserterror CODEUNIT.Run(CODEUNIT::"Map Currency Exchange Rate", DataExch);

        // Verify
        Assert.ExpectedError(StrSubstNo(FieldNotMappedErr, TempCurrencyExchangeRate.FieldCaption("Currency Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRelationalExchRateAmountIsMandatoryField()
    var
        DataExch: Record "Data Exch.";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        Currency: Record Currency;
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
    begin
        // Setup
        Initialize();

        CreateCurrencyExchangeDataExchangeSetup(DataExchLineDef);
        MapMandatoryFields(DataExchLineDef);
        CreateCurrencies(Currency, TempCurrencyExchangeRate, WorkDate(), NumberOfCurrencies);
        CreateDataExchangeTestData(DataExch, DataExchLineDef, TempCurrencyExchangeRate);

        DataExchFieldMapping.SetRange("Field ID", TempCurrencyExchangeRate.FieldNo("Relational Exch. Rate Amount"));
        DataExchFieldMapping.FindFirst();
        DataExchFieldMapping.Delete(true);

        // Execute
        asserterror CODEUNIT.Run(CODEUNIT::"Map Currency Exchange Rate", DataExch);

        // Verify
        Assert.ExpectedError(StrSubstNo(FieldNotMappedErr, TempCurrencyExchangeRate.FieldCaption("Relational Exch. Rate Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDateIsDefaultedToTodayIfNotMapped()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        Currency: Record Currency;
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
    begin
        // Setup
        Initialize();

        CreateCurrencyExchangeDataExchangeSetup(DataExchLineDef);
        MapMandatoryFields(DataExchLineDef);
        CreateCurrencies(Currency, TempCurrencyExchangeRate, Today, NumberOfCurrencies);
        CreateDataExchangeTestData(DataExch, DataExchLineDef, TempCurrencyExchangeRate);

        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");

        // Execute
        CODEUNIT.Run(CODEUNIT::"Map Currency Exchange Rate", DataExch);

        // Verify
        VerifyCurrencyExchangeRateMatch(TempCurrencyExchangeRate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExchangeRateAmountIsDefaultedToOne()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        Currency: Record Currency;
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
    begin
        // Setup
        Initialize();

        CreateCurrencyExchangeDataExchangeSetup(DataExchLineDef);
        MapMandatoryFields(DataExchLineDef);
        MapCommonFields(DataExchLineDef);
        CreateCurrencies(Currency, TempCurrencyExchangeRate, WorkDate(), NumberOfCurrencies);
        CreateDataExchangeTestData(DataExch, DataExchLineDef, TempCurrencyExchangeRate);

        DataExchFieldMapping.SetRange("Field ID", TempCurrencyExchangeRate.FieldNo("Exchange Rate Amount"));
        DataExchFieldMapping.FindFirst();
        DataExchFieldMapping.Delete(true);

        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");

        // Execute
        CODEUNIT.Run(CODEUNIT::"Map Currency Exchange Rate", DataExch);

        // Verify
        VerifyCurrencyExchangeRateMatch(TempCurrencyExchangeRate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRunningWithAdditionalFieldsMapped()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        Currency: Record Currency;
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
    begin
        // Setup
        Initialize();

        CreateCurrencyExchangeDataExchangeSetup(DataExchLineDef);
        MapMandatoryFields(DataExchLineDef);
        MapCommonFields(DataExchLineDef);
        MapAdditionalFields(DataExchLineDef);
        CreateCurrencies(Currency, TempCurrencyExchangeRate, WorkDate(), NumberOfCurrencies);
        CreateDataExchangeTestData(DataExch, DataExchLineDef, TempCurrencyExchangeRate);

        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");

        // Execute
        CODEUNIT.Run(CODEUNIT::"Map Currency Exchange Rate", DataExch);

        // Verify
        VerifyCurrencyExchangeRateMatch(TempCurrencyExchangeRate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCurrenciesThatAreNotSpecifiedAreNotMapped()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        Currency: Record Currency;
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Setup
        Initialize();

        NumberOfCurrencies := 5;
        CreateCurrencyExchangeDataExchangeSetup(DataExchLineDef);
        MapMandatoryFields(DataExchLineDef);
        MapCommonFields(DataExchLineDef);
        MapAdditionalFields(DataExchLineDef);
        CreateCurrencies(Currency, TempCurrencyExchangeRate, WorkDate(), NumberOfCurrencies);
        CreateDataExchangeTestData(DataExch, DataExchLineDef, TempCurrencyExchangeRate);

        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");

        // Remove all currencies except one
        Currency.SetFilter(Code, '<>%1', Currency.Code);
        Currency.DeleteAll();

        TempCurrencyExchangeRate.SetFilter("Currency Code", '<>%1', Currency.Code);
        TempCurrencyExchangeRate.DeleteAll();

        // Execute
        CODEUNIT.Run(CODEUNIT::"Map Currency Exchange Rate", DataExch);

        // Verify
        Assert.AreEqual(1, CurrencyExchangeRate.Count, 'There should be one currency in the system');
        VerifyCurrencyExchangeRateMatch(TempCurrencyExchangeRate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvalidAmountsAreSkipped()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        Currency: Record Currency;
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Setup
        Initialize();

        NumberOfCurrencies := 5;
        CreateCurrencyExchangeDataExchangeSetup(DataExchLineDef);
        MapMandatoryFields(DataExchLineDef);
        MapCommonFields(DataExchLineDef);
        MapAdditionalFields(DataExchLineDef);
        CreateCurrencies(Currency, TempCurrencyExchangeRate, WorkDate(), NumberOfCurrencies);
        CreateDataExchangeTestData(DataExch, DataExchLineDef, TempCurrencyExchangeRate);

        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");

        DataExchFieldMapping.SetRange("Field ID", CurrencyExchangeRate.FieldNo("Relational Exch. Rate Amount"));
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchFieldMapping.FindFirst();

        DataExchField.SetRange("Column No.", DataExchFieldMapping."Column No.");
        DataExchField.FindFirst();
        DataExchField.Value := '-';
        DataExchField.Modify();

        // Execute
        CODEUNIT.Run(CODEUNIT::"Map Currency Exchange Rate", DataExch);

        // Verify
        Assert.AreEqual(NumberOfCurrencies - 1, CurrencyExchangeRate.Count, 'Currency with value missing should be ignored');
        TempCurrencyExchangeRate.FindFirst();
        TempCurrencyExchangeRate.Delete();
        VerifyCurrencyExchangeRateMatch(TempCurrencyExchangeRate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRunningTwiceOnSameDay()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        Currency: Record Currency;
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Setup
        Initialize();

        CreateCurrencyExchangeDataExchangeSetup(DataExchLineDef);
        MapMandatoryFields(DataExchLineDef);
        MapCommonFields(DataExchLineDef);
        MapAdditionalFields(DataExchLineDef);
        CreateCurrencies(Currency, TempCurrencyExchangeRate, WorkDate(), NumberOfCurrencies);
        CreateDataExchangeTestData(DataExch, DataExchLineDef, TempCurrencyExchangeRate);

        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");

        // Execute
        CODEUNIT.Run(CODEUNIT::"Map Currency Exchange Rate", DataExch);

        Clear(DataExch);
        CreateDataExchangeTestData(DataExch, DataExchLineDef, TempCurrencyExchangeRate);
        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");

        // Execute
        CODEUNIT.Run(CODEUNIT::"Map Currency Exchange Rate", DataExch);

        // Verify
        Assert.AreEqual(NumberOfCurrencies, CurrencyExchangeRate.Count, 'There should be only a single set of currency exchange rates');
        VerifyCurrencyExchangeRateMatch(TempCurrencyExchangeRate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRunningOnDifferentDays()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        Currency: Record Currency;
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
        TempTwoDaysBeforeCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Setup
        Initialize();

        CreateCurrencyExchangeDataExchangeSetup(DataExchLineDef);
        MapMandatoryFields(DataExchLineDef);
        MapCommonFields(DataExchLineDef);
        MapAdditionalFields(DataExchLineDef);
        CreateCurrencies(Currency, TempCurrencyExchangeRate, WorkDate(), NumberOfCurrencies);
        CreateDataExchangeTestData(DataExch, DataExchLineDef, TempCurrencyExchangeRate);

        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");

        CODEUNIT.Run(CODEUNIT::"Map Currency Exchange Rate", DataExch);

        TempCurrencyExchangeRate.FindFirst();
        repeat
            TempTwoDaysBeforeCurrencyExchangeRate.Copy(TempCurrencyExchangeRate);
            TempTwoDaysBeforeCurrencyExchangeRate."Starting Date" :=
              CalcDate('<-2D>', TempTwoDaysBeforeCurrencyExchangeRate."Starting Date");
            TempTwoDaysBeforeCurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDecInRange(1, 1000, 2));
            TempTwoDaysBeforeCurrencyExchangeRate.Insert();
        until TempCurrencyExchangeRate.Next() = 0;

        Clear(DataExch);
        CreateDataExchangeTestData(DataExch, DataExchLineDef, TempTwoDaysBeforeCurrencyExchangeRate);
        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");

        // Execute
        CODEUNIT.Run(CODEUNIT::"Map Currency Exchange Rate", DataExch);

        // Verify
        Assert.AreEqual(
          2 * NumberOfCurrencies, CurrencyExchangeRate.Count, 'There should be only a single set of currency exchange rates');
        VerifyCurrencyExchangeRateMatch(TempCurrencyExchangeRate);
        VerifyCurrencyExchangeRateMatch(TempTwoDaysBeforeCurrencyExchangeRate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditableFieldsWhenCurrExchRateServEnabledAndEditCard()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        CurrExchRateServiceCard: TestPage "Curr. Exch. Rate Service Card";
    begin
        // [FEATURE] [UI] [Curr. Exch. Rate Service Card]
        // [SCENARIO 280945] Stan can change value in Enabled field on Card when Curr. Exch. Rate Service is enabled and Card is opened for edit
        // [SCENARIO 280945] Stan cannot change all other field values
        Initialize();

        // [GIVEN] Curr. Exch. Rate Update Setup was enabled
        MockCurrExchRateUpdateSetup(CurrExchRateUpdateSetup, true);

        // [WHEN] Open page Curr. Exch. Rate Service Card for edit
        CurrExchRateServiceCard.OpenEdit();
        CurrExchRateServiceCard.GotoRecord(CurrExchRateUpdateSetup);

        // [THEN] All fields are not editable except for field Enabled on page Curr. Exch. Rate Service Card
        Assert.IsTrue(CurrExchRateServiceCard.Enabled.Editable(), '');
        VerifyFieldsNotEditableOnCurrExchRateServiceCard(CurrExchRateServiceCard);
        CurrExchRateServiceCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure EditableFieldsWhenCurrExchRateServDisabledAndEditCard()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        CurrExchRateServiceCard: TestPage "Curr. Exch. Rate Service Card";
    begin
        // [FEATURE] [UI] [Curr. Exch. Rate Service Card]
        // [SCENARIO 280945] Stan can change all field values except for ShowEnableWarning on Card when Curr. Exch. Rate Service is disabled and Card is opened for edit
        Initialize();

        // [GIVEN] Curr. Exch. Rate Update Setup was disabled
        MockCurrExchRateUpdateSetup(CurrExchRateUpdateSetup, false);

        // [WHEN] Open page Curr. Exch. Rate Service Card for edit
        CurrExchRateServiceCard.OpenEdit();
        CurrExchRateServiceCard.GotoRecord(CurrExchRateUpdateSetup);

        // [THEN] All fields are editable except for ShowEnableWarning on page Curr. Exch. Rate Service Card
        Assert.IsFalse(CurrExchRateServiceCard.ShowEnableWarning.Editable(), '');
        VerifyFieldsEditableOnCurrExchRateServiceCard(CurrExchRateServiceCard);
        CurrExchRateServiceCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditableFieldsWhenCurrExchRateServEnabledAndViewCard()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        CurrExchRateServiceCard: TestPage "Curr. Exch. Rate Service Card";
    begin
        // [FEATURE] [UI] [Curr. Exch. Rate Service Card]
        // [SCENARIO 280945] Stan cannot change field values on Card when Curr. Exch. Rate Service is enabled and Card is opened in view mode
        Initialize();

        // [GIVEN] Curr. Exch. Rate Update Setup was enabled
        MockCurrExchRateUpdateSetup(CurrExchRateUpdateSetup, true);

        // [WHEN] Open page Curr. Exch. Rate Service Card in view mode
        CurrExchRateServiceCard.OpenView();
        CurrExchRateServiceCard.GotoRecord(CurrExchRateUpdateSetup);

        // [THEN] All fields aren't editable on page Curr. Exch. Rate Service Card
        Assert.IsFalse(CurrExchRateServiceCard.Enabled.Editable(), '');
        VerifyFieldsNotEditableOnCurrExchRateServiceCard(CurrExchRateServiceCard);
        CurrExchRateServiceCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure EditableFieldsWhenCurrExchRateServDisabledAndViewCard()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        CurrExchRateServiceCard: TestPage "Curr. Exch. Rate Service Card";
    begin
        // [FEATURE] [UI] [Curr. Exch. Rate Service Card]
        // [SCENARIO 280945] Stan cannot change field values on Card when Curr. Exch. Rate Service is disabled and Card is opened in view mode
        Initialize();

        // [GIVEN] Curr. Exch. Rate Update Setup was disabled
        MockCurrExchRateUpdateSetup(CurrExchRateUpdateSetup, false);

        // [WHEN] Open page Curr. Exch. Rate Service Card in view mode
        CurrExchRateServiceCard.OpenView();
        CurrExchRateServiceCard.GotoRecord(CurrExchRateUpdateSetup);

        // [THEN] All fields aren't editable on page Curr. Exch. Rate Service Card
        Assert.IsFalse(CurrExchRateServiceCard.Enabled.Editable(), '');
        VerifyFieldsNotEditableOnCurrExchRateServiceCard(CurrExchRateServiceCard);
        CurrExchRateServiceCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowEnableWarningEnabledWhenCurrExchRateServEnabledAndEditCard()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        CurrExchRateServiceCard: TestPage "Curr. Exch. Rate Service Card";
    begin
        // [FEATURE] [UI] [Curr. Exch. Rate Service Card]
        // [SCENARIO 280945] Stan can interact with ShowEnableWarning when Curr. Exch. Rate Service is enabled and Card is opened for edit
        Initialize();

        // [GIVEN] Curr. Exch. Rate Update Setup was enabled
        MockCurrExchRateUpdateSetup(CurrExchRateUpdateSetup, true);

        // [WHEN] Open page Curr. Exch. Rate Service Card for edit
        CurrExchRateServiceCard.OpenEdit();
        CurrExchRateServiceCard.GotoRecord(CurrExchRateUpdateSetup);

        // [THEN] ShowEnableWarning is enabled on page Curr. Exch. Rate Service Card
        Assert.IsTrue(CurrExchRateServiceCard.ShowEnableWarning.Enabled(), '');
        CurrExchRateServiceCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ShowEnableWarningNotEnabledWhenCurrExchRateServDisabledAndEditCard()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        CurrExchRateServiceCard: TestPage "Curr. Exch. Rate Service Card";
    begin
        // [FEATURE] [UI] [Curr. Exch. Rate Service Card]
        // [SCENARIO 280945] Stan cannot interact with ShowEnableWarning when Curr. Exch. Rate Service is disabled and Card is opened for edit
        Initialize();

        // [GIVEN] Curr. Exch. Rate Update Setup was disabled
        MockCurrExchRateUpdateSetup(CurrExchRateUpdateSetup, false);

        // [WHEN] Open page Curr. Exch. Rate Service Card for edit
        CurrExchRateServiceCard.OpenEdit();
        CurrExchRateServiceCard.GotoRecord(CurrExchRateUpdateSetup);

        // [THEN] ShowEnableWarning is disabled on page Curr. Exch. Rate Service Card
        Assert.IsFalse(CurrExchRateServiceCard.ShowEnableWarning.Enabled(), '');
        CurrExchRateServiceCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowEnableWarningNotEnabledWhenCurrExchRateServEnabledAndViewCard()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        CurrExchRateServiceCard: TestPage "Curr. Exch. Rate Service Card";
    begin
        // [FEATURE] [UI] [Curr. Exch. Rate Service Card]
        // [SCENARIO 280945] Stan cannot interact with ShowEnableWarning when Curr. Exch. Rate Service is enabled and Card is opened in view mode
        Initialize();

        // [GIVEN] Curr. Exch. Rate Update Setup was enabled
        MockCurrExchRateUpdateSetup(CurrExchRateUpdateSetup, true);

        // [WHEN] Open page Curr. Exch. Rate Service Card in view mode
        CurrExchRateServiceCard.OpenView();
        CurrExchRateServiceCard.GotoRecord(CurrExchRateUpdateSetup);

        // [THEN] ShowEnableWarning is disabled on page Curr. Exch. Rate Service Card
        Assert.IsFalse(CurrExchRateServiceCard.ShowEnableWarning.Enabled(), '');
        CurrExchRateServiceCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ShowEnableWarningNotEnabledWhenCurrExchRateServDisabledAndViewCard()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        CurrExchRateServiceCard: TestPage "Curr. Exch. Rate Service Card";
    begin
        // [FEATURE] [UI] [Curr. Exch. Rate Service Card]
        // [SCENARIO 280945] Stan cannot interact with ShowEnableWarning when Curr. Exch. Rate Service is disabled and Card is opened in view mode
        Initialize();

        // [GIVEN] Curr. Exch. Rate Update Setup was disabled
        MockCurrExchRateUpdateSetup(CurrExchRateUpdateSetup, false);

        // [WHEN] Open page Curr. Exch. Rate Service Card in view mode
        CurrExchRateServiceCard.OpenView();
        CurrExchRateServiceCard.GotoRecord(CurrExchRateUpdateSetup);

        // [THEN] ShowEnableWarning is disabled on page Curr. Exch. Rate Service Card
        Assert.IsFalse(CurrExchRateServiceCard.ShowEnableWarning.Enabled(), '');
        CurrExchRateServiceCard.Close();
    end;

    local procedure Initialize()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Currency Exch. Rate Unit Tests");
        Currency.DeleteAll();
        CurrencyExchangeRate.DeleteAll();
        DataExch.DeleteAll(true);
        DataExchDef.DeleteAll(true);
        CurrExchRateUpdateSetup.DeleteAll(true);

        DefualtExchangeRateAmount := 1;
        NumberOfCurrencies := 10;

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Currency Exch. Rate Unit Tests");

        BindSubscription(LibraryJobQueue);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        Initialized := true;

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Currency Exch. Rate Unit Tests");
    end;

    local procedure MockCurrExchRateUpdateSetup(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; Enabled: Boolean)
    begin
        CurrExchRateUpdateSetup.Init();
        CurrExchRateUpdateSetup.Code := LibraryUtility.GenerateGUID();
        CurrExchRateUpdateSetup.Enabled := Enabled;
        CurrExchRateUpdateSetup.Insert();
    end;

    local procedure CreateCurrencyExchRateSyncSetup(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; WebServiceURL: Text)
    begin
        CurrExchRateUpdateSetup.Init();
        CurrExchRateUpdateSetup.Validate(Code,
          LibraryUtility.GenerateRandomCode(CurrExchRateUpdateSetup.FieldNo(Code), DATABASE::"Curr. Exch. Rate Update Setup"));
        CurrExchRateUpdateSetup.Insert(true);

        CurrExchRateUpdateSetup.SetWebServiceURL(WebServiceURL);
        CurrExchRateUpdateSetup.Modify(true);
    end;

    local procedure CreateCurrencyExchangeDataExchangeSetup(var DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        CreateDataExchangeDefinition(DataExchDef);

        DataExchLineDef.InsertRec(DataExchDef.Code, 'CEXR', 'Currency Exchange Rate', 0);
        CreateDataExchMapping(DataExchLineDef);
    end;

    local procedure CreateDataExchangeDefinition(var DataExchDef: Record "Data Exch. Def")
    begin
        LibraryPaymentFormat.CreateDataExchDef(
          DataExchDef, CODEUNIT::"Import XML File to Data Exch.",
          CODEUNIT::"Map Data Exch. To RapidStart", CODEUNIT::"Import XML File to Data Exch.", 0, 0, 0);
    end;

    local procedure CreateDataExchMapping(DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        DataExchMapping.Init();
        DataExchMapping.Validate("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchMapping.Validate("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchMapping.Validate("Table ID", DATABASE::"Currency Exchange Rate");
        DataExchMapping.Insert(true);
    end;

    local procedure MapFields(var ColumnNo: Integer; DataExchLineDef: Record "Data Exch. Line Def"; FieldID: Integer)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        CreateDataExchangeColumnDef(DataExchColumnDef, DataExchLineDef, ColumnNo, '');
        CreateDataExchFieldMapping(DataExchColumnDef, FieldID);
        ColumnNo += 1;
    end;

    local procedure CreateDataExchangeColumnDef(var DataExchColumnDef: Record "Data Exch. Column Def"; DataExchLineDef: Record "Data Exch. Line Def"; ColumnNo: Integer; Path: Text[250])
    var
        Language: Codeunit Language;
    begin
        DataExchColumnDef.Init();
        DataExchColumnDef.Validate("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchColumnDef.Validate("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.Validate("Column No.", ColumnNo);
        DataExchColumnDef.Validate("Data Formatting Culture", Language.GetCultureName(WindowsLanguage));
        DataExchColumnDef.Validate(Path, Path);
        DataExchColumnDef.Insert(true);
    end;

    local procedure CreateDataExchFieldMapping(DataExchColumnDef: Record "Data Exch. Column Def"; FieldID: Integer)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchFieldMapping.Init();
        DataExchFieldMapping.Validate("Data Exch. Def Code", DataExchColumnDef."Data Exch. Def Code");
        DataExchFieldMapping.Validate("Data Exch. Line Def Code", DataExchColumnDef."Data Exch. Line Def Code");
        DataExchFieldMapping.Validate("Column No.", DataExchColumnDef."Column No.");
        DataExchFieldMapping.Validate("Table ID", DATABASE::"Currency Exchange Rate");
        DataExchFieldMapping.Validate("Field ID", FieldID);
        DataExchFieldMapping.Insert(true);
    end;

    local procedure MapMandatoryFields(DataExchLineDef: Record "Data Exch. Line Def")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ColumnNo: Integer;
    begin
        GetLastColumnNo(ColumnNo, DataExchLineDef);

        MapFields(ColumnNo, DataExchLineDef, CurrencyExchangeRate.FieldNo("Currency Code"));
        MapFields(ColumnNo, DataExchLineDef, CurrencyExchangeRate.FieldNo("Relational Exch. Rate Amount"));
    end;

    local procedure MapCommonFields(DataExchLineDef: Record "Data Exch. Line Def")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ColumnNo: Integer;
    begin
        GetLastColumnNo(ColumnNo, DataExchLineDef);

        MapFields(ColumnNo, DataExchLineDef, CurrencyExchangeRate.FieldNo("Starting Date"));
        MapFields(ColumnNo, DataExchLineDef, CurrencyExchangeRate.FieldNo("Exchange Rate Amount"));
    end;

    local procedure MapAdditionalFields(DataExchLineDef: Record "Data Exch. Line Def")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ColumnNo: Integer;
    begin
        GetLastColumnNo(ColumnNo, DataExchLineDef);

        MapFields(ColumnNo, DataExchLineDef, CurrencyExchangeRate.FieldNo("Adjustment Exch. Rate Amount"));
        MapFields(ColumnNo, DataExchLineDef, CurrencyExchangeRate.FieldNo("Relational Currency Code"));
        MapFields(ColumnNo, DataExchLineDef, CurrencyExchangeRate.FieldNo("Relational Adjmt Exch Rate Amt"));
    end;

    local procedure GetLastColumnNo(var ColumnNo: Integer; DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);

        if DataExchColumnDef.FindLast() then
            ColumnNo := DataExchColumnDef."Column No." + 1
        else
            ColumnNo := 1;
    end;

    local procedure CreateDataExchangeTestData(var DataExch: Record "Data Exch."; DataExchLineDef: Record "Data Exch. Line Def"; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        CreateDataExchange(DataExch, DataExchLineDef);
        CurrentNodeID := 1;
        LineNo := 1;
        if CurrencyExchangeRate.FindSet() then
            repeat
                CreateDataExchangeField(
                  DataExch, DataExchLineDef, CurrencyExchangeRate.FieldNo("Currency Code"), CurrencyExchangeRate."Currency Code",
                  CurrentNodeID, LineNo);
                CreateDataExchangeField(
                  DataExch, DataExchLineDef, CurrencyExchangeRate.FieldNo("Relational Exch. Rate Amount"),
                  Format(CurrencyExchangeRate."Relational Exch. Rate Amount"), CurrentNodeID, LineNo);
                CreateDataExchangeField(
                  DataExch, DataExchLineDef, CurrencyExchangeRate.FieldNo("Starting Date"),
                  Format(CurrencyExchangeRate."Starting Date"), CurrentNodeID, LineNo);
                CreateDataExchangeField(
                  DataExch, DataExchLineDef, CurrencyExchangeRate.FieldNo("Exchange Rate Amount"),
                  Format(CurrencyExchangeRate."Exchange Rate Amount"), CurrentNodeID, LineNo);
                CreateDataExchangeField(
                  DataExch, DataExchLineDef, CurrencyExchangeRate.FieldNo("Adjustment Exch. Rate Amount"),
                  Format(CurrencyExchangeRate."Adjustment Exch. Rate Amount"), CurrentNodeID, LineNo);
                CreateDataExchangeField(
                  DataExch, DataExchLineDef, CurrencyExchangeRate.FieldNo("Relational Adjmt Exch Rate Amt"),
                  Format(CurrencyExchangeRate."Relational Adjmt Exch Rate Amt"), CurrentNodeID, LineNo);
                LineNo += 1;
            until CurrencyExchangeRate.Next() = 0;
    end;

    local procedure CreateCurrencies(var Currency: Record Currency; var TempExpectedCurrencyExchangeRate: Record "Currency Exchange Rate" temporary; StartDate: Date; NumberToInsert: Integer)
    var
        I: Integer;
    begin
        for I := 1 to NumberToInsert do begin
            Clear(Currency);
            LibraryERM.CreateCurrency(Currency);

            // This exchange rate will be used to generate Data Exchange data and to assert values
            TempExpectedCurrencyExchangeRate.Init();
            TempExpectedCurrencyExchangeRate.Validate("Currency Code", Currency.Code);
            TempExpectedCurrencyExchangeRate.Validate("Starting Date", StartDate);
            TempExpectedCurrencyExchangeRate.Insert(true);

            TempExpectedCurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDecInRange(1, 1000, 2));
            TempExpectedCurrencyExchangeRate.Validate("Exchange Rate Amount", DefualtExchangeRateAmount);
            TempExpectedCurrencyExchangeRate.Validate(
              "Adjustment Exch. Rate Amount", TempExpectedCurrencyExchangeRate."Exchange Rate Amount");
            TempExpectedCurrencyExchangeRate.Validate(
              "Relational Adjmt Exch Rate Amt", TempExpectedCurrencyExchangeRate."Relational Exch. Rate Amount");
            TempExpectedCurrencyExchangeRate.Modify(true);
        end;
    end;

    local procedure CreateDataExchange(var DataExch: Record "Data Exch."; DataExchLineDef: Record "Data Exch. Line Def")
    begin
        DataExch.Init();
        DataExch."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
        DataExch."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExch.Insert(true);
    end;

    local procedure CreateDataExchangeField(DataExch: Record "Data Exch."; DataExchLineDef: Record "Data Exch. Line Def"; FieldNo: Integer; TextValue: Text[250]; var CurrentNodeID: Integer; LineNo: Integer)
    var
        DataExchField: Record "Data Exch. Field";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchFieldMapping.SetRange("Field ID", FieldNo);
        if not DataExchFieldMapping.FindFirst() then
            exit;

        DataExchField.Init();
        DataExchField.Validate("Data Exch. No.", DataExch."Entry No.");
        DataExchField.Validate("Column No.", DataExchFieldMapping."Column No.");
        DataExchField.Validate("Node ID", GetNodeID(CurrentNodeID));
        DataExchField.Validate(Value, TextValue);
        DataExchField.Validate("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchField.Validate("Line No.", LineNo);
        DataExchField.Insert(true);

        CurrentNodeID += 1;
    end;

    local procedure GetNodeID(CurrentNodeCount: Integer): Text
    begin
        exit(Format(CurrentNodeCount, 0, '<Integer,4><Filler Char,0>'))
    end;

    local procedure VerifyCurrencyExchangeRateMatch(var TempExpectedCurrencyExchangeRate: Record "Currency Exchange Rate" temporary)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        TempExpectedCurrencyExchangeRate.Reset();
        TempExpectedCurrencyExchangeRate.FindSet();

        repeat
            Assert.IsTrue(
              CurrencyExchangeRate.Get(TempExpectedCurrencyExchangeRate."Currency Code", TempExpectedCurrencyExchangeRate."Starting Date"),
              'Could not find currency exchange rate');
            Assert.AreEqual(
              TempExpectedCurrencyExchangeRate."Exchange Rate Amount", CurrencyExchangeRate."Exchange Rate Amount",
              'Exchange Rate Amount field does not match');
            Assert.AreEqual(
              TempExpectedCurrencyExchangeRate."Adjustment Exch. Rate Amount", CurrencyExchangeRate."Adjustment Exch. Rate Amount",
              'Adjustment Exch. Rate Amount field does not match');
            Assert.AreEqual(
              TempExpectedCurrencyExchangeRate."Relational Currency Code", CurrencyExchangeRate."Relational Currency Code",
              'Relational Currency Code field does not match');
            Assert.AreEqual(
              TempExpectedCurrencyExchangeRate."Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount",
              'Relational Exch. Rate Amount field does not match');
            Assert.AreEqual(
              TempExpectedCurrencyExchangeRate."Fix Exchange Rate Amount", CurrencyExchangeRate."Fix Exchange Rate Amount",
              'Fix Exchange Rate Amount field does not match');
            Assert.AreEqual(
              TempExpectedCurrencyExchangeRate."Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Adjmt Exch Rate Amt",
              'Relational Adjmt Exch Rate Amt field does not match');
        until TempExpectedCurrencyExchangeRate.Next() = 0;
    end;

    local procedure VerifyFieldsNotEditableOnCurrExchRateServiceCard(var CurrExchRateServiceCard: TestPage "Curr. Exch. Rate Service Card")
    begin
        Assert.IsFalse(CurrExchRateServiceCard.ShowEnableWarning.Editable(), '');
        Assert.IsFalse(CurrExchRateServiceCard.Code.Editable(), '');
        Assert.IsFalse(CurrExchRateServiceCard.Description.Editable(), '');
        Assert.IsFalse(CurrExchRateServiceCard.ServiceURL.Editable(), '');
        Assert.IsFalse(CurrExchRateServiceCard."Service Provider".Editable(), '');
        Assert.IsFalse(CurrExchRateServiceCard."Terms of Service".Editable(), '');
        Assert.IsFalse(CurrExchRateServiceCard."Log Web Requests".Editable(), '');
    end;

    local procedure VerifyFieldsEditableOnCurrExchRateServiceCard(var CurrExchRateServiceCard: TestPage "Curr. Exch. Rate Service Card")
    begin
        Assert.IsTrue(CurrExchRateServiceCard.Enabled.Editable(), '');
        Assert.IsTrue(CurrExchRateServiceCard.Code.Editable(), '');
        Assert.IsTrue(CurrExchRateServiceCard.Description.Editable(), '');
        Assert.IsTrue(CurrExchRateServiceCard.ServiceURL.Editable(), '');
        Assert.IsTrue(CurrExchRateServiceCard."Service Provider".Editable(), '');
        Assert.IsTrue(CurrExchRateServiceCard."Terms of Service".Editable(), '');
        Assert.IsTrue(CurrExchRateServiceCard."Log Web Requests".Editable(), '');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

