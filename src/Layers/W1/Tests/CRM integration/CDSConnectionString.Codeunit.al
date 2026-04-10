codeunit 139193 "CDS Connection String"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CDS Integration]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryUtility: Codeunit "Library - Utility";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        UserNameMustInclDomainErr: Label 'The user name must include the domain when the authentication type is set to Active Directory.';
        UserNameMustBeEmailErr: Label 'The user name must be a valid email address when the authentication type is set to Office 365.';
        IsNotFoundOnThePageErr: Label 'is not found on the page';
        PasswordConnectionStringFormatTxt: Label 'Url=%1; UserName=%2; Password=%3; ProxyVersion=%4; %5;', Locked = true;
        PasswordAuthTxt: Label 'AuthType=AD', Locked = true;
        ClientSecretConnectionStringFormatTxt: Label '%1; Url=%2; ClientId=%3; ClientSecret=%4; ProxyVersion=%5', Locked = true;
        ClientSecretAuthTxt: Label 'AuthType=ClientSecret', Locked = true;
        CertificateConnectionStringFormatTxt: Label '%1; Url=%2; ClientId=%3; Certificate=%4; ProxyVersion=%5', Locked = true;
        CertificateAuthTxt: Label 'AuthType=Certificate', Locked = true;
        UserTok: Label '{USER}', Locked = true;
        PasswordTok: Label '{PASSWORD}', Locked = true;
        ClientIdTok: Label '{CLIENTID}', Locked = true;
        ClientSecretTok: Label '{CLIENTSECRET}', Locked = true;
        CertificateTok: Label '{CERTIFICATE}', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AuthTypeDefaultO365ForDynamicsComAddress()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [UT]
        // [SCENARIO] Default "Auth Type" should be "O365" if "Server address" contains '.dynamics.com'
        Initialize();
        // [GIVEN] "Auth Type" =  'AD'
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::AD;

        // [WHEN] Validate 'Server Address' as 'https://somedomain.dynamics.com'
        CDSConnectionSetup.Validate("Server Address", 'https://somedomain.dynamics.com');

        // [THEN] "Auth Type" = 'O365'
        CDSConnectionSetup.TestField("Authentication Type", CDSConnectionSetup."Authentication Type"::Office365);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AuthTypeCanBeChangedFromO365ToAD()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [UT]
        // [SCENARIO] Auth Type can be changed to 'AD' if "Server address" contains '.dynamics.com'
        Initialize();
        // [GIVEN] 'Server Address' that contains '.dynamics.com' and "Auth Type" =  'O365'
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;
        CDSConnectionSetup."Server Address" := 'https://somedomain.dynamics.com';

        // [WHEN] Modify "Auth Type" to 'AD'
        CDSConnectionSetup.Validate("Authentication Type", CDSConnectionSetup."Authentication Type"::AD);

        // [THEN] "Auth Type" =  'AD'
        CDSConnectionSetup.TestField("Authentication Type", CDSConnectionSetup."Authentication Type"::AD);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AuthTypeDefaultADForNotDynamicsComAddress()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [UT]
        // [SCENARIO] Default "Auth Type" should be "AD" if "Server address" does not contain '.dynamics.com'
        Initialize();
        // [GIVEN] "Auth Type" =  'O365'
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;

        // [WHEN] Validate 'Server Address' as 'https://somedomain.com'
        CDSConnectionSetup.Validate("Server Address", 'https://somedomain.com');

        // [THEN] "Auth Type" =  'AD'
        CDSConnectionSetup.TestField("Authentication Type", CDSConnectionSetup."Authentication Type"::AD);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AuthTypeCanBeChangedFromADToO365()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [UT]
        // [SCENARIO] Auth Type can be changed to 'O365' if "Server address" does not contain '.dynamics.com'
        Initialize();
        // [GIVEN] 'Server Address' does not contain '.dynamics.com' and "Auth Type" =  'AD'
        CDSConnectionSetup."Server Address" := 'https://somedomain.com';
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::AD;

        // [WHEN] Modify "Auth Type" to 'O365'
        CDSConnectionSetup.Validate("Authentication Type", CDSConnectionSetup."Authentication Type"::Office365);

        // [THEN] "Auth Type" =  'O365'
        CDSConnectionSetup.TestField("Authentication Type", CDSConnectionSetup."Authentication Type"::Office365);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ServerAddressShouldBeHTTPS()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [Server Address]
        // [SCENARIO] "Server address" should start with 'https'
        Initialize();
        // [GIVEN] A connection setup
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;

        // [WHEN] Modify "Server address" to start with 'http'
        asserterror CDSConnectionSetup.Validate("Server Address", 'http://somedomain.dynamics.com');

        // [THEN] Error thrown
        Assert.ExpectedError('The application is set up to support secure connections (HTTPS) to the Dataverse environment only. You cannot use HTTP.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AuthTypeControlNotVisibleInSAAS()
    var
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [SaaS] [UI]
        Initialize();
        // [GIVEN] It is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [WHEN] Open CDS Connection Setup Page
        CDSConnectionSetupPage.OpenView();
        // [THEN] "Authentication Type" is not visible
        asserterror CDSConnectionSetupPage."Authentication Type".Activate();
        Assert.ExpectedError(IsNotFoundOnThePageErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AuthTypeControlVisibleInNotSAAS()
    var
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [UI]
        Initialize();
        // [GIVEN] It is not SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [WHEN] Open CDS Connection Setup Page
        CDSConnectionSetupPage.OpenView();
        // [THEN] "Authentication Type" is not visible
        Assert.IsTrue(CDSConnectionSetupPage."Authentication Type".Visible(), 'Authentication Type is not visible.')
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AuthTypeControlIsEditable()
    var
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [UI]
        Initialize();
        // [WHEN] Open CDS Connection Setup Page
        LibraryApplicationArea.DisableApplicationAreaSetup();
        CDSConnectionSetupPage.OpenEdit();
        // [THEN] "Authentication Type" is editable
        Assert.IsTrue(CDSConnectionSetupPage."Authentication Type".Editable(), 'Authentication Type is not editable.')
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UserNameMustIncludeDomainForAuthTypeAD()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [User Name]
        // [SCENARIO] "User Name" validation should fail if "Auth Type" is 'AD', but "Domain" is not defined
        Initialize();
        // [GIVEN] "Auth Type" =  'AD'
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::AD;
        // [WHEN] Validate "User Name" as 'admin'
        asserterror CDSConnectionSetup.Validate("User Name", 'admin');
        // [THEN] Error: 'User Name must include domain name for authentication type Active Directory'
        Assert.ExpectedError(UserNameMustInclDomainErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UserNameMustIncludeAtSymbolForAuthTypeO365()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [User Name]
        // [SCENARIO] "User Name" validation should fail if "Auth Type" is 'O365', but "User Name" does not contain '@'
        Initialize();
        // [GIVEN] "Auth Type" =  'O365'
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;
        // [WHEN] Validate "User Name" as 'admin'
        asserterror CDSConnectionSetup.Validate("User Name", 'admin');
        // [THEN] Error: 'User Name must be an e-mail address for authentication type Office 365'
        Assert.ExpectedError(UserNameMustBeEmailErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UserNameWithBackslashFillsDomain()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [Domain]
        // [SCENARIO] Validation of "User name" that contains '\' should fill "Domain"
        Initialize();
        // [GIVEN] "Authentication Type" is AD, "Domain" is blank
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::AD;
        CDSConnectionSetup.Domain := '';
        // [WHEN] Validate "User Name" as 'domain001\admin'
        CDSConnectionSetup.Validate("User Name", 'domain001\admin');
        // [THEN] "Domain" is 'domain001'
        CDSConnectionSetup.TestField(Domain, 'domain001');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UserNameWithoutBackslashBlanksDomain()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [Domain]
        // [SCENARIO] Validation of "User name" that does not contain '\' should blank "Domain"
        // [GIVEN] "Authentication Type" is O365, "Domain" is 'domain001'
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;
        CDSConnectionSetup.Domain := 'domain001';
        // [WHEN] Validate "User Name" as 'admin'
        CDSConnectionSetup.Validate("User Name", 'admin@domain.com');
        // [THEN] "Domain" is blank
        CDSConnectionSetup.TestField(Domain, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BlankedUserNameKeepDomainUnchanged()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [Domain]
        // [SCENARIO] Validation of "User name" as '' should keep "Domain" and "Authentication Type" unchnaged
        // [GIVEN] "Authentication Type" is AD, User Name is "domain001\user", "Domain" is 'domain001'
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::AD;
        CDSConnectionSetup."User Name" := 'domain001\user';
        CDSConnectionSetup.Domain := 'domain001';
        // [WHEN] Validate "User Name" as '' (needed for temp connection requiring admin credentials)
        CDSConnectionSetup.Validate("User Name", '');
        // [THEN] "User Name" is '', "Domain" is 'domain001', "Authentication Type" is AD
        CDSConnectionSetup.TestField("Authentication Type", CDSConnectionSetup."Authentication Type"::AD);
        CDSConnectionSetup.TestField("User Name", '');
        CDSConnectionSetup.TestField(Domain, 'domain001');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConnectionStringControlNotVisibleInSAAS()
    var
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Connection String] [SaaS] [UI]
        Initialize();
        // [GIVEN] It is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [WHEN] Open CDS Connection Setup Page
        CDSConnectionSetupPage.OpenView();
        // [THEN] "Connection String" is not visible
        asserterror CDSConnectionSetupPage."Connection String".Activate();
        Assert.ExpectedError(IsNotFoundOnThePageErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConnectionStringControlVisibleInNotSAAS()
    var
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Connection String] [UI]
        Initialize();
        // [GIVEN] It is not SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [WHEN] Open CDS Connection Setup Page
        CDSConnectionSetupPage.OpenView();
        // [THEN] "Connection String" is visible
        Assert.IsTrue(CDSConnectionSetupPage."Connection String".Visible(), 'Connection String is not visible.')
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConnectionStringControlNotEditableIfConnectionEnabledO365()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Connection String] [UI]
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [GIVEN] CDS Connection Setup "Is Enabled" is Yes
        CDSConnectionSetup."Is Enabled" := true;
        CDSConnectionSetup."User Name" := 'user@test.net';
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;
        CDSConnectionSetup.Insert();
        // [WHEN] Open CDS Connection Setup Page
        CDSConnectionSetupPage.OpenEdit();
        // [THEN] "Authentication Type" and "Connection String" are not editable
        Assert.IsFalse(CDSConnectionSetupPage."Connection String".Editable(), 'Connection String is editable.');
        Assert.IsFalse(CDSConnectionSetupPage."Authentication Type".Editable(), 'Authentication Type is editable.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConnectionStringControlNotEditableIfConnectionEnabledIFD()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Connection String] [UI]
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [GIVEN] CDS Connection Setup "Is Enabled" is Yes, "Authentication Type" = IFD
        CDSConnectionSetup."Is Enabled" := true;
        CDSConnectionSetup."User Name" := 'user@test.net';
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::IFD;
        CDSConnectionSetup.Insert();
        // [WHEN] Open CDS Connection Setup Page
        CDSConnectionSetupPage.OpenEdit();
        // [THEN] "Authentication Type" and "Connection String" are not editable
        Assert.IsFalse(CDSConnectionSetupPage."Connection String".Editable(), 'Connection String is editable.');
        Assert.IsFalse(CDSConnectionSetupPage."Authentication Type".Editable(), 'Authentication Type is editable.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConnectionStringControEditableIfConnectionDisabledOAuth()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Connection String] [UI]
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [GIVEN] CDS Connection Setup "Is Enabled" is No, "Authentication Type" = OAuth
        CDSConnectionSetup."Is Enabled" := false;
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::OAuth;
        CDSConnectionSetup.Insert();
        // [WHEN] Open CDS Connection Setup Page
        CDSConnectionSetupPage.OpenEdit();
        // [THEN] "Authentication Type" and "Connection String" are not editable
        Assert.IsTrue(CDSConnectionSetupPage."Connection String".Editable(), 'Connection String is not editable.');
        Assert.IsTrue(CDSConnectionSetupPage."Authentication Type".Editable(), 'Authentication Type is not editable.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConnectionStringControlNotEditableForO365AndAD()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Connection String] [UI]
        // [SCENARIO] "Connection String" control should not be editable if "Auth Type" is 'O365' or 'AD'
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [WHEN] Open CDS Connection Setup Page
        CDSConnectionSetupPage.OpenEdit();
        // [WHEN] "Auth Type" is 'O365'
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;
        CDSConnectionSetupPage."Authentication Type".Value(Format(CDSConnectionSetup."Authentication Type"));
        // [THEN] "Connection String" is not editable
        Assert.IsTrue(
          CDSConnectionSetupPage."Connection String".Editable(), 'Connection String is not editable for O365.');
        // [WHEN] "Auth Type" is 'AD'
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::AD;
        CDSConnectionSetupPage."Authentication Type".Value(Format(CDSConnectionSetup."Authentication Type"));
        // [THEN] "Connection String" is not editable
        Assert.IsTrue(
          CDSConnectionSetupPage."Connection String".Editable(), 'Connection String is not editable for AD.')
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConnectionStringControlEditableForOAuthAndIFD()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Connection String] [UI]
        // [SCENARIO] "Connection String" control should be editable if "Auth Type" is 'OAuth' or 'IFD'
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [WHEN] Open CDS Connection Setup Page
        CDSConnectionSetupPage.OpenEdit();
        // [WHEN] "Auth Type" is 'OAuth'
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::OAuth;
        CDSConnectionSetupPage."Authentication Type".Value(Format(CDSConnectionSetup."Authentication Type"));
        // [THEN] "Connection String" is editable
        Assert.IsTrue(
          CDSConnectionSetupPage."Connection String".Editable(), 'Connection String is not editable for OAuth.');
        // [WHEN] "Auth Type" is 'IFD'
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::IFD;
        CDSConnectionSetupPage."Authentication Type".Value(Format(CDSConnectionSetup."Authentication Type"));
        // [THEN] "Connection String" is editable
        Assert.IsTrue(
          CDSConnectionSetupPage."Connection String".Editable(), 'Connection String is not editable for IFD.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DefaultConnectionStringIncludesPwdPlaceholder()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
    begin
        // [FEATURE] [Connection String] [Password]
        // [SCENARIO] Default "Connection String" shows '{PASSWORD}' as a placeholder for real password
        // [GIVEN] "Auth Type" is 'O365'
        CDSConnectionSetup.DeleteAll();
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;
        // [WHEN] "User Name" is validated
        CDSConnectionSetup.Validate("User Name", 'admin@domain.com');
        CDSConnectionSetup.Insert();

        // [THEN] "Connection String" generated and contains '{PASSWORD}'
        Assert.ExpectedMessage('{PASSWORD}', CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConnectionStringForO365MatchesTemplate()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        ConnectionString: Text;
    begin
        // [FEATURE] [Connection String]
        // [SCENARIO] Default "Connection String" for 'O365' should match the O365 string template
        Initialize();
        // [GIVEN] "Server Address" is set, "Auth Type" is 'O365'
        CDSConnectionSetup.Validate("Server Address", 'https://somedomain.com');
        CDSConnectionSetup.Validate("Authentication Type", CDSConnectionSetup."Authentication Type"::Office365);
        // [WHEN] Validate "User Name"
        CDSConnectionSetup.Validate("User Name", 'admin@somedomain.com');
        CDSConnectionSetup.Insert();

        // [THEN] "Connection String" contains parameters: AuthType=O365, Url, Username, Password.
        ConnectionString := CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup);
        Assert.ExpectedMessage('AuthType=Office365', ConnectionString);
        Assert.ExpectedMessage(
          'Url=' + CDSConnectionSetup."Server Address", ConnectionString);
        Assert.ExpectedMessage(
          'UserName=' + CDSConnectionSetup."User Name", ConnectionString);
        Assert.ExpectedMessage('Password={PASSWORD}', ConnectionString);
        // [THEN] "Connection String" does not contain parameter: Domain.
        asserterror Assert.ExpectedMessage('Domain=', ConnectionString);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConnectionStringForADMatchesTemplate()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        ConnectionString: Text;
    begin
        // [FEATURE] [Connection String]
        // [SCENARIO] Default "Connection String" for 'AD' should match the AD string template
        Initialize();
        // [GIVEN] "Server Address" is set, "Auth Type" is 'AD'
        CDSConnectionSetup.Validate("Server Address", 'https://somedomain.com');
        CDSConnectionSetup.Validate("Authentication Type", CDSConnectionSetup."Authentication Type"::AD);
        // [WHEN] Validate "User Name"
        CDSConnectionSetup.Validate("User Name", 'somedomain\admin');
        CDSConnectionSetup.Insert();

        // [THEN] "Connection String" contains parameters: AuthType=O365, Url, Domain, Username, Password.
        ConnectionString := CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup);
        Assert.ExpectedMessage('AuthType=AD', ConnectionString);
        Assert.ExpectedMessage(
          'Url=' + CDSConnectionSetup."Server Address", ConnectionString);
        Assert.ExpectedMessage(
          'Domain=' + CDSConnectionSetup.Domain, ConnectionString);
        Assert.ExpectedMessage('UserName=admin', ConnectionString);
        Assert.ExpectedMessage('Password={PASSWORD}', ConnectionString);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConnectionStringForOAuthMatchesTemplate()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        ConnectionString: Text;
    begin
        // [FEATURE] [Connection String]
        // [SCENARIO] Default "Connection String" for 'OAuth' should match the OAuth string template
        Initialize();
        // [GIVEN] "Server Address" is set, "Auth Type" is 'OAuth'
        CDSConnectionSetup.Validate("Server Address", 'https://somedomain.com');
        CDSConnectionSetup.Validate("Authentication Type", CDSConnectionSetup."Authentication Type"::OAuth);
        // [WHEN] Validate "User Name"
        CDSConnectionSetup.Validate("User Name", 'admin@somedomain.com');
        CDSConnectionSetup.Insert();

        // [THEN] "Connection String" contains parameters: AuthType=OAuth, Url, Domain, Username, Password.
        ConnectionString := CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup);
        Assert.ExpectedMessage('AuthType=OAuth', ConnectionString);
        Assert.ExpectedMessage(
          'Url=' + CDSConnectionSetup."Server Address", ConnectionString);
        Assert.ExpectedMessage(
          'UserName=' + CDSConnectionSetup."User Name", ConnectionString);
        Assert.ExpectedMessage('Password={PASSWORD}', ConnectionString);
        // [THEN] "Connection String" contains parameters: AppId, RedirectUri, TokenCacheStorePath, LoginPrompt.
        Assert.ExpectedMessage('AppId= ;', ConnectionString);
        Assert.ExpectedMessage('RedirectUri= ;', ConnectionString);
        Assert.ExpectedMessage('TokenCacheStorePath= ;', ConnectionString);
        Assert.ExpectedMessage('LoginPrompt=Auto', ConnectionString);
        // [THEN] "Connection String" does not contain parameter: Domain.
        asserterror Assert.ExpectedMessage('Domain=', ConnectionString);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConnectionStringForIFDMatchesTemplate()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        ConnectionString: Text;
    begin
        // [FEATURE] [Connection String]
        // [SCENARIO] Default "Connection String" for 'IFD' should match the AD string template
        Initialize();
        // [GIVEN] "Server Address" is set, "Auth Type" is 'IFD'
        CDSConnectionSetup.Validate("Server Address", 'https://somedomain.com');
        CDSConnectionSetup.Validate("Authentication Type", CDSConnectionSetup."Authentication Type"::IFD);
        // [WHEN] Validate "User Name"
        CDSConnectionSetup.Validate("User Name", 'somedomain\admin');
        CDSConnectionSetup.Insert();

        // [THEN] "Connection String" contains parameters: AuthType=O365, Url, Domain, Username, Password.
        ConnectionString := CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup);
        Assert.ExpectedMessage('AuthType=IFD', ConnectionString);
        Assert.ExpectedMessage(
          'Url=' + CDSConnectionSetup."Server Address", ConnectionString);
        Assert.ExpectedMessage(
          'Domain=' + CDSConnectionSetup.Domain, ConnectionString);
        Assert.ExpectedMessage('UserName=admin', ConnectionString);
        Assert.ExpectedMessage('Password={PASSWORD}', ConnectionString);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CDSConnectionStringHandleLargeText()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        ConnectionStringValue: Text;
    begin
        // [FEATURE] [Connection String]
        // [SCENARIO 229446] Connection String can handle text > 250 symbols
        Initialize();

        // [WHEN] Text of length > 250 symbols assigned to CDS Connection String
        ConnectionStringValue := LibraryUtility.GenerateRandomText(300) + '{PASSWORD}';
        CDSIntegrationImpl.SetConnectionString(CDSConnectionSetup, ConnectionStringValue);
        CDSConnectionSetup.Insert();

        // [THEN] The text value is saved to CDS Connection Setup record
        Assert.ExpectedMessage(ConnectionStringValue, CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CDSConnectionCanBeEmpty()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        ConnectionStringValue: Text;
    begin
        // [FEATURE] [Connection String]
        // [SCENARIO 234959] Connection String can be empty
        Initialize();

        // [GIVEN] Connection String is filled
        ConnectionStringValue := LibraryUtility.GenerateRandomText(100) + '{PASSWORD}';
        CDSIntegrationImpl.SetConnectionString(CDSConnectionSetup, ConnectionStringValue);
        CDSConnectionSetup.Insert();
        Assert.ExpectedMessage(ConnectionStringValue, CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup));

        // [WHEN] Connection string is updated with empty value
        ConnectionStringValue := '';
        CDSIntegrationImpl.SetConnectionString(CDSConnectionSetup, ConnectionStringValue);
        CDSConnectionSetup.Find();
        // [THEN] No error appear and the value is saved
        Assert.AreEqual('', CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup), 'Wrong connection string value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatSDKVersionInConnectionStringWithPassword()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        OldConnectionString: Text;
        NewConnectionString: Text;
        OldVersion: Integer;
        NewVersion: Integer;
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO] Changing SDK version updates the connection string with the new version

        // [WHEN] SDK Version in CDS Connection Setup record is "8"
        OldVersion := 8;
        CDSConnectionSetup.DeleteAll();
        CDSConnectionSetup.Init();
        CDSConnectionSetup."Is Enabled" := false;
        CDSConnectionSetup."Server Address" := '@@test@@';
        CDSConnectionSetup."Proxy Version" := OldVersion;
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::AD;
        CDSConnectionSetup.Insert();
        OldConnectionString := StrSubstNo(PasswordConnectionStringFormatTxt, CDSConnectionSetup."Server Address", UserTok, PasswordTok, OldVersion, PasswordAuthTxt);
        CDSIntegrationImpl.SetConnectionString(CDSConnectionSetup, OldConnectionString);
        CDSConnectionSetup.Get();
        Assert.AreEqual(OldConnectionString, CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup), 'Unexpected old connection string');

        // [WHEN] SDK Version is set to "9.1"
        NewVersion := 91;
        CDSConnectionSetup.Validate("Proxy Version", NewVersion);
        CDSConnectionSetup.Modify();

        // [THEN] Proxy Version in CDS Connection Setup record is "9.1", other parts are unchanged
        CDSConnectionSetup.Get();
        NewConnectionString := StrSubstNo(PasswordConnectionStringFormatTxt, CDSConnectionSetup."Server Address", UserTok, PasswordTok, NewVersion, PasswordAuthTxt);
        Assert.AreEqual(NewConnectionString, CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup), 'Unexpected new connection string');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatSDKVersionInConnectionStringWithClientSecret()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        OldConnectionString: Text;
        NewConnectionString: Text;
        OldVersion: Integer;
        NewVersion: Integer;
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO] Changing SDK version updates the connection string with the new version

        // [WHEN] SDK Version in CDS Connection Setup record is "8"
        OldVersion := 8;
        CDSConnectionSetup.DeleteAll();
        CDSConnectionSetup.Init();
        CDSConnectionSetup."Is Enabled" := false;
        CDSConnectionSetup."Server Address" := '@@test@@';
        CDSConnectionSetup."Proxy Version" := OldVersion;
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;
        CDSConnectionSetup.Insert();
        OldConnectionString := StrSubstNo(ClientSecretConnectionStringFormatTxt, ClientSecretAuthTxt, CDSConnectionSetup."Server Address", ClientIdTok, ClientSecretTok, OldVersion);
        CDSIntegrationImpl.SetConnectionString(CDSConnectionSetup, OldConnectionString);
        CDSConnectionSetup.Get();
        Assert.AreEqual(OldConnectionString, CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup), 'Unexpected old connection string');

        // [WHEN] SDK Version is set to "9.1"
        NewVersion := 91;
        CDSConnectionSetup.Validate("Proxy Version", NewVersion);
        CDSConnectionSetup.Modify();

        // [THEN] Proxy Version in CDS Connection Setup record is "9.1", other parts are unchanged
        CDSConnectionSetup.Get();
        NewConnectionString := StrSubstNo(ClientSecretConnectionStringFormatTxt, ClientSecretAuthTxt, CDSConnectionSetup."Server Address", ClientIdTok, ClientSecretTok, NewVersion);
        Assert.AreEqual(NewConnectionString, CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup), 'Unexpected new connection string');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatSDKVersionInConnectionStringWithCertificate()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        OldConnectionString: Text;
        NewConnectionString: Text;
        OldVersion: Integer;
        NewVersion: Integer;
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO] Changing SDK version updates the connection string with the new version

        // [WHEN] SDK Version in CDS Connection Setup record is "8"
        OldVersion := 8;
        CDSConnectionSetup.DeleteAll();
        CDSConnectionSetup.Init();
        CDSConnectionSetup."Is Enabled" := false;
        CDSConnectionSetup."Server Address" := '@@test@@';
        CDSConnectionSetup."Proxy Version" := OldVersion;
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;
        CDSConnectionSetup.Insert();
        OldConnectionString := StrSubstNo(CertificateConnectionStringFormatTxt, CertificateAuthTxt, CDSConnectionSetup."Server Address", ClientIdTok, CertificateTok, OldVersion);
        CDSIntegrationImpl.SetConnectionString(CDSConnectionSetup, OldConnectionString);
        CDSConnectionSetup.Get();
        Assert.AreEqual(OldConnectionString, CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup), 'Unexpected old connection string');

        // [WHEN] SDK Version is set to "9.1"
        NewVersion := 91;
        CDSConnectionSetup.Validate("Proxy Version", NewVersion);
        CDSConnectionSetup.Modify();

        // [THEN] Proxy Version in CDS Connection Setup record is "9.1", other parts are unchanged
        CDSConnectionSetup.Get();
        NewConnectionString := StrSubstNo(CertificateConnectionStringFormatTxt, CertificateAuthTxt, CDSConnectionSetup."Server Address", ClientIdTok, CertificateTok, NewVersion);
        Assert.AreEqual(NewConnectionString, CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup), 'Unexpected new connection string');
    end;

    local procedure Initialize()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        CDSConnectionSetup.DeleteAll();
        LibraryApplicationArea.EnableFoundationSetup();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
