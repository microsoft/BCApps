codeunit 135203 "CF Frcst. Azure AI"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Cash Flow] [Forecast] [Azure AI]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        CryptographyManagement: Codeunit "Cryptography Management";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryCashFlowHelper: Codeunit "Library - Cash Flow Helper";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        IsInitialized: Boolean;
        AzureAIMustBeEnabledErr: Label 'Azure AI Enabled in Cash Flow Setup must be set to true.', Comment = '%1 =Azure AI Enabled field, %2-Cash Flow Setup';
        AzureAIAPIURLEmptyErr: Label 'You must specify an %1 and an %2 for the %3.', Comment = '%1 =API URL field,%2 =API Key field, %3-Cash Flow Setup';
        MinimumHistoricalDataErr: Label 'There is not enough historical data for Azure AI to create a forecast.';
        SetupScheduledForecastingMsg: Label 'You can include Azure AI capabilities in the cash flow forecast.';
        XPAYABLESTxt: Label 'PAYABLES', Locked = true;
        XRECEIVABLESTxt: Label 'RECEIVABLES', Locked = true;
        XPAYABLESCORRECTIONTxt: Label 'Payables Correction';
        XRECEIVABLESCORRECTIONTxt: Label 'Receivables Correction';
        XSALESORDERSTxt: Label 'Sales Orders';
        XPURCHORDERSTxt: Label 'Purchase Orders';
        XTAXPAYABLESTxt: Label 'TAX TO RETURN', Locked = true;
        XTAXRECEIVABLESTxt: Label 'TAX TO PAY', Locked = true;
        XTAXPAYABLESCORRECTIONTxt: Label 'Tax from Purchase entries';
        XTAXRECEIVABLESCORRECTIONTxt: Label 'Tax from Sales entries';
        XTAXSALESORDERSTxt: Label 'Tax from Sales Orders';
        XTAXPURCHORDERSTxt: Label 'Tax from Purchase Orders';
        MockServiceURITxt: Label 'https://localhost:8080/services.azureml.net/workspaces/2eaccaaec84c47c7a1f8f01ec0a6eea7', Locked = true;
        MockServiceKeyTxt: Label 'TestKey';
        EnableEncryptionTxt: Label 'Enabling encryption will generate an encryption key on the server.';
        APIURLAPIKeyErr: Label 'You must specify an API URL and an API Key for the Cash Flow Setup.';

    [Test]
    [HandlerFunctions('SuggestWorksheetLinesReqPageHandler')]
    [Scope('OnPrem')]
    procedure AzureAINotEnabledError()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecast: Record "Cash Flow Forecast";
        ErrorMessage: Record "Error Message";
    begin
        // [SCENARIO] Azure AI Enabled is FALSE, error is reported
        // [GIVEN] Cash Flow Setup With Enabled set to FALSE
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        CashFlowSetup.Get();
        CashFlowSetup.Validate("Azure AI Enabled", false);
        CashFlowSetup.Modify(true);

        // [WHEN] Suggest Cash Flow Forecast Page is run
        CreateAndPostCashFlowForecast(CashFlowForecast);

        // [THEN] 1st error message: 'Azure AI Must Be Enabled'
        ErrorMessage.Find('-');
        Assert.AreEqual(AzureAIMustBeEnabledErr, ErrorMessage."Message", '1st error message');
        // [THEN] 2nd error message: 'You must specify API URL and API Key'
        Assert.IsTrue(ErrorMessage.Next() <> 0, '2nd error message not found');
        Assert.AreEqual(APIURLAPIKeyErr, ErrorMessage."Message", '2nd error message');
    end;

    [Test]
    [HandlerFunctions('SuggestWorksheetLinesReqPageHandler')]
    [Scope('OnPrem')]
    procedure APIKeyNotDefinedError()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecast: Record "Cash Flow Forecast";
        ErrorMessage: Record "Error Message";
        ApiKey: Text;
    begin
        // [SCENARIO] Azure AI ML API Key not defined, error is reported
        // [GIVEN] Cash Flow Setup With API Key set to empty string
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        CashFlowSetup.Get();
        ApiKey := '';
        CashFlowSetup.SaveUserDefinedAPIKey(ApiKey);
        CashFlowSetup.Modify(true);

        // [WHEN] Suggest Cash Flow Forecast Page is run
        CreateAndPostCashFlowForecast(CashFlowForecast);

        // [THEN] Error message is shown
        ErrorMessage.FindFirst();
        Assert.AreEqual(StrSubstNo(AzureAIAPIURLEmptyErr, CashFlowSetup.FieldCaption("API URL"),
            CashFlowSetup.FieldCaption("API Key"), CashFlowSetup.TableCaption()), ErrorMessage."Message", '');
    end;

    [Test]
    [HandlerFunctions('SuggestWorksheetLinesReqPageHandler')]
    [Scope('OnPrem')]
    procedure APIURLNotDefinedError()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecast: Record "Cash Flow Forecast";
        ErrorMessage: Record "Error Message";
    begin
        // [SCENARIO] Azure AI ML API URI not defined, error is reported
        // [GIVEN] Cash Flow Setup With not defined API URI
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        CashFlowSetup.Get();
        CashFlowSetup.Validate("API URL", '');
        CashFlowSetup.Modify(true);

        // [WHEN] Suggest Cash Flow Forecast Page is run
        CreateAndPostCashFlowForecast(CashFlowForecast);

        // [THEN] Error message is shown
        ErrorMessage.FindFirst();
        Assert.AreEqual(StrSubstNo(AzureAIAPIURLEmptyErr, CashFlowSetup.FieldCaption("API URL"),
            CashFlowSetup.FieldCaption("API Key"), CashFlowSetup.TableCaption()), ErrorMessage."Message", '');
    end;

    [Test]
    [HandlerFunctions('SuggestWorksheetLinesReqPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure NotEnoughHistoricalData()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecast: Record "Cash Flow Forecast";
        ErrorMessage: Record "Error Message";
    begin
        // [SCENARIO] Azure AI ML API URI not defined, error is reported if not enough historical data.
        // [GIVEN] Cash Flow Setup With not defined API URI
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        CashFlowSetup.Get();

        CashFlowSetup.Validate("API URL", MockServiceURITxt);
        CashFlowSetup.Validate("API Key", MockServiceKeyTxt);
        CashFlowSetup.Modify(true);

        // [WHEN] Suggest Cash Flow Forecast Page is run
        CreateAndPostCashFlowForecast(CashFlowForecast);

        // [THEN] Error message is shown
        ErrorMessage.FindFirst();
        Assert.AreEqual(MinimumHistoricalDataErr, ErrorMessage."Message", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAIDeltaBiggerThanVariancePercNotInserted()
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowAzureAIBuffer: Record "Cash Flow Azure AI Buffer";
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] When Azure AI result has Variance % bigger than defined in Cash Flow Setup, the result is not inserted
        // [GIVEN] Azure AI forecast with variance % bigger than Variance % in Cash Flow Setup
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        CashFlowSetup.Get();

        InsertTimeSeriesForecast(TempTimeSeriesForecast, XPAYABLESTxt, LibraryRandom.RandDec(100, 2));
        TempTimeSeriesForecast.Validate("Delta %", CashFlowSetup."Variance %" + 2);
        TempTimeSeriesForecast.Modify(true);

        // [WHEN] Forecast is called
        LibraryLowerPermissions.AddO365CashFlow();
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Record is not inserted
        Assert.IsFalse(CashFlowAzureAIBuffer.FindFirst(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAIPositivePayablesNotInserted()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] When Azure AI result for Payables is positive, result is not inserted
        // [GIVEN] Azure AI Payable forecast with positive amount
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        CashFlowSetup.Get();
        LibraryLowerPermissions.AddO365CashFlow();
        VerifyNotInserted(XPAYABLESTxt, 'Payables record with positive amount is inserted.', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAINegativeReceivablesNotInserted()
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] When Azure AI result for Receivables is positive, result is not inserted
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryLowerPermissions.AddO365CashFlow();
        // [GIVEN] Azure AI Receivables forecast with negative amount
        VerifyNotInserted(XRECEIVABLESTxt, 'Receivable Record with negative amount is inserted', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAIPositiveTaxReceivablesNotInserted()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        // [SCENARIO] When Azure AI result for Tax Receivable is positive, result is not inserted
        // [GIVEN] Azure AI Payable forecast with positive amount
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        CashFlowSetup.Get();
        LibraryLowerPermissions.AddO365CashFlow();
        VerifyNotInserted(XTAXRECEIVABLESTxt, 'Tax Receivables record with positive amount is inserted.', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAINegativeTaxPayablesNotInserted()
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] When Azure AI result for Tax Payable is negative, result is not inserted
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryLowerPermissions.AddO365CashFlow();
        // [GIVEN] Azure AI Tax Payable forecast with negative amount
        VerifyNotInserted(XTAXPAYABLESTxt, 'Tax Payables record with negative amount is inserted.', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAIPayablesRecord()
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] When Azure AI Payables result has negative amount, result is inserted
        // [GIVEN] Azure AI with variance % smaller than Variance % in Cash Flow Setup
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        Amount := -LibraryRandom.RandDec(100, 2);
        InsertTimeSeriesForecast(TempTimeSeriesForecast, XPAYABLESTxt, Amount);

        // [WHEN] Forecast is called
        LibraryLowerPermissions.AddO365CashFlow();
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Record is inserted
        VerifyAzureAIRecord(XPAYABLESTxt, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAIReceivablesRecord()
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        Amount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] When Azure AI Receivables result has positive amount Forecast record is inserted
        // [GIVEN] Azure AI with variance % smaller than Variance % in Cash Flow Setup
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        Amount := LibraryRandom.RandDec(100, 2);
        InsertTimeSeriesForecast(TempTimeSeriesForecast, XRECEIVABLESTxt, Amount);

        // [WHEN] Forecast is called
        LibraryLowerPermissions.AddO365CashFlow();
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Record is inserted
        VerifyAzureAIRecord(XRECEIVABLESTxt, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAITaxPayablesRecord()
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] When Azure AI Tax Payables result has positive amount, result is inserted
        // [GIVEN] Azure AI with variance % smaller than Variance % in Cash Flow Setup
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryLowerPermissions.AddO365CashFlow();
        VerifyInserted(XTAXPAYABLESTxt, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAITaxReceivablesRecord()
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] When Azure AI Tax Receivables result has negative amount Forecast record is inserted
        // [GIVEN] Azure AI with variance % smaller than Variance % in Cash Flow Setup
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryLowerPermissions.AddO365CashFlow();
        VerifyInserted(XTAXRECEIVABLESTxt, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAIPayablesCorrectionRecord()
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        Amount: Decimal;
        VendorLedgerAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] When Azure AI result is in the period which contains Vendor Ledger Entries,
        // [SCENARIO] Payables Forecast record is inserted, Payables Correction record is inserted
        // [GIVEN] Azure AI Payables forecast and Vendor Ledger Entry
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        Amount := -LibraryRandom.RandDec(100, 2);
        InsertTimeSeriesForecast(TempTimeSeriesForecast, XPAYABLESTxt, Amount);

        VendorLedgerAmount := Amount + 1;
        InsertVendorLedgerEntry(TempTimeSeriesForecast."Period Start Date", VendorLedgerAmount);

        // [WHEN] Forecast is called
        LibraryLowerPermissions.AddO365CashFlow();
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Azure AI Payables Record is  inserted
        VerifyAzureAIRecord(XPAYABLESTxt, Amount);

        // [THEN] Azure AI Payables Correction Record is  inserted
        VerifyAzureAIRecord(XPAYABLESCORRECTIONTxt, -VendorLedgerAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAIReceivablesCorrectionRecord()
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        Amount: Decimal;
        CustLedgerAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] When Azure AI result is in the period with existing Cust Ledger Entries,
        // [SCENARIO] Receivables Forecast record is inserted, Receivables Correction record is inserted
        // [GIVEN] Azure AI Receivables forecast and Customer Ledger Entry
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        Amount := LibraryRandom.RandDec(100, 2);
        InsertTimeSeriesForecast(TempTimeSeriesForecast, XRECEIVABLESTxt, Amount);
        CustLedgerAmount := Amount - 1;
        InsertCustLedgerEntry(TempTimeSeriesForecast."Period Start Date", CustLedgerAmount);

        // [WHEN] Forecast is called
        LibraryLowerPermissions.AddO365CashFlow();
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Azure AI Receivables Record is  inserted
        VerifyAzureAIRecord(XRECEIVABLESTxt, Amount);

        // [THEN] Azure AI Receivables Correction Record is  inserted
        VerifyAzureAIRecord(XRECEIVABLESCORRECTIONTxt, -CustLedgerAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAITaxPayablesCorrectionRecord()
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] When Azure AI result is in the period which contains VAT Ledger Entries,
        // [SCENARIO] Tax Payables Forecast record is inserted, Tax Payables Correction record is inserted
        // [GIVEN] Azure AI Payables tax forecast and VAT Ledger Entries Aggregated
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryLowerPermissions.AddO365CashFlow();
        VerifyCorrectionInserted(XTAXPAYABLESTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAITaxPayablesCorrectionRecords()
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        Amount: Decimal;
        VATLedgerAmount: Decimal;
        DocumentDate: Date;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] When Azure AI result is in the period which contains VAT Ledger Entries,
        // [SCENARIO] Tax Payables Forecast record is inserted, Tax Payables Correction record is inserted
        // [GIVEN] Azure AI Payables tax forecast and VAT Ledger Entry
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        Amount := LibraryRandom.RandDec(100, 2) + 20;

        InsertTimeSeriesForecast(TempTimeSeriesForecast, XTAXPAYABLESTxt, Amount);

        VATLedgerAmount := Amount - 10;
        ClearTax();
        InsertVATLedgerEntry(CalcDate('<CM>', TempTimeSeriesForecast."Period Start Date"), VATLedgerAmount, false);
        DocumentDate := CalcDate('<CM>', TempTimeSeriesForecast."Period Start Date");

        VATLedgerAmount := 5;

        InsertVATLedgerEntry(CalcDate('<CM-1D>', TempTimeSeriesForecast."Period Start Date"), VATLedgerAmount, false);

        VATLedgerAmount := 3;

        InsertVATLedgerEntry(CalcDate('<CM-2D>', TempTimeSeriesForecast."Period Start Date"), VATLedgerAmount, false);

        // [WHEN] Forecast is called
        LibraryLowerPermissions.AddO365CashFlow();
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Azure AI Payables Record is  inserted
        VerifyAzureAITaxRecord(XTAXPAYABLESTxt, Amount, CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));

        // [THEN] Azure AI Payables Correction Record is  inserted
        VerifyAzureAITaxRecord(
          XTAXPAYABLESCORRECTIONTxt, -(Amount - 10 + 5 + 3), CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAITaxReceivablesCorrectionRecord()
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] When Azure AI result is in the period with existing VAT Ledger Entries,
        // [SCENARIO] Receivables Tax Forecast record is inserted, Receivables Tax Correction record is inserted
        // [GIVEN] Azure AI Receivables forecast and VAT Ledger Entry
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        LibraryLowerPermissions.AddO365CashFlow();
        VerifyCorrectionInserted(XTAXRECEIVABLESTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAITaxReceivablesCorrectionRecords()
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        Amount: Decimal;
        VATLedgerAmount: Decimal;
        DocumentDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] When Azure AI result is in the period with existing Cust Ledger Entries,
        // [SCENARIO] Receivables Forecast record is inserted, Receivables Correction record is inserted
        // [GIVEN] Azure AI Receivables forecast and VAT Ledger Entry
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        Amount := LibraryRandom.RandDec(100, 2) + 20;
        InsertTimeSeriesForecast(TempTimeSeriesForecast, XTAXRECEIVABLESTxt, -Amount);

        ClearTax();
        VATLedgerAmount := Amount - 10;
        InsertVATLedgerEntry(CalcDate('<CM>', TempTimeSeriesForecast."Period Start Date"), -VATLedgerAmount, true);
        DocumentDate := CalcDate('<CM>', TempTimeSeriesForecast."Period Start Date");

        VATLedgerAmount := 5;

        InsertVATLedgerEntry(CalcDate('<CM-1D>', TempTimeSeriesForecast."Period Start Date"), -VATLedgerAmount, true);

        VATLedgerAmount := 3;

        InsertVATLedgerEntry(CalcDate('<CM-2D>', TempTimeSeriesForecast."Period Start Date"), -VATLedgerAmount, true);

        // [WHEN] Forecast is called
        LibraryLowerPermissions.AddO365CashFlow();
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Azure AI Tax Payables Record is  inserted
        VerifyAzureAITaxRecord(XTAXRECEIVABLESTxt, -Amount, CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));

        // [THEN] Azure AI Tax Payables Correction Record is  inserted
        VerifyAzureAITaxRecord(
          XTAXRECEIVABLESCORRECTIONTxt, Amount - 10 + 5 + 3, CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAITaxPayablesCorrectionMultiplePeriodsRecords()
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        Amount: Decimal;
        AmountNextPeriod: Decimal;
        VATLedgerAmount: Decimal;
        DocumentDate: Date;
        DocumentDateNext: Date;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] When Azure AI result is in the period which contains VAT Ledger Entries,
        // [SCENARIO] Tax Payables Forecast record is inserted, Tax Payables Correction record is inserted
        // [GIVEN] Azure AI Payables tax forecast and VAT Ledger Entries
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        CashFlowForecastHandler.Initialize();

        Amount := LibraryRandom.RandDec(100, 2) + 20;
        ClearTax();
        InsertTimeSeriesForecast(TempTimeSeriesForecast, XTAXPAYABLESTxt, Amount);
        DocumentDate := TempTimeSeriesForecast."Period Start Date";

        VATLedgerAmount := Amount - 10;
        InsertVATLedgerEntry(CalcDate('<CM-1D>', TempTimeSeriesForecast."Period Start Date"), VATLedgerAmount, false);
        VATLedgerAmount := 5;

        InsertVATLedgerEntry(CalcDate('<CM-2D>', TempTimeSeriesForecast."Period Start Date"), VATLedgerAmount, false);

        VATLedgerAmount := 3;

        InsertVATLedgerEntry(CalcDate('<CM-3D>', TempTimeSeriesForecast."Period Start Date"), VATLedgerAmount, false);

        AmountNextPeriod := LibraryRandom.RandDec(200, 2) + 20;

        InsertTimeSeriesForecast(TempTimeSeriesForecast, XTAXPAYABLESTxt, AmountNextPeriod);
        TempTimeSeriesForecast."Period Start Date" := CalcDate('<CM+1M-1D>', TempTimeSeriesForecast."Period Start Date");
        TempTimeSeriesForecast.Modify();
        DocumentDateNext := TempTimeSeriesForecast."Period Start Date";

        VATLedgerAmount := AmountNextPeriod - 10;
        InsertVATLedgerEntry(CalcDate('<CM-1D>', TempTimeSeriesForecast."Period Start Date"), VATLedgerAmount, false);
        VATLedgerAmount := 5;

        InsertVATLedgerEntry(CalcDate('<CM-2D>', TempTimeSeriesForecast."Period Start Date"), VATLedgerAmount, false);

        VATLedgerAmount := 3;

        InsertVATLedgerEntry(CalcDate('<CM-3D>', TempTimeSeriesForecast."Period Start Date"), VATLedgerAmount, false);

        // [WHEN] Forecast is called
        LibraryLowerPermissions.AddO365CashFlow();
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Azure AI Tax Payables Records are  inserted
        VerifyAzureAITaxRecord(XTAXPAYABLESTxt, Amount, CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));
        VerifyAzureAITaxRecord(XTAXPAYABLESTxt, AmountNextPeriod, CashFlowSetup.GetTaxPaymentDueDate(DocumentDateNext));

        // [THEN] Azure AI Tax Payables Correction Records are inserted
        VerifyAzureAITaxRecord(
          XTAXPAYABLESCORRECTIONTxt, -(Amount - 10 + 5 + 3), CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));
        VerifyAzureAITaxRecord(
          XTAXPAYABLESCORRECTIONTxt, -(AmountNextPeriod - 10 + 5 + 3), CashFlowSetup.GetTaxPaymentDueDate(DocumentDateNext));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAITaxReceivablesCorrectionMultiplePeriodsRecords()
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        Amount: Decimal;
        AmountNextPeriod: Decimal;
        VATLedgerAmount: Decimal;
        DocumentDate: Date;
        DocumentDateNextPeriod: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] When Azure AI result is in the period with existing VAT Ledger Entries,
        // [SCENARIO] Receivables Forecast record is inserted, TAX Receivables Correction record is inserted
        // [GIVEN] Azure AI Receivables forecast and VAT Ledger Entries
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        CashFlowForecastHandler.Initialize();

        Amount := LibraryRandom.RandDec(100, 2) + 20;
        ClearTax();
        InsertTimeSeriesForecast(TempTimeSeriesForecast, XTAXRECEIVABLESTxt, -Amount);

        VATLedgerAmount := Amount - 10;
        InsertVATLedgerEntry(CalcDate('<CM>', TempTimeSeriesForecast."Period Start Date"), -VATLedgerAmount, true);
        DocumentDate := CalcDate('<CM>', TempTimeSeriesForecast."Period Start Date");
        VATLedgerAmount := 5;

        InsertVATLedgerEntry(CalcDate('<CM-1D>', TempTimeSeriesForecast."Period Start Date"), -VATLedgerAmount, true);

        VATLedgerAmount := 3;

        InsertVATLedgerEntry(CalcDate('<CM-2D>', TempTimeSeriesForecast."Period Start Date"), -VATLedgerAmount, true);

        AmountNextPeriod := LibraryRandom.RandDec(200, 2) + 20;

        InsertTimeSeriesForecast(TempTimeSeriesForecast, XTAXRECEIVABLESTxt, -AmountNextPeriod);
        TempTimeSeriesForecast."Period Start Date" := CalcDate('<CM+1M-1D>', TempTimeSeriesForecast."Period Start Date");
        TempTimeSeriesForecast.Modify();
        DocumentDateNextPeriod := TempTimeSeriesForecast."Period Start Date";

        VATLedgerAmount := AmountNextPeriod - 10;
        InsertVATLedgerEntry(CalcDate('<CM-1D>', TempTimeSeriesForecast."Period Start Date"), -VATLedgerAmount, true);
        VATLedgerAmount := 5;

        InsertVATLedgerEntry(CalcDate('<CM-2D>', TempTimeSeriesForecast."Period Start Date"), -VATLedgerAmount, true);

        VATLedgerAmount := 3;

        InsertVATLedgerEntry(CalcDate('<CM-3D>', TempTimeSeriesForecast."Period Start Date"), -VATLedgerAmount, true);

        // [WHEN] Forecast is called
        LibraryLowerPermissions.AddO365CashFlow();
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Azure AI Payables Record is  inserted
        VerifyAzureAITaxRecord(XTAXRECEIVABLESTxt, -Amount, CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));
        VerifyAzureAITaxRecord(
          XTAXRECEIVABLESTxt, -AmountNextPeriod, CashFlowSetup.GetTaxPaymentDueDate(DocumentDateNextPeriod));

        // [THEN] Azure AI Payables Correction Record is  inserted
        VerifyAzureAITaxRecord(
          XTAXRECEIVABLESCORRECTIONTxt, Amount - 10 + 5 + 3, CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));
        VerifyAzureAITaxRecord(
          XTAXRECEIVABLESCORRECTIONTxt, AmountNextPeriod - 10 + 5 + 3, CashFlowSetup.GetTaxPaymentDueDate(DocumentDateNextPeriod));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAIPayablesCorrectionAmountOverForecasted()
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        Amount: Decimal;
        VendorLedgerAmount: Decimal;
        DocumentDate: Date;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] When Azure AI result is in the period with existing Vendor Ledger Entries,
        // [SCENARIO] And sum of Vendor Ledger Entries is bigger than Payables Azure AI forecast
        // [SCENARIO] Then Payables Forecast record is inserted, Correction record is inserted with amount of forecast
        // [GIVEN] Azure AI Receivables forecast, VAT Ledger Entry and Vendor Ledger Entry
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        Amount := -LibraryRandom.RandDec(100, 2);
        InsertTimeSeriesForecast(TempTimeSeriesForecast, XPAYABLESTxt, Amount);
        InsertTimeSeriesForecast(TempTimeSeriesForecast, XTAXPAYABLESTxt, -Amount);

        VendorLedgerAmount := Amount - 1;
        ClearTax();
        InsertVendorLedgerEntry(TempTimeSeriesForecast."Period Start Date", VendorLedgerAmount);
        InsertVATLedgerEntry(TempTimeSeriesForecast."Period Start Date", VendorLedgerAmount, false);
        DocumentDate := TempTimeSeriesForecast."Period Start Date";

        // [WHEN] Forecast is called
        LibraryLowerPermissions.AddO365CashFlow();
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Payables Forecast Record is  inserted
        VerifyAzureAIRecord(XPAYABLESTxt, Amount);

        // [THEN] Azure AI Payables Correction Record is  inserted with amount of Payables forecast
        VerifyAzureAIRecord(XPAYABLESCORRECTIONTxt, -Amount);
        VerifyAzureAITaxRecord(XTAXPAYABLESCORRECTIONTxt, -Abs(Amount), CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAIReceivablesCorrectionAmountOverForecasted()
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        Amount: Decimal;
        CustLedgerAmount: Decimal;
        DocumentDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] When Azure AI result is in the period with existing Cust Ledger Entries and VAT Ledger Entries,
        // [SCENARIO] And sum of Customer Ledger Entries is bigger than Payables Azure AI forecast
        // [SCENARIO] Then Receivables Forecast record is inserted, Correction record is inserted with amount of forecast
        // [GIVEN] Azure AI Receivables forecast, VAT Entry and Customer Ledger Entry
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        Amount := LibraryRandom.RandDec(100, 2);
        InsertTimeSeriesForecast(TempTimeSeriesForecast, XRECEIVABLESTxt, Amount);
        InsertTimeSeriesForecast(TempTimeSeriesForecast, XTAXRECEIVABLESTxt, -Amount);

        CustLedgerAmount := Amount + 1;
        ClearTax();
        InsertCustLedgerEntry(TempTimeSeriesForecast."Period Start Date", CustLedgerAmount);
        InsertVATLedgerEntry(TempTimeSeriesForecast."Period Start Date", CustLedgerAmount, true);
        DocumentDate := TempTimeSeriesForecast."Period Start Date";
        // [WHEN] Forecast is called
        LibraryLowerPermissions.AddO365CashFlow();
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Receivables Forecast Record is not inserted
        VerifyAzureAIRecord(XRECEIVABLESTxt, Amount);

        // [THEN] Azure AI Receivables Correction Record is  inserted with amount of Receivables forecast
        VerifyAzureAIRecord(XRECEIVABLESCORRECTIONTxt, -Amount);
        VerifyAzureAITaxRecord(XTAXRECEIVABLESCORRECTIONTxt, Abs(Amount), CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAIPayablesCorrectionRecordPurchOrders()
    var
        PurchaseHeader: Record "Purchase Header";
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowManagement: Codeunit "Cash Flow Management";
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        Amount: Decimal;
        VendorLedgerAmount: Decimal;
        DocumentDate: Date;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] When Azure AI result is in the period which contains Vendor Ledger Entries
        // [SCENARIO] and Purchase Orders then Payables Forecast record is inserted, Payables Correction record is inserted
        // [SCENARIO] Purchase Orders record is created
        // [GIVEN] Azure AI Payables forecast, Vendor Ledger Entry, Purchase Orders
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        Amount := LibraryRandom.RandDec(100, 2);
        InsertTimeSeriesForecast(TempTimeSeriesForecast, XPAYABLESTxt, -Amount);
        InsertTimeSeriesForecast(TempTimeSeriesForecast, XTAXPAYABLESTxt, Abs(2 * Amount));

        VendorLedgerAmount := Round(Amount / 3, 0.01);
        ClearTax();
        InsertVendorLedgerEntry(TempTimeSeriesForecast."Period Start Date", -VendorLedgerAmount);
        CreatePurchOrder(PurchaseHeader, TempTimeSeriesForecast."Period Start Date", VendorLedgerAmount, 10);
        DocumentDate := TempTimeSeriesForecast."Period Start Date";
        // [WHEN] Forecast is called
        LibraryLowerPermissions.AddO365CashFlow();
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Azure AI Payables Record is  inserted
        VerifyAzureAIRecord(XPAYABLESTxt, -Amount);

        VerifyAzureAITaxRecord(
          XTAXPAYABLESTxt, 2 * Amount, CashFlowSetup.GetTaxPaymentDueDate(PurchaseHeader."Posting Date"));

        // [THEN] Azure AI Payables Correction Record is  inserted
        VerifyAzureAIRecord(XPAYABLESCORRECTIONTxt, VendorLedgerAmount);

        // [THEN] Purchase Orders Correction Record is  inserted
        VerifyAzureAIRecord(XPURCHORDERSTxt, Abs(CashFlowManagement.GetTotalAmountFromPurchaseOrder(PurchaseHeader)));
        VerifyAzureAITaxRecord(
          XTAXPURCHORDERSTxt, -Abs(CashFlowManagement.GetTaxAmountFromPurchaseOrder(PurchaseHeader)),
          CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAIReceivablesCorrectionRecordSalesOrders()
    var
        SalesHeader: Record "Sales Header";
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowManagement: Codeunit "Cash Flow Management";
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        Amount: Decimal;
        CustomerLedgerAmount: Decimal;
        DocumentDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] When Azure AI result is in the period which contains Customer Ledger Entries
        // [SCENARIO] and Purchase Orders then Payables Forecast record is inserted, Receivables Correction record is inserted
        // [SCENARIO] Sales Orders record is created
        // [GIVEN] Azure AI Receivables forecast, Customer Ledger Entry, Sales Orders
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        Amount := LibraryRandom.RandDec(100, 2);
        InsertTimeSeriesForecast(TempTimeSeriesForecast, XRECEIVABLESTxt, Amount);
        InsertTimeSeriesForecast(TempTimeSeriesForecast, XTAXRECEIVABLESTxt, -Amount);

        CustomerLedgerAmount := Round(Amount / 3, 0.01);
        ClearTax();
        InsertCustLedgerEntry(TempTimeSeriesForecast."Period Start Date", CustomerLedgerAmount);

        CreateSalesOrder(SalesHeader, TempTimeSeriesForecast."Period Start Date", CustomerLedgerAmount, 10);
        DocumentDate := TempTimeSeriesForecast."Period Start Date";
        // [WHEN] Forecast is called
        LibraryLowerPermissions.AddO365CashFlow();
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Azure AI Receivables Record is  inserted
        VerifyAzureAIRecord(XRECEIVABLESTxt, Amount);

        // [THEN] Azure AI Receivables Correction Record is  inserted
        VerifyAzureAIRecord(XRECEIVABLESCORRECTIONTxt, -CustomerLedgerAmount);

        // [THEN] Sales Orders Correction Record is  inserted
        VerifyAzureAIRecord(XSALESORDERSTxt, -Abs(CashFlowManagement.GetTotalAmountFromSalesOrder(SalesHeader)));
        VerifyAzureAITaxRecord(
          XTAXSALESORDERSTxt, Abs(CashFlowManagement.GetTaxAmountFromSalesOrder(SalesHeader)),
          CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAIPurchOrdersAmountOverForecasted()
    var
        PurchaseHeader: Record "Purchase Header";
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        CashFlowManagement: Codeunit "Cash Flow Management";
        Amount: Decimal;
        VendorLedgerAmount: Decimal;
        DocumentDate: Date;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] When Azure AI result is in the period which contains Vendor Ledger Entries
        // [SCENARIO] and Purchase Orders with total amount over forecasted, then Payables Forecast record is inserted,
        // [SCENARIO] Payables Correction record is inserted, Purchase Orders record is created with remaining forecasted amount
        // [GIVEN] Azure AI Payables forecast, Vendor Ledger Entry, Purchase Orders
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        Amount := -LibraryRandom.RandDec(100, 2);
        VendorLedgerAmount := Round(Amount / 3, 0.01);
        InsertTimeSeriesForecast(TempTimeSeriesForecast, XPAYABLESTxt, Amount);
        InsertTimeSeriesForecast(
          TempTimeSeriesForecast, XTAXPAYABLESTxt, Abs(Amount));

        ClearTax();
        InsertVendorLedgerEntry(TempTimeSeriesForecast."Period Start Date", VendorLedgerAmount);
        CreatePurchOrder(PurchaseHeader, TempTimeSeriesForecast."Period Start Date", -Amount, 100);
        TempTimeSeriesForecast.Value := Abs(CashFlowManagement.GetTaxAmountFromPurchaseOrder(PurchaseHeader));
        TempTimeSeriesForecast.Modify();

        DocumentDate := TempTimeSeriesForecast."Period Start Date";

        // [WHEN] Forecast is called
        LibraryLowerPermissions.AddO365CashFlow();
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Azure AI Payables Record is  inserted
        VerifyAzureAIRecord(XPAYABLESTxt, Amount);

        // [THEN] Azure AI Payables Correction Record is  inserted
        VerifyAzureAIRecord(XPAYABLESCORRECTIONTxt, -VendorLedgerAmount);

        // [THEN] Purchase Orders Correction Record is inserted with remaining amount of the forecast
        VerifyAzureAIRecord(XPURCHORDERSTxt, Abs(Amount - VendorLedgerAmount));
        VerifyAzureAITaxRecord(
          XTAXPURCHORDERSTxt, -Abs(CashFlowManagement.GetTaxAmountFromPurchaseOrder(PurchaseHeader)),
          CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillAzureAISalesOrdersAmountOverForecasted()
    var
        SalesHeader: Record "Sales Header";
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        CashFlowManagement: Codeunit "Cash Flow Management";
        Amount: Decimal;
        CustomerLedgerAmount: Decimal;
        DocumentDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] When Azure AI result is in the period which contains Customer Ledger Entries
        // [SCENARIO] and Purchase Orders  with total amount over forecasted, then Payables Forecast record is inserted,
        // [SCENARIO] Receivables Correction record is inserted, Sales Orders record is created with remaining forecasted amount
        // [GIVEN] Azure AI Receivables forecast, Customer Ledger Entry, Sales Orders
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        Amount := LibraryRandom.RandDec(100, 2);
        CustomerLedgerAmount := Round(Amount / 3, 0.01);
        ClearTax();

        InsertTimeSeriesForecast(TempTimeSeriesForecast, XRECEIVABLESTxt, Amount);
        InsertTimeSeriesForecast(
          TempTimeSeriesForecast, XTAXRECEIVABLESTxt, -Abs(Amount));

        CreateSalesOrder(SalesHeader, TempTimeSeriesForecast."Period Start Date", Amount, 100);
        InsertCustLedgerEntry(TempTimeSeriesForecast."Period Start Date", CustomerLedgerAmount);
        TempTimeSeriesForecast.Value := -Abs(CashFlowManagement.GetTaxAmountFromSalesOrder(SalesHeader));
        TempTimeSeriesForecast.Modify();

        DocumentDate := TempTimeSeriesForecast."Period Start Date";
        // [WHEN] Forecast is called
        LibraryLowerPermissions.AddO365CashFlow();
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Azure AI Receivables Record is  inserted
        VerifyAzureAIRecord(XRECEIVABLESTxt, Amount);

        // [THEN] Azure AI Receivables Correction Record is  inserted
        VerifyAzureAIRecord(XRECEIVABLESCORRECTIONTxt, -CustomerLedgerAmount);

        // [THEN] Purchase Orders Correction Record is inserted with remaining amount of the forecast
        VerifyAzureAIRecord(XSALESORDERSTxt, -Abs(Amount - CustomerLedgerAmount));
        VerifyAzureAITaxRecord(
          XTAXSALESORDERSTxt, Abs(CashFlowManagement.GetTaxAmountFromSalesOrder(SalesHeader)),
          CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepareDataNotEnoughHistoricalData()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        ErrorMessage: Record "Error Message";
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        // [SCENARIO] Azure AI ML API URI not defined, error is reported in preparation phase if not enough historical data
        // [GIVEN] Cash Flow Setup With not defined API URI
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        if not EnvironmentInformation.IsSaaS() then
            exit;

        CashFlowSetup.Get();

        // [WHEN] Suggest Cash Flow Forecast Page is run
        CashFlowForecastHandler.Initialize();
        Initialize();
        CashFlowForecastHandler.CalculateForecast();

        // [THEN] Error message is shown
        ErrorMessage.FindFirst();
        Assert.AreEqual(MinimumHistoricalDataErr, ErrorMessage."Message", '');
    end;

    [Test]
    [HandlerFunctions('CashFlowForecastPageHandler,NotificationEnableAzureAIHandler')]
    [Scope('OnPrem')]
    procedure EnableAzureAINotificationOnOpenCashFlowChartPage()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        // [FEATURE] [Chart]
        // [SCENARIO] User opens page with Cash Flow Forecast for the first time, if a Cash flow chart is configured but Azure AI is Disabled
        // [SCENARIO] Then Notification is shown
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        // [GIVEN] Azure AI is disabled
        CashFlowSetup.Get();
        CashFlowSetup.Validate("Azure AI Enabled", false);
        CashFlowSetup.Validate("CF No. on Chart in Role Center", '1');
        CashFlowSetup.Modify(true);

        // [WHEN] When user opens Cash Flow Forecast Chart page
        PAGE.Run(PAGE::"Cash Flow Forecast Chart");

        // [THEN] The notification is sent and captured by the handler function.
    end;

    [Test]
    [HandlerFunctions('CashFlowForecastPageHandler')]
    [Scope('OnPrem')]
    procedure EnableAzureAINotificationOnOpenCashFlowChartPageNotShown()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        // [FEATURE] [Chart]
        // [SCENARIO] User opens page with Cash Flow Forecast, Azure AI is Enabled
        // [SCENARIO] Then Notification is not shown
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        // [GIVEN] Azure AI is disabled
        CashFlowSetup.Get();

        // [WHEN] When user opens Cash Flow Forecast Chart page
        PAGE.Run(PAGE::"Cash Flow Forecast Chart");

        // [THEN] The notification is not sent (handler function)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesAndPurchaseOrdersAmounts()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        CashFlowManagement: Codeunit "Cash Flow Management";
        Amount: Decimal;
        VAT: Integer;
    begin
        // [FEATURE] [VAT]
        // [SCENARIO] Calculated amounts for AzureAI correction include VAT
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        VAT := LibraryRandom.RandInt(20);

        CreateSalesOrder(SalesHeader, WorkDate(), Amount, VAT);
        Assert.AreNearlyEqual(CashFlowManagement.GetTotalAmountFromSalesOrder(SalesHeader),
          (1 + (VAT / 100)) * Amount, 0.1, 'Amount was different than expected');

        CreatePurchOrder(PurchaseHeader, WorkDate(), Amount, VAT);
        Assert.AreNearlyEqual(CashFlowManagement.GetTotalAmountFromPurchaseOrder(PurchaseHeader),
          (1 + (VAT / 100)) * Amount, 0.1, 'Amount was different than expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitializeSaaSUserDefinedAPI()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        ErrorMessage: Record "Error Message";
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        ApiKey: Text;
    begin
        // [SCENARIO] When Azure AI ML API URI user defined in SaaS, Limit Exceeds error is not thrown
        // [GIVEN] Cash Flow Setup With user defined API URI
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        CashFlowSetup.Get();
        ApiKey := MockServiceKeyTxt;
        CashFlowSetup.Validate("API URL", MockServiceURITxt);
        CashFlowSetup.SaveUserDefinedAPIKey(ApiKey);
        CashFlowSetup.Modify(true);

        // [WHEN] Initialize of Cash Flow Forecast Handler is invoked
        CashFlowForecastHandler.Initialize();
        Initialize();

        // [THEN] There is no Error message
        Assert.IsFalse(ErrorMessage.FindFirst(), 'Cannot initialize Cash Flow Handler in SaaS when API is user defined ');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure Initialize()
    var
        ErrorMessage: Record "Error Message";
        CashFlowAzureAIBuffer: Record "Cash Flow Azure AI Buffer";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"CF Frcst. Azure AI");

        CreateCashFlowSetup();
        ErrorMessage.DeleteAll();
        CashFlowAzureAIBuffer.DeleteAll();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"CF Frcst. Azure AI");
        if CryptographyManagement.IsEncryptionEnabled() then
            CryptographyManagement.DisableEncryption(true);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"CF Frcst. Azure AI");
    end;

    local procedure CreateAndPostCashFlowForecast(var CashFlowForecast: Record "Cash Flow Forecast")
    begin
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);

        Commit();
        LibraryVariableStorage.Enqueue(CashFlowForecast."No.");  // Enqueue SuggestWorksheetLinesReqPageHandler.
        REPORT.Run(REPORT::"Suggest Worksheet Lines");
    end;

    local procedure CreateCashFlowSetup()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        DateFormula: DateFormula;
        ApiKey: Text;
    begin
        CashFlowSetup.DeleteAll();
        CashFlowSetup.Init();
        CashFlowSetup.Insert(true);
        CashFlowSetup.Validate("Azure AI Enabled", true);
        CashFlowSetup.Validate("API URL", '');
        ApiKey := '';
        CashFlowSetup.SaveUserDefinedAPIKey(ApiKey);
        CashFlowSetup.Validate("Period Type", CashFlowSetup."Period Type"::Month);
        CashFlowSetup.Validate("Taxable Period", CashFlowSetup."Taxable Period"::Monthly);
        Evaluate(DateFormula, '<10D>');
        CashFlowSetup.Validate("Tax Payment Window", DateFormula);
        CashFlowSetup.Validate("Variance %", LibraryRandom.RandInt(99));
        CashFlowSetup.Validate(Horizon, LibraryRandom.RandInt(10));
        CashFlowSetup.Validate("Historical Periods", LibraryRandom.RandInt(10));
        CashFlowSetup.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; DueDate: Date; AmountValue: Decimal; VAT: Integer)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        TaxGroup: Record "Tax Group";
        TaxAreaLine: Record "Tax Area Line";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Posting Date", DueDate);
        SalesHeader.Validate("Document Date", DueDate);
        SalesHeader.Validate("Due Date", DueDate);
        LibraryERM.CreateTaxGroup(TaxGroup);
        CreateTaxAreaLine(TaxAreaLine);
        CreateTaxDetail(TaxAreaLine."Tax Jurisdiction Code", TaxGroup.Code);
        SalesHeader.Validate("Tax Area Code", TaxAreaLine."Tax Area");
        SalesHeader.Validate("Tax Liable", true);
        SalesHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", AmountValue);
        SalesLine.Validate("VAT %", VAT);
        SalesLine.Validate("Amount Including VAT", AmountValue);
        SalesLine.Validate("Line Amount", AmountValue);
        SalesLine.Validate("Tax Group Code", TaxGroup.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchOrder(var PurchaseHeader: Record "Purchase Header"; DueDate: Date; AmountValue: Decimal; VAT: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Posting Date", DueDate);
        PurchaseHeader.Validate("Document Date", DueDate);
        PurchaseHeader.Validate("Due Date", DueDate);
        PurchaseHeader.Validate("Tax Liable", true);
        PurchaseHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("VAT %", VAT);
        PurchaseLine.Validate("Amount Including VAT", AmountValue);
        PurchaseLine.Validate("Direct Unit Cost", AmountValue);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateTaxDetail(TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
    begin
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, 0, WorkDate());
        TaxDetail.Validate("Tax Below Maximum", LibraryRandom.RandDec(10, 2));
        TaxDetail.Modify(true);
    end;

    local procedure CreateTaxAreaLine(var TaxAreaLine: Record "Tax Area Line")
    var
        TaxArea: Record "Tax Area";
        TaxJurisdiction: Record "Tax Jurisdiction";
        GLAccount: Record "G/L Account";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateGLAccount(GLAccount);
        TaxJurisdiction."Tax Account (Purchases)" := GLAccount."No.";
        TaxJurisdiction.Modify(true);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxJurisdiction.Code);
    end;

    local procedure InsertTimeSeriesForecast(var TempTimeSeriesForecast: Record "Time Series Forecast" temporary; GroupID: Code[50]; Amount: Decimal)
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        CashFlowSetup.Get();
        TempTimeSeriesForecast.Init();
        TempTimeSeriesForecast."Group ID" := GroupID;
        TempTimeSeriesForecast."Period No." := TempTimeSeriesForecast."Period No." + 1;
        TempTimeSeriesForecast."Period Start Date" := GetDateWithoutLedgerEntries();
        TempTimeSeriesForecast.Value := Amount;
        TempTimeSeriesForecast.Delta := LibraryRandom.RandDec(100, 2);
        TempTimeSeriesForecast."Delta %" := CashFlowSetup."Variance %" - 1;// by default Delta % is smaller
        TempTimeSeriesForecast.Insert();
    end;

    local procedure InsertVendorLedgerEntry(DueDate: Date; AmountValue: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        LastEntryNo: Integer;
    begin
        if VendorLedgerEntry.FindLast() then;
        LastEntryNo := VendorLedgerEntry."Entry No.";
        InsertDetailedVendorLedgerEntry(LastEntryNo + 1, AmountValue);
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LastEntryNo + 1;
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Due Date" := DueDate;
        VendorLedgerEntry."Vendor No." := LibraryPurchase.CreateVendorNo();
        VendorLedgerEntry."Document No." := CopyStr(CreateGuid(), 1, 20);
        VendorLedgerEntry."Amount (LCY)" := AmountValue;
        VendorLedgerEntry.Insert();
    end;

    local procedure InsertCustLedgerEntry(DueDate: Date; AmountValue: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        LastEntryNo: Integer;
    begin
        if CustLedgerEntry.FindLast() then;
        LastEntryNo := CustLedgerEntry."Entry No.";
        InsertDetailedCustLedgerEntry(LastEntryNo + 1, AmountValue);
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LastEntryNo + 1;
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Due Date" := DueDate;
        CustLedgerEntry."Customer No." := LibrarySales.CreateCustomerNo();
        CustLedgerEntry."Document No." := CopyStr(CreateGuid(), 1, 20);
        CustLedgerEntry."Amount (LCY)" := AmountValue;
        CustLedgerEntry.Insert();
    end;

    local procedure InsertVATLedgerEntry(DocumentDate: Date; AmountValue: Decimal; IsSales: Boolean)
    var
        VATEntry: Record "VAT Entry";
        LastEntryNo: Integer;
    begin
        if VATEntry.FindLast() then;
        LastEntryNo := VATEntry."Entry No.";
        VATEntry.Init();
        VATEntry."Entry No." := LastEntryNo + 1;
        VATEntry."Document Date" := DocumentDate;
        if IsSales then
            VATEntry.Type := VATEntry.Type::Sale
        else
            VATEntry.Type := VATEntry.Type::Purchase;
        VATEntry."Document No." := CopyStr(CreateGuid(), 1, 20);
        VATEntry.Amount := AmountValue;
        VATEntry.Insert();
    end;

    local procedure InsertDetailedCustLedgerEntry(CustLedgerEntryNo: Integer; AmountValue: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        LastEntryNo: Integer;
    begin
        if DetailedCustLedgEntry.FindLast() then;
        LastEntryNo := DetailedCustLedgEntry."Entry No.";
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := LastEntryNo + 1;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntryNo;
        DetailedCustLedgEntry.Amount := AmountValue;
        DetailedCustLedgEntry."Amount (LCY)" := AmountValue;
        DetailedCustLedgEntry."Ledger Entry Amount" := true;
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry.Insert();
    end;

    local procedure InsertDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer; AmountValue: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        LastEntryNo: Integer;
    begin
        if DetailedVendorLedgEntry.FindLast() then;
        LastEntryNo := DetailedVendorLedgEntry."Entry No.";
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := LastEntryNo + 1;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntryNo;
        DetailedVendorLedgEntry.Amount := AmountValue;
        DetailedVendorLedgEntry."Amount (LCY)" := AmountValue;
        DetailedVendorLedgEntry."Ledger Entry Amount" := true;
        DetailedVendorLedgEntry."Posting Date" := WorkDate();
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure ClearTax()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
    begin
        SalesHeader.DeleteAll();
        PurchaseHeader.DeleteAll();
        VATEntry.DeleteAll();
    end;

    local procedure GetDateWithoutLedgerEntries(): Date
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        LastLedgerEntryDate: Date;
    begin
        CustLedgerEntry.SetCurrentKey("Due Date");
        if CustLedgerEntry.FindLast() then;
        LastLedgerEntryDate := CustLedgerEntry."Due Date";

        // vendor ledger entries
        VendorLedgerEntry.SetCurrentKey("Due Date");
        if VendorLedgerEntry.FindFirst() then;
        if LastLedgerEntryDate < VendorLedgerEntry."Due Date" then
            LastLedgerEntryDate := VendorLedgerEntry."Due Date";

        VATEntry.SetCurrentKey("Posting Date");
        if VATEntry.FindFirst() then;
        if LastLedgerEntryDate < VATEntry."Posting Date" then
            LastLedgerEntryDate := VATEntry."Posting Date";

        // sales orders
        SalesHeader.SetCurrentKey("Due Date");
        if SalesHeader.FindLast() then;
        if LastLedgerEntryDate < SalesHeader."Due Date" then
            LastLedgerEntryDate := SalesHeader."Due Date";

        // purchase orders
        // sales orders
        PurchaseHeader.SetCurrentKey("Due Date");
        if PurchaseHeader.FindLast() then;
        if LastLedgerEntryDate < PurchaseHeader."Document Date" then
            LastLedgerEntryDate := PurchaseHeader."Document Date";

        if LastLedgerEntryDate = 0D then
            exit(WorkDate());

        exit(CalcDate('<+1D>', LastLedgerEntryDate));
    end;

    local procedure VerifyAzureAIRecord(GroupIDValue: Text[50]; AmountValue: Decimal)
    var
        CashFlowAzureAIBuffer: Record "Cash Flow Azure AI Buffer";
    begin
        Clear(CashFlowAzureAIBuffer);
        CashFlowAzureAIBuffer.SetRange("Group Id", GroupIDValue);
        CashFlowAzureAIBuffer.FindFirst();
        Assert.AreNearlyEqual(AmountValue, CashFlowAzureAIBuffer.Amount, 0.1, '');
    end;

    local procedure VerifyAzureAITaxRecord(GroupIDValue: Text[50]; AmountValue: Decimal; DateValue: Date)
    var
        CashFlowAzureAIBuffer: Record "Cash Flow Azure AI Buffer";
    begin
        Clear(CashFlowAzureAIBuffer);
        if AmountValue = 0 then
            exit;
        CashFlowAzureAIBuffer.SetRange("Group Id", GroupIDValue);
        CashFlowAzureAIBuffer.SetRange("Period Start", DateValue);
        CashFlowAzureAIBuffer.FindFirst();
        Assert.AreNearlyEqual(AmountValue, CashFlowAzureAIBuffer.Amount, 0.1, '');
        Assert.AreEqual(DateValue, CashFlowAzureAIBuffer."Period Start", 'Period Date for Azure AI tax record is incorrect');
    end;

    [Scope('OnPrem')]
    procedure VerifyNotInserted(Type: Text[50]; AssertMsg: Text; IsPositiveAmount: Boolean)
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowAzureAIBuffer: Record "Cash Flow Azure AI Buffer";
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
    begin
        if IsPositiveAmount then
            InsertTimeSeriesForecast(TempTimeSeriesForecast, Type, LibraryRandom.RandDec(100, 2))
        else
            InsertTimeSeriesForecast(TempTimeSeriesForecast, Type, -LibraryRandom.RandDec(100, 2));

        // [WHEN] Forecast is called
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Record is not inserted
        Assert.IsFalse(CashFlowAzureAIBuffer.FindFirst(), AssertMsg);
    end;

    [Scope('OnPrem')]
    procedure VerifyInserted(Type: Text[50]; IsPositiveAmount: Boolean)
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        Amount: Decimal;
    begin
        Amount := LibraryRandom.RandDec(100, 2);
        if IsPositiveAmount then
            Amount := LibraryRandom.RandDec(100, 2)
        else
            Amount := -LibraryRandom.RandDec(100, 2);

        InsertTimeSeriesForecast(TempTimeSeriesForecast, Type, Amount);
        // [WHEN] Forecast is called
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Record is inserted
        VerifyAzureAITaxRecord(Type, Amount, CashFlowSetup.GetTaxPaymentDueDate(GetDateWithoutLedgerEntries()));
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrectionInserted(Type: Text)
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
        Amount: Decimal;
        VATLedgerAmount: Decimal;
        DocumentDate: Date;
    begin
        Amount := LibraryRandom.RandDec(100, 2) + 2;
        if Type = XTAXPAYABLESTxt then
            InsertTimeSeriesForecast(TempTimeSeriesForecast, XTAXPAYABLESTxt, Amount)
        else
            InsertTimeSeriesForecast(TempTimeSeriesForecast, XTAXRECEIVABLESTxt, -Amount);

        VATLedgerAmount := Amount - 1;
        ClearTax();
        if Type = XTAXPAYABLESTxt then
            InsertVATLedgerEntry(TempTimeSeriesForecast."Period Start Date", VATLedgerAmount, false)
        else
            InsertVATLedgerEntry(TempTimeSeriesForecast."Period Start Date", VATLedgerAmount, true);

        DocumentDate := TempTimeSeriesForecast."Period Start Date";
        // [WHEN] Forecast is called
        CashFlowForecastHandler.CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);

        // [THEN] Azure AI Tax Record is  inserted
        if Type = XTAXPAYABLESTxt then
            VerifyAzureAITaxRecord(XTAXPAYABLESTxt, Amount, CashFlowSetup.GetTaxPaymentDueDate(DocumentDate))
        else
            VerifyAzureAITaxRecord(XTAXRECEIVABLESTxt, -Amount, CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));
        // [THEN] Azure AI Tax Correction Record is  inserted
        if Type = XTAXPAYABLESTxt then
            VerifyAzureAITaxRecord(XTAXPAYABLESCORRECTIONTxt, -VATLedgerAmount, CashFlowSetup.GetTaxPaymentDueDate(DocumentDate))
        else
            VerifyAzureAITaxRecord(
              XTAXRECEIVABLESCORRECTIONTxt, VATLedgerAmount, CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestWorksheetLinesReqPageHandler(var SuggestWorksheetLines: TestRequestPage "Suggest Worksheet Lines")
    var
        CashFlowNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CashFlowNo);
        SuggestWorksheetLines.CashFlowNo.SetValue(CashFlowNo);
        SuggestWorksheetLines."ConsiderSource[SourceType::""Azure AI""]".SetValue(true); // Azure AI
        SuggestWorksheetLines.OK().Invoke();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure NotificationEnableAzureAIHandler(var Notification: Notification): Boolean
    begin
        Assert.AreEqual(SetupScheduledForecastingMsg, Notification.Message, 'A different notification is being sent.');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CashFlowForecastPageHandler(var CashFlowForecastChartTestPage: TestPage "Cash Flow Forecast Chart")
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(EnableEncryptionTxt, Question);
        Reply := false;
    end;
}

