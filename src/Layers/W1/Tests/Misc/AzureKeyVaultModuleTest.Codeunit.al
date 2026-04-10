codeunit 135209 "Azure Key Vault Module Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Azure] [Key Vault]
    end;

    var
        Assert: Codeunit Assert;
        MLForecastTok: Label 'ml-forecast';
        FakeSecret: Label 'a fake secret', Locked = true;
        AnotherFakeSecret: Label 'another fake secret', Locked = true;
        MachineLearningTok: Label 'machinelearning';
        YodleeCobrandNameTok: Label 'YodleeCobrandName';
        YodleeCobrandPasswordTok: Label 'YodleeCobrandPassword';
        YodleeServiceUriTok: Label 'YodleeServiceUri';
        MissingSecretErr: Label '%1 is either missing or empty', Comment = '%1 = Secret Name.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestKeyVault()
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        Secret: Text;
    begin
        // [SCENARIO] When the key vault is called, the correct value is retrieved

        // [GIVEN] A configured Azure Key Vault
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider();
        MockAzureKeyvaultSecretProvider.AddSecretMapping('ml-forecast', FakeSecret);
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);

        // [WHEN] The key vault is called
        AzureKeyVault.GetAzureKeyVaultSecret('ml-forecast', Secret);

        // [THEN] The value is retrieved
        Assert.AreEqual(FakeSecret, Secret, 'The returned secret was incorrect');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestKeyVaultCache()
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        Secret: Text;
    begin
        // [SCENARIO] When the key vault secret provider is changed, the cache is cleared and the new value is retrieved

        // [GIVEN] A configured Azure Key Vault
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider();
        MockAzureKeyvaultSecretProvider.AddSecretMapping('ml-forecast', AnotherFakeSecret);
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);

        // [WHEN] The key vault is called
        AzureKeyVault.GetAzureKeyVaultSecret('ml-forecast', Secret);

        // [THEN] The value is retrieved
        Assert.AreEqual(AnotherFakeSecret, Secret, 'The returned secret was incorrect');

        // [WHEN] The Key Vault Secret Provider is changed
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider();
        MockAzureKeyvaultSecretProvider.AddSecretMapping('ml-forecast', FakeSecret);
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);
        AzureKeyVault.GetAzureKeyVaultSecret('ml-forecast', Secret);

        // [THEN] The cache is cleared and the value is retrieved
        Assert.AreEqual(FakeSecret, Secret, 'The returned secret was incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetrievalOfSecrets()
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        TimeSeriesManagement: Codeunit "Time Series Management";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        MLForecast: Text;
        MachineLearning: Text;
        MachineLearningCredentials: Text;
        YodleeCobrandPassword: Text;
        YodleeCobranName: Text;
        YodleeServiceUri: Text;
        APIURI: Text[250];
        APIKey: SecretText;
        Limit: Decimal;
        LimitType: Option;
    begin
        // [SCENARIO] Azure Key vault is present and stores the following keys

        // [GIVEN] A key vault
        MachineLearningCredentials := '{"ApiKeys":["test"],"Limit":"10","ApiUris":["https://services.azureml.net/workspaces/fc0584f5f74a4aa19a55096fc8ebb2b7"]}'; // non-existing API URI

        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider();
        MockAzureKeyvaultSecretProvider.AddSecretMapping(StrSubstNo('ml-forecast-%1', TenantId()), MachineLearningCredentials);
        MockAzureKeyvaultSecretProvider.AddSecretMapping(MLForecastTok, MachineLearningCredentials);
        MockAzureKeyvaultSecretProvider.AddSecretMapping(MachineLearningTok, MachineLearningCredentials);
        MockAzureKeyvaultSecretProvider.AddSecretMapping(StrSubstNo('machinelearning-%1', TenantId()), MachineLearningCredentials);
        MockAzureKeyvaultSecretProvider.AddSecretMapping(YodleeCobrandNameTok, MachineLearningCredentials);
        MockAzureKeyvaultSecretProvider.AddSecretMapping(YodleeCobrandPasswordTok, MachineLearningCredentials);
        MockAzureKeyvaultSecretProvider.AddSecretMapping(YodleeServiceUriTok, MachineLearningCredentials);

        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);

        // [WHEN] The secrets are retrieved
        TimeSeriesManagement.GetMLForecastCredentials(APIURI, APIKey, LimitType, Limit);
        AzureKeyVault.GetAzureKeyVaultSecret(MLForecastTok, MLForecast);
        AzureKeyVault.GetAzureKeyVaultSecret(MachineLearningTok, MachineLearning);
        AzureKeyVault.GetAzureKeyVaultSecret(YodleeCobrandNameTok, YodleeCobranName);
        AzureKeyVault.GetAzureKeyVaultSecret(YodleeCobrandPasswordTok, YodleeCobrandPassword);
        AzureKeyVault.GetAzureKeyVaultSecret(YodleeServiceUriTok, YodleeServiceUri);

        // [THEN] The values returned are not empty
        Assert.AreNotEqual(APIURI, '', 'API URI was empty');
        Assert.AreNotEqual(UnwrapSecretText(APIKey), '', 'API Key was empty');
        Assert.AreNotEqual(LimitType, '', 'Limit type was empty');
        Assert.AreNotNearlyEqual(Limit, 0, 0.01, 'Timeout was 0');
        Assert.AreNotEqual(MLForecast, '', 'MLForecast was empty');
        Assert.AreNotEqual(MachineLearning, '', 'Machine learning was empty');
        Assert.AreNotEqual(YodleeCobranName, '', 'YodleeCobranName was empty');
        Assert.AreNotEqual(YodleeCobrandPassword, '', 'YodleeCobrandPassword was empty');
        Assert.AreNotEqual(YodleeServiceUri, '', 'YodleeServiceUri was empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetrievalOfUnkownSecretFails()
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        Secret: Text;
    begin
        // [SCENARIO] When an unknown key is provided, then retrieval of the secret fails

        // [GIVEN] A configured Azure Key Vault
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider();
        MockAzureKeyvaultSecretProvider.AddSecretMapping('somesecret', FakeSecret);
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);

        // [WHEN] The key vault is called with an unknown key
        asserterror AzureKeyVault.GetAzureKeyVaultSecret('somekeythatdoesnotexist', Secret);

        // [THEN] An error is thrown
        Assert.ExpectedError(StrSubstNo(MissingSecretErr, 'somekeythatdoesnotexist'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetrievalOfImageAnalysisSecrets()
    var
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        ImageAnalysisParams: Text;
        ApiUri: Text[250];
        ApiKey: SecretText;
        LimitType: Option Year,Month,Day,Hour;
        LimitValue: Integer;
    begin
        // [SCENARIO] Retrival of image analysis secrets from Azure Key Vault

        // [GIVEN] A key vault
        ImageAnalysisParams := '[{"key":"key1","endpoint":"endpoint1","limittype":"Month","limitvalue":"200"}]';
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider();
        MockAzureKeyvaultSecretProvider.AddSecretMapping('cognitive-vision-params', ImageAnalysisParams);
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);

        // [WHEN] The secrets are retrieved
        ImageAnalysisManagement.GetImageAnalysisCredentials(ApiKey, ApiUri, LimitType, LimitValue);

        // [THEN] The values returned are correct
        Assert.AreEqual(ApiUri, 'endpoint1', 'Retrieved Api Uri was wrong.');
        Assert.AreEqual(UnwrapSecretText(ApiKey), 'key1', 'Retrieved Api Key was wrong.');
        Assert.AreEqual(LimitType, LimitType::Month, 'Retrieved Limit type was wrong.');
        Assert.AreEqual(LimitValue, 200, 'Retrieved Limit type was wrong.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetrievalOfIsvSecret()
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        Secret: Text;
    begin
        // [SCENARIO] When an ISV key is provided, then retrieval of the secret succeeds

        // [GIVEN] A configured Azure Key Vault
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider();
        MockAzureKeyvaultSecretProvider.AddSecretMapping('isv-anykey', FakeSecret);
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);

        // [WHEN] The key vault is called with an ISV key
        AzureKeyVault.GetAzureKeyVaultSecret('isv-anykey', Secret);

        // [THEN] A secret is returned
        Assert.AreEqual(FakeSecret, Secret, 'The returned secret was incorrect');
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    local procedure UnwrapSecretText(SecretTextToUnwrap: SecretText): Text
    begin
        exit(SecretTextToUnwrap.Unwrap());
    end;

}

