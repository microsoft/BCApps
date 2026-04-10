codeunit 139196 "CDS Connection Setup Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CDS Integration] [Connection Setup]
    end;

    var
        Assert: Codeunit Assert;
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryMockCRMConnection: Codeunit "Library - Mock CRM Connection";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        URLNeededErr: Label 'A URL is required.';
        URLNamePswNeededErr: Label 'A URL, user name and password are required.';
        OnlyBasicAppAreaMsg: Label 'You do not have access to this page, because your experience is set to Basic.';
        UnfavorableSolutionMsg: Label 'The base integration solution was not detected in Dataverse.';
        JobQueueEntryStatusOnHoldErr: Label 'Job Queue Entry status should be On Hold.';
        SetupSuccessfulMsg: Label 'The default setup for Dataverse synchronization has completed successfully.';
        ConnectionSuccessMsg: Label 'The connection test was successful. The settings are valid.';
        CRMIntegrationEnabledStateErr: Label 'CRMIntegrationEnabledState is wrong';
        ConnectionDisabledMsg: Label 'Connection to Dataverse is broken and that it has been disabled due to an error: %1', Comment = '%1=disable reason';
        CannotResolveUserFromConnectionSetupErr: Label 'The user that is specified in the Dataverse Connection Setup does not exist.';
        PasswordConnectionStringFormatTxt: Label 'Url=%1; UserName=%2; Password=%3; ProxyVersion=%4; %5;', Locked = true;
        PasswordAuthTxt: Label 'AuthType=Office365', Locked = true;
        ClientSecretConnectionStringFormatTxt: Label '%1; Url=%2; ClientId=%3; ClientSecret=%4; ProxyVersion=%5', Locked = true;
        ClientSecretAuthTxt: Label 'AuthType=ClientSecret', Locked = true;
        CertificateConnectionStringFormatTxt: Label '%1; Url=%2; ClientId=%3; Certificate=%4; ProxyVersion=%5', Locked = true;
        CertificateAuthTxt: Label 'AuthType=Certificate', Locked = true;
        UserTok: Label '{USER}', Locked = true;
        PasswordTok: Label '{PASSWORD}', Locked = true;
        ClientIdTok: Label '{CLIENTID}', Locked = true;
        ClientSecretTok: Label '{CLIENTSECRET}', Locked = true;
        CertificateTok: Label '{CERTIFICATE}', Locked = true;
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('AssistedSetupModalHandler,ConfirmYes')]
    [Scope('OnPrem')]
    procedure RunAssistedSetupFromNormalSetupRecordMissing()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [SCENARIO] CDS Connection Assisted Setup can be opened from CDS Connection Setup page
        Initialize();
        // [GIVEN] CDS Connection Setup record is missing
        CDSConnectionSetup.DeleteAll();
        // [GIVEN] CDS Connection Setup page is opened
        CDSConnectionSetupPage.OpenEdit();
        // [GIVEN] Server Address is "TEST"
        CDSConnectionSetupPage."Server Address".SetValue('TEST');

        // [WHEN] Assisted Setup is invoked
        CDSConnectionSetupPage."Assisted Setup".Invoke();

        // [THEN] CDS Connection Setup wizard is opened and Server Address = "TEST"
        // Wizard page is opened in AssistedSetupModalHandler
        Assert.ExpectedMessage(CDSConnectionSetupPage."Server Address".Value(), LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [HandlerFunctions('AssistedSetupModalHandler,ConfirmYes')]
    [Scope('OnPrem')]
    procedure RunAssistedSetupFromNormalSetupRecordExists()
    var
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [SCENARIO] CDS Connection Assisted Setup can be opened from CDS Connection Setup page
        Initialize();
        // [GIVEN] CDS Connection Setup record exists
        InitializeSetup(false);
        // [GIVEN] CDS Connection Setup page is opened
        CDSConnectionSetupPage.OpenEdit();
        // [GIVEN] Server Address is "TEST"
        CDSConnectionSetupPage."Server Address".SetValue('TEST');

        // [WHEN] Assisted Setup is invoked
        CDSConnectionSetupPage."Assisted Setup".Invoke();

        // [THEN] CDS Connection Setup wizard is opened and Server Address = "TEST"
        // Wizard page is opened in AssistedSetupModalHandler
        Assert.ExpectedMessage(CDSConnectionSetupPage."Server Address".Value(), LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoCDSConnectionOnCompanyOpen()
    var
        LogInManagement: Codeunit LogInManagement;
    begin
        // [FEATURE] [LogIn]
        // [SCENARIO] On opening the company there should be no attempt to connect to CDS
        // [GIVEN] CDS Connection is set, but not registered
        Initialize();
        RegisterTestTableConnection();
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST');
        Assert.AreEqual('', GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM), 'Default CRM connection');

        // [WHEN] COD40.CompanyOpen
        LogInManagement.CompanyOpen();
        // [THEN] Should be no registered CDS connection
        Assert.IsFalse(HasTableConnection(TABLECONNECTIONTYPE::CRM, ''), 'Should be no <blank> connection');
        Assert.IsFalse(HasTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST'), 'Should be no TEST connection');
        Assert.IsFalse(HasTableConnection(TABLECONNECTIONTYPE::CRM, 'CDS'), 'Should be no Dataverse connection');
        Assert.AreEqual('', GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM), 'Default CRM connection');
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,HandleDataEncryptionManagementPage')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DataEncryptionMgtPageShownIfPasswordFilled()
    var
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [UI] [Encryption]
        // [GIVEN] Encryption is disabled
        Initialize();
        // [GIVEN] CDS Connection is not enabled
        InitializeSetup(false);

        // [GIVEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenEdit();
        // [WHEN] Enter a new Password
        CDSConnectionSetupPage.Password.SetValue('password');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SavedProxyVersionOnOpenPage()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [UI] [SDK Version]
        Initialize();
        // [GIVEN] CDS Connection is not enabled
        InitializeSetup(false);
        CDSConnectionSetup.Get();
        // [GIVEN] Proxy Version has non-default value
        CDSConnectionSetup."Proxy Version" := 8;
        CDSConnectionSetup.Modify();

        // [GIVEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenView();

        // [THEN] Saved Proxy Version is presented
        CDSConnectionSetupPage."SDK Version".AssertEquals(8);
    end;

    [Test]
    [HandlerFunctions('ConfirmNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DefaultProxyVersionOnOpenPage()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
        LatestSDKVersion: Integer;
    begin
        // [FEATURE] [UI] [SDK Version]
        Initialize();
        // [GIVEN] CDS Connection is not enabled
        InitializeSetup(false);
        CDSConnectionSetup.Get();
        // [GIVEN] Proxy Version is not specified
        CDSConnectionSetup."Proxy Version" := 0;
        CDSConnectionSetup.Modify();

        // [GIVEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenView();

        // [THEN] The latest SDK proxy version is by default
        LatestSDKVersion := LibraryCRMIntegration.GetLastestSDKVersion();
        CDSConnectionSetupPage."SDK Version".AssertEquals(LatestSDKVersion);

        // [WHEN] Close CDS Connection Setup page
        CDSConnectionSetupPage.Close();
        CDSConnectionSetup.Get();
        // [THEN] Default Proxy Version is saved
        Assert.AreEqual(LatestSDKVersion, CDSConnectionSetup."Proxy Version", 'Default Proxy Version should be saved.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure ChangeServerAddressUpdatesConnectionString()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Connection String]
        // [SCENARIO] When Server Address is changed in page it is also changed in connection string
        Initialize();

        // [GIVEN] Connection is not enabled
        InitializeSetup(true);
        CDSConnectionSetup.Get();
        CDSConnectionSetup."Is Enabled" := false;
        CDSConnectionSetup.Modify();

        // [WHEN] Connection Setup page is opened
        CDSConnectionSetupPage.OpenEdit();
        // [WHEN] Server Address is changed
        CDSConnectionSetupPage."Server Address".SetValue('https://test.dynamics.com');
        // [THEN] Connection String is updated
        Assert.ExpectedMessage('Url=https://test.dynamics.com', CDSConnectionSetupPage."Connection String".Value());
        CDSConnectionSetupPage.Close();
        CDSConnectionSetup.Get();
        Assert.ExpectedMessage('Url=https://test.dynamics.com', CDSConnectionSetup."Connection String");
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure ChangeUserNameUpdatesConnectionString()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Connection String]
        // [SCENARIO] When User Name is changed in page it is also changed in connection string
        Initialize();

        // [GIVEN] Connection is not enabled
        InitializeSetup(true);
        CDSConnectionSetup.Get();
        CDSConnectionSetup."Is Enabled" := false;
        CDSConnectionSetup.Modify();

        // [WHEN] Connection Setup page is opened
        CDSConnectionSetupPage.OpenEdit();
        // [WHEN] User Name is changed
        CDSConnectionSetupPage."User Name".SetValue('user@test.dynamics.com');
        // [THEN] Connection String is updated
        Assert.ExpectedMessage('user@test.dynamics.com', CDSConnectionSetupPage."Connection String".Value());
        CDSConnectionSetupPage.Close();
        CDSConnectionSetup.Get();
        Assert.ExpectedMessage('user@test.dynamics.com', CDSConnectionSetup."Connection String");
    end;

    [Test]
    [HandlerFunctions('ConfirmNo')]
    [Scope('OnPrem')]
    procedure ChangePasswordDoesNotUpdateConnectionString()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Connection String]
        // [SCENARIO] When User Password is changed in page it is also changed in connection string
        Initialize();

        // [GIVEN] Connection is not enabled
        InitializeSetup(true);
        CDSConnectionSetup.Get();
        CDSConnectionSetup."Is Enabled" := false;
        CDSConnectionSetup.Modify();

        // [WHEN] Connection Setup page is opened
        CDSConnectionSetupPage.OpenEdit();
        // [WHEN] Password is changed
        CDSConnectionSetupPage.Password.SetValue('new password');
        // [THEN] Connection String is updated
        Assert.IsFalse(CDSConnectionSetupPage."Connection String".Value().Contains('new password'), 'Connection string is updted.');
    end;

    [Scope('OnPrem')]
    procedure CRMIntegrationEnabledStateWhenDisableConnection()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [CDS Connection Setup] [UT]
        // [SCENARIO] CRMIntegrationEnabledState <> Enabled when disable CDS Connection Setup
        // [GIVEN] CDS Connection Setup
        Initialize();
        RegisterTestTableConnection();
        LibraryCRMIntegration.EnsureCDSSystemUser();
        LibraryCRMIntegration.CreateCRMOrganization();
        // [GIVEN] CRMIntegrationEnabledState = Enabled
        Assert.IsTrue(CDSIntegrationImpl.IsIntegrationEnabled(), CRMIntegrationEnabledStateErr);

        // [WHEN] Disable the connection
        CDSConnectionSetup.Get();
        CDSConnectionSetup.Validate("Is Enabled", false);
        CDSConnectionSetup.Modify(true);

        // [THEN] CRMIntegrationEnabledState <> Enabled
        Assert.IsFalse(CDSIntegrationImpl.IsIntegrationEnabled(), CRMIntegrationEnabledStateErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SavedOwnershipModelOnOpenPage()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [UI] [Ownership Model]
        Initialize();
        // [GIVEN] CDS Connection is not enabled
        InitializeSetup(false);
        CDSConnectionSetup.Get();
        // [GIVEN] Ownership model is not specified
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Person;
        CDSConnectionSetup.Modify();

        // [GIVEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenView();

        // [THEN] Presented Ownership Model is team
        CDSConnectionSetupPage."Ownership Model".AssertEquals(CDSConnectionSetup."Ownership Model"::Person);
    end;

    [Test]
    [HandlerFunctions('ConfirmNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DefaultOwnershipModelOnOpenPage()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [UI] [Ownership Model]
        Initialize();
        // [GIVEN] CDS Connection is not enabled
        InitializeSetup(false);
        CDSConnectionSetup.Get();
        // [GIVEN] Ownership model is not specified
        Clear(CDSConnectionSetup."Ownership Model");
        CDSConnectionSetup.Modify();

        // [GIVEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenEdit();

        // [THEN] Presented Ownership Model is team
        CDSConnectionSetupPage."Ownership Model".AssertEquals(CDSConnectionSetup."Ownership Model"::Team);

        // [WHEN] Close CDS Connection Setup page
        CDSConnectionSetupPage.Close();
        CDSConnectionSetup.Get();
        // [THEN] Saved Ownership model is team
        Assert.AreEqual(CDSConnectionSetup."Ownership Model"::Team, CDSConnectionSetup."Ownership Model", 'Ownership Model should be team.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SavedCoupledBusinessUnitOnOpenPage()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [UI] [Coupled Business Unit]
        Initialize();
        // [GIVEN] CDS Connection is not enabled
        InitializeSetup(false);
        CDSConnectionSetup.Get();
        CDSConnectionSetup."Server Address" := '@@test@@';
        // [GIVEN] Coupled Business Unit is specified
        CDSConnectionSetup."Business Unit Id" := CreateGuid();
        CDSConnectionSetup."Business Unit Name" := 'Test Business Unit';
        CDSConnectionSetup.Modify();

        // [GIVEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenView();

        // [THEN] Coupled Business Unit is empty
        CDSConnectionSetupPage."Business Unit Name".AssertEquals('Test Business Unit');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DefaultCoupledBusinessUnitOnOpenPage()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
        EmptyGuid: Guid;
    begin
        // [FEATURE] [UI] [Coupled Business Unit]
        Initialize();
        // [GIVEN] CDS Connection is not enabled
        InitializeSetup(false);
        CDSConnectionSetup.Get();
        // [GIVEN] Servre Address is specified
        CDSConnectionSetup."Server Address" := '@@test@@';
        // [GIVEN] Coupled Business Unit is not specified
        CDSConnectionSetup."Business Unit Id" := EmptyGuid;
        CDSConnectionSetup."Business Unit Name" := '';
        CDSConnectionSetup.Modify();

        // [GIVEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenView();

        // [THEN] Coupled Business Unit is empty
        CDSConnectionSetupPage."Business Unit Name".AssertEquals(CDSIntegrationImpl.GetDefaultBusinessUnitName());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EmptyCoupledBusinessUnitOnOpenPage()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
        EmptyGuid: Guid;
    begin
        // [FEATURE] [UI] [Coupled Business Unit]
        Initialize();
        // [GIVEN] CDS Connection is not enabled
        InitializeSetup(false);
        CDSConnectionSetup.Get();
        // [GIVEN] Server Address is not specified
        CDSConnectionSetup."Server Address" := '';
        // [GIVEN] Coupled Business Unit is not specified
        CDSConnectionSetup."Business Unit Id" := EmptyGuid;
        CDSConnectionSetup."Business Unit Name" := '';
        CDSConnectionSetup.Modify();

        // [GIVEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenView();

        // [THEN] Coupled Business Unit name is empty
        CDSConnectionSetupPage."Business Unit Name".AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('ConfirmNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DefaultCoupledBusinessUnitOnChangeServerAddress()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
        EmptyGuid: Guid;
    begin
        // [FEATURE] [UI] [Coupled Business Unit]
        Initialize();
        // [GIVEN] CDS Connection is not enabled
        InitializeSetup(false);
        CDSConnectionSetup.Get();
        // [GIVEN] Server Address is specified
        CDSConnectionSetup."Server Address" := '@@test@@test@@';
        // [GIVEN] Coupled Business Unit is specified
        CDSConnectionSetup."Business Unit Id" := CreateGuid();
        CDSConnectionSetup."Business Unit Name" := 'Test Business Unit';
        CDSConnectionSetup.Modify();

        // [GIVEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenEdit();
        // [WHEN] Enter a new Server Address
        CDSConnectionSetupPage."Server Address".SetValue('@@test@@');

        // [THEN] Default Business Unit name is presented
        CDSConnectionSetupPage."Business Unit Name".AssertEquals(CDSIntegrationImpl.GetDefaultBusinessUnitName());

        // [WHEN] Close CDS Connection Setup page
        CDSConnectionSetupPage.Close();
        CDSConnectionSetup.Get();
        // [THEN] Empty Business Unit ID is saved
        Assert.AreEqual(EmptyGuid, CDSConnectionSetup."Business Unit Id", 'Business Unit ID should be empty.');
        // [THEN] Default Business Unit Name is saved
        Assert.AreEqual(CDSIntegrationImpl.GetDefaultBusinessUnitName(), CDSConnectionSetup."Business Unit Name", 'Business Unit name should be empty.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EmptyCoupledBusinessUnitOnClearServerAddress()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
        EmptyGuid: Guid;
    begin
        // [FEATURE] [UI] [Coupled Business Unit]
        Initialize();
        // [GIVEN] CDS Connection is not enabled
        InitializeSetup(false);
        // [GIVEN] Coupled Business Unit is not empty
        CDSConnectionSetup.Get();
        CDSConnectionSetup."Business Unit Id" := CreateGuid();
        CDSConnectionSetup."Business Unit Name" := 'Test Business Unit';
        CDSConnectionSetup.Modify();

        // [GIVEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenEdit();
        // [WHEN] Enter a new Server Address
        CDSConnectionSetupPage."Server Address".SetValue('');

        // [THEN] Coupled Business Unit name is set to default
        CDSConnectionSetupPage."Business Unit Name".AssertEquals('');

        // [WHEN] Close CDS Connection Setup page
        CDSConnectionSetupPage.Close();
        CDSConnectionSetup.Get();
        // [THEN] Saved Business Unit ID is empty
        Assert.AreEqual(EmptyGuid, CDSConnectionSetup."Business Unit Id", 'Business Unit ID should be empty.');
        // [THEN] Saved Business Unit name is set to default
        Assert.AreEqual('', CDSConnectionSetup."Business Unit Name", 'Business Unit name should be empty.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleDataEncryptionManagementPage(var DataEncryptionManagementPage: TestPage "Data Encryption Management")
    begin
        Assert.IsFalse(DataEncryptionManagementPage.EncryptionEnabledState.AsBoolean(), 'Encryption should be disabled on the page');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ServerAddressRequiredToEnableO365()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        DummyPassword: Text;
    begin
        // [FEATURE] [UT]
        Initialize();

        CDSConnectionSetup.DeleteAll();
        CDSConnectionSetup.Init();
        CDSConnectionSetup."User Name" := 'tester@domain.net';
        DummyPassword := 'T3sting!';
        CDSConnectionSetup.SetPassword(DummyPassword);
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;
        CDSConnectionSetup.Insert();

        asserterror CDSConnectionSetup.Validate("Is Enabled", true);
        Assert.ExpectedError(URLNeededErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ServerAddressRequiredToEnable()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        DummyPassword: Text;
    begin
        // [FEATURE] [UT]
        Initialize();

        CDSConnectionSetup.DeleteAll();
        CDSConnectionSetup.Init();
        CDSConnectionSetup."User Name" := 'tester@domain.net';
        DummyPassword := 'T3sting!';
        CDSConnectionSetup.SetPassword(DummyPassword);
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::AD;
        CDSConnectionSetup.Insert();

        asserterror CDSConnectionSetup.Validate("Is Enabled", true);
        Assert.ExpectedError(URLNamePswNeededErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InvokeResetConfigurationCreatesNewMappings()
    var
        JobQueueEntry: Record "Job Queue Entry";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSConnectionSetup: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Table Mapping] [UI]
        Initialize();

        // [GIVEN] Connection to CRM established
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        ConfigureCDS();

        // [GIVEN] No Integration Table Mapping records
        // [GIVEN] No Job Queue Entry records
        IntegrationTableMapping.DeleteAll(true);
        JobQueueEntry.DeleteAll();

        InitializeSetup(true);

        // [GIVEN] CDS Connection Setup page
        CDSConnectionSetup.OpenEdit();

        // [WHEN] "Use Default Synchronization Setup" action is invoked
        CDSConnectionSetup.ResetConfiguration.Invoke();

        // [THEN] Integration Table Mapping and Job Queue Entry tables are not empty
        Assert.AreNotEqual(0, IntegrationTableMapping.Count(), 'Expected the reset mappings to create new mappings');
        Assert.AreNotEqual(0, JobQueueEntry.Count(), 'Expected the reset mappings to create new job queue entries');

        // [THEN] Message "The default setup for CDS synchronization has completed successfully." appears
        Assert.ExpectedMessage(SetupSuccessfulMsg, LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UrlValidationIsNotCaseSensitive()
    var
        CDSConnectionSetup: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Server Address] [UI]
        // [SCENARIO] The user-entered server address URL is not case sensitive

        // [GIVEN] A camel case server address URL
        // [WHEN] The user sets the value
        Initialize();
        CDSConnectionSetup.OpenEdit();
        CDSConnectionSetup."Server Address".SetValue('https://CamelCaseUrl.crm4.dynamics.com');

        // [THEN] No confirm dialog pops-up asking to auro-replace the URL with the lowercase version
        // This test succeeds if no confirm dialog shows up to ask user for agreement to replace the URL.
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UrlValidationWhenMissingHTTPS()
    var
        CDSConnectionSetup: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Server Address] [UI]
        // [SCENARIO] The user-entered server address URL is prefixed with 'https://' if needed

        // [GIVEN] A server address URL
        // [WHEN] The user sets the value, omitting the beginning 'https://'
        Initialize();
        CDSConnectionSetup.OpenEdit();
        CDSConnectionSetup."Server Address".SetValue('company.crm4.dynamics.com');

        // [THEN] A confirmation dialog opens (the handler is exercised simulating the user clicking Yes)
        // [THEN] The URL is prefixed with 'https://'
        Assert.AreEqual('https://company.crm4.dynamics.com', CDSConnectionSetup."Server Address".Value(), 'Incorrect URL auto-completion');
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [Scope('OnPrem')]
    procedure CannotOpenPageIfAppAreaBasic()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        // [FEATURE] [UI]
        // [GIVEN] Application Area is set to Basic for the current user
        ApplicationAreaSetup.SetRange("User ID", UserId());
        ApplicationAreaSetup.DeleteAll();

        ApplicationAreaSetup.Init();
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, MaxStrLen(ApplicationAreaSetup."User ID"));
        ApplicationAreaSetup.Basic := true;
        ApplicationAreaSetup.Insert();
        ApplicationAreaMgmtFacade.SetupApplicationArea();

        // [WHEN] Open CDS Connection Setup page
        LibraryVariableStorage.Enqueue(OnlyBasicAppAreaMsg);
        asserterror PAGE.Run(PAGE::"CDS Connection Setup");

        // [THEN] A message: "You do not have access to this page." and silent error
        // handled by MessageDequeue
        Assert.ExpectedError('');
        LibraryApplicationArea.ClearApplicationAreaCache();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ActionSyncJobs()
    var
        CDSConnectionSetup: TestPage "CDS Connection Setup";
        JobQueueEntries: TestPage "Job Queue Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Action "Synch. Job Queue Entries" opens page with CRM synch. jobs.
        Initialize();
        // [GIVEN] CDS Connection Setup, where "Is Enabled" = Yes
        InitializeSetup(true);
        // [GIVEN] 4 Job Queue Entries: 2 are for CDS Integration
        InsertJobQueueEntries();
        // [WHEN] Run action "Synch. Job Queue Entries" on CDS Connection Setup page
        CDSConnectionSetup.OpenView();
        JobQueueEntries.Trap();
        CDSConnectionSetup."Synch. Job Queue Entries".Invoke();
        // [THEN] Page "Job Queue Entries" is open, where are 2 jobs
        Assert.IsTrue(JobQueueEntries.First(), 'First');
        Assert.IsTrue(JobQueueEntries.Next(), 'Second');
        Assert.IsFalse(JobQueueEntries.Next(), 'Third should fail');
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SolutionVersionDrillDownNotInstalled()
    var
        CDSSolution: Record "CDS Solution";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CDS Connection Setup page shows a message on drilldown if the solution is not installed
        Initialize();
        // [GIVEN] CDS Connection Setup, where "Is Enabled" = Yes
        RegisterTestTableConnection();
        // [GIVEN] CDS Base Integration Solution is not installed
        CDSSolution.DeleteAll();
        // [GIVEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenView();
        // [WHEN] DrillDown on "Solution Version" control
        LibraryVariableStorage.Enqueue(UnfavorableSolutionMsg);
        CDSConnectionSetupPage."Solution Version".DrillDown();
        // [THEN] The message: "Solution was not detected."
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('ConfirmNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SynchronizeNowNotConfirmed()
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] No sync should bne done if not confirming action "Synchronize Modified Records"
        Initialize();
        ConfigureCDS();
        // [GIVEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenEdit();
        // [GIVEN] Run "Synchronize Modified Records" action
        CDSConnectionSetupPage.SynchronizeNow.Invoke();
        // [WHEN] Answer No to confirmation
        // handled by ConfirmNo
        // [THEN] No sync is done
        Assert.AreEqual(0, IntegrationSynchJob.Count(), 'Expected zero jobs to be created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartInitialSynchAction()
    var
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
        CRMFullSynchReviewPage: TestPage "CRM Full Synch. Review";
    begin
        // [FEATURE] [UI]
        Initialize();
        ConfigureCDS();
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        // [GIVEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenEdit();
        // [WHEN] run action StartInitialSynch
        CRMFullSynchReviewPage.Trap();
        CDSConnectionSetupPage.StartInitialSynchAction.Invoke();
        // [THEN] CRMFullSynchReview page is open
        CRMFullSynchReviewPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CoupleUsersActionDisabled()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupTestPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [UI] [Salesperson]
        // [SCENARIO] Action "Couple Salespersons" should open CRM System User List, where coupling controls are enabled
        Initialize();
        RegisterTestTableConnection();

        // [GIVEN] Ownership model is Team
        CDSConnectionSetup.Get();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Team;
        CDSConnectionSetup.Modify();

        // [GIVEN] "CDS Connection Setup" page is open
        CDSConnectionSetupTestPage.OpenEdit();
        // [THEN] Action "Couple Salespersons" is disabled
        Assert.IsFalse(CDSConnectionSetupTestPage.CoupleUsers.Enabled(), 'Action is enabled.');
    end;

    [Test]
    [HandlerFunctions('CRMSystemUserListHandler')]
    [Scope('OnPrem')]
    procedure CoupleUsersActionOpensCRMSystemUsersList()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupTestPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [UI] [Salesperson]
        // [SCENARIO] Action "Couple Salespersons" should open CRM System User List, where coupling controls are enabled
        Initialize();
        RegisterTestTableConnection();

        // [GIVEN] Ownership model is Person
        CDSConnectionSetup.Get();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Person;
        CDSConnectionSetup.Modify();

        // [GIVEN] "CDS Connection Setup" page is open
        CDSConnectionSetupTestPage.OpenEdit();

        // [WHEN] Run action "Couple Salespersons"
        Assert.IsTrue(CDSConnectionSetupTestPage.CoupleUsers.Enabled(), 'Action is disabled.');
        CDSConnectionSetupTestPage.CoupleUsers.Invoke();

        // [THEN] CRM System User List is open, where Salesperson Code column is editable, action Couple is enabled
        // returned by CRMSystemUserListHandler
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Salesperson Code column should be editable.');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Couple action should be enabled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DisableJobQueueEntriesOnDisableConnection()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [SCENARIO] Disabling CDS Connection move all CDS Job Queue Entries in "On Hold" status
        Initialize();

        // [GIVEN] CDS Connection Setup with Integration Table Mapping and CDS Job Queue Entries
        RegisterTestTableConnection();
        CreateIntTableMappingWithJobQueueEntries();

        // [WHEN] Disable the connection
        CDSConnectionSetup.Get();
        CDSConnectionSetup.Validate("Is Enabled", false);
        CDSConnectionSetup.Modify(true);

        // [THEN] All CDS Job Queue Entries has Status = On Hold
        VerifyJobQueueEntriesStatusIsOnHold();
    end;


    [Test]
    [Scope('OnPrem')]
    procedure SDKVersionEnabled()
    var
        CDSConnectionSetup: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO] SDK Version selection is enabled when connection is not enabled
        Initialize();
        // [GIVEN] Connection is not enabled
        InitializeSetup(false);
        // [WHEN] Connection Setup opened and connection not enabled
        CDSConnectionSetup.OpenEdit();
        // [THEN] SDK Version field is enabled
        Assert.IsTrue(CDSConnectionSetup."SDK Version".Enabled(), 'Expected "SDK Version" field to be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SDKVersionDisabled()
    var
        CDSConnectionSetup: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO] SDK Version selection is disabled only when connection is enabled
        Initialize();
        // [GIVEN] Connection is enabled
        InitializeSetup(true);
        // [WHEN] Connection Setup opened
        CDSConnectionSetup.OpenEdit();
        // [THEN] SDK Version field is not enabled
        Assert.IsFalse(CDSConnectionSetup."SDK Version".Enabled(), 'Expected "SDK Version" field not to be enabled');
    end;

    [Test]
    [HandlerFunctions('ConnectionBrokenNotificationHandler,ConfirmYes')]
    [Scope('OnPrem')]
    procedure DisableConnectionNotificationConnectionSetup()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [SCENARIO] Verify Disable Reason is displayed in notification if connection was disabled
        Initialize();
        InitializeSetup(false);

        // [GIVEN] CRM Connection is disabled due to reason "ABC"
        CDSConnectionSetup.Get();
        CDSConnectionSetup."Disable Reason" := 'ABC';
        CDSConnectionSetup.Modify();

        // [WHEN] CDS Connection Setup page is opened
        CDSConnectionSetupPage.OpenEdit();

        // [THEN] Notification message includes connection disabled reason "ABC"
        Assert.AreEqual(
          StrSubstNo(ConnectionDisabledMsg, CDSConnectionSetup."Disable Reason"),
          LibraryVariableStorage.DequeueText(), 'Unexpected notification.');

        CDSConnectionSetupPage.Close();
    end;

    [Test]
    [HandlerFunctions('MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ActionTestConnectionWhenIntegrationEnabled()
    var
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Action "Test Connection" works when integration is enabled.
        Initialize();
        // [GIVEN] CDS Connection Setup, where "Is Enabled" = Yes
        RegisterTestTableConnection();
        // [GIVEN] Open CDS Connection Setup page

        CDSConnectionSetupPage.OpenEdit();
        // [WHEN] Run "Test Connection" action
        CDSConnectionSetupPage."Test Connection".Invoke();
        // [THEN] Expected message appears
        Assert.ExpectedMessage(ConnectionSuccessMsg, LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [HandlerFunctions('MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ActionTestConnectionWhenIntegrationDisabled()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
        DummyPassword: Text;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Action "Test Connection" works when integration is enabled.
        Initialize();
        // [GIVEN] Disabled CDS Connection
        InitializeSetup(false);
        CDSConnectionSetup.Get();
        DummyPassword := 'test';
        CDSConnectionSetup.SetPassword(DummyPassword);
        CDSConnectionSetup.Modify();
        // [GIVEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenEdit();

        // [WHEN] Run "Test Connection" action
        CDSConnectionSetupPage."Test Connection".Invoke();
        // [THEN] Expected message appears
        Assert.ExpectedMessage(ConnectionSuccessMsg, LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ActionIntegrationSolutionsDisabled()
    var
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Action "Integration Solutions" is disabled when integration is not enabled.
        Initialize();
        // [GIVEN] CDS Connection Setup, where "Is Enabled" = No
        InitializeSetup(false);

        // [WHEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenEdit();
        // [THEN] Action "Integration Solutions" is disabled
        Assert.IsFalse(CDSConnectionSetupPage."Integration Solutions".Enabled(), 'Action is enabled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ActionIntegrationUserRolesDisabled()
    var
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Action "Integration User Roles" is disabled when integration is not enabled.
        Initialize();
        // [GIVEN] CDS Connection Setup, where "Is Enabled" = No
        InitializeSetup(false);

        // [WHEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenEdit();
        // [THEN] Action "Integration User Roles" is disabled
        Assert.IsFalse(CDSConnectionSetupPage."Integration User Roles".Enabled(), 'Action is enabled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ActionIOwningTeamRolesDisabled()
    var
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Action "Owning Team Roles" is disabled when integration is not enabled.
        Initialize();
        // [GIVEN] CDS Connection Setup, where "Is Enabled" = No
        InitializeSetup(false);

        // [WHEN] Open CDS Connection Setup page
        CDSConnectionSetupPage.OpenEdit();
        // [THEN] Action "Owning Team Roles" is disabled
        Assert.IsFalse(CDSConnectionSetupPage."Owning Team Roles".Enabled(), 'Action is enabled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('SolutionsModalHandler')]
    [Scope('OnPrem')]
    procedure ActionIntegrationSolutions()
    var
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Action "Integration Solutions" opens page with the solutions.
        Initialize();
        // [GIVEN] CDS Connection Setup, where "Is Enabled" = Yes
        RegisterTestTableConnection();

        // [WHEN] Run action "Integration Solutions" on CDS Connection Setup page
        CDSConnectionSetupPage.OpenEdit();
        CDSConnectionSetupPage."Integration Solutions".Invoke();
        // [THEN] CDS Integration Solutions page is opened
        Assert.ExpectedMessage('Solutions', LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ActionIntegrationUserRoles()
    var
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Action "Integration User Roles" opens page with the user roles.
        Initialize();
        // [GIVEN] CDS Connection Setup, where "Is Enabled" = Yes
        RegisterTestTableConnection();

        // [WHEN] Run action "Integration User Roles" on CDS Connection Setup page
        CDSConnectionSetupPage.OpenEdit();
        asserterror CDSConnectionSetupPage."Integration User Roles".Invoke();

        // [THEN] CDS Integration User Roles page throws the specific error
        Assert.ExpectedError(CannotResolveUserFromConnectionSetupErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('TeamRolesModalHandler')]
    [Scope('OnPrem')]
    procedure ActionIOwningTeamRoles()
    var
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Action "Owning Team Roles" opens page with the team roles.
        Initialize();
        // [GIVEN] CDS Connection Setup, where "Is Enabled" = Yes
        RegisterTestTableConnection();

        // [WHEN] Run action "Owning Team Roles" on CDS Connection Setup page
        CDSConnectionSetupPage.OpenEdit();
        CDSConnectionSetupPage."Owning Team Roles".Invoke();
        // [THEN] CDS Owning Team Roles page is opened
        Assert.ExpectedMessage('TeamRoles', LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure UpdatSDKVersionInConnectionStringWithPassword()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
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
        OldConnectionString := StrSubstNo(PasswordConnectionStringFormatTxt, CDSConnectionSetup."Server Address", UserTok, PasswordTok, OldVersion, PasswordAuthTxt);
        CDSIntegrationImpl.SetConnectionString(CDSConnectionSetup, OldConnectionString);
        CDSConnectionSetup.Get();
        Assert.AreEqual(OldConnectionString, CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup), 'Unexpected old connection string');

        // [WHEN] SDK Version is set to "10.0"
        NewVersion := 100;
        CDSConnectionSetupPage.OpenEdit();
        CDSConnectionSetupPage."SDK Version".SetValue(NewVersion);
        CDSConnectionSetupPage.Close();

        // [THEN] Proxy Version in CDS Connection Setup record is "10.0", other parts are unchanged
        CDSConnectionSetup.Get();
        NewConnectionString := StrSubstNo(PasswordConnectionStringFormatTxt, CDSConnectionSetup."Server Address", UserTok, PasswordTok, NewVersion, PasswordAuthTxt);
        Assert.AreEqual(NewConnectionString, CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup), 'Unexpected new connection string');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure UpdatSDKVersionInConnectionStringWithClientSecret()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
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

        // [WHEN] SDK Version is set to "10.0"
        NewVersion := 100;
        CDSConnectionSetupPage.OpenEdit();
        CDSConnectionSetupPage."SDK Version".SetValue(NewVersion);
        CDSConnectionSetupPage.Close();

        // [THEN] Proxy Version in CDS Connection Setup record is "10.0", other parts are unchanged
        CDSConnectionSetup.Get();
        NewConnectionString := StrSubstNo(ClientSecretConnectionStringFormatTxt, ClientSecretAuthTxt, CDSConnectionSetup."Server Address", ClientIdTok, ClientSecretTok, NewVersion);
        Assert.AreEqual(NewConnectionString, CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup), 'Unexpected new connection string');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure UpdatSDKVersionInConnectionStringWithCertificate()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
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

        // [WHEN] SDK Version is set to "10.0"
        NewVersion := 100;
        CDSConnectionSetupPage.OpenEdit();
        CDSConnectionSetupPage."SDK Version".SetValue(NewVersion);
        CDSConnectionSetupPage.Close();

        // [THEN] Proxy Version in CDS Connection Setup record is "10.0", other parts are unchanged
        CDSConnectionSetup.Get();
        NewConnectionString := StrSubstNo(CertificateConnectionStringFormatTxt, CertificateAuthTxt, CDSConnectionSetup."Server Address", ClientIdTok, CertificateTok, NewVersion);
        Assert.AreEqual(NewConnectionString, CDSIntegrationImpl.GetConnectionString(CDSConnectionSetup), 'Unexpected new connection string');
    end;

    local procedure Initialize()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryVariableStorage.Clear();
        if CryptographyManagement.IsEncryptionEnabled() then
            CryptographyManagement.DisableEncryption(true);
        Assert.IsFalse(EncryptionEnabled(), 'Encryption should be disabled');

        CDSIntegrationMgt.ResetCache();
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, '');
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM));
        Assert.AreEqual('', GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM), 'DEFAULTTABLECONNECTION should not be registered');

        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();

        LibraryMockCRMConnection.MockConnection();

        if IsInitialized then
            exit;

        IsInitialized := true;
        SetTenantLicenseStateToTrial();
    end;

    local procedure CreateIntTableMappingWithJobQueueEntries()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        IntegrationTableMapping.DeleteAll();
        CreateTableMapping();
        JobQueueEntry.DeleteAll();
        InsertJobQueueEntries();
        InsertJobQueueEntriesWithError();
        IntegrationTableMapping.FindFirst();
        JobQueueEntry.ModifyAll("Record ID to Process", IntegrationTableMapping.RecordId());
    end;

    local procedure CreateTableMapping()
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Init();
        IntegrationTableMapping."Table ID" := DATABASE::Currency;
        IntegrationTableMapping."Integration Table ID" := DATABASE::"CRM Transactioncurrency";
        IntegrationTableMapping.Validate("Integration Table UID Fld. No.", CRMTransactioncurrency.FieldNo(TransactionCurrencyId));
        IntegrationTableMapping."Synch. Codeunit ID" := CODEUNIT::"CRM Integration Table Synch.";

        IntegrationTableMapping.Name := 'FIRST';
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        IntegrationTableMapping.Insert();

        IntegrationTableMapping.Name := 'SECOND';
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::Bidirectional;
        IntegrationTableMapping.Insert();
    end;

    local procedure InitializeSetup(IsEnabled: Boolean)
    begin
        InitializeSetup('@@test@@', IsEnabled);
    end;

    local procedure InitializeSetup(HostName: Text; IsEnabled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        DummyPassword: Text;
    begin
        CDSConnectionSetup.DeleteAll();
        CDSConnectionSetup.Init();
        CDSConnectionSetup."Server Address" := CopyStr(HostName, 1, MaxStrLen(CDSConnectionSetup."Server Address"));
        DummyPassword := 'T3sting!';
        if IsEnabled then
            CDSConnectionSetup.SetPassword(DummyPassword);
        CDSConnectionSetup."Is Enabled" := IsEnabled;
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Team;
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;
        CDSConnectionSetup.Validate("User Name", 'UserName@asEmail.net');
        CDSConnectionSetup.Insert();
    end;

    local procedure RegisterTestTableConnection()
    begin
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST');
        RegisterTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST', '@@test@@');
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST');
        InitializeSetup(true);
    end;

    local procedure InsertJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.DeleteAll();
        InsertJobQueueEntry(CODEUNIT::"Integration Synch. Job Runner", JobQueueEntry.Status::Ready);
        InsertJobQueueEntry(CODEUNIT::"Integration Synch. Job Runner", JobQueueEntry.Status::"In Process");
        InsertJobQueueEntry(CODEUNIT::"CRM Statistics Job", JobQueueEntry.Status::Ready);
    end;

    local procedure InsertJobQueueEntriesWithError()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        InsertJobQueueEntry(CODEUNIT::"CRM Statistics Job", JobQueueEntry.Status::Error);
    end;

    local procedure InsertJobQueueEntry(ID: Integer; Status: Option)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := ID;
        JobQueueEntry.Status := Status;
        JobQueueEntry.Insert();
    end;

    local procedure VerifyJobQueueEntriesStatusIsOnHold()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.FindSet();
        repeat
            Assert.IsTrue(JobQueueEntry.Status = JobQueueEntry.Status::"On Hold", JobQueueEntryStatusOnHoldErr);
        until JobQueueEntry.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageOk(Message: Text)
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageDequeue(Message: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CRMSystemUserListHandler(var CRMSystemuserList: TestPage "CRM Systemuser List")
    begin
        LibraryVariableStorage.Enqueue(CRMSystemuserList.SalespersonPurchaserCode.Editable());
        LibraryVariableStorage.Enqueue(CRMSystemuserList.Couple.Visible());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SDKVersionListModalHandler(var SDKVersionList: TestPage "SDK Version List")
    begin
        SDKVersionList.GotoKey(LibraryVariableStorage.DequeueInteger());
        SDKVersionList.OK().Invoke();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure ConnectionBrokenNotificationHandler(var ConnectionBrokenNotification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(ConnectionBrokenNotification.Message());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AssistedSetupModalHandler(var CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard")
    begin
        LibraryVariableStorage.Enqueue(CDSConnectionSetupWizard.ServerAddress.Value());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SolutionsModalHandler(var CDSIntegrationSolutions: TestPage "CDS Integration Solutions")
    begin
        LibraryVariableStorage.Enqueue('Solutions');
        Assert.IsTrue(CDSIntegrationSolutions.First(), 'first');
        Assert.IsFalse(CDSIntegrationSolutions.Next(), 'second');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TeamRolesModalHandler(var CDSIntegrationUserRoles: TestPage "CDS Owning Team Roles")
    begin
        LibraryVariableStorage.Enqueue('TeamRoles');
    end;

    local procedure SetTenantLicenseStateToTrial()
    var
        TenantLicenseState: Record "Tenant License State";
    begin
        TenantLicenseState."Start Date" := CurrentDateTime();
        TenantLicenseState.State := TenantLicenseState.State::Trial;
        TenantLicenseState.Insert();
    end;

    local procedure ConfigureCDS()
    begin
        RegisterTestTableConnection();
        LibraryCRMIntegration.EnsureCDSSystemUser();
    end;
}
