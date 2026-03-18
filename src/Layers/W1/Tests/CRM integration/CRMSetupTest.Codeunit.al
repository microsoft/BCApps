codeunit 139160 "CRM Setup Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Connection Setup]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        URLNamePswNeededErr: Label 'A %1 URL and user name are required to enable a connection';
        ConnectionErr: Label 'The connection setup cannot be validated. Verify the settings and try again.';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        OnlyBasicAppAreaMsg: Label 'You do not have access to this page, because your experience is set to Basic.';
        UnfavorableCRMSolutionInstalledMsg: Label 'The %1 Integration Solution was not detected.';
        FavorableCRMSolutionInstalledMsg: Label 'The %1 Integration Solution is installed in %2.';
        WebClientUrlResetMsg: Label 'The %1 Web Client URL has been reset to the default value.';
        ConnectionSuccessMsg: Label 'The connection test was successful';
        LCYMustMatchBaseCurrencyErr: Label '%1 does not match any ISO Currency Code in the Dataverse currency table.', Comment = '%1 - ISO currency code';
        CRMSetupTest: Codeunit "CRM Setup Test";
        JobQueueEntryStatusReadyErr: Label 'Job Queue Entry status should be Ready.';
        JobQueueEntryStatusOnHoldErr: Label 'Job Queue Entry status should be On Hold.';
        CRMSOIntegrationDisabledMsg: Label 'Sales Order Integration with %1 is disabled.';
        CRMProductName: Codeunit "CRM Product Name";
        SetupSuccessfulMsg: Label 'The default setup for %1 synchronization has completed successfully.';
        NotMatchCurrencyCodeErr: Label 'To continue, make sure that the local currency code in General Ledger Setup complies with the ISO standard and create a currency in Dataverse currency table that uses it as ISO Currency Code.';
        CRMIntegrationEnabledStateErr: Label 'CRMIntegrationEnabledState is wrong';
        ConnectionDisabledMsg: Label 'Connection to Dynamics 365 is broken and that it has been disabled due to an error: %1';
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
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure NoCRMConnectionOnCompanyOpen()
    var
        LogInManagement: Codeunit LogInManagement;
    begin
        // [FEATURE] [LogIn]
        // [SCENARIO] On opening the company there should be no attempt to connect to CRM
        // [GIVEN] CRM Connection is set, but not registered
        Initialize();
        LibraryCRMIntegration.RegisterTestTableConnection();
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST');
        Assert.AreEqual('', GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM), 'Default CRM connection');

        // [WHEN] COD40.CompanyOpen
        LogInManagement.CompanyOpen();
        // [THEN] Should be no registered CRM connection
        Assert.IsFalse(HasTableConnection(TABLECONNECTIONTYPE::CRM, ''), 'Should be no <blank> connection');
        Assert.IsFalse(HasTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST'), 'Should be no TEST connection');
        Assert.AreEqual('', GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM), 'Default CRM connection');
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,HandleDataEncryptionManagementPage')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DataEncryptionMgtPageShownIfPwdFilled()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI] [Encryption]
        // [GIVEN] Encryption is disabled
        Initialize();
        // [GIVEN] CRM Connection is not enabled
        InitSetup(false, '');

        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit();
        // [WHEN] Enter a new Password
        CRMConnectionSetupPage.Password.SetValue('password');
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
    procedure IsCRMIntegrationEnabled()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [CRM Integration Management]
        // [SCENARIO] IsCRMIntegrationEnabled() returns if CRM Integration is enabled
        Initialize();

        // [GIVEN] Disabled or Missing CRM Connection
        // [WHEN] Asking if CRM Integration Is Enabled
        // [THEN] Response is false
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM));
        Assert.IsFalse(CRMIntegrationManagement.IsCRMIntegrationEnabled(), 'Did not expect integration to be enabled');

        LibraryCRMIntegration.CreateCRMConnectionSetup('', 'host', false);
        Assert.IsFalse(CRMIntegrationManagement.IsCRMIntegrationEnabled(), 'Did not expect integration to be enabled');

        // [GIVEN] Enabled CRM Connection
        LibraryCRMIntegration.ResetEnvironment();
        // [GIVEN] CRM Connection is registered
        LibraryCRMIntegration.ConfigureCRM();
        // [WHEN] Asking if CRM Integration Is Enabled
        CRMIntegrationManagement.ClearState();
        Assert.IsTrue(
          CRMIntegrationManagement.IsCRMIntegrationEnabled(),
          'Expected Integration to be enabled when a connection is enabled and registered.');
        // [THEN] Response is TRUE

        // [GIVEN] Enabled CRM Connection
        // [GIVEN] CRM Connection is not registered
        CRMConnectionSetup.Get();
        CRMConnectionSetup.TestField("Is Enabled", true);
        CRMConnectionSetup.UnregisterConnection();
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM));

        // [WHEN] Asking if CRM Integration Is Enabled
        CRMIntegrationManagement.ClearState();
        Assert.IsTrue(
          CRMIntegrationManagement.IsCRMIntegrationEnabled(),
          'Expected Integration to be enabled when a connection is enabled but not registered.');
        // [THEN] Response is TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsCRMIntegrationEnabledValidConnectionFailedOnStart()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [CRM Integration Management] [Restore Connection]
        // [SCENARIO] IsCRMIntegrationEnabled() not enabled connection, if CRMConnectionSetup."Restore Connection" is 'Yes' and connection setup is valid, but failed.
        Initialize();

        // [GIVEN] Valid CRM Connection is disabled, "Restore Connection" is 'Yes'
        InitSetup(true, '');
        LibraryCRMIntegration.RegisterTestTableConnection();
        LibraryCRMIntegration.EnsureCRMSystemUser();
        LibraryCRMIntegration.CreateCRMOrganization();
        MockCRMConnectionSetupWithEnableValidConnection();

        // [GIVEN] "LCY Code" doesn't match ISO code og CRM base currency (cause failure on connection enabling)
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := 'XXX';
        GeneralLedgerSetup.Modify();

        // [WHEN] running IsCRMIntegrationEnabled()
        CRMIntegrationManagement.ClearState();
        asserterror CRMIntegrationManagement.IsCRMIntegrationEnabled();
        // [THEN] Runtime error on enabling connection: '...does not match ISO Currency Code...'
        Assert.ExpectedError(NotMatchCurrencyCodeErr);
        // [THEN] Response is 'Yes', "Is Enabled" is 'No', "Restore Connection" is 'No'
        CRMConnectionSetup.Get();
        CRMConnectionSetup.TestField("Restore Connection", false);
        CRMConnectionSetup.TestField("Is Enabled", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsCRMIntegrationEnabledValidConnectionOnStart()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [CRM Integration Management] [Restore Connection]
        // [SCENARIO] IsCRMIntegrationEnabled() enabled connection, if CRMConnectionSetup."Restore Connection" is 'Yes' and connection setup is valid.
        Initialize();

        // [GIVEN] CRM Connection is disabled, "Restore Connection" is 'Yes'
        // [GIVEN] CRM Connection is valid
        LibraryCRMIntegration.RegisterTestTableConnection();
        LibraryCRMIntegration.EnsureCRMSystemUser();
        LibraryCRMIntegration.CreateCRMOrganization();
        MockCRMConnectionSetupWithEnableValidConnection();

        // [WHEN] running IsCRMIntegrationEnabled()
        CRMIntegrationManagement.ClearState();
        Assert.IsTrue(
          CRMIntegrationManagement.IsCRMIntegrationEnabled(),
          'Expected Integration to be enabled.');

        // [THEN] Response is 'Yes', "Is Enabled" is 'Yes', "Restore Connection" is 'No'
        CRMConnectionSetup.Get();
        CRMConnectionSetup.TestField("Restore Connection", false);
        CRMConnectionSetup.TestField("Is Enabled", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsCRMIntegrationEnabledInvalidConnectionOnStart()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [CRM Integration Management] [Restore Connection]
        // [SCENARIO] IsCRMIntegrationEnabled() does not enable connection, if CRMConnectionSetup."Restore Connection" is 'Yes', but connection setup is invalid.
        Initialize();

        // [GIVEN] CRM Connection is disabled, "Restore Connection" is 'Yes'
        // [GIVEN] CRM Connection is invalid (failing on connection test)
        MockCRMConnectionSetupWithEnableValidConnection();

        // [WHEN] running IsCRMIntegrationEnabled()
        CRMIntegrationManagement.ClearState();
        Assert.IsFalse(
          CRMIntegrationManagement.IsCRMIntegrationEnabled(),
          'Expected Integration to be disabled.');

        // [THEN] Response is 'No', "Is Enabled" is 'No', "Restore Connection" is 'No'
        CRMConnectionSetup.Get();
        CRMConnectionSetup.TestField("Restore Connection", false);
        CRMConnectionSetup.TestField("Is Enabled", false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RegisterConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionName: Code[10];
    begin
        Initialize();

        ConnectionName := 'No. 1';
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionName);

        // Get a disabled and unregistered connection
        LibraryCRMIntegration.CreateCRMConnectionSetup(ConnectionName, 'invalid.dns.int', false);
        AssertConnectionNotRegistered(ConnectionName);

        // Enable it without registering it
        CRMConnectionSetup.Get(ConnectionName);
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup.Modify(false);

        AssertConnectionNotRegistered(ConnectionName);

        // Register
        CRMConnectionSetup.RegisterConnection();
        // Second attempt of registration skips registration if it exists
        CRMConnectionSetup.RegisterConnection();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UnregisterConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionName: Code[10];
    begin
        Initialize();

        ConnectionName := 'No. 1';
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionName);

        // Get an enabled and registered connection
        LibraryCRMIntegration.CreateCRMConnectionSetup(ConnectionName, 'invalid.dns.int', true);
        CRMConnectionSetup.Get(ConnectionName);
        CRMConnectionSetup.RegisterConnection();

        // Unregister and check
        CRMConnectionSetup.UnregisterConnection();
        AssertConnectionNotRegistered(ConnectionName);
    end;

    [Test]
    [HandlerFunctions('ConfirmNo')]
    [Scope('OnPrem')]
    procedure ConnectionRegistrationMirrorsEnabledCheckbox()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        Initialize();
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryCRMIntegration.RegisterTestTableConnection();
        // [GIVEN] There is no connection to CRM
        CRMConnectionSetup.UnregisterConnection();
        Assert.IsFalse(HasTableConnection(TABLECONNECTIONTYPE::CRM, ''), 'HASTABLECONNECTION before');

        // [WHEN] Enter details in the setup page and enable the connection
        CRMConnectionSetupPage.OpenEdit();
        CRMConnectionSetupPage."Server Address".SetValue('@@test@@');
        CRMConnectionSetupPage."Authentication Type".SetValue('OAuth 2.0');
        CRMConnectionSetupPage."User Name".SetValue('tester@domain.net');
        CRMConnectionSetupPage.Password.SetValue('T3sting!');
        CRMConnectionSetupPage."Is Enabled".SetValue(true);
        // [THEN] Connection is enabled
        Assert.IsTrue(HasTableConnection(TABLECONNECTIONTYPE::CRM, ''), 'HASTABLECONNECTION when enabled');

        // [WHEN] Disable the connection on the page
        CRMConnectionSetupPage."Is Enabled".SetValue(false);
        CRMConnectionSetupPage.Close();
        // [THEN] Connection is disabled
        Assert.IsFalse(HasTableConnection(TABLECONNECTIONTYPE::CRM, ''), 'HASTABLECONNECTION when disabled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ServerAddressRequiredToEnable()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        DummyPassword: Text;
    begin
        // [FEATURE] [UT]
        Initialize();

        CRMConnectionSetup.Init();
        CRMConnectionSetup."User Name" := 'tester@domain.net';
        DummyPassword := 'T3sting!';
        CRMConnectionSetup.SetPassword(DummyPassword);
        CRMConnectionSetup.Insert();

        asserterror CRMConnectionSetup.Validate("Is Enabled", true);
        Assert.ExpectedError(StrSubstNo(URLNamePswNeededErr, CRMProductName.SHORT()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UserNameRequiredToEnable()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        DummyPassword: Text;
    begin
        // [FEATURE] [UT]
        Initialize();

        CRMConnectionSetup.Init();
        CRMConnectionSetup."Server Address" := '@@test@@';
        DummyPassword := 'T3sting!';
        CRMConnectionSetup.SetPassword(DummyPassword);
        CRMConnectionSetup.Insert();

        asserterror CRMConnectionSetup.Validate("Is Enabled", true);
        Assert.ExpectedError(StrSubstNo(URLNamePswNeededErr, CRMProductName.SHORT()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure WorkingConnectionRequiredToEnable()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        DummyPassword: Text;
    begin
        // [FEATURE] [UT]
        Initialize();
        LibraryCRMIntegration.UnbindMockConnection();

        // Enter details in the page and enable the connection
        CRMConnectionSetup.Init();
        CRMConnectionSetup."Server Address" := 'https://nocrmhere.gov';
        CRMConnectionSetup.Validate("User Name", 'tester@domain.net');
        DummyPassword := 'T3sting!';
        CRMConnectionSetup.SetPassword(DummyPassword);
        CRMConnectionSetup.Insert();

        asserterror CRMConnectionSetup.Validate("Is Enabled", true);
        Assert.ExpectedError(ConnectionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnableConnectionCanResetIntegrationTableMappingsIfEmpty()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [Table Mapping] [UI]
        Initialize();
        LibraryCRMIntegration.RegisterTestTableConnection();
        LibraryCRMIntegration.EnsureCRMSystemUser();
        LibraryCRMIntegration.CreateCRMOrganization();
        // [GIVEN] Table Mapping is empty
        Assert.TableIsEmpty(DATABASE::"Integration Table Mapping");

        // [GIVEN] Connection is disabled
        CRMConnectionSetup.DeleteAll();
        InitSetup(false, '');

        // [WHEN] Enable the connection
        CRMConnectionSetup.Get();
        CRMConnectionSetup.Validate("Is Enabled", true);

        // [THEN] Table Mapping is filled
        Assert.TableIsNotEmpty(DATABASE::"Integration Table Mapping");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EnableDisableConnectionUpdatesBaseCurrencyData()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMOrganization: Record "CRM Organization";
    begin
        // [FEATURE] [Currency] [UT]
        // [SCENARIO] CRM Connection Setup collects(clears) base currency data from CRM Organization if connection enabled(disabled)
        Initialize();
        LibraryCRMIntegration.ConfigureCRM();

        // [GIVEN] CRM Organization, where BaseCurrencySymbol = 'ABC', BaseCurrencyId = 'X', BaseCurrencyPrecision = 2
        LibraryCRMIntegration.CreateCRMOrganizationWithCurrencyPrecision(2);
        CRMConnectionSetup.Get();
        // [GIVEN] CRM Connection Setup, where BaseCurrencySymbol = '', BaseCurrencyId = <null>, BaseCurrencyPrecision = 0
        Clear(CRMOrganization);
        VerifyCurrencyData(CRMConnectionSetup, CRMOrganization);

        // [WHEN] Enable connection on CRM Connection Setup
        CRMConnectionSetup.Validate("Is Enabled", true);

        // [THEN] CRM Connection Setup, where BaseCurrencySymbol = 'ABC', BaseCurrencyId = 'X', BaseCurrencyPrecision = 2
        CRMOrganization.FindFirst();
        VerifyCurrencyData(CRMConnectionSetup, CRMOrganization);

        // [WHEN] Disable connection on CRM Connection Setup
        CRMConnectionSetup.Validate("Is Enabled", false);

        // [THEN] CRM Connection Setup, where BaseCurrencySymbol = '', BaseCurrencyId = <null>, BaseCurrencyPrecision = 0
        Clear(CRMOrganization);
        VerifyCurrencyData(CRMConnectionSetup, CRMOrganization);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EnableConnectionShouldFailIfBaseCurrencyNotEqualLCY()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMOrganization: Record "CRM Organization";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        GLSetup: Record "General Ledger Setup";
        User: Record User;
        DummyPassword: Text;
    begin
        // [FEATURE] [Currency] [LCY] [UT]
        // [SCENARIO] Connection cannot be enabled if CRM base currencydoes not match LCY
        Initialize();
        User.ModifyAll("Authentication Email", '');
        LibraryCRMIntegration.ConfigureCRM();

        // [GIVEN] CRM Organization, where "BaseCurrencyId" = 'X'
        LibraryCRMIntegration.CreateCRMOrganizationWithCurrencyPrecision(2);
        // [GIVEN] CRM Transactioncurrency 'X', where "ISO Currency Code" = 'USD'
        CRMOrganization.FindFirst();
        CRMTransactioncurrency.Get(CRMOrganization.BaseCurrencyId);
        CRMTransactioncurrency.ISOCurrencyCode := 'USD';
        CRMTransactioncurrency.Modify();

        // [GIVEN] LCY is 'GBP'
        GLSetup.Get();
        GLSetup."LCY Code" := 'GBP';
        GLSetup.Modify();

        // [GIVEN] CRM Connection Setup is set, but not enabled
        LibraryCRMIntegration.CreateCRMConnectionSetup('', '@@test@@', false);
        CRMConnectionSetup.Get();
        DummyPassword := 'value';
        CRMConnectionSetup.SetPassword(DummyPassword);
        CRMConnectionSetup.Modify();

        // [WHEN] Enable connection on CRM Connection Setup
        asserterror CRMConnectionSetup.Validate("Is Enabled", true);

        // [THEN] Error message: "LCY Code GBP does not match any ISO Currency Code in the Dataverse currency table."
        Assert.ExpectedError(
          StrSubstNo(LCYMustMatchBaseCurrencyErr, GLSetup."LCY Code"));
    end;

    [Test]
    [HandlerFunctions('MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CanTestConnectionWhenNotIsEnabled()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        DummyPassword: Text;
    begin
        Initialize();
        LibraryCRMIntegration.RegisterTestTableConnection();
        LibraryCRMIntegration.EnsureCRMSystemUser();
        CRMConnectionSetup.DeleteAll();
        CRMConnectionSetup.Init();
        CRMConnectionSetup."Server Address" := '@@test@@';
        CRMConnectionSetup.Validate("User Name", 'tester@domain.net');
        DummyPassword := 'value';
        CRMConnectionSetup.SetPassword(DummyPassword);
        CRMConnectionSetup.Insert();

        CRMConnectionSetup.PerformTestConnection();
    end;

    [Test]
    [HandlerFunctions('CRMOptionMappingModalHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntTableUIDFieldTypeShowsTypeOnListPage()
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        IntegrationTableMapping: Record "Integration Table Mapping";
        ShippingAgent: Record "Shipping Agent";
        IntegrationTableMappingList: TestPage "Integration Table Mapping List";
    begin
        // [FEATURE] [Option Mapping] [UI]
        Initialize();

        // [GIVEN] Two Table Mappings, where "Integration Table UID Fld. No." is of type GUID and Option.
        IntegrationTableMapping.DeleteAll(true);

        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := '1';
        IntegrationTableMapping."Table ID" := DATABASE::Customer;
        IntegrationTableMapping."Integration Table ID" := DATABASE::"CRM Account";
        IntegrationTableMapping.Validate("Integration Table UID Fld. No.", 1);
        IntegrationTableMapping.Insert(true);

        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := '2';
        IntegrationTableMapping."Table ID" := DATABASE::"Shipping Agent";
        IntegrationTableMapping."Integration Table ID" := DATABASE::"CRM Account";
        IntegrationTableMapping.Validate("Integration Table UID Fld. No.", 16);
        IntegrationTableMapping.Insert(true);

        // [GIVEN] The mapping to the option field has one related record in "CRM Option Mapping" table
        ShippingAgent.Init();
        ShippingAgent.Code := LibraryUtility.GenerateGUID();
        ShippingAgent.Insert();

        CRMOptionMapping.Init();
        CRMOptionMapping."Record ID" := ShippingAgent.RecordId;
        CRMOptionMapping."Table ID" := DATABASE::"Shipping Agent";
        CRMOptionMapping."Option Value" := -1;
        CRMOptionMapping."Option Value Caption" := Format(CRMOptionMapping."Option Value") + ShippingAgent.Code;
        CRMOptionMapping.Insert();
        // Expected values for CRMOptionMappingModalHandler
        LibraryVariableStorage.Enqueue(Format(ShippingAgent.RecordId));
        LibraryVariableStorage.Enqueue(CRMOptionMapping."Option Value");
        LibraryVariableStorage.Enqueue(CRMOptionMapping."Option Value Caption");

        // [WHEN] Open page "Integration Table Mapping List" in edit mode
        IntegrationTableMappingList.OpenEdit();

        // [THEN] "Integration Field" and "Integration Field Type" columns are not enabled
        Assert.IsFalse(
          IntegrationTableMappingList.IntegrationFieldCaption.Editable(),
          'IntegrationFieldCaption should not be enabled');
        Assert.IsFalse(
          IntegrationTableMappingList.IntegrationFieldType.Editable(),
          'IntegrationFieldType should not be enabled');
        // [THEN] Two records, where "Integration Field Type" is 'GUID' and 'Option'
        IntegrationTableMappingList.IntegrationFieldType.AssertEquals('GUID');
        // [THEN] Drill Down on "Integration Field" of 'GUID' type does nothing
        IntegrationTableMappingList.IntegrationFieldCaption.DrillDown();
        IntegrationTableMappingList.Next();
        IntegrationTableMappingList.IntegrationFieldType.AssertEquals('Option');
        // [THEN] Drill Down on "Integration Field" of 'Option' field opens "CRM Option Mapping" page
        IntegrationTableMappingList.IntegrationFieldCaption.DrillDown();
        // verified by CRMOptionMappingModalHandler
        IntegrationTableMappingList.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InvokeResetConfigurationCreatesNewMappings()
    var
        JobQueueEntry: Record "Job Queue Entry";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Table Mapping] [UI]
        Initialize();

        // [GIVEN] Connection to CRM established
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryCRMIntegration.ConfigureCRM();

        // [GIVEN] No Integration Table Mapping records
        // [GIVEN] No Job Queue Entry records
        IntegrationTableMapping.DeleteAll(true);
        JobQueueEntry.DeleteAll();

        LibraryCRMIntegration.CreateCRMConnectionSetup('', '@@test@@', true);

        // [GIVEN] CRM Connection Setup page
        CRMConnectionSetup.OpenEdit();

        // [WHEN] "Use Default Synchronization Setup" action is invoked
        CRMConnectionSetup.ResetConfiguration.Invoke();

        // [THEN] Integration Table Mapping and Job Queue Entry tables are not empty
        Assert.AreNotEqual(0, IntegrationTableMapping.Count, 'Expected the reset mappings to create new mappings');
        Assert.AreNotEqual(0, JobQueueEntry.Count, 'Expected the reset mappings to create new job queue entries');

        // [THEN] Message "The default setup for Dynamics 365 Sales synchronization has completed successfully." appears
        Assert.ExpectedMessage(StrSubstNo(SetupSuccessfulMsg, CRMProductName.SHORT()), LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UrlValidationIsNotCaseSensitive()
    var
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Server Address] [UI]
        // [SCENARIO] The user-entered server address URL is not case sensitive

        // [GIVEN] A camel case server address URL
        // [WHEN] The user sets the value
        Initialize();
        CRMConnectionSetup.OpenEdit();
        CRMConnectionSetup."Server Address".SetValue('https://CamelCaseUrl.crm4.dynamics.com');

        // [THEN] No confirm dialog pops-up asking to auro-replace the URL with the lowercase version
        // This test succeeds if no confirm dialog shows up to ask user for agreement to replace the URL.
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UrlValidationWhenMissingHTTPS()
    var
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Server Address] [UI]
        // [SCENARIO] The user-entered server address URL is prefixed with 'https://' if needed

        // [GIVEN] A server address URL
        // [WHEN] The user sets the value, omitting the beginning 'https://'
        Initialize();
        CRMConnectionSetup.OpenEdit();
        CRMConnectionSetup."Server Address".SetValue('company.crm4.dynamics.com');

        // [THEN] A confirmation dialog opens (the handler is exercised simulating the user clicking Yes)
        // [THEN] The URL is prefixed with 'https://'
        Assert.AreEqual('https://company.crm4.dynamics.com', CRMConnectionSetup."Server Address".Value, 'Incorrect URL auto-completion');
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
        ApplicationAreaSetup.SetRange("User ID", UserId);
        ApplicationAreaSetup.DeleteAll();

        ApplicationAreaSetup.Init();
        ApplicationAreaSetup."User ID" := UserId;
        ApplicationAreaSetup.Basic := true;
        ApplicationAreaSetup.Insert();
        ApplicationAreaMgmtFacade.SetupApplicationArea();

        // [WHEN] Open CRM Connection Setup page
        LibraryVariableStorage.Enqueue(OnlyBasicAppAreaMsg);
        asserterror PAGE.Run(PAGE::"CRM Connection Setup");

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
        CRMConnectionSetup: TestPage "CRM Connection Setup";
        JobQueueEntries: TestPage "Job Queue Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Action "Synch. Job Queue Entries" opens page with CRM synch. jobs.
        Initialize();
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = Yes
        InitSetup(true, '');
        // [GIVEN] 4 Job Queue Entries: 3 are for CRM Integration, 3 of them active
        InsertJobQueueEntries();
        // [WHEN] Run action "Synch. Job Queue Entries" on CRM Connection Setup page
        CRMConnectionSetup.OpenView();
        JobQueueEntries.Trap();
        CRMConnectionSetup."Synch. Job Queue Entries".Invoke();
        // [THEN] Page "Job Queue Entries" is open, where are 3 jobs
        Assert.IsTrue(JobQueueEntries.First(), 'First');
        Assert.IsTrue(JobQueueEntries.Next(), 'Second');
        Assert.IsTrue(JobQueueEntries.Next(), 'Third');
        Assert.IsFalse(JobQueueEntries.Next(), 'Fourth should fail');
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AllJobsActive()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CRM Connection Setup page shows '3 of 3' when all jobs are active
        Initialize();
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = Yes
        InitSetup(true, '');
        // [GIVEN] 4 Job Queue Entries: 3 are for CRM Integration, 3 of them active
        InsertJobQueueEntries();

        // [WHEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenView();

        // [THEN] Control "Active scheduled synchronization jobs" is '3 of 3'
        CRMConnectionSetupPage.ScheduledSynchJobsActive.AssertEquals('3 of 3');

        // [WHEN] DrillDown on '3 of 3'
        LibraryVariableStorage.Enqueue('all scheduled synchronization jobs are ready or already processing.');
        CRMConnectionSetupPage.ScheduledSynchJobsActive.DrillDown();
        // [THEN] Message : "all scheduled synchronization jobs are ready or already processing."
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoActiveJobs()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CRM Connection Setup page shows '0 of 0' when connection is disabled
        Initialize();
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = No
        InitSetup(false, '');
        // [GIVEN] 4 Job Queue Entries: 3 are for CRM Integration, 3 of them active
        InsertJobQueueEntries();

        // [WHEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenView();
        // [THEN] Control "Active scheduled synchronization jobs" is '0 of 0'
        CRMConnectionSetupPage.ScheduledSynchJobsActive.AssertEquals('0 of 0');

        // [WHEN] DrillDown on '0 of 0'
        LibraryVariableStorage.Enqueue('There is no job queue started.');
        CRMConnectionSetupPage.ScheduledSynchJobsActive.DrillDown();
        // [THEN] Message : "There is no job queue started"
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NotAllJobsActive()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CRM Connection Setup page shows '3 of 4' when part of jobs are active
        Initialize();
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = Yes
        InitSetup(true, '');
        // [GIVEN] 6 Job Queue Entries: 4 are for CRM Integration, 3 of them active
        InsertJobQueueEntries();
        InsertJobQueueEntriesWithError();

        // [WHEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenView();

        // [THEN] Control "Active scheduled synchronization jobs" is '3 of 4'
        CRMConnectionSetupPage.ScheduledSynchJobsActive.AssertEquals('3 of 4');

        // [WHEN] DrillDown on '3 of 4'
        LibraryVariableStorage.Enqueue('An active job queue is available but only 3 of the 4');
        CRMConnectionSetupPage.ScheduledSynchJobsActive.DrillDown();
        // [THEN] Message : "An active job queue is available but only 3 of the 4"
        // handled by MessageDequeue
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMStatJobExcludedIfSolutionNotInstalled()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ActiveJobs: Integer;
        TotalJobs: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] CRM Connection Setup page excludes jobs running "CRM Statistics Job".
        Initialize();
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = Yes, "Is CRM Solution Installed" = No
        InitSetup(true, '');
        CRMConnectionSetup.Get();
        CRMConnectionSetup."Is CRM Solution Installed" := false;

        // [GIVEN] 4 Job Queue Entries: 3 are for CRM Integration, 3 of them active, 1 are running "CRM Statistics Job"
        InsertJobQueueEntries();

        // [WHEN] Run CountCRMJobQueueEntries that returns ActiveJobs and TotalJobs
        CRMConnectionSetup.CountCRMJobQueueEntries(ActiveJobs, TotalJobs);

        // [THEN] Active Jobs = 2, Total Jobs = 2; "CRM Statistics Job" is not included
        Assert.AreEqual(2, ActiveJobs, 'ActiveJobs');
        Assert.AreEqual(2, TotalJobs, 'TotalJobs');
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NAVSolutionIsInstalledDrillDown()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CRM Connection Setup page shows a message on drilldown if the solution is installed
        Initialize();
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = Yes
        InitSetup(true, '');
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenView();
        // [GIVEN] "Is CRM Solution Installed" is Yes
        CRMConnectionSetupPage."Is CRM Solution Installed".AssertEquals(true);
        // [WHEN] DrillDown on "Is CRM Solution Installed" control
        LibraryVariableStorage.Enqueue(StrSubstNo(FavorableCRMSolutionInstalledMsg, PRODUCTNAME.Short(), CRMProductName.SHORT()));
        CRMConnectionSetupPage."Is CRM Solution Installed".DrillDown();
        // [THEN] The message: "Solution is installed."
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('MessageDequeue,ConfirmYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NAVSolutionIsNotInstalledDrillDown()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CRM Connection Setup page shows a message on drilldown if the solution is not installed
        Initialize();
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = No
        InitSetup(false, '');
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenView();
        // [GIVEN] "Is CRM Solution Installed" is No
        CRMConnectionSetupPage."Is CRM Solution Installed".AssertEquals(false);
        // [WHEN] DrillDown on "Is CRM Solution Installed" control
        LibraryVariableStorage.Enqueue(StrSubstNo(UnfavorableCRMSolutionInstalledMsg, PRODUCTNAME.Short()));
        CRMConnectionSetupPage."Is CRM Solution Installed".DrillDown();
        // [THEN] The message: "Solution was not detected."
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMVersionNotValid()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CRM Connection Setup page shows message 'CRM might not work correctly' on drilldown on the CRM Version '7.1'
        Initialize();
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = Yes, "CRM Version" = '7.1'
        InitSetup(true, '7.1');
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenView();

        // [WHEN] DrillDown on "CRM Version" control
        LibraryVariableStorage.Enqueue(StrSubstNo('This version of %1 might not work correctly with %2',
            CRMProductName.SHORT(), PRODUCTNAME.Short()));
        CRMConnectionSetupPage."CRM Version Status".DrillDown();
        // [THEN] Message: 'This version of Dynamics CRM might not work correctly with Dynamics NAV'
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMVersionValid()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CRM Connection Setup page shows message 'The version is valid' on drilldown on the CRM Version '7.2'
        Initialize();
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = Yes, "CRM Version" = '7.2'
        InitSetup(true, '7.2');

        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenView();

        // [WHEN] DrillDown on Version control
        LibraryVariableStorage.Enqueue(StrSubstNo('The version of %1 is valid.', CRMProductName.SHORT()));
        CRMConnectionSetupPage."CRM Version Status".DrillDown();
        // [THEN] Message: 'The version of Dynamics CRM is valid.'
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ResetWebClientURLAction()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Reset Web Client URL" action show a message "URL has been reset"
        Initialize();
        InitSetup(true, '');
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit();
        // [WHEN] Run "Reset Web Client URL" action
        LibraryVariableStorage.Enqueue(StrSubstNo(WebClientUrlResetMsg, PRODUCTNAME.Short()));
        CRMConnectionSetupPage."Reset Web Client URL".Invoke();
        CRMConnectionSetupPage.Close();
        // [THEN] Message: "URL has been reset"
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('ConfirmNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IsSOIntegrationEnabledDrillDownNotConfirmed()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Is S.Order Integration Enabled" is not set to Yes if not confirming on drill down.
        Initialize();
        InitSetup(true, '');
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit();
        // [GIVEN] "Is S.Order Integration Enabled" is "No"
        CRMConnectionSetupPage."Is S.Order Integration Enabled".AssertEquals(false);
        // [GIVEN] DrillDown on "Is S.Order Integration Enabled"
        CRMConnectionSetupPage."Is S.Order Integration Enabled".SetValue(true);
        // [WHEN] answer "No" to confirmation dialog
        // handled by ConfirmNo
        // [THEN] "Is S.Order Integration Enabled" is "No"
        CRMConnectionSetupPage."Is S.Order Integration Enabled".AssertEquals(false);
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestConnectionAction()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        Initialize();
        LibraryCRMIntegration.RegisterTestTableConnection();
        LibraryCRMIntegration.EnsureCRMSystemUser();

        CRMConnectionSetup.DeleteAll();
        InitSetup(true, '');
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit();
        // [WHEN] Run "Test Connection" action
        LibraryVariableStorage.Enqueue(ConnectionSuccessMsg);
        CRMConnectionSetupPage."Test Connection".Invoke();
        // [THEN] Message: "The connection test was successful"
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('ConfirmNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SynchronizeNowNotConfirmed()
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] No sync should bne done if not confirming action "Synchronize Modified Records"
        Initialize();
        LibraryCRMIntegration.ConfigureCRM();
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit();
        // [GIVEN] Run "Synchronize Modified Records" action
        CRMConnectionSetupPage.SynchronizeNow.Invoke();
        // [WHEN] Answer No to confirmation
        // handled by ConfirmNo
        // [THEN] No sync is done
        Assert.AreEqual(0, IntegrationSynchJob.Count, 'Expected zero jobs to be created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartInitialSynchAction()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
        CRMFullSynchReviewPage: TestPage "CRM Full Synch. Review";
    begin
        // [FEATURE] [UI]
        Initialize();
        LibraryCRMIntegration.ConfigureCRM();
        CreateTableMapping();
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit();
        // [WHEN] run action StartInitialSynch
        CRMFullSynchReviewPage.Trap();
        CRMConnectionSetupPage.StartInitialSynchAction.Invoke();
        // [THEN] CRMFullSynchReview page is open
        CRMFullSynchReviewPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageOk')]
    [Scope('OnPrem')]
    procedure SynchronizeNowEnumeratesAllMappings()
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetupTestPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        Initialize();
        CDSConnectionSetup.DeleteAll();
        LibraryCRMIntegration.ConfigureCRM();
        ResetDefaultCRMSetupConfiguration();

        if not CRMConnectionSetup.Get() then
            LibraryCRMIntegration.CreateCRMConnectionSetup('', '@@test@@', true);

        // [GIVEN] CRM Connection Setup with Integration Table Mappings
        CRMConnectionSetup.RegisterConnection();
        CreateTableMapping();

        // [WHEN] Invoking the Synchronize Now action
        CRMConnectionSetupTestPage.OpenEdit();
        Assert.IsTrue(CRMConnectionSetupTestPage.SynchronizeNow.Enabled(), 'Expected the Synchronize Now action to be enabled');
        CRMConnectionSetupTestPage.SynchronizeNow.Invoke();

        // [WHEN] The scheduled jobs are finished
        SimulateIntegrationSyncJobsExecution();

        // [THEN] Jobs are created for each mapping and direction
        Assert.AreEqual(40, IntegrationSynchJob.Count, 'Expected a job to be created for each mapping and direction');
        CRMConnectionSetup.DeleteAll();
        InitializeCDSConnectionSetup();
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
        CRMConnectionSetup."Unit Group Mapping Enabled" := false;
        CRMConnectionSetup.Modify();
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnableCRMJobQueueEntriesOnEnableCRMConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [SCENARIO] Enabling CRM Connection move all CRM Job Queue Entries in "Ready" status
        Initialize();
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();

        // [GIVEN] CRM Connection Setup with Integration Table Mapping and CRM Job Queue Entries
        CreateCRMConnectionSetup();
        CRMConnectionSetup.DeleteAll();
        InitSetup(false, '');

        // [WHEN] Enable the connection
        CRMConnectionSetup.Get();
        CRMConnectionSetup.Validate("Is Enabled", true);
        CRMConnectionSetup.Modify(true);

        // [THEN] All CRM Job Queue Entries has Status = Ready
        VerifyJobQueueEntriesStatusIsReady();
        CRMConnectionSetup.Validate("Is Enabled", false);
        CRMConnectionSetup.Modify(true);
        CRMConnectionSetup.Delete();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DisableCRMJobQueueEntriesOnDisableCRMConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [SCENARIO] Disabling CRM Connection move all CRM Job Queue Entries in "On Hold" status
        Initialize();

        // [GIVEN] CRM Connection Setup with Integration Table Mapping and CRM Job Queue Entries
        CreateCRMConnectionSetup();
        CRMConnectionSetup.DeleteAll();
        InitSetup(true, '');

        // [WHEN] Disable the connection
        CRMConnectionSetup.Get();
        CRMConnectionSetup.Validate("Is Enabled", false);
        CRMConnectionSetup.Modify(true);

        // [THEN] All CRM Job Queue Entries has Status = On Hold
        VerifyJobQueueEntriesStatusIsOnHold();
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [Scope('OnPrem')]
    procedure DisableCRMSalesOrderIntegration()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 211784] Disable CRM Sales Order Integration from CRM Connection Setup page
        Initialize();

        // [GIVEN] CRM Connection Enabled and Sales Order Integration enabled
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();
        SetSalesOrderIntegrationInOrg(true);

        // [GIVEN] Open CRM Connection Setup page and "Sales Order Integration Enabled" = TRUE
        CRMConnectionSetupPage.OpenEdit();
        CRMConnectionSetupPage."Is S.Order Integration Enabled".AssertEquals(true);

        // [WHEN] Set "Sales Order Integration Enabled" = FALSE
        LibraryVariableStorage.Enqueue(StrSubstNo(CRMSOIntegrationDisabledMsg, CRMProductName.SHORT()));
        CRMConnectionSetupPage."Is S.Order Integration Enabled".SetValue(false);

        // [THEN] Then Message appears that Sales Order Integration is now disabled and "Sales Order Integration Enabled" = FALSE
        CRMConnectionSetupPage."Is S.Order Integration Enabled".AssertEquals(false);
        CRMConnectionSetupPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure JobQueueEntriesDescription()
    var
        JobQueueEntry: Record "Job Queue Entry";
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Table Mapping] [UI]
        // [SCENARIO 229986] CRM synchronization job queue entries have proper description
        Initialize();

        // [GIVEN] New CRM connection setup
        PrepareNewConnectionSetup();

        // [GIVEN] Open CRM connection setup page
        CRMConnectionSetup.OpenEdit();

        // [WHEN] Reset configuration action is being clicked
        CRMConnectionSetup.ResetConfiguration.Invoke();

        // [THEN] Created job queue entries does not have "%2" in the description
        JobQueueEntry.SetFilter(Description, '*%2*');
        Assert.RecordIsEmpty(JobQueueEntry);

        // [THEN] Created job queue entries have description with "Dynamics 365 Sales"
        JobQueueEntry.SetFilter(Description, StrSubstNo('*%1*', CRMProductName.SHORT()));
        Assert.RecordIsNotEmpty(JobQueueEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AutoCreateSalesOrdersJobQueueEntryCreatedOnResetConfiguration()
    var
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [SCENARIO 229986] Job queue entry for codeunit "Auto Create Sales Orders" created while resetting configuration if CRMConnectionSetup."Auto Create Sales Orders" = TRUE
        Initialize();

        // [GIVEN] New CRM connection setup
        PrepareNewConnectionSetup();

        // [GIVEN] CRMConnectionSetup."Auto Create Sales Orders" = TRUE
        SetAutoCreateSalesOrders(true);

        // [GIVEN] Open CRM connection setup page
        CRMConnectionSetup.OpenEdit();

        // [WHEN] Reset configuration action is being clicked
        CRMConnectionSetup.ResetConfiguration.Invoke();

        // [THEN] Job queue entry for codeunit "Auto Create Sales Orders" created
        VerifyAutoCreateSalesOrdersJobQueueEntryExists();
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AutoCreateSalesOrdersJobQueueEntryIsNotCreatedOnResetConfiguration()
    var
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [SCENARIO 229986] Job queue entry for codeunit "Auto Create Sales Orders" is not created while resetting configuration if CRMConnectionSetup."Auto Create Sales Orders" = FALSE
        Initialize();

        // [GIVEN] New CRM connection setup
        PrepareNewConnectionSetup();

        // [GIVEN] CRMConnectionSetup."Auto Create Sales Orders" = FALSE
        SetAutoCreateSalesOrders(false);

        // [GIVEN] Open CRM connection setup page
        CRMConnectionSetup.OpenEdit();

        // [WHEN] Reset configuration action is being clicked
        CRMConnectionSetup.ResetConfiguration.Invoke();

        // [THEN] Job queue entry for codeunit "Auto Create Sales Orders" does not created
        VerifyAutoCreateSalesOrdersJobQueueEntryDoesNotExist();
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AutoProcessSalesQuotesJobQueueEntryCreatedOnResetConfiguration()
    var
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [SCENARIO 229986] Job queue entry for codeunit "Auto Process Sales Quotes" created while resetting configuration if CRMConnectionSetup."Auto Process Sales Quotes" = TRUE
        Initialize();

        // [GIVEN] New CRM connection setup
        PrepareNewConnectionSetup();

        // [GIVEN] CRMConnectionSetup."Auto Process Sales Quotes" = TRUE
        SetAutoProcessSalesQuotes(true);

        // [GIVEN] Open CRM connection setup page
        CRMConnectionSetup.OpenEdit();

        // [WHEN] Reset configuration action is being clicked
        CRMConnectionSetup.ResetConfiguration.Invoke();

        // [THEN] Job queue entry for codeunit "Auto Process Sales Quotes" created
        VerifyAutoProcessSalesQuotesJobQueueEntryExists();
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AutoProcessSalesQuotesJobQueueEntryIsNotCreatedOnResetConfiguration()
    var
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [SCENARIO 229986] Job queue entry for codeunit "Auto Process Sales Quotes" is not created while resetting configuration if CRMConnectionSetup."Auto Process Sales Quotes" = FALSE
        Initialize();

        // [GIVEN] New CRM connection setup
        PrepareNewConnectionSetup();

        // [GIVEN] CRMConnectionSetup."Auto Process Sales Quotes" = FALSE
        SetAutoProcessSalesQuotes(false);

        // [GIVEN] Open CRM connection setup page
        CRMConnectionSetup.OpenEdit();

        // [WHEN] Reset configuration action is being clicked
        CRMConnectionSetup.ResetConfiguration.Invoke();

        // [THEN] Job queue entry for codeunit "Auto Process Sales Quotes" does not created
        VerifyAutoProcessSalesQuotesJobQueueEntryDoesNotExist();
    end;


    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AutoCreateSalesOrdersEditableIfOrdersIntegrationEnabled()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 229986] CRMConnectionSetup."Auto Create Sales Orders" is editable in case of orders integration enabled
        Initialize();

        // [GIVEN] CRM Connection Enabled and Sales Order Integration enabled
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();
        SetSalesOrderIntegrationInOrg(true);

        // [WHEN] Opened CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit();

        // [THEN] Sales Order Integration enabled
        CRMConnectionSetupPage."Is S.Order Integration Enabled".AssertEquals(true);

        // [THEN] "Auto Create Sales Orders" is editable
        Assert.IsTrue(CRMConnectionSetupPage."Auto Create Sales Orders".Editable(), 'Field must be editable.');
    end;

    [Test]
    [HandlerFunctions('MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AutoCreateSalesOrdersNotEditableIfOrdersIntegrationDisabled()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 229986] CRMConnectionSetup."Auto Create Sales Orders" = FALSE and not editable in case of orders integration disabled
        Initialize();

        // [GIVEN] CRM Connection Enabled and Sales Order Integration enabled
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();
        SetSalesOrderIntegrationInOrg(true);

        // [GIVEN] CRM Connection Setup with "Auto Create Sales Orders" = TRUE
        SetAutoCreateSalesOrders(true);

        // [GIVEN] Opened CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit();

        // [WHEN] Order integration is being disabled
        CRMConnectionSetupPage."Is S.Order Integration Enabled".SetValue(false);

        // [THEN] "Auto Create Sales Orders" = FALSE
        CRMConnectionSetupPage."Auto Create Sales Orders".AssertEquals(false);

        // [THEN] "Auto Create Sales Orders" is not editable
        Assert.IsFalse(CRMConnectionSetupPage."Auto Create Sales Orders".Editable(), 'Field must be not editable.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EnablingAutoCreateSalesOrdersMakesJobQueueEntryCreated()
    var
        JobQueueEntry: Record "Job Queue Entry";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 229986] Setting CRMConnectionSetup."Auto Create Sales Orders" = TRUE makes job queue entry created
        Initialize();
        JobQueueEntry.DeleteAll();

        // [GIVEN] CRM Connection Enabled and Sales Order Integration enabled
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();
        SetSalesOrderIntegrationInOrg(true);

        // [GIVEN] Opened CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit();

        // [WHEN] Set "Auto Create Sales Orders" = TRUE
        CRMConnectionSetupPage."Auto Create Sales Orders".SetValue(true);

        // [THEN] Job queue entry created with Object ID to Run = "Auto Create Sales Orders"
        VerifyAutoCreateSalesOrdersJobQueueEntryExists();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DisablingAutoCreateSalesOrdersMakesJobQueueEntryDeleted()
    var
        JobQueueEntry: Record "Job Queue Entry";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 229986] Setting CRMConnectionSetup."Auto Create Sales Orders" = FALSE makes job queue entry deleted
        Initialize();
        JobQueueEntry.DeleteAll();

        // [GIVEN] CRM Connection Enabled and Sales Order Integration enabled
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();
        SetSalesOrderIntegrationInOrg(true);

        // [GIVEN] Opened CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit();

        // [GIVEN] Set "Auto Create Sales Orders" = TRUE
        CRMConnectionSetupPage."Auto Create Sales Orders".SetValue(true);

        // [WHEN] Set "Auto Create Sales Orders" = FALSE
        CRMConnectionSetupPage."Auto Create Sales Orders".SetValue(false);

        // [THEN] Job queue entry does not exist with Object ID to Run = "Auto Create Sales Orders"
        VerifyAutoCreateSalesOrdersJobQueueEntryDoesNotExist();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EnablingAutoProcessSalesQuotesMakesJobQueueEntryCreated()
    var
        JobQueueEntry: Record "Job Queue Entry";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 229986] Setting CRMConnectionSetup."Auto Process Sales Quotes" = TRUE makes job queue entry created
        Initialize();
        JobQueueEntry.DeleteAll();

        // [GIVEN] CRM Connection Enabled
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();

        // [GIVEN] Opened CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit();

        // [WHEN] Set "Auto Process Sales Quotes" = TRUE
        CRMConnectionSetupPage."Auto Process Sales Quotes".SetValue(true);

        // [THEN] Job queue entry created with Object ID to Run = "Auto Process Sales Quotes"
        VerifyAutoProcessSalesQuotesJobQueueEntryExists();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DisablingAutoProcessSalesQuotesMakesJobQueueEntryDeleted()
    var
        JobQueueEntry: Record "Job Queue Entry";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 229986] Setting CRMConnectionSetup."Auto Process Sales Quotes" = TRUE makes job queue entry created
        Initialize();
        JobQueueEntry.DeleteAll();

        // [GIVEN] CRM Connection Enabled
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();

        // [GIVEN] Opened CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit();

        // [WHEN] Set "Auto Process Sales Quotes" = TRUE
        CRMConnectionSetupPage."Auto Process Sales Quotes".SetValue(true);

        // [WHEN] Set "Auto Process Sales Quotes" = FALSE
        CRMConnectionSetupPage."Auto Process Sales Quotes".SetValue(false);

        // [THEN] Job queue entry does not exist with Object ID to Run = "Auto Process Sales Quotes"
        VerifyAutoProcessSalesQuotesJobQueueEntryDoesNotExist();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTGetJobQueueEntriesObjectIDToRunFilter()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        "Filter": Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 229986] GetJobQueueEntriesObjectIDToRunFilter returns filter which contains codeunits 5339, 5350, 5349

        // [WHEN] Function GetJobQueueEntriesObjectIDToRunFilter is being run
        Filter := CRMConnectionSetup.GetJobQueueEntriesObjectIDToRunFilter();

        // [THEN] Resulted filter contains codeunit 5339
        VerifyCodeunitInFilter(Filter, CODEUNIT::"Integration Synch. Job Runner");
        // [THEN] Resulted filter contains codeunit 5350
        VerifyCodeunitInFilter(Filter, CODEUNIT::"CRM Statistics Job");
        // [THEN] Resulted filter contains codeunit 5349
        VerifyCodeunitInFilter(Filter, CODEUNIT::"Auto Create Sales Orders");
        // [THEN] Resulted filter contains codeunit 5354
        VerifyCodeunitInFilter(Filter, CODEUNIT::"Auto Process Sales Quotes");
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure IntegrationTableMappingNameCannotBeBlank()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableMappingList: TestPage "Integration Table Mapping List";
    begin
        // [FEATURE] [Table Mapping] [UI]
        // [SCENARIO 235022] You cannot create Integration Table Mapping with blank Name.
        Initialize();

        IntegrationTableMapping.Init();
        IntegrationTableMapping."Table ID" := DATABASE::"Integration Table Mapping";
        IntegrationTableMapping.Insert();

        IntegrationTableMappingList.OpenEdit();
        IntegrationTableMappingList.GotoRecord(IntegrationTableMapping);
        asserterror IntegrationTableMappingList.Name.SetValue('');

        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure ConnectionSetupDefaultSDKVersion()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
        LatestSDKVersion: Integer;
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO 234755] Connection Setup has SDK Version 9 by default
        Initialize();
        LatestSDKVersion := LibraryCRMIntegration.GetLastestSDKVersion();

        // [WHEN] Connection Setup page opened first time
        CRMConnectionSetupPage.OpenEdit();

        // [THEN] The latest SDK proxy version is by default
        CRMConnectionSetupPage.SDKVersion.AssertEquals(LatestSDKVersion);

        // [WHEN] Server address in entered and page closed
        CRMConnectionSetupPage."Server Address".SetValue('https://test.dynamics.com');
        CRMConnectionSetupPage.Close();

        // [THEN] CRM Connection Setup record has the latest SDK proxy version
        CRMConnectionSetup.Get();
        CRMConnectionSetup.TestField("Proxy Version", LatestSDKVersion);

        // [WHEN] CRM Connection Setup record has Proxy Version = 0 and CRM Connection Setup page is opened
        CRMConnectionSetup.Validate("Proxy Version", 0);
        CRMConnectionSetup.Modify();
        CRMConnectionSetupPage.OpenEdit();

        // [THEN] The latest SDK proxy version is by default
        CRMConnectionSetupPage.SDKVersion.AssertEquals(LatestSDKVersion);
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure ConnectionSetupSDKVersionEnabledDisabled()
    var
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO 234755] SDK Version selection is disabled when connection is not enabled, but CDS is enabled
        Initialize();
        // [GIVEN] Connection is not enabled
        // [WHEN] Connection Setup opened and connection not enabled
        CRMConnectionSetup.OpenEdit();
        // [THEN] SDK Version field is disabled
        Assert.IsFalse(CRMConnectionSetup.SDKVersion.Enabled(), 'Expected "SDK Version" field not to be enabled');
        CRMConnectionSetup.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure ConnectionSetupChangeSDKVersion()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO 234755] When SDK Version is changed in page it changes in record also
        Initialize();
        // [GIVEN] Connection is not enabled
        // [GIVEN] Connection Setup page is opened

        // [WHEN] SDK Version is set to "8"
        CRMConnectionSetupPage.OpenEdit();
        CRMConnectionSetupPage.SDKVersion.SetValue(8);
        CRMConnectionSetupPage.Close();
        // [THEN] Proxy Version in CRM Connection Setup record is "8"
        CRMConnectionSetup.Get();
        CRMConnectionSetup.TestField("Proxy Version", 8);

        // [WHEN] SDK Version is set to "9"
        CRMConnectionSetupPage.OpenEdit();
        CRMConnectionSetupPage.SDKVersion.SetValue(9);
        CRMConnectionSetupPage.Close();
        // [THEN] Proxy Version in CRM Connection Setup record is "9"
        CRMConnectionSetup.Get();
        CRMConnectionSetup.TestField("Proxy Version", 9);
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure UpdatSDKVersionInConnectionStringWithPassword()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        OldConnectionString: Text;
        NewConnectionString: Text;
        OldVersion: Integer;
        NewVersion: Integer;
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO] Changing SDK version updates the connection string with the new version

        // [WHEN] SDK Version in CRM Connection Setup record is "8"
        OldVersion := 8;
        CDSConnectionSetup.DeleteAll();
        CDSConnectionSetup.Init();
        CDSConnectionSetup."Is Enabled" := true;
        CDSConnectionSetup."Server Address" := '@@test@@';
        CDSConnectionSetup."Proxy Version" := OldVersion;
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::AD;
        CDSConnectionSetup.Insert();
        OldConnectionString := StrSubstNo(PasswordConnectionStringFormatTxt, CDSConnectionSetup."Server Address", UserTok, PasswordTok, OldVersion, PasswordAuthTxt);
        CDSIntegrationImpl.SetConnectionString(CDSConnectionSetup, OldConnectionString);
        CRMConnectionSetup.DeleteAll();
        CRMConnectionSetup.LoadConnectionStringElementsFromCDSConnectionSetup();
        CRMConnectionSetup.Get();
        Assert.AreEqual(OldConnectionString, CRMConnectionSetup.GetConnectionString(), 'Unexpected old connection string');

        // [WHEN] SDK Version is set to "10.0"
        NewVersion := 100;
        CRMConnectionSetupPage.OpenEdit();
        CRMConnectionSetupPage.SDKVersion.SetValue(NewVersion);
        CRMConnectionSetupPage.Close();

        // [THEN] Proxy Version in CRM Connection Setup record is "10.0", other parts are unchanged
        CRMConnectionSetup.Get();
        NewConnectionString := StrSubstNo(PasswordConnectionStringFormatTxt, CRMConnectionSetup."Server Address", UserTok, PasswordTok, NewVersion, PasswordAuthTxt);
        Assert.AreEqual(NewConnectionString, CRMConnectionSetup.GetConnectionString(), 'Unexpected new connection string');
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure UpdatSDKVersionInConnectionStringWithClientSecret()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        OldConnectionString: Text;
        NewConnectionString: Text;
        OldVersion: Integer;
        NewVersion: Integer;
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO] Changing SDK version updates the connection string with the new version

        // [WHEN] SDK Version in CRM Connection Setup record is "8"
        OldVersion := 8;
        CDSConnectionSetup.DeleteAll();
        CDSConnectionSetup.Init();
        CDSConnectionSetup."Is Enabled" := true;
        CDSConnectionSetup."Server Address" := '@@test@@';
        CDSConnectionSetup."Proxy Version" := OldVersion;
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;
        CDSConnectionSetup.Insert();
        OldConnectionString := StrSubstNo(ClientSecretConnectionStringFormatTxt, ClientSecretAuthTxt, CDSConnectionSetup."Server Address", ClientIdTok, ClientSecretTok, OldVersion);
        CDSIntegrationImpl.SetConnectionString(CDSConnectionSetup, OldConnectionString);
        CRMConnectionSetup.DeleteAll();
        CRMConnectionSetup.LoadConnectionStringElementsFromCDSConnectionSetup();
        CRMConnectionSetup.Get();
        Assert.AreEqual(OldConnectionString, CRMConnectionSetup.GetConnectionString(), 'Unexpected old connection string');

        // [WHEN] SDK Version is set to "10.0"
        NewVersion := 100;
        CRMConnectionSetupPage.OpenEdit();
        CRMConnectionSetupPage.SDKVersion.SetValue(NewVersion);
        CRMConnectionSetupPage.Close();

        // [THEN] Proxy Version in CRM Connection Setup record is "10.0", other parts are unchanged
        CRMConnectionSetup.Get();
        NewConnectionString := StrSubstNo(ClientSecretConnectionStringFormatTxt, ClientSecretAuthTxt, CRMConnectionSetup."Server Address", ClientIdTok, ClientSecretTok, NewVersion);
        Assert.AreEqual(NewConnectionString, CRMConnectionSetup.GetConnectionString(), 'Unexpected new connection string');
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure UpdatSDKVersionInConnectionStringWithCertificate()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        OldConnectionString: Text;
        NewConnectionString: Text;
        OldVersion: Integer;
        NewVersion: Integer;
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO] Changing SDK version updates the connection string with the new version

        // [WHEN] SDK Version in CRM Connection Setup record is "8"
        OldVersion := 8;
        CDSConnectionSetup.DeleteAll();
        CDSConnectionSetup.Init();
        CDSConnectionSetup."Is Enabled" := true;
        CDSConnectionSetup."Server Address" := '@@test@@';
        CDSConnectionSetup."Proxy Version" := OldVersion;
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;
        CDSConnectionSetup.Insert();
        OldConnectionString := StrSubstNo(CertificateConnectionStringFormatTxt, CertificateAuthTxt, CDSConnectionSetup."Server Address", ClientIdTok, CertificateTok, OldVersion);
        CDSIntegrationImpl.SetConnectionString(CDSConnectionSetup, OldConnectionString);
        CRMConnectionSetup.DeleteAll();
        CRMConnectionSetup.LoadConnectionStringElementsFromCDSConnectionSetup();
        CRMConnectionSetup.Get();
        Assert.AreEqual(OldConnectionString, CRMConnectionSetup.GetConnectionString(), 'Unexpected old connection string');

        // [WHEN] SDK Version is set to "10.0"
        NewVersion := 100;
        CRMConnectionSetupPage.OpenEdit();
        CRMConnectionSetupPage.SDKVersion.SetValue(NewVersion);
        CRMConnectionSetupPage.Close();

        // [THEN] Proxy Version in CRM Connection Setup record is "10.0", other parts are unchanged
        CRMConnectionSetup.Get();
        NewConnectionString := StrSubstNo(CertificateConnectionStringFormatTxt, CertificateAuthTxt, CRMConnectionSetup."Server Address", ClientIdTok, CertificateTok, NewVersion);
        Assert.AreEqual(NewConnectionString, CRMConnectionSetup.GetConnectionString(), 'Unexpected new connection string');
    end;

    [Scope('OnPrem')]
    procedure CRMIntegrationEnabledStateWhenDisableConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [CRM Connection Setup] [UT]
        // [SCENARIO 254415] CRMIntegrationEnabledState <> Enabled when disable CRM Connection Setup
        // [GIVEN] CRM Connection Setup
        Initialize();
        LibraryCRMIntegration.RegisterTestTableConnection();
        LibraryCRMIntegration.EnsureCRMSystemUser();
        LibraryCRMIntegration.CreateCRMOrganization();
        // [GIVEN] CRMIntegrationEnabledState = Enabled
        Assert.IsTrue(CRMIntegrationManagement.IsCRMIntegrationEnabled(), CRMIntegrationEnabledStateErr);

        // [WHEN] Disable the connection
        CRMConnectionSetup.Get();
        CRMConnectionSetup.Validate("Is Enabled", false);
        CRMConnectionSetup.Modify(true);

        // [THEN] CRMIntegrationEnabledState <> Enabled
        Assert.IsFalse(CRMIntegrationManagement.IsCRMIntegrationEnabled(), CRMIntegrationEnabledStateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DisableReasonCleanedOnConnectionEnable()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [CRM Connection Setup] [UT]
        // [SCENARIO 257435] Disable Reason is cleared when Connection is enabled
        Initialize();
        LibraryCRMIntegration.RegisterTestTableConnection();
        LibraryCRMIntegration.EnsureCRMSystemUser();
        LibraryCRMIntegration.CreateCRMOrganization();

        // [GIVEN] Connection is disabled, "Disable Reason" = ABC
        CRMConnectionSetup.DeleteAll();
        InitSetup(false, '');
        CRMConnectionSetup.Get();
        CRMConnectionSetup."Disable Reason" := 'ABC';
        CRMConnectionSetup.Modify();

        // [WHEN] Enable the connection
        CRMConnectionSetup.Validate("Is Enabled", true);

        // [THEN] "Disable Reason" is empty
        CRMConnectionSetup.TestField("Disable Reason", '');
    end;

    [Test]
    [HandlerFunctions('ConnectionBrokenNotificationHandler,ConfirmYes')]
    [Scope('OnPrem')]
    procedure DisableConnectionNotificationConnectionSetup()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [SCENARIO 257435] Verify Disable Reason is displayed in notification if connection was disabled
        Initialize();
        InitSetup(false, '');

        // [GIVEN] CRM Connection is disabled due to reason "ABC"
        CRMConnectionSetup.Get();
        CRMConnectionSetup."Disable Reason" := 'ABC';
        CRMConnectionSetup.Modify();

        // [WHEN] CRM Connection Setup page is opened
        CRMConnectionSetupPage.OpenEdit();

        // [THEN] Notification message includes connection disabled reason "ABC"
        Assert.AreEqual(
          StrSubstNo(ConnectionDisabledMsg, CRMConnectionSetup."Disable Reason"),
          LibraryVariableStorage.DequeueText(), 'Unexpected notification.');

        CRMConnectionSetupPage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EnableDisableCRMItemAvailabilityWebService()
    var
        JobQueueEntry: Record "Job Queue Entry";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Item Availability]
        // [SCENARIO 265230] CRM Item Availability service can be enabled and disabled
        Initialize();

        // [GIVEN] CRM Connection Enabled and Sales Order Integration enabled
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();

        // [GIVEN] CRM Connection is enabled, Item Availability service is not setup
        // [WHEN] CRM Connection Setup page is opened
        CRMConnectionSetupPage.OpenEdit();

        // [THEN] Dynamics 365 Business Central Item Availability Web Service is Enabled = FALSE
        CRMConnectionSetupPage."Item Availability Enabled".AssertEquals(false);

        // [WHEN] Item Availability Service is Enabled pressed
        CRMConnectionSetupPage."Item Availability Enabled".SetValue(true);
        CRMConnectionSetupPage.Close();
        CRMConnectionSetupPage.OpenView();

        // [THEN] Item Availability job queue entry is scheduled
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"CRM Item Availability Job");
        Assert.RecordIsNotEmpty(JobQueueEntry);

        // [WHEN] Item Availability Service is Enabled pressed again to disable
        CRMConnectionSetupPage."Item Availability Enabled".SetValue(false);
        CRMConnectionSetupPage.Close();
        CRMConnectionSetupPage.OpenView();

        // [THEN] Item Availability job queue entry does not exist
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"CRM Item Availability Job");
        Assert.RecordIsEmpty(JobQueueEntry);
    end;

    [Test]
    [HandlerFunctions('CRMAssistedSetupModalHandler,ConfirmYes')]
    [Scope('OnPrem')]
    procedure RunAssistedSetupFromCRMConnectionSetup()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [SCENARIO 266927] CRM Connection Assisted Setup can be opened from CRM Connection Setup page
        Initialize();

        // [GIVEN] CRM Connection Setup page is opened, Server Address "SA"
        CRMConnectionSetupPage.OpenEdit();
        CRMConnectionSetupPage."Server Address".SetValue('TEST');

        // [WHEN] Assisted Setup is invoked
        CRMConnectionSetupPage."Assisted Setup".Invoke();

        // [THEN] CRM Connection Setup wizard is opened and Server Address = "SA"
        // Wizard page is opened in CRMAssistedSetupModalHandler
        Assert.ExpectedMessage(CRMConnectionSetupPage."Server Address".Value, LibraryVariableStorage.DequeueText());
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

        Clear(CRMSetupTest);
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, '');
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM));
        Assert.AreEqual(
          '', GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM),
          'DEFAULTTABLECONNECTION should not be registered');

        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
        InitializeCDSConnectionSetup();

        if IsInitialized then
            exit;

        IsInitialized := true;
        SetTenantLicenseStateToTrial();

        Commit();
    end;

    local procedure InitializeCDSConnectionSetup()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        ClientSecret: Text;
    begin
        CDSConnectionSetup.DeleteAll();
        CDSConnectionSetup."Is Enabled" := true;
        CDSConnectionSetup."Server Address" := '@@test@@';
        CDSConnectionSetup."User Name" := 'user@test.net';
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;
        CDSConnectionSetup."Proxy Version" := LibraryCRMIntegration.GetLastestSDKVersion();
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        ClientSecret := 'ClientSecret';
        CDSConnectionSetup.SetClientSecret(ClientSecret);
    end;

    local procedure AssertConnectionNotRegistered(ConnectionName: Code[10])
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CRMConnectionSetup.Get(ConnectionName);
        CRMConnectionSetup.RegisterConnection();
        CRMConnectionSetup.UnregisterConnection();
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
        JobQueueEntry.ModifyAll("Record ID to Process", IntegrationTableMapping.RecordId);
    end;

    local procedure CreateCRMConnectionSetup()
    begin
        LibraryCRMIntegration.RegisterTestTableConnection();
        LibraryCRMIntegration.EnsureCRMSystemUser();
        LibraryCRMIntegration.CreateCRMOrganization();
        CreateIntTableMappingWithJobQueueEntries();
    end;

    local procedure InitSetup(Enable: Boolean; Version: Text[30])
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        DummyPassword: Text;
    begin
        CRMConnectionSetup.Init();
        CRMConnectionSetup."Is Enabled" := Enable;
        CRMConnectionSetup."Is CRM Solution Installed" := Enable;
        CRMConnectionSetup."Server Address" := '@@test@@';
        CRMConnectionSetup.Validate("User Name", 'tester@domain.net');
        DummyPassword := 'Password';
        CRMConnectionSetup.SetPassword(DummyPassword);
        CRMConnectionSetup."CRM Version" := Version;
        CRMConnectionSetup.Insert();

        if CRMConnectionSetup."Is Enabled" then
            CRMConnectionSetup.RegisterConnection();
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

    local procedure MockCRMConnectionSetupWithEnableValidConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        DummyPassword: Text;
    begin
        CRMConnectionSetup.DeleteAll();
        LibraryCRMIntegration.CreateCRMConnectionSetup('', '@@test@@', false);
        CRMConnectionSetup.Get();
        DummyPassword := 'password';
        CRMConnectionSetup.SetPassword(DummyPassword);
        CRMConnectionSetup."Restore Connection" := true;
        CRMConnectionSetup.Modify();
    end;

    local procedure PrepareNewConnectionSetup()
    var
        JobQueueEntry: Record "Job Queue Entry";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryCRMIntegration.ConfigureCRM();

        IntegrationTableMapping.DeleteAll(true);
        JobQueueEntry.DeleteAll();

        LibraryCRMIntegration.CreateCRMConnectionSetup('', '@@test@@', true);
    end;

    local procedure SetAutoCreateSalesOrders(NewAutoCreateOrders: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CRMConnectionSetup.Get();
        CRMConnectionSetup.Validate("Auto Create Sales Orders", NewAutoCreateOrders);
        CRMConnectionSetup.Modify(true);
    end;

    local procedure SetAutoProcessSalesQuotes(NewAutoProcessQuotes: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CRMConnectionSetup.Get();
        CRMConnectionSetup.Validate("Auto Process Sales Quotes", NewAutoProcessQuotes);
        CRMConnectionSetup.Modify(true);
    end;

    local procedure VerifyCurrencyData(CRMConnectionSetup: Record "CRM Connection Setup"; CRMOrganization: Record "CRM Organization")
    begin
        CRMConnectionSetup.TestField(CurrencyDecimalPrecision, CRMOrganization.CurrencyDecimalPrecision);
        CRMConnectionSetup.TestField(BaseCurrencyId, CRMOrganization.BaseCurrencyId);
        CRMConnectionSetup.TestField(BaseCurrencyPrecision, CRMOrganization.BaseCurrencyPrecision);
        CRMConnectionSetup.TestField(BaseCurrencySymbol, CRMOrganization.BaseCurrencySymbol);
    end;

    local procedure VerifyJobQueueEntriesStatusIsReady()
    var
        JobQueueEntry: Record "Job Queue Entry";
        CRMProductName: Codeunit "CRM Product Name";
    begin
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
        JobQueueEntry.FindSet();
        repeat
            if JobQueueEntry.Description.Contains(CRMProductName.SHORT()) then
                Assert.IsTrue(JobQueueEntry.Status = JobQueueEntry.Status::Ready, JobQueueEntryStatusReadyErr);
        until JobQueueEntry.Next() = 0;
    end;

    local procedure VerifyJobQueueEntriesStatusIsOnHold()
    var
        JobQueueEntry: Record "Job Queue Entry";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CheckSetOnHold: Boolean;
    begin
        JobQueueEntry.FindSet();
        repeat
            CheckSetOnHold := true;
            if IntegrationTableMapping.Get(JobQueueEntry."Record ID to Process") then
                if IntegrationTableMapping."Table ID" in [Database::Contact, Database::Customer, Database::"Salesperson/Purchaser", Database::Vendor, Database::Currency] then
                    CheckSetOnHold := false;
            if CheckSetOnHold then
                Assert.IsTrue(JobQueueEntry.Status = JobQueueEntry.Status::"On Hold", JobQueueEntryStatusOnHoldErr);
        until JobQueueEntry.Next() = 0;
    end;

    local procedure VerifyAutoCreateSalesOrdersJobQueueEntryExists()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Auto Create Sales Orders");
        Assert.RecordIsNotEmpty(JobQueueEntry);
    end;

    local procedure VerifyAutoCreateSalesOrdersJobQueueEntryDoesNotExist()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Auto Create Sales Orders");
        Assert.RecordIsEmpty(JobQueueEntry);
    end;

    local procedure VerifyAutoProcessSalesQuotesJobQueueEntryExists()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Auto Process Sales Quotes");
        Assert.RecordIsNotEmpty(JobQueueEntry);
    end;

    local procedure VerifyAutoProcessSalesQuotesJobQueueEntryDoesNotExist()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Auto Process Sales Quotes");
        Assert.RecordIsEmpty(JobQueueEntry);
    end;

    local procedure VerifyCodeunitInFilter("Filter": Text; CodeunitId: Integer)
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Codeunit);
        AllObj.FilterGroup(2);
        AllObj.SetFilter("Object ID", Filter);
        AllObj.FilterGroup(0);
        AllObj.SetRange("Object ID", CodeunitId);
        Assert.IsTrue(AllObj.FindFirst(), StrSubstNo('Filter does not contain codeunit %1', CodeunitId));
    end;

    local procedure SetSalesOrderIntegrationInOrg(EnabledSalesOrderIntegration: Boolean)
    var
        CRMOrganization: Record "CRM Organization";
    begin
        CRMOrganization.FindFirst();
        CRMOrganization.IsSOPIntegrationEnabled := EnabledSalesOrderIntegration;
        CRMOrganization.Modify();
    end;

    local procedure SimulateIntegrationSyncJobsExecution()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
        JobQueueEntry.FindSet();
        repeat
            Codeunit.Run(Codeunit::"Integration Synch. Job Runner", JobQueueEntry);
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMOptionMappingModalHandler(var CRMOptionMappingPage: TestPage "CRM Option Mapping")
    begin
        Assert.IsFalse(CRMOptionMappingPage.Editable(), 'The page should be NOT editable');
        CRMOptionMappingPage.First();
        CRMOptionMappingPage.Record.AssertEquals(LibraryVariableStorage.DequeueText());
        CRMOptionMappingPage."Option Value".AssertEquals(LibraryVariableStorage.DequeueInteger());
        CRMOptionMappingPage."Option Value Caption".AssertEquals(LibraryVariableStorage.DequeueText());
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
        LibraryVariableStorage.Enqueue(ConnectionBrokenNotification.Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMAssistedSetupModalHandler(var CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard")
    begin
        LibraryVariableStorage.Enqueue(CRMConnectionSetupWizard.ServerAddress.Value);
    end;

    local procedure SetTenantLicenseStateToTrial()
    var
        TenantLicenseState: Record "Tenant License State";
    begin
        TenantLicenseState."Start Date" := CurrentDateTime;
        TenantLicenseState.State := TenantLicenseState.State::Trial;
        TenantLicenseState.Insert();
    end;
}

