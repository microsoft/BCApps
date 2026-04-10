codeunit 134560 "Cash Flow Setup Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cash Flow] [Payment Date] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        UnexpectedAPIURLTxt: Label 'Unexpected API URL is retrieved.';
        UnexpectedAPIKeyTxt: Label 'Unexpected API Key is retrieved.';
        UnexpectedLimitTxt: Label 'Unexpected Limit Value is retrieved.';
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        InvalidURIErr: Label 'Provided API URL (%1) is not a valid AzureML URL.', Comment = '%1 = custom URL', Locked = true;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextTaxPaymentDateMonthly()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        Initialize();
        TestGetNextTaxPaymentDate(CashFlowSetup."Taxable Period"::Monthly, '<5D>', DMY2Date(10, 8, 2016), DMY2Date(5, 9, 2016));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextTaxPaymentDateMonthlyNoOffset()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        Initialize();
        TestGetNextTaxPaymentDate(CashFlowSetup."Taxable Period"::Monthly, '<>', DMY2Date(10, 8, 2016), DMY2Date(31, 8, 2016));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextTaxPaymentDateMonthlyNextYear()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        Initialize();
        TestGetNextTaxPaymentDate(CashFlowSetup."Taxable Period"::Monthly, '<1M+10D>', DMY2Date(10, 12, 2016), DMY2Date(10, 2, 2017));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextTaxPaymentDateMonthlyNegativeOffset()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        Initialize();
        TestGetNextTaxPaymentDate(CashFlowSetup."Taxable Period"::Monthly, '<-5D>', DMY2Date(10, 9, 2016), DMY2Date(25, 9, 2016));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextTaxPaymentDateQuarterly()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        // NAV calculates 30 Sep + 1M = 30 Oct
        // Therefore 30 Oct + 2D = 1 Nov
        Initialize();
        TestGetNextTaxPaymentDate(CashFlowSetup."Taxable Period"::Quarterly, '<1M+2D>', DMY2Date(10, 8, 2016), DMY2Date(1, 11, 2016));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextTaxPaymentDateQuarterlyNoOffset()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        Initialize();
        TestGetNextTaxPaymentDate(CashFlowSetup."Taxable Period"::Quarterly, '<>', DMY2Date(1, 1, 2016), DMY2Date(31, 3, 2016));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextTaxPaymentDateQuarterlyNegativeOffset()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        Initialize();
        TestGetNextTaxPaymentDate(CashFlowSetup."Taxable Period"::Quarterly, '<-1M-5D>', DMY2Date(1, 1, 2016), DMY2Date(24, 2, 2016));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextTaxPaymentDateYearly()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        Initialize();
        TestGetNextTaxPaymentDate(CashFlowSetup."Taxable Period"::Yearly, '<5D>', DMY2Date(10, 8, 2016), DMY2Date(5, 1, 2017));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextTaxPaymentDateYearlyNoOffset()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        Initialize();
        TestGetNextTaxPaymentDate(CashFlowSetup."Taxable Period"::Yearly, '', DMY2Date(10, 8, 2016), DMY2Date(31, 12, 2016));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextTaxPaymentDateYearlyYear()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        Initialize();
        TestGetNextTaxPaymentDate(CashFlowSetup."Taxable Period"::Yearly, '<1M>', DMY2Date(10, 8, 2016), DMY2Date(31, 1, 2017));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextTaxPaymentDateYearlyNegativeOffset()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        Initialize();
        TestGetNextTaxPaymentDate(CashFlowSetup."Taxable Period"::Yearly, '<-5D>', DMY2Date(10, 9, 2016), DMY2Date(26, 12, 2016));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextTaxPaymentDateAccountingPeriod()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        Initialize();
        TestGetNextTaxPaymentDate(CashFlowSetup."Taxable Period"::"Accounting Period", '<5D>', DMY2Date(10, 8, 2016), DMY2Date(5, 9, 2016));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextTaxPaymentDateAccountingPeriodNegativeOffset()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        Initialize();
        TestGetNextTaxPaymentDate(CashFlowSetup."Taxable Period"::"Accounting Period", '<-5D>', DMY2Date(10, 9, 2016), DMY2Date(25, 9, 2016));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetTaxPeriodDatesQuarterly()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        Initialize();
        TestGetStartEndTaxPeriodDate(CashFlowSetup."Taxable Period"::Quarterly, '',
          DMY2Date(31, 3, 2016), DMY2Date(1, 1, 2016), DMY2Date(31, 3, 2016));
        TestGetStartEndTaxPeriodDate(CashFlowSetup."Taxable Period"::Quarterly, '<2D>',
          DMY2Date(2, 4, 2016), DMY2Date(1, 1, 2016), DMY2Date(31, 3, 2016));
        TestGetStartEndTaxPeriodDate(CashFlowSetup."Taxable Period"::Quarterly, '<1M+2D>',
          DMY2Date(2, 5, 2016), DMY2Date(1, 1, 2016), DMY2Date(31, 3, 2016));
    end;

    local procedure InitializeAccountingPeriods()
    var
        AccountingPeriod: Record "Accounting Period";
        StartingDate: Date;
        EndingDate: Date;
    begin
        if AccountingPeriod.Count > 0 then
            AccountingPeriod.DeleteAll();

        StartingDate := DMY2Date(1, 1, 2015);
        EndingDate := DMY2Date(1, 1, 2018);

        while StartingDate <= EndingDate do begin
            AccountingPeriod.Init();
            AccountingPeriod.Validate("Starting Date", StartingDate);
            AccountingPeriod.Insert();
            StartingDate := CalcDate('<1M>', StartingDate);
        end;
    end;

    local procedure TestGetNextTaxPaymentDate(TaxablePeriod: Option; TaxPaymentWindowText: Text; ReferenceDate: Date; ExpectedTaxPaymentDate: Date)
    var
        CashFlowSetup: Record "Cash Flow Setup";
        TaxPaymentWindow: DateFormula;
        ActualTaxPaymentDate: Date;
    begin
        Evaluate(TaxPaymentWindow, TaxPaymentWindowText);
        CashFlowSetup.UpdateTaxPaymentInfo(TaxablePeriod, TaxPaymentWindow, CashFlowSetup."Tax Bal. Account Type"::" ", '');
        ActualTaxPaymentDate := CashFlowSetup.GetTaxPaymentDueDate(ReferenceDate);
        Assert.AreEqual(ExpectedTaxPaymentDate, ActualTaxPaymentDate, 'Incorrect calculation of next tax payment date.');
    end;

    local procedure TestGetStartEndTaxPeriodDate(TaxablePeriod: Option; TaxPaymentWindowText: Text; ReferenceDate: Date; ExpectedStart: Date; ExpectedEnd: Date)
    var
        CashFlowSetup: Record "Cash Flow Setup";
        TaxPaymentWindow: DateFormula;
        ActualStart: Date;
        ActualEnd: Date;
    begin
        Evaluate(TaxPaymentWindow, TaxPaymentWindowText);
        CashFlowSetup.UpdateTaxPaymentInfo(TaxablePeriod, TaxPaymentWindow, CashFlowSetup."Tax Bal. Account Type"::" ", '');
        CashFlowSetup.GetTaxPeriodStartEndDates(ReferenceDate, ActualStart, ActualEnd);
        Assert.AreEqual(ExpectedStart, ActualStart, 'Incorrect calculation of start of tax period.');
        Assert.AreEqual(ExpectedEnd, ActualEnd, 'Incorrect calculation of end of tax period.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetInvalidURLThrowsError()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        APIURL: Text[250];
    begin
        Initialize();
        // [SCENARIO] Setting an invalid URL on the cash flow setup throws an error

        // [GIVEN] Not SaaS environment
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        APIURL := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(50, 1), 1, 50);

        // [WHEN] Setting a invalid URL on the cash flow setup
        CashFlowSetup.Get();
        asserterror CashFlowSetup.Validate("API URL", APIURL);

        // [THEN] An error is thrown
        Assert.ExpectedError(StrSubstNo(InvalidURIErr, APIURL));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetMLCredentialsNoSaaSNoUserDefined()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        APIURL: Text[250];
        APIKey: SecretText;
        LimitValue: Decimal;
        UsingStdCreds: Boolean;
    begin
        Initialize();
        // [SCENARIO] Get AzureML credentials from Cach Flow Setup, when not SaaS instance and no user defined credentials

        // [GIVEN] Not SaaS environment
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] GetMLCredentials invoked
        CashFlowSetup.GetMLCredentials(APIURL, APIKey, LimitValue, UsingStdCreds);

        // [THEN] API URL and API Key are empty, Limit is 0
        Assert.AreEqual(APIURL, '', '');
        Assert.AreEqual(UnwrapSecretText(APIKey), '', '');
        Assert.AreEqual(LimitValue, 0, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetMLCredentialsNoSaaSUserDefined()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        APIURL: Text[250];
        APIKey: SecretText;
        LimitValue: Decimal;
        APIURLInput: Text[250];
        APIKeyInput: Text[200];
        UsingStdCreds: Boolean;
    begin
        Initialize();
        // [SCENARIO] Get AzureML credentials from Cach Flow Setup, when not SaaS instance and user defined credentials
        // [GIVEN] Not SaaS environment, with API URL and API Key defined
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        EnterMLCredentials(CashFlowSetup, APIURLInput, APIKeyInput);

        // [WHEN] GetMLCredentials invoked
        CashFlowSetup.GetMLCredentials(APIURL, APIKey, LimitValue, UsingStdCreds);

        // [THEN] User-defined API URL and API Key are used
        VerifyMLCredentials(APIURL, APIKey, LimitValue, APIURLInput, APIKeyInput, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetMLCredentialsSaaSNoUserDefined()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        APIURL: Text[250];
        APIKey: SecretText;
        LimitValue: Decimal;
        UsingStdCreds: Boolean;
    begin
        Initialize();
        // [SCENARIO] Get AzureML credentials from Azure Key Vault, when SaaS instance and no user defined credentials
        // [GIVEN] Not SaaS environment, with API URL and API Key not defined
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] GetMLCredentials invoked
        CashFlowSetup.GetMLCredentials(APIURL, APIKey, LimitValue, UsingStdCreds);

        // [THEN] API URL and API Key are retrieved from Azure Key Vault
        // Assert.AreNotEqual(APIURL,'',UnexpectedAPIURLTxt);
        // Assert.AreNotEqual(APIKey,'',UnexpectedAPIKeyTxt);
        // Assert.AreNotEqual(LimitValue,0,UnexpectedLimitTxt);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetMLCredentialsSaaSUserDefined()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        APIURL: Text[250];
        APIKey: SecretText;
        APIURLInput: Text[250];
        APIKeyInput: Text[200];
        LimitValue: Decimal;
        UsingStdCreds: Boolean;
    begin
        Initialize();
        // [SCENARIO] Get AzureML credentials from Cach Flow Setup, when SaaS instance and user defined credentials
        // [GIVEN] SaaS environment, with API URL and API Key defined
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnterMLCredentials(CashFlowSetup, APIURLInput, APIKeyInput);

        // [WHEN] GetMLCredentials invoked
        CashFlowSetup.GetMLCredentials(APIURL, APIKey, LimitValue, UsingStdCreds);

        // [THEN] User-defined API URL and API Key are used from Cash Flow Setup
        VerifyMLCredentials(APIURL, APIKey, LimitValue, APIURLInput, APIKeyInput, 0);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure EnterMLCredentials(var CashFlowSetup: Record "Cash Flow Setup"; var APIURL: Text[250]; var APIKey: Text[200])
    var
        AzureMLURI: Label 'http://%1.services.azureml.net', Locked = true;
    begin
        CashFlowSetup.Get();
        APIKey := CreateGuid();
        APIURL := StrSubstNo(AzureMLURI, CopyStr(LibraryUtility.GenerateRandomAlphabeticText(50, 1), 1, 50));
        CashFlowSetup.SaveUserDefinedAPIKey(APIKey);
        CashFlowSetup.Validate("API URL", APIURL);
        CashFlowSetup.Modify(true);
    end;

    local procedure VerifyMLCredentials(APIURL: Text[250]; APIKey: SecretText; LimitValue: Decimal; APIURLInput: Text[250]; APIKeyInput: Text[200]; LimitInput: Decimal)
    begin
        Assert.AreEqual(APIURLInput, APIURL, UnexpectedAPIURLTxt);
        Assert.AreEqual(APIKeyInput, UnwrapSecretText(APIKey), UnexpectedAPIKeyTxt);
        Assert.AreEqual(LimitInput, LimitValue, UnexpectedLimitTxt);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        InitializeAccountingPeriods();

        IsInitialized := true;
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    local procedure UnwrapSecretText(SecretTextToUnwrap: SecretText): Text
    begin
        exit(SecretTextToUnwrap.Unwrap());
    end;
}

