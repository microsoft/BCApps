codeunit 139173 "CRM Synch. Helper Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [CRM Synch. Helper]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CurrencyNotFoundErr: Label 'The currency with the ISO code ''%1'' cannot be found. Therefore, the exchange rate between ''%2'' and ''%3'' cannot be calculated.', Comment = '%1,%2,%3=the ISO code of a currency (example: DKK);';
        IncorrectUnitGroupNameErr: Label 'Incorrect Unit Group name.';
        IncorrectStateCodeErr: Label 'Incorrect State Code.';
        IncorrectStatusCodeErr: Label 'Incorrect Status Code.';
        BaseCurrencyIsNullErr: Label 'The base currency is not defined. Disable and enable CRM connection to initialize setup properly.';

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBaseCurrencyPrecision()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        // [FEATURE] [Currency] [UT]
        // [SCENARIO] GetBaseCurrencyPrecision() should return: 1 for 0; 0.01 for 2; 0.0000000001 for 10
        CRMConnectionSetup.DeleteAll();
        CRMConnectionSetup.BaseCurrencyPrecision := 0;
        CRMConnectionSetup.Insert();
        Assert.AreEqual(1, CRMSynchHelper.GetBaseCurrencyPrecision(), 'for BaseCurrencyPrecision = 0');

        CRMConnectionSetup.BaseCurrencyPrecision := 1;
        CRMConnectionSetup.Modify();
        Assert.AreEqual(0.1, CRMSynchHelper.GetBaseCurrencyPrecision(), 'for BaseCurrencyPrecision = 1');

        CRMConnectionSetup.BaseCurrencyPrecision := 2;
        CRMConnectionSetup.Modify();
        Assert.AreEqual(0.01, CRMSynchHelper.GetBaseCurrencyPrecision(), 'for BaseCurrencyPrecision = 2');

        CRMConnectionSetup.BaseCurrencyPrecision := 10;
        CRMConnectionSetup.Modify();
        Assert.AreEqual(0.0000000001, CRMSynchHelper.GetBaseCurrencyPrecision(), 'for BaseCurrencyPrecision = 10');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetCRMCurrencyDefaultPrecision()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        CurrencyPrecision: Integer;
    begin
        // [FEATURE] [Currency]
        // [SCENARIO] GetCRMCurrencyDefaultPrecision() should return CRM Currency default precision
        // [GIVEN] CRM enabled, CRM default precision is defined
        InitializeCRMIntegration();
        CurrencyPrecision := LibraryRandom.RandIntInRange(0, 20);
        CRMConnectionSetup.Get();
        CRMConnectionSetup.CurrencyDecimalPrecision := CurrencyPrecision;
        CRMConnectionSetup.Modify();

        // [WHEN] GetCRMCurrencyDefaultPrecision() is called
        // [THEN] The correct currency precision is retrieved
        Assert.AreEqual(CurrencyPrecision, CRMSynchHelper.GetCRMCurrencyDefaultPrecision(), 'Unexpected CRM default currency precision');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetCRMLCYToFCYExchangeRate()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        ISOCurrencyCode: Text[5];
    begin
        // [FEATURE] [Currency] [FCY]
        // [SCENARIO] GetCRMLCYToFCYExchangeRate() should return an exchage rate of CRM base currency (LCY) to another currency (FCY)
        // [GIVEN] CRM enabled, CRM base currency is set
        InitializeCRMIntegration();
        ResetDefaultCRMSetupConfiguration();
        LibraryCRMIntegration.CreateCRMOrganization();
        ISOCurrencyCode := LibraryCRMIntegration.GetBaseCRMTestCurrencySymbol();
        LibraryERM.SetLCYCode(ISOCurrencyCode);
        LibraryCRMIntegration.CreateCRMTransactionCurrency(CRMTransactioncurrency, ISOCurrencyCode);

        CRMConnectionSetup.Get();
        CRMConnectionSetup.Validate("Is Enabled", true);
        CRMConnectionSetup.Modify();

        // [WHEN] GetCRMLCYToFCYExchangeRate() is called
        // [THEN] The correct exchange rate = '1' is retrieved
        Assert.AreEqual(1, CRMSynchHelper.GetCRMLCYToFCYExchangeRate(ISOCurrencyCode), 'Incorrect exchange rate');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetFCYtoFCYExchangeRate()
    var
        FromCurrency: Record Currency;
        ToCurrency: Record Currency;
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        // [FEATURE] [Currency] [FCY]
        // [SCENARIO] GetFCYtoFCYExchangeRate() should return currency exchange rate from one FCY to another FCY
        // [GIVEN] FCY1 (rate 12:1), FCY2 (rate 3:1)
        FromCurrency.Get(CreateCurrencyWithExchangeRate(12));
        ToCurrency.Get(CreateCurrencyWithExchangeRate(3));

        // [WHEN] GetFCYtoFCYExchangeRate() is called
        // [THEN] The rate is 4
        Assert.AreEqual(
          4, CRMSynchHelper.GetFCYtoFCYExchangeRate(FromCurrency.Code, ToCurrency.Code), 'Incorrect FromFCY to ToFCY exchange rate');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetCRMLCYToFCYExchangeRateOnNullBaseCurrency()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        // [FEATURE] [Currency]
        // [SCENARIO] GetCRMLCYToFCYExchangeRate() should throw 'The base currency is not defined.' if CRM Conenction Setup is not initialized.
        // [GIVEN] CRM Connection Setup, where BaseCurrencyId is <null>
        CRMConnectionSetup.Get();
        Clear(CRMConnectionSetup.BaseCurrencyId);
        CRMConnectionSetup.Modify();

        // [WHEN] GetCRMLCYToFCYExchangeRate('USD') is called
        asserterror CRMSynchHelper.GetCRMLCYToFCYExchangeRate('USD');
        // [THEN] Error message: 'The base currency is not defined.'
        Assert.ExpectedError(BaseCurrencyIsNullErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetLCYtoLCYExchangeRate()
    var
        Currency: Record Currency;
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        // [FEATURE] [Currency] [FCY]
        // [SCENARIO] GetFCYtoFCYExchangeRate() should return 1 as a currency exchange rate for a currency to itself
        // [GIVEN] A currency (rate 12:1)
        Currency.Get(CreateCurrencyWithExchangeRate(12));

        // [WHEN] GetFCYtoFCYExchangeRate() is called
        // [THEN] The rate is equal to 1
        Assert.AreEqual(1, CRMSynchHelper.GetFCYtoFCYExchangeRate(Currency.Code, Currency.Code), 'Incorrect LCY to LCY exchange rate');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetEmptytoEmptyExchangeRate()
    var
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        // [FEATURE] [Currency] [FCY]
        // [SCENARIO] GetFCYtoFCYExchangeRate() should throw an error for blank to blank currency
        // [GIVEN] A currency
        // [WHEN] The exchange rate is calculated between empty and empty
        // [THEN] An error is thrown : "Currency cannot be found"
        asserterror CRMSynchHelper.GetFCYtoFCYExchangeRate('', '');
        Assert.ExpectedError(StrSubstNo(CurrencyNotFoundErr, '', '', ''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetEmptytoLCYExchangeRate()
    var
        Currency: Record Currency;
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        // [FEATURE] [Currency] [FCY]
        // [SCENARIO] GetFCYtoFCYExchangeRate() should throw an error for blank to not blank currency
        // [GIVEN] A currency
        Currency.Get(CreateCurrencyWithExchangeRate(12));

        // [WHEN] The exchange rate is calculated between empty and the currency
        // [THEN] An error is thrown : "Currency cannot be found"
        asserterror CRMSynchHelper.GetFCYtoFCYExchangeRate('', Currency.Code);
        Assert.ExpectedError(StrSubstNo(CurrencyNotFoundErr, '', Currency.Code, ''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetLCYtoEmptyExchangeRate()
    var
        Currency: Record Currency;
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        // [FEATURE] [Currency] [FCY]
        // [SCENARIO] GetFCYtoFCYExchangeRate() should throw an error for not blank to blank currency
        // [GIVEN] A currency
        Currency.Get(CreateCurrencyWithExchangeRate(12));

        // [WHEN] The exchange rate is calculated between the currency and empty
        // [THEN] An error is thrown
        asserterror CRMSynchHelper.GetFCYtoFCYExchangeRate(Currency.Code, '');
        Assert.ExpectedError(StrSubstNo(CurrencyNotFoundErr, '', '', Currency.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetFCYtoLCYExchangeRate()
    var
        Currency: Record Currency;
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        // [FEATURE] [Currency] [FCY]
        // [SCENARIO] GetFCYtoFCYExchangeRate() should return a currency exchange rate for a currency to LCY
        // [GIVEN] A currency (rate 12:1)
        Currency.Get(CreateCurrencyWithExchangeRate(12));

        // [WHEN] GetFCYtoFCYExchangeRate() is called
        // [THEN] The rate is 12
        Assert.AreEqual(
          12, CRMSynchHelper.GetFCYtoFCYExchangeRate(Currency.Code, LibraryERM.GetLCYCode()), 'Incorrect FCY to LCY exchange rate');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFindCRMDefaultPriceListCreate()
    var
        CRMPricelevel: Record "CRM Pricelevel";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] FindCRMDefaultPriceList() should create the default NAV Price List in CRM, if it doesn't exist
        InitializeCRMIntegration();

        // [GIVEN] There is no NAV default price list in CRM
        // [WHEN] FindCRMDefaultPriceList is called
        LibraryCRMIntegration.CreateCRMOrganization();
        CRMSynchHelper.FindCRMDefaultPriceList(CRMPricelevel);

        // [THEN] The correct price list is created
        VerifyCRMDefaultPriceList(CRMPricelevel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFindCRMDefaultPriceListGet()
    var
        CRMPricelevel: Record "CRM Pricelevel";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] FindCRMDefaultPriceList() should return the default NAV Price List in CRM, if it does already exist
        InitializeCRMIntegration();

        // [GIVEN] There is no NAV default price list in CRM
        LibraryCRMIntegration.CreateCRMOrganization();
        LibraryCRMIntegration.SetCRMDefaultPriceList(CRMPricelevel);
        Clear(CRMPricelevel);

        // [WHEN] FindCRMDefaultPriceList is called
        CRMSynchHelper.FindCRMDefaultPriceList(CRMPricelevel);

        // [THEN] The correct price list is created
        VerifyCRMDefaultPriceList(CRMPricelevel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCRMDefaultPriceListIdAfterReset()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMPricelevel: Record "CRM Pricelevel";
        NullGUID: Guid;
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] "CRM Connection Setup"."Default CRM Price List ID" is cleared on reset default CRM setup configuration
        InitializeCRMIntegration();

        // [GIVEN] CRM Connection setup has non-empty "Default CRM Price List ID"
        LibraryCRMIntegration.CreateCRMOrganization();
        LibraryCRMIntegration.SetCRMDefaultPriceList(CRMPricelevel);

        // [WHEN] Reset default CRM setup configuration
        ResetDefaultCRMSetupConfiguration();

        // [THEN] "Default CRM Price List ID" is empty in CRM Connection Setup
        CRMConnectionSetup.Get();
        CRMConnectionSetup.TestField("Default CRM Price List ID", NullGUID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCRMDefaultPriceListIdRestoredAfterReset()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        ExpectedGUID: Guid;
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] Blank "Default CRM Price List ID" is restored to the found Default Price List if it alreay exists
        InitializeCRMIntegration();

        // [GIVEN] CRM Connection setup has non-empty "Default CRM Price List ID"
        LibraryCRMIntegration.CreateCRMOrganization();
        LibraryCRMIntegration.SetCRMDefaultPriceList(CRMPricelevel);
        ExpectedGUID := CRMPricelevel.PriceLevelId;
        // [GIVEN] Reset default CRM setup configuration
        ResetDefaultCRMSetupConfiguration();

        // [WHEN] FindCRMDefaultPriceList is called
        Clear(CRMPricelevel);
        CRMSynchHelper.FindCRMDefaultPriceList(CRMPricelevel);

        // [THEN] "Default CRM Price List ID" is restored in CRM Connection Setup
        CRMConnectionSetup.Get();
        CRMConnectionSetup.TestField("Default CRM Price List ID", ExpectedGUID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateCRMPriceListItemNullGUID()
    var
        CRMProduct: Record "CRM Product";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        AdditionalFieldsWereModified: Boolean;
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] UpdateCRMPriceListItem() should return FALSE if Product GUID is not defined
        // [GIVEN] A null product GUID
        CRMProduct.Init();

        // [WHEN] UpdateCRMPriceListItem() is called
        AdditionalFieldsWereModified := CRMSynchHelper.UpdateCRMPriceListItem(CRMProduct);

        // [THEN] The function returns FALSE
        Assert.IsFalse(AdditionalFieldsWereModified, 'Unexpected return value.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateCRMPriceListItemCreate()
    var
        CRMProduct: Record "CRM Product";
        Resource: Record Resource;
        CRMProductpricelevel: Record "CRM Productpricelevel";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        AdditionalFieldsWereModified: Boolean;
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] UpdateCRMPriceListItem() should create a new price list item in CRM
        InitializeCRMIntegration();

        // [GIVEN] A coupled Resource and CRM Product
        LibraryCRMIntegration.CreateCoupledResourceAndProduct(Resource, CRMProduct);

        // [WHEN] UpdateCRMPriceListItem()  is called
        AdditionalFieldsWereModified := CRMSynchHelper.UpdateCRMPriceListItem(CRMProduct);

        // [THEN] The function returns TRUE which means that modification or creation of data ocurred
        Assert.IsTrue(AdditionalFieldsWereModified, 'The function should report that additional fields were modified.');

        // [THEN] The correct price list item is created
        CRMProductpricelevel.SetRange(ProductId, CRMProduct.ProductId);
        Assert.IsTrue(CRMProductpricelevel.FindFirst(), 'The expected price list was not created in CRM.');

        // [THEN] The price list item has correct values
        AssertProductAndPriceListItemAreConsistent(CRMProduct, CRMProductpricelevel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateCRMPriceListItemCreateNullPriceLevelID()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMProduct: Record "CRM Product";
        Resource: Record Resource;
        CRMProductpricelevel: Record "CRM Productpricelevel";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        AdditionalFieldsWereModified: Boolean;
    begin
        // [FEATURE] [Price List]
        // [SCENARIO 381363] UpdateCRMPriceListItem() should create a default price list and new price list item in CRM if Price List ID is blank
        InitializeCRMIntegration();
        // [GIVEN] "Default CRM Price List ID" is blank
        CRMConnectionSetup.Get();
        Clear(CRMConnectionSetup."Default CRM Price List ID");
        CRMConnectionSetup.Modify();

        // [GIVEN] A coupled Resource and CRM Product, where PriceLevelId is blank
        LibraryCRMIntegration.CreateCoupledResourceAndProduct(Resource, CRMProduct);
        Clear(CRMProduct.PriceLevelId);
        CRMProduct.Modify();

        // [WHEN] UpdateCRMPriceListItem() is called
        AdditionalFieldsWereModified := CRMSynchHelper.UpdateCRMPriceListItem(CRMProduct);

        // [THEN] The function returns TRUE which means that modification or creation of data ocurred
        Assert.IsTrue(AdditionalFieldsWereModified, 'The function should report that additional fields were modified.');

        // [THEN] "Default CRM Price List ID" is not blank
        CRMConnectionSetup.Get();
        CRMConnectionSetup.TestField("Default CRM Price List ID");

        // [THEN] The correct price list item is created
        CRMProductpricelevel.SetRange(ProductId, CRMProduct.ProductId);
        Assert.IsTrue(CRMProductpricelevel.FindFirst(), 'The expected price list was not created in CRM.');

        // [THEN] The price list item has correct values
        AssertProductAndPriceListItemAreConsistent(CRMProduct, CRMProductpricelevel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateCRMPriceListItemUpdate()
    var
        CRMProduct: Record "CRM Product";
        Resource: Record Resource;
        CRMProductpricelevel: Record "CRM Productpricelevel";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] UpdateCRMPriceListItem() should update an existing price list item in CRM
        InitializeCRMIntegration();

        // [GIVEN] A coupled Resource and CRM Product
        LibraryCRMIntegration.CreateCoupledResourceAndProduct(Resource, CRMProduct);
        // [GIVEN] A price list item associated to the price
        CRMSynchHelper.UpdateCRMPriceListItem(CRMProduct);

        // [WHEN] CRM product has changed fields
        LibraryCRMIntegration.ChangeCRMProductFields(CRMProduct);

        // [WHEN] UpdateCRMPriceListItem() is called

        // [THEN] The function returns TRUE to mark that a change had been made
        Assert.IsTrue(CRMSynchHelper.UpdateCRMPriceListItem(CRMProduct), 'Incorrect return value');

        // [THEN] The price list item has correct values
        CRMProductpricelevel.SetRange(ProductId, CRMProduct.ProductId);
        Assert.IsTrue(CRMProductpricelevel.FindFirst(), 'The expected price list was not created in CRM.');
        AssertProductAndPriceListItemAreConsistent(CRMProduct, CRMProductpricelevel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFindNAVLocalCurrencyInCRMCreate()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        ISOCurrencyCode: Text[5];
        CurrencyPrecision: Integer;
    begin
        // [FEATURE] [Currency]
        // [SCENARIO] FindNAVLocalCurrencyInCRM() should insert a LCY CRMTransactioncurrency if NAV LCY does not exist in CRMTransactioncurrency
        InitializeCRMIntegration();

        // [GIVEN] NAV LCY = CRMOrganization.BaseCurrencySymbol
        CurrencyPrecision := LibraryRandom.RandIntInRange(1, 2);
        LibraryCRMIntegration.CreateCRMOrganizationWithCurrencyPrecision(CurrencyPrecision);
        CRMConnectionSetup.Get();
        CRMConnectionSetup.Validate("Is Enabled", true);
        CRMConnectionSetup.Modify();
        ISOCurrencyCode := DelChr(CRMConnectionSetup.BaseCurrencySymbol);

        LibraryERM.SetLCYCode(ISOCurrencyCode);
        // [GIVEN] DKK does not exist as a currency in CRMTransactionCurrency table
        CRMTransactioncurrency.DeleteAll();

        // [WHEN] FindNAVLocalCurrencyInCRM is called
        CRMSynchHelper.FindNAVLocalCurrencyInCRM(CRMTransactioncurrency);

        // [THEN] The correct CRMTransactionCurrency record is returned
        Assert.AreEqual(
          ISOCurrencyCode, CRMTransactioncurrency.ISOCurrencyCode, 'Unexpected ISO Currency Code on CRM TransactionCurrency create');
        Assert.AreEqual(ISOCurrencyCode, CRMTransactioncurrency.CurrencySymbol, 'Unexpected currency symbol');
        Assert.AreEqual(ISOCurrencyCode, CRMTransactioncurrency.CurrencyName, 'Unexpected currency name');
        Assert.AreEqual(CurrencyPrecision, CRMTransactioncurrency.CurrencyPrecision, 'Unexpected currency precision');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFindNAVLocalCurrencyInCRMGet()
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        ISOCurrencyCode: Text[5];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO] FindNAVLocalCurrencyInCRM() should return a LCY CRMTransactioncurrency if NAV LCY exists in CRMTransactioncurrency
        InitializeCRMIntegration();

        // [GIVEN] NAV LCY = DKK
        ISOCurrencyCode := 'DKK';
        LibraryERM.SetLCYCode(ISOCurrencyCode);
        // [GIVEN] DKK exists as a currency in CRMTransactionCurrency table
        LibraryCRMIntegration.CreateCRMTransactionCurrency(CRMTransactioncurrency, ISOCurrencyCode);

        // [WHEN] FindNAVLocalCurrencyInCRM is called
        Clear(CRMTransactioncurrency);
        CRMSynchHelper.FindNAVLocalCurrencyInCRM(CRMTransactioncurrency);

        // [THEN] The correct CRMTransactionCurrency record is returned
        Assert.AreEqual(
          ISOCurrencyCode, CRMTransactioncurrency.ISOCurrencyCode, 'Unexpected ISO Currency Code on CRM TransactionCurrency get');
        Assert.AreEqual(ISOCurrencyCode, CRMTransactioncurrency.CurrencySymbol, 'Unexpected currency symbol');
        Assert.AreEqual(ISOCurrencyCode, CRMTransactioncurrency.CurrencyName, 'Unexpected currency name');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetUnitOfMeasureName()
    var
        UnitOfMeasure: Record "Unit of Measure";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        UnitOfMeasureRecordRef: RecordRef;
    begin
        // [FEATURE] [Unit Of Measure]
        // [SCENARIO] GetUnitOfMeasureName() should return Code of "Unit Of Measure"
        // [GIVEN] An unit of measure record ref
        UnitOfMeasure.Init();
        UnitOfMeasure.Code := 'STONE';
        UnitOfMeasureRecordRef.GetTable(UnitOfMeasure);

        // [WHEN] GetUnitOfMeasureName() is invoked
        // [THEN] The correct value is returned
        Assert.AreEqual(
          UnitOfMeasure.Code, CRMSynchHelper.GetUnitOfMeasureName(UnitOfMeasureRecordRef), 'Unexpected Unit of Measure name');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetUnitGroupName()
    var
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        // [FEATURE] [Unit Of Measure]
        // [SCENARIO] GetUnitGroupName() should add "NAV " prefix
        // [GIVEN] An unit of measure name
        // [WHEN] GetUnitGroupName() is called
        // [THEN] The unit group name equals the unit of measure name prefixed with "NAV "
        Assert.AreEqual('NAV KM', CRMSynchHelper.GetUnitGroupName('KM'), IncorrectUnitGroupNameErr);
        Assert.AreEqual('NAV BRONTOZAUR', CRMSynchHelper.GetUnitGroupName('BRONTOZAUR'), IncorrectUnitGroupNameErr);
        Assert.AreEqual('NAV NAV', CRMSynchHelper.GetUnitGroupName('NAV'), IncorrectUnitGroupNameErr);
        Assert.AreEqual('NAV ', CRMSynchHelper.GetUnitGroupName(''), IncorrectUnitGroupNameErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetCRMProductStateToActive()
    var
        CRMProduct: Record "CRM Product";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        // [SCENARIO] SetCRMProductStateToActive() should set the StateCode and StatusCode on a CRM Product to Active
        // [GIVEN] CRM Product, where StateCode and StatusCode are Retired
        CRMProduct.Init();
        CRMProduct.StateCode := CRMProduct.StateCode::Retired;
        CRMProduct.StatusCode := CRMProduct.StatusCode::Retired;

        // [WHEN] SetCRMProductStateToActive() is called
        CRMSynchHelper.SetCRMProductStateToActive(CRMProduct);

        // [THEN] StateCode and StatusCode are set to Active
        Assert.AreEqual(CRMProduct.StateCode::Active, CRMProduct.StateCode, IncorrectStateCodeErr);
        Assert.AreEqual(CRMProduct.StatusCode::Active, CRMProduct.StatusCode, IncorrectStatusCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateCRMInvoiceStateActive()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CRMInvoice: Record "CRM Invoice";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO] UpdateCRMInvoiceStatus() should update the state and status on the CRM Invoice, when not paid
        LibraryTestInitialize.OnTestInitialize(Codeunit::"CRM Synch. Helper Test");

        // [GIVEN] A posted NAV sales invoice, not paid
        CreateAndPostSalesInvoice(SalesInvoiceHeader);

        // [WHEN] UpdateCRMInvoiceStatus() is called on unpaid CRM invoice
        UpdateCRMInvoiceStatus(CRMInvoice, SalesInvoiceHeader);

        // [THEN] The CRM invoice, where StateCode is Active, StatusCode is Billed
        Assert.AreEqual(CRMInvoice.StateCode::Active, CRMInvoice.StateCode, IncorrectStateCodeErr);
        Assert.AreEqual(CRMInvoice.StatusCode::Billed, CRMInvoice.StatusCode, IncorrectStatusCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateCRMInvoiceStatePaid()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CRMInvoice: Record "CRM Invoice";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"CRM Synch. Helper Test");

        // [FEATURE] [Invoice]
        // [SCENARIO] UpdateCRMInvoiceStatus() should update the state and status on the CRM Invoice, fully paid
        // [GIVEN] A posted NAV sales invoice, fully paid
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        CreatePaymentAndApplyToInvoice(
          SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT");

        // [WHEN] The paid CRM invoice status is updated
        // [WHEN] UpdateCRMInvoiceStatus() is called on paid CRM invoice
        UpdateCRMInvoiceStatus(CRMInvoice, SalesInvoiceHeader);

        // [THEN] The CRM invoice StateCode is Paid, StatusCode is Complete
        Assert.AreEqual(CRMInvoice.StateCode::Paid, CRMInvoice.StateCode, IncorrectStateCodeErr);
        Assert.AreEqual(CRMInvoice.StatusCode::Complete, CRMInvoice.StatusCode, IncorrectStatusCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateCRMInvoiceStatePartial()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CRMInvoice: Record "CRM Invoice";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"CRM Synch. Helper Test");

        // [FEATURE] [Invoice]
        // [SCENARIO] UpdateCRMInvoiceStatus() should update the state and status on the CRM Invoice, partial payment applied
        // [GIVEN] A posted NAV sales invoice, and a partial payment applied
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        CreatePaymentAndApplyToInvoice(SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.",
          -SalesInvoiceHeader."Amount Including VAT" / 2);

        // [WHEN] The partially paid invoice status in CRM is updated
        UpdateCRMInvoiceStatus(CRMInvoice, SalesInvoiceHeader);

        // [THEN] The CRM invoice StateCode is Paid, StatusCode is Partial
        Assert.AreEqual(CRMInvoice.StateCode::Paid, CRMInvoice.StateCode, IncorrectStateCodeErr);
        Assert.AreEqual(CRMInvoice.StatusCode::Partial, CRMInvoice.StatusCode, IncorrectStatusCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateOwnerIfChangedWithNoChange()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
    begin
        // [FEATURE] [CRM Account]
        // [SCENARIO] UpdateOwnerIfChanged() should not update OwnerId if source is not changed
        ResetDefaultCRMSetupConfiguration();
        // [GIVEN] Customer coupled to CRM Account.
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        // [GIVEN] Salesperson coupled CRM SystemUser
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        // [GIVEN] CRM Account Record has OwnerID coupled SystemUser
        // [GIVEN] CRM Account Record has OwnerIDType is "team"
        CRMAccount.OwnerId := CRMSystemuser.SystemUserId;
        CRMAccount.OwnerIdType := CRMAccount.OwnerIdType::team;
        // [GIVEN] Customer has salesperson code matching coupled salesperson.
        Customer."Salesperson Code" := SalespersonPurchaser.Code;

        // [WHEN] UpdateOwnerIfChanged is called
        SourceRecordRef.GetTable(Customer);
        DestinationRecordRef.GetTable(CRMAccount);
        CRMSynchHelper.UpdateOwnerIfChanged(
          SourceRecordRef, DestinationRecordRef, Customer.FieldNo("Salesperson Code"), CRMAccount.FieldNo(OwnerId),
          CRMAccount.FieldNo(OwnerIdType), CRMAccount.OwnerIdType::systemuser);

        // [THEN] The OwnerID is is not changed
        // [THEN] The OwnerIDType is not changed
        DestinationRecordRef.SetTable(CRMAccount);
        Assert.AreEqual(CRMSystemuser.SystemUserId, CRMAccount.OwnerId, 'Did not expect the OwnerId to change');
        Assert.AreEqual(CRMAccount.OwnerIdType::team, CRMAccount.OwnerIdType, 'Did not expect the OwnerIdType to change');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateOwnerIfChangedWithChange()
    var
        SalespersonPurchaserA: Record "Salesperson/Purchaser";
        CRMSystemuserA: Record "CRM Systemuser";
        SalespersonPurchaserB: Record "Salesperson/Purchaser";
        CRMSystemuserB: Record "CRM Systemuser";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
    begin
        // [FEATURE] [CRM Account]
        // [SCENARIO] UpdateOwnerIfChanged() should update OwnerId and OwnerIdType if source's OwnerId is changed
        ResetDefaultCRMSetupConfiguration();
        // [GIVEN] Customer coupled to CRM Account.
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        // [GIVEN] Salesperson A coupled CRM SystemUser A
        // [GIVEN] Salesperson B coupled CRM SystemUser B
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaserA, CRMSystemuserA);
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaserB, CRMSystemuserB);

        // [GIVEN] CRM Account Record has OwnerID coupled SystemUser A
        // [GIVEN] CRM Account Record has OwnerIDType is "team"
        CRMAccount.OwnerId := CRMSystemuserA.SystemUserId;
        CRMAccount.OwnerIdType := CRMAccount.OwnerIdType::team;

        // [GIVEN] Customer has salesperson code matching coupled SalespersonB.
        Customer."Salesperson Code" := SalespersonPurchaserB.Code;

        // [WHEN] UpdateOwnerIfChanged() is called
        SourceRecordRef.GetTable(Customer);
        DestinationRecordRef.GetTable(CRMAccount);
        CRMSynchHelper.UpdateOwnerIfChanged(
          SourceRecordRef, DestinationRecordRef, Customer.FieldNo("Salesperson Code"), CRMAccount.FieldNo(OwnerId),
          CRMAccount.FieldNo(OwnerIdType), CRMAccount.OwnerIdType::systemuser);

        // [THEN] CRM Account will have OwnerID = SystemUser B, OwnerIDType = "systemuser"
        DestinationRecordRef.SetTable(CRMAccount);
        Assert.AreEqual(CRMSystemuserB.SystemUserId, CRMAccount.OwnerId, 'Expected the OwnerId to change');
        Assert.AreEqual(CRMAccount.OwnerIdType::systemuser, CRMAccount.OwnerIdType, 'Expected the OwnerIdType to change');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateCRMInvoiceWithCreateBillsPaymentMethod()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CRMInvoice: Record "CRM Invoice";
        PaymentMethod: Record "Payment Method";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"CRM Synch. Helper Test");

        // [SCENARIO 201236] Update the state and status on the CRM Invoice, when not paid and Payment Method has "Create Bills" flag in Spanish version
        InitializeCRMIntegration();

        // [GIVEN] Payment Method "PM" with "Create Bills" flag, activated in ES version
        // [GIVEN] A posted NAV sales invoice "SI", not paid
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        CreateSalesInvoiceWithPaymentMethod(PaymentMethod, SalesInvoiceHeader);

        // [WHEN] CRM invoice status is updated
        UpdateCRMInvoiceStatus(CRMInvoice, SalesInvoiceHeader);

        // [THEN] The CRM invoice state is active, status is billed
        CRMInvoice.TestField(StateCode, CRMInvoice.StateCode::Active);
        CRMInvoice.TestField(StatusCode, CRMInvoice.StatusCode::Billed);
    end;

    local procedure CreateCurrencyWithExchangeRate(ExchangeRate: Decimal): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), ExchangeRate, ExchangeRate);
        exit(Currency.Code);
    end;

    local procedure InitializeCRMIntegration()
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
    end;

    local procedure AssertProductAndPriceListItemAreConsistent(CRMProduct: Record "CRM Product"; CRMProductpricelevel: Record "CRM Productpricelevel")
    begin
        Assert.AreEqual(CRMProduct.PriceLevelId, CRMProductpricelevel.PriceLevelId, 'Incorrect price list id');
        Assert.AreEqual(CRMProduct.DefaultUoMId, CRMProductpricelevel.UoMId, 'Incorrect unit of measure id');
        Assert.AreEqual(CRMProduct.DefaultUoMScheduleId, CRMProductpricelevel.UoMScheduleId, 'Incorrect unit group id');
        Assert.AreEqual(CRMProduct.ProductId, CRMProductpricelevel.ProductId, 'Incorrect product id');
        Assert.AreEqual(CRMProduct.Price, CRMProductpricelevel.Amount, 'Incorrect price');
        Assert.AreEqual(CRMProduct.TransactionCurrencyId, CRMProductpricelevel.TransactionCurrencyId, 'Incorrect currency id');
        Assert.AreEqual(CRMProduct.ProductNumber, CRMProductpricelevel.ProductNumber, 'Incorrect product number');
    end;

    local procedure CreateAndPostSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
        SalesInvoiceHeader.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        SalesInvoiceHeader.FindLast();
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        SalesInvoiceHeader.CalcFields(Amount);
    end;

    local procedure CreatePaymentAndApplyToInvoice(CustomerNo: Code[20]; AppliesToDocNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibrarySales.CreatePaymentAndApplytoInvoice(GenJournalLine, CustomerNo, AppliesToDocNo, Amount);
    end;

    local procedure CreateSalesInvoiceWithPaymentMethod(var PaymentMethod: Record "Payment Method"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.Validate("Payment Method Code", PaymentMethod.Code);
        SalesHeader.Modify(true);
        SalesInvoiceHeader.Get(
          LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure UpdateCRMInvoiceStatus(var CRMInvoice: Record "CRM Invoice"; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        CRMInvoice.Init();
        CRMInvoice.Insert();
        CRMSynchHelper.UpdateCRMInvoiceStatus(CRMInvoice, SalesInvoiceHeader);
    end;

    local procedure ResetDefaultCRMSetupConfiguration()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        ClientSecret: Text;
    begin
        CRMConnectionSetup.Get();
        CDSConnectionSetup.LoadConnectionStringElementsFromCRMConnectionSetup();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Person;
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        ClientSecret := 'ClientSecret';
        CDSConnectionSetup.SetClientSecret(ClientSecret);
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
    end;

    local procedure VerifyCRMDefaultPriceList(CRMPricelevel: Record "CRM Pricelevel")
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CRMConnectionSetup.Get();
        Assert.AreEqual(
          CRMConnectionSetup."Default CRM Price List ID", CRMPricelevel.PriceLevelId,
          'Unexpected CRM Price List Id');
    end;
}

