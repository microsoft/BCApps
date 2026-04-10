codeunit 134413 "Test Doc. Exch. Service Setup"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Document Exchange Service]
    end;

    var
        Assert: Codeunit Assert;
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        InvalidUriErr: Label 'The URI is not valid.';
        SignUpUrlProdTxt: Label 'https://go.tradeshift.com/register', Locked = true;
        SignInUrlProdTxt: Label 'https://go.tradeshift.com/login', Locked = true;
        ServiceUrlProdTxt: Label 'https://api.tradeshift.com/tradeshift/rest/external', Locked = true;
        AuthUrlProdTxt: Label 'https://api.tradeshift.com/tradeshift/auth/login', Locked = true;
        TokenUrlProdTxt: Label 'https://api.tradeshift.com/tradeshift/auth/token', Locked = true;
        SignUpUrlSandboxTxt: Label 'https://sandbox.tradeshift.com/register', Locked = true;
        SignInUrlSandboxTxt: Label 'https://sandbox.tradeshift.com/login', Locked = true;
        ServiceUrlSandboxTxt: Label 'https://api-sandbox.tradeshift.com/tradeshift/rest/external', Locked = true;
        AuthUrlSandboxTxt: Label 'https://api-sandbox.tradeshift.com/tradeshift/auth/login', Locked = true;
        TokenUrlSandboxTxt: Label 'https://api-sandbox.tradeshift.com/tradeshift/auth/token', Locked = true;
        ValidUrlTxt: Label 'https://microsoft.com', Locked = true;
        InvalidUrlTxt: Label 'http://this is an invalid url', Locked = true;
        OAuthLandingTxt: Label '/OAuthLanding.htm', Locked = true;
        EmptyAccessTokenTxt: Label 'The access token is empty.';

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupUrlBlank()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // Init
        AzureKeyVaultTestLibrary.ClearSecrets();
        DocExchServiceSetup.Init();

        // Execute
        DocExchServiceSetup.Validate("Sign-up URL", '');
        DocExchServiceSetup.Validate("Sign-in URL", '');
        DocExchServiceSetup.Validate("Service URL", '');
        DocExchServiceSetup.Validate("Auth URL", '');
        DocExchServiceSetup.Validate("Token URL", '');
        DocExchServiceSetup.Validate("Redirect URL", '');

        // Validate
        Assert.AreEqual('', DocExchServiceSetup."Sign-up URL", 'Sign-up URL');
        Assert.AreEqual('', DocExchServiceSetup."Sign-in URL", 'Sign-in URL');
        Assert.AreEqual('', DocExchServiceSetup."Service URL", 'Service URL');
        Assert.AreEqual('', DocExchServiceSetup."Auth URL", 'Auth URL');
        Assert.AreEqual('', DocExchServiceSetup."Token URL", 'Token URL');
        Assert.AreEqual('', DocExchServiceSetup."Redirect URL", 'Redirect URL');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupUrlInvalidUrl()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // Init
        DocExchServiceSetup.Init();

        // Execute & Validate
        asserterror DocExchServiceSetup.Validate("Sign-up URL", InvalidUrlTxt);
        Assert.ExpectedError(InvalidUriErr);
        asserterror DocExchServiceSetup.Validate("Sign-in URL", InvalidUrlTxt);
        Assert.ExpectedError(InvalidUriErr);
        asserterror DocExchServiceSetup.Validate("Service URL", InvalidUrlTxt);
        Assert.ExpectedError(InvalidUriErr);
        asserterror DocExchServiceSetup.Validate("Auth URL", InvalidUrlTxt);
        Assert.ExpectedError(InvalidUriErr);
        asserterror DocExchServiceSetup.Validate("Token URL", InvalidUrlTxt);
        Assert.ExpectedError(InvalidUriErr);
        asserterror DocExchServiceSetup.Validate("Redirect URL", InvalidUrlTxt);
        Assert.ExpectedError(InvalidUriErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupUrlPositive()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // Init
        DocExchServiceSetup.Init();

        // Execute & Validate
        DocExchServiceSetup.Validate("Sign-up URL", ValidUrlTxt);
        DocExchServiceSetup.Validate("Sign-in URL", ValidUrlTxt);
        DocExchServiceSetup.Validate("Service URL", ValidUrlTxt);
        DocExchServiceSetup.Validate("Auth URL", ValidUrlTxt);
        DocExchServiceSetup.Validate("Token URL", ValidUrlTxt);
        DocExchServiceSetup.Validate("Redirect URL", ValidUrlTxt);

        // Validate
        Assert.AreEqual(ValidUrlTxt, DocExchServiceSetup."Sign-up URL", 'Sign-up URL');
        Assert.AreEqual(ValidUrlTxt, DocExchServiceSetup."Sign-in URL", 'Sign-in URL');
        Assert.AreEqual(ValidUrlTxt, DocExchServiceSetup."Service URL", 'Service URL');
        Assert.AreEqual(ValidUrlTxt, DocExchServiceSetup."Auth URL", 'Auth URL');
        Assert.AreEqual(ValidUrlTxt, DocExchServiceSetup."Token URL", 'Token URL');
        Assert.AreEqual(ValidUrlTxt, DocExchServiceSetup."Redirect URL", 'Redirect URL');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupSetURLsToDefaultDefaultProduction()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceSetupCard: TestPage "Doc. Exch. Service Setup";
    begin
        // Init
        DocExchServiceSetup.DeleteAll(true);

        // Execute
        DocExchServiceSetupCard.OpenEdit();
        DocExchServiceSetupCard."Sign-up URL".SetValue(ValidUrlTxt);
        DocExchServiceSetupCard."Sign-in URL".SetValue(ValidUrlTxt);
        DocExchServiceSetupCard."Service URL".SetValue(ValidUrlTxt);
        DocExchServiceSetupCard."Auth URL".SetValue(ValidUrlTxt);
        DocExchServiceSetupCard."Token URL".SetValue(ValidUrlTxt);
        DocExchServiceSetupCard."Redirect URL".SetValue(ValidUrlTxt);
        DocExchServiceSetupCard.SetURLsToDefault.Invoke();

        // Validate
        Assert.AreEqual(SignUpUrlProdTxt, DocExchServiceSetupCard."Sign-up URL".Value(), 'Sign-up URL');
        Assert.AreEqual(SignInUrlProdTxt, DocExchServiceSetupCard."Sign-in URL".Value(), 'Sign-in URL');
        Assert.AreEqual(ServiceUrlProdTxt, DocExchServiceSetupCard."Service URL".Value(), 'Service URL');
        Assert.AreEqual(AuthUrlProdTxt, DocExchServiceSetupCard."Auth URL".Value(), 'Auth URL');
        Assert.AreEqual(TokenUrlProdTxt, DocExchServiceSetupCard."Token URL".Value(), 'Token URL');
        Assert.IsTrue(DocExchServiceSetupCard."Redirect URL".Value().EndsWith(OAuthLandingTxt), 'Redirect URL');

        DocExchServiceSetupCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupSetURLsToDefaultDefaultSandbox()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceSetupCard: TestPage "Doc. Exch. Service Setup";
    begin
        // Init
        DocExchServiceSetup.DeleteAll(true);

        // Execute
        DocExchServiceSetupCard.OpenEdit();
        DocExchServiceSetupCard."Sign-up URL".SetValue(ValidUrlTxt);
        DocExchServiceSetupCard."Sign-in URL".SetValue(ValidUrlTxt);
        DocExchServiceSetupCard."Service URL".SetValue(ServiceUrlSandboxTxt);
        DocExchServiceSetupCard."Auth URL".SetValue(ValidUrlTxt);
        DocExchServiceSetupCard."Token URL".SetValue(ValidUrlTxt);
        DocExchServiceSetupCard."Redirect URL".SetValue(ValidUrlTxt);
        DocExchServiceSetupCard.SetURLsToDefault.Invoke();

        // Validate
        Assert.AreEqual(SignUpUrlSandboxTxt, DocExchServiceSetupCard."Sign-up URL".Value(), 'Sign-up URL');
        Assert.AreEqual(SignInUrlSandboxTxt, DocExchServiceSetupCard."Sign-in URL".Value(), 'Sign-in URL');
        Assert.AreEqual(ServiceUrlSandboxTxt, DocExchServiceSetupCard."Service URL".Value(), 'Service URL');
        Assert.AreEqual(AuthUrlSandboxTxt, DocExchServiceSetupCard."Auth URL".Value(), 'Auth URL');
        Assert.AreEqual(TokenUrlSandboxTxt, DocExchServiceSetupCard."Token URL".Value(), 'Token URL');
        Assert.IsTrue(DocExchServiceSetupCard."Redirect URL".Value().EndsWith(OAuthLandingTxt), 'Redirect URL');

        DocExchServiceSetupCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupProductionURLs()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceSetupCard: TestPage "Doc. Exch. Service Setup";
    begin
        // Init
        DocExchServiceSetup.DeleteAll(true);

        // Exectute
        DocExchServiceSetupCard.OpenEdit();
        Assert.AreEqual(SignUpUrlProdTxt, DocExchServiceSetupCard."Sign-up URL".Value(), 'Sign-up URL');
        Assert.AreEqual(SignInUrlProdTxt, DocExchServiceSetupCard."Sign-in URL".Value(), 'Sign-in URL');
        Assert.AreEqual(ServiceUrlProdTxt, DocExchServiceSetupCard."Service URL".Value(), 'Service URL');
        Assert.AreEqual(AuthUrlProdTxt, DocExchServiceSetupCard."Auth URL".Value(), 'Auth URL');
        Assert.AreEqual(TokenUrlProdTxt, DocExchServiceSetupCard."Token URL".Value(), 'Token URL');
        Assert.IsTrue(DocExchServiceSetupCard."Redirect URL".Value().EndsWith(OAuthLandingTxt), 'Redirect URL');
        DocExchServiceSetupCard.Sandbox.SetValue(false);
        DocExchServiceSetupCard.Close();

        // Validate
        DocExchServiceSetup.Get();
        Assert.AreEqual(SignUpUrlProdTxt, DocExchServiceSetup."Sign-up URL", 'Sign-up URL');
        Assert.AreEqual(SignInUrlProdTxt, DocExchServiceSetup."Sign-in URL", 'Sign-in URL');
        Assert.AreEqual(ServiceUrlProdTxt, DocExchServiceSetup."Service URL", 'Service URL');
        Assert.AreEqual(AuthUrlProdTxt, DocExchServiceSetup."Auth URL", 'Auth URL');
        Assert.AreEqual(TokenUrlProdTxt, DocExchServiceSetup."Token URL", 'Token URL');
        Assert.IsTrue(DocExchServiceSetup."Redirect URL".EndsWith(OAuthLandingTxt), 'Redirect URL');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupSandboxURLs()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceSetupCard: TestPage "Doc. Exch. Service Setup";
    begin
        // Init
        DocExchServiceSetup.DeleteAll(true);

        // Exectute
        DocExchServiceSetupCard.OpenEdit();
        Assert.AreEqual(SignUpUrlProdTxt, DocExchServiceSetupCard."Sign-up URL".Value(), 'Sign-up URL');
        Assert.AreEqual(SignInUrlProdTxt, DocExchServiceSetupCard."Sign-in URL".Value(), 'Sign-in URL');
        Assert.AreEqual(ServiceUrlProdTxt, DocExchServiceSetupCard."Service URL".Value(), 'Service URL');
        Assert.AreEqual(AuthUrlProdTxt, DocExchServiceSetupCard."Auth URL".Value(), 'Auth URL');
        Assert.AreEqual(TokenUrlProdTxt, DocExchServiceSetupCard."Token URL".Value(), 'Token URL');
        Assert.IsTrue(DocExchServiceSetupCard."Redirect URL".Value().EndsWith(OAuthLandingTxt), 'Redirect URL');
        DocExchServiceSetupCard.Sandbox.SetValue(true);
        DocExchServiceSetupCard.Close();

        // Validate
        DocExchServiceSetup.Get();
        Assert.AreEqual(SignUpUrlSandboxTxt, DocExchServiceSetup."Sign-up URL", 'Sign-up URL');
        Assert.AreEqual(SignInUrlSandboxTxt, DocExchServiceSetup."Sign-in URL", 'v');
        Assert.AreEqual(ServiceUrlSandboxTxt, DocExchServiceSetup."Service URL", 'Service URL');
        Assert.AreEqual(AuthUrlSandboxTxt, DocExchServiceSetup."Auth URL", 'Auth URL');
        Assert.AreEqual(TokenUrlSandboxTxt, DocExchServiceSetup."Token URL", 'Token URL');
        Assert.IsTrue(DocExchServiceSetup."Redirect URL".EndsWith(OAuthLandingTxt), 'Redirect URL');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupPageOAuth2VisibilityOnPrem()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceSetupCard: TestPage "Doc. Exch. Service Setup";
    begin
        // Init
        AzureKeyVaultTestLibrary.ClearSecrets();
        DocExchServiceSetup.DeleteAll(true);
        Assert.IsTrue(DocExchServiceSetup.IsEmpty(), '');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // Execute
        DocExchServiceSetupCard.OpenEdit();

        // Verify
        Assert.IsTrue(DocExchServiceSetupCard."Client Id".Visible(), 'Client Id');
        Assert.IsTrue(DocExchServiceSetupCard."Client Secret".Visible(), 'Client Secret');
        Assert.IsTrue(DocExchServiceSetupCard."Redirect URL".Visible(), 'Redirect URL');
        DocExchServiceSetupCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupPageOAuth2VisibilityNoPredefinedApp()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceSetupCard: TestPage "Doc. Exch. Service Setup";
    begin
        // Init
        AzureKeyVaultTestLibrary.ClearSecrets();
        DocExchServiceSetup.DeleteAll(true);
        Assert.IsTrue(DocExchServiceSetup.IsEmpty(), '');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // Execute
        DocExchServiceSetupCard.OpenEdit();

        // Verify
        Assert.IsTrue(DocExchServiceSetupCard."Client Id".Visible(), 'Client Id');
        Assert.IsTrue(DocExchServiceSetupCard."Client Secret".Visible(), 'Client Secret');
        Assert.IsTrue(DocExchServiceSetupCard."Redirect URL".Visible(), 'Redirect URL');
        DocExchServiceSetupCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupPageOAuth2VisibilityPredefinedAppInAKV()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceSetupCard: TestPage "Doc. Exch. Service Setup";
    begin
        // Init
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetSecretsInAKV();
        DocExchServiceSetup.DeleteAll(true);
        Assert.IsTrue(DocExchServiceSetup.IsEmpty(), '');

        // Execute
        DocExchServiceSetupCard.OpenEdit();

        // Verify
        Assert.IsFalse(DocExchServiceSetupCard."Client Id".Visible(), 'Client Id');
        Assert.IsFalse(DocExchServiceSetupCard."Client Secret".Visible(), 'Client Secret');
        Assert.IsFalse(DocExchServiceSetupCard."Redirect URL".Visible(), 'Redirect URL');
        DocExchServiceSetupCard.Close();
        AzureKeyVaultTestLibrary.ClearSecrets();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupPageOAuth2VisibilityPredefinedAppThroughSubscribers()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        TestDocExchServiceSetup: Codeunit "Test Doc. Exch. Service Setup";
        DocExchServiceSetupCard: TestPage "Doc. Exch. Service Setup";
    begin
        // Init
        AzureKeyVaultTestLibrary.ClearSecrets();
        DocExchServiceSetup.DeleteAll(true);
        Assert.IsTrue(DocExchServiceSetup.IsEmpty(), '');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        BindSubscription(TestDocExchServiceSetup);

        // Execute
        DocExchServiceSetupCard.OpenEdit();

        // Verify
        Assert.IsFalse(DocExchServiceSetupCard."Client Id".Visible(), 'Client Id');
        Assert.IsFalse(DocExchServiceSetupCard."Client Secret".Visible(), 'Client Secret');
        Assert.IsFalse(DocExchServiceSetupCard."Redirect URL".Visible(), 'Redirect URL');

        DocExchServiceSetupCard.Close();
        UnbindSubscription(TestDocExchServiceSetup);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,ActivateAppNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupPageChangeClientId()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
        DocExchServiceSetupCard: TestPage "Doc. Exch. Service Setup";
        ClientId: Text;
    begin
        // Init
        AzureKeyVaultTestLibrary.ClearSecrets();
        DocExchServiceSetup.DeleteAll(true);
        Assert.IsTrue(DocExchServiceSetup.IsEmpty(), '');

        ClientId := Format(CreateGuid());

        // Execute
        DocExchServiceSetupCard.OpenEdit();
        DocExchServiceSetupCard."Client Id".Value := ClientId;
        DocExchServiceSetupCard.Close();

        // Verify
        DocExchServiceSetup.Get();
        Assert.AreEqual(ClientId, DocExchServiceMgt.GetClientId(false), 'Unexpected client id');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupPageChangeClientSecret()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
        DocExchServiceSetupCard: TestPage "Doc. Exch. Service Setup";
        ClientSecret: Text;
    begin
        // Init
        AzureKeyVaultTestLibrary.ClearSecrets();
        DocExchServiceSetup.DeleteAll(true);
        Assert.IsTrue(DocExchServiceSetup.IsEmpty(), '');

        ClientSecret := Format(CreateGuid());

        // Execute
        DocExchServiceSetupCard.OpenEdit();
        DocExchServiceSetupCard."Client Secret".Value := ClientSecret;
        DocExchServiceSetupCard.Close();

        // Verify
        DocExchServiceSetup.Get();
        AssertSecret(ClientSecret, DocExchServiceMgt.GetClientSecretAsSecretText(false), 'Unexpected client secret');
        AssertSecret(ClientSecret, DocExchServiceSetup.GetClientSecretAsSecretText(), 'Unexpected client secret');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupPageRenewToken()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceSetupCard: TestPage "Doc. Exch. Service Setup";
    begin
        // Init
        DocExchServiceSetup.DeleteAll(true);
        Assert.IsTrue(DocExchServiceSetup.IsEmpty(), '');

        // Execute
        DocExchServiceSetupCard.OpenEdit();
        asserterror DocExchServiceSetupCard.RenewToken.Invoke();
        DocExchServiceSetupCard.Close();

        // Verify
        Assert.ExpectedError('The document exchange service is not enabled.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupPageJobQueueEntry()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceSetupCard: TestPage "Doc. Exch. Service Setup";
    begin
        // Init
        DocExchServiceSetup.DeleteAll(true);
        Assert.IsTrue(DocExchServiceSetup.IsEmpty(), '');

        // Execute & Verify
        DocExchServiceSetupCard.OpenEdit();
        DocExchServiceSetupCard.JobQueueEntry.Invoke();
        DocExchServiceSetupCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupPageEncryptionManagement()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceSetupCard: TestPage "Doc. Exch. Service Setup";
    begin
        // Init
        DocExchServiceSetup.DeleteAll(true);
        Assert.IsTrue(DocExchServiceSetup.IsEmpty(), '');

        // Execute & Verify
        DocExchServiceSetupCard.OpenEdit();
        DocExchServiceSetupCard.EncryptionManagement.Invoke();
        DocExchServiceSetupCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupPageTestConnection()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceSetupCard: TestPage "Doc. Exch. Service Setup";
    begin
        // Init
        DocExchServiceSetup.DeleteAll(true);
        Assert.IsTrue(DocExchServiceSetup.IsEmpty(), '');

        // Execute
        DocExchServiceSetupCard.OpenEdit();
        asserterror DocExchServiceSetupCard.TestConnection.Invoke();
        DocExchServiceSetupCard.Close();

        // Verify
        Assert.ExpectedError(EmptyAccessTokenTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchServiceMgtClientIdSecretEmpty()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
        ClientId: Text;
        ClientSecret: SecretText;
    begin
        // Init
        AzureKeyVaultTestLibrary.ClearSecrets();
        DocExchServiceSetup.DeleteAll(true);
        DocExchServiceSetup.Init();
        DocExchServiceSetup.Insert(true);

        // Execute
        ClientId := DocExchServiceMgt.GetClientId(false);
        ClientSecret := DocExchServiceMgt.GetClientSecretAsSecretText(false);

        // Verify
        Assert.AreEqual('', ClientId, 'Unexpected client id');
        Assert.IsTrue(ClientSecret.IsEmpty(), 'Unexpected client secret');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchServiceMgtClientIdSecretInAKV()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
        ActualClientId: Text;
        ActualClientSecret: SecretText;
        ExpectedClientId: Text;
        ExpectedClientSecret: Text;
    begin
        // Init
        DocExchServiceSetup.DeleteAll(true);
        DocExchServiceSetup.Init();
        DocExchServiceSetup.Insert(true);
        ExpectedClientId := Format(CreateGuid());
        ExpectedClientSecret := Format(CreateGuid());
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetSecretsInAKV(ExpectedClientId, ExpectedClientSecret);

        // Execute
        ActualClientId := DocExchServiceMgt.GetClientId(false);
        ActualClientSecret := DocExchServiceMgt.GetClientSecretAsSecretText(false);
        AzureKeyVaultTestLibrary.ClearSecrets();

        // Verify
        Assert.AreEqual(ExpectedClientId, ActualClientId, 'Unexpected client id.');
        AssertSecret(ExpectedClientsecret, ActualClientSecret, 'Unexpected client secret');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchServiceMgtClientIdSecretThroughSubscribers()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
        TestDocExchServiceSetup: Codeunit "Test Doc. Exch. Service Setup";
        ClientId: Text;
        ClientSecret: SecretText;
    begin
        // Init
        AzureKeyVaultTestLibrary.ClearSecrets();
        DocExchServiceSetup.DeleteAll(true);
        DocExchServiceSetup.Init();
        DocExchServiceSetup.Insert(true);
        BindSubscription(TestDocExchServiceSetup);

        // Execute
        ClientId := DocExchServiceMgt.GetClientId(false);
        ClientSecret := DocExchServiceMgt.GetClientSecretAsSecretText(false);
        UnbindSubscription(TestDocExchServiceSetup);

        // Verify
        Assert.AreNotEqual('', ClientId, 'Unexpected client id');
        Assert.IsFalse(ClientSecret.IsEmpty(), 'Unexpected client secret');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchServiceMgtCheckConnection()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
    begin
        // Init
        DocExchServiceSetup.DeleteAll(true);
        DocExchServiceSetup.Init();
        DocExchServiceSetup.Insert(true);

        // Execute
        asserterror DocExchServiceMgt.CheckConnection();

        // Verify
        Assert.ExpectedError('You must configure the connection to the document exchange service on the Document Exchange Service Setup page.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchServiceMgtCheckConnectionMissing()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
    begin
        // Init
        DocExchServiceSetup.DeleteAll(true);

        // Execute
        asserterror DocExchServiceMgt.CheckConnection();

        // Verify
        Assert.ExpectedError('You must configure the connection to the document exchange service on the Document Exchange Service Setup page.');
    end;

    local procedure setSecretsInAKV()
    var
        ClientId: Text;
        ClientSecret: Text;
    begin
        ClientId := Format(CreateGuid());
        ClientSecret := Format(CreateGuid());
        SetSecretsInAKV(ClientId, ClientSecret);
    end;

    local procedure SetSecretsInAKV(ClientId: Text; ClientSecret: Text)
    var
        MockAzureKeyVaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
    begin
        MockAzureKeyVaultSecretProvider := MockAzureKeyVaultSecretProvider.MockAzureKeyVaultSecretProvider();
        MockAzureKeyvaultSecretProvider.AddSecretMapping('AllowedApplicationSecrets', 'DocExchClientIdProd,DocExchClientSecretProd,DocExchClientIdTest,DocExchClientSecretTest');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('DocExchClientIdProd', ClientId);
        MockAzureKeyVaultSecretProvider.AddSecretMapping('DocExchClientSecretProd', ClientSecret);
        MockAzureKeyVaultSecretProvider.AddSecretMapping('DocExchClientIdTest', ClientId);
        MockAzureKeyVaultSecretProvider.AddSecretMapping('DocExchClientSecretTest', ClientSecret);
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyVaultSecretProvider);
    end;

    [NonDebuggable]
    local procedure AssertSecret(Expected: Text; Actual: SecretText; Message: Text)
    begin
        Assert.AreEqual(Expected, Actual.Unwrap(), Message);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Doc. Exch. Service Mgt.", 'OnGetClientId', '', false, false)]
    local procedure HandleOnGetClientId(var ClientId: Text)
    begin
        ClientId := Format(CreateGuid());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Doc. Exch. Service Mgt.", 'OnGetClientSecret', '', false, false)]
    local procedure HandleOnGetClientSecret(var ClientSecret: Text)
    begin
        ClientSecret := Format(CreateGuid());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Answer: Boolean)
    begin
        Answer := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Answer: Boolean)
    begin
        Answer := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DocExchServiceAuthPageHandler(var DocExchServiceAuth: TestPage "Doc. Exch. Service Auth.")
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure ActivateAppNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.AreEqual('To connect to the document exchange service, your administrator must activate the integration app.', Notification.Message(), 'Unexpected notification.');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure RenewTokenNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.AreEqual('The token for connecting to the document exchange service has expired.', Notification.Message(), 'Unexpected notification.');
    end;
}

