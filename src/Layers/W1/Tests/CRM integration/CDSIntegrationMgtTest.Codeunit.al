codeunit 139195 "CDS Integration Mgt Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CDS Integration Management]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryMockCRMConnection: Codeunit "Library - Mock CRM Connection";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        IsInitialized: Boolean;
        BaseSolutionUniqueNameTxt: Label 'bcbi_CdsBaseIntegration', Locked = true;
        ConnectionRequiredFieldsErr: Label 'A URL is required.';
        TestServerAddressTok: Label '@@test@@', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IsIntegrationEnabledWhenMissing()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [CDS Integration Management]
        // [SCENARIO] IsntegrationEnabled() returns if CDS Integration is enabled
        Initialize();

        // [GIVEN] Missing CDS Connection Setup
        CDSConnectionSetup.DeleteAll();
        // [WHEN] Asking if CDS Integration Is Enabled
        // [THEN] Response is false
        Assert.IsFalse(CDSIntegrationMgt.IsIntegrationEnabled(), 'Integration is enbeled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IsIntegrationEnabledWhenNotConfigured()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [CDS Integration Management]
        // [SCENARIO] IsntegrationEnabled() returns if CDS Integration is enabled
        Initialize();

        // [GIVEN] CDS Integration is not configured
        InitializeSetup(false);
        CDSConnectionSetup.Get();
        CDSConnectionSetup.DeletePassword();
        Clear(CDSConnectionSetup."User Password Key");
        CDSConnectionSetup.Modify();
        // [WHEN] Asking if CDS Integration Is Enabled
        // [THEN] Response is false
        Assert.IsFalse(CDSIntegrationMgt.IsIntegrationEnabled(), 'Integration is enabled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IsIntegrationEnabledWhenDisabled()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        DummyPassword: Text;
    begin
        // [FEATURE] [CDS Integration Management]
        // [SCENARIO] IsntegrationEnabled() returns if CDS Integration is enabled
        Initialize();

        // [GIVEN] Disabled CDS Connection
        InitializeSetup(false);
        CDSConnectionSetup.Get();
        DummyPassword := 'test';
        CDSConnectionSetup.SetPassword(DummyPassword);
        CDSConnectionSetup.Modify();
        // [WHEN] Asking if CDS Integration Is Enabled
        // [THEN] Response is false
        Assert.IsFalse(CDSIntegrationMgt.IsIntegrationEnabled(), 'Integration is enabled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IsIntegrationEnabledWhenEnabled()
    begin
        // [FEATURE] [CDS Integration Management]
        // [SCENARIO] IsntegrationEnabled() returns if CDS Integration is enabled
        Initialize();

        // [GIVEN] Enabled CDS Connection
        InitializeSetup(true);
        // [WHEN] Asking if CDS Integration Is Enabled
        // [THEN] Response is true
        Assert.IsTrue(CDSIntegrationMgt.IsIntegrationEnabled(), 'Integration is disabled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestConnectionWhenMissing()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        Success: Boolean;
    begin
        // [FEATURE] [CDS Integration Management]
        // [SCENARIO] Test Connection
        Initialize();

        // [GIVEN] Missing CDS Connection Setup
        CDSConnectionSetup.DeleteAll();
        // [WHEN] Test Connection
        // [THEN] Response is false
        Success := CDSIntegrationImpl.TestConnection(CDSConnectionSetup);
        Assert.ExpectedError(ConnectionRequiredFieldsErr);
        Assert.IsFalse(Success, 'Test connection succeed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestConnectionWhenNotConfigured()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        Success: Boolean;
    begin
        // [FEATURE] [CDS Integration Management]
        // [SCENARIO] Test Connection
        Initialize();

        // [GIVEN] CDS Integration is not configured
        InitializeSetup(false);
        CDSConnectionSetup.Get();
        CDSConnectionSetup."Server Address" := '';
        CDSConnectionSetup.DeletePassword();
        Clear(CDSConnectionSetup."User Password Key");
        CDSConnectionSetup.Modify();
        // [WHEN] Test Connection
        // [THEN] Response is false
        Success := CDSIntegrationImpl.TestConnection(CDSConnectionSetup);
        Assert.ExpectedError(ConnectionRequiredFieldsErr);
        Assert.IsFalse(Success, 'Test connection succeed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestConnectionWhenDisabled()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        DummyPassword: Text;
    begin
        // [FEATURE] [CDS Integration Management]
        // [SCENARIO] Test Connection
        Initialize();

        // [GIVEN] Disabled CDS Connection
        InitializeSetup(false);
        CDSConnectionSetup.Get();
        DummyPassword := 'test';
        CDSConnectionSetup.SetPassword(DummyPassword);
        CDSConnectionSetup.Modify();
        // [WHEN] Test Connection
        // [THEN] Response is true
        Assert.IsTrue(CDSIntegrationImpl.TestConnection(CDSConnectionSetup), 'Test connection failed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestConnectionWhenEnabled()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [CDS Integration Management]
        // [SCENARIO] Test Connection
        Initialize();

        // [GIVEN] Enabled CDS Connection and registered
        InitializeSetup(true);
        CDSConnectionSetup.Get();
        // [WHEN] Test Connection
        // [THEN] Response is true
        Assert.IsTrue(CDSIntegrationImpl.TestConnection(CDSConnectionSetup), 'Test connection failed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestActiveConnectionWhenNotActive()
    begin
        // [FEATURE] [CDS Integration Management]
        // [SCENARIO] Test Connection
        Initialize();

        // [GIVEN] CDS Connection is enabled but not registered
        InitializeSetup(true);
        // [WHEN] Test Active Connection
        // [THEN] Response is true
        Assert.IsFalse(CDSIntegrationImpl.TestActiveConnection(), 'Test active connection succeed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestActiveConnectionWhenActive()
    begin
        // [FEATURE] [CDS Integration Management]
        // [SCENARIO] Test Connection
        Initialize();

        // [GIVEN] CDS Connection is enabled and registered
        RegisterTestTableConnection();
        // [WHEN] Test Active Connection
        // [THEN] Response is true
        Assert.IsTrue(CDSIntegrationImpl.TestActiveConnection(), 'Test active connection failed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RegisterConnectionSucceed()
    begin
        // [FEATURE] [CDS Integration Management] [Register Connection]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        InitializeSetup(true);
        Assert.AreEqual('', GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM), 'Default connection exists.');
        // [GIVEN] Connection is not registered
        Assert.IsFalse(HasTableConnection(TABLECONNECTIONTYPE::CRM, CDSIntegrationImpl.GetConnectionDefaultName()), 'Connection is registered.');

        // [WHEN] Register connection
        Assert.IsTrue(CDSIntegrationMgt.RegisterConnection(), 'Connection registration failed.');
        // [THEN] Connection is registered
        Assert.IsTrue(HasTableConnection(TABLECONNECTIONTYPE::CRM, CDSIntegrationImpl.GetConnectionDefaultName()), 'Connection is not registered.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RegisterConnectionKeepExisting()
    begin
        // [FEATURE] [CDS Integration Management] [Register Connection]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        InitializeSetup(true);
        // [GIVEN] Connection is registered and active
        Assert.IsTrue(CDSIntegrationMgt.RegisterConnection(), 'Connection registration failed.');
        Assert.IsTrue(HasTableConnection(TABLECONNECTIONTYPE::CRM, CDSIntegrationImpl.GetConnectionDefaultName()), 'Connection is not registered.');
        Assert.IsTrue(CDSIntegrationMgt.ActivateConnection(), 'Connection activation failed.');
        Assert.IsTrue(CDSIntegrationMgt.IsConnectionActive(), 'Connection is not active.');

        // [WHEN] Register connection again with KeepExisting=true
        Assert.IsTrue(CDSIntegrationMgt.RegisterConnection(), 'Connection registration failed.');
        // [THEN] Connection is still registered and active
        Assert.IsTrue(HasTableConnection(TABLECONNECTIONTYPE::CRM, CDSIntegrationImpl.GetConnectionDefaultName()), 'Connection is not registered.');
        Assert.IsTrue(CDSIntegrationMgt.IsConnectionActive(), 'Connection is not active.');
        // [WHEN] Connection is re-activated
        Assert.IsTrue(CDSIntegrationMgt.ActivateConnection(), 'Connection activation failed.');
        // [THEN] Connection is still active
        Assert.IsTrue(CDSIntegrationMgt.IsConnectionActive(), 'Connection is not active.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RegisterConnectionCloseExisting()
    begin
        // [FEATURE] [CDS Integration Management] [Register Connection]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        InitializeSetup(true);
        // [GIVEN] Connection is registered and active
        Assert.IsTrue(CDSIntegrationMgt.RegisterConnection(), 'Connection registration failed.');
        Assert.IsTrue(HasTableConnection(TABLECONNECTIONTYPE::CRM, CDSIntegrationImpl.GetConnectionDefaultName()), 'Connection is not registered.');
        Assert.IsTrue(CDSIntegrationMgt.ActivateConnection(), 'Connection activation failed.');
        Assert.IsTrue(CDSIntegrationMgt.IsConnectionActive(), 'Connection is not active.');

        // [WHEN] Register connection again with KeepExisting=false
        Assert.IsTrue(CDSIntegrationImpl.RegisterConnection(false), 'Connection registration failed.');
        // [THEN] Connection is registered but not active
        Assert.IsTrue(HasTableConnection(TABLECONNECTIONTYPE::CRM, CDSIntegrationImpl.GetConnectionDefaultName()), 'Connection is not registered.');
        Assert.IsFalse(CDSIntegrationMgt.IsConnectionActive(), 'Connection is active.');
        // [WHEN] Connection is re-activated
        Assert.IsTrue(CDSIntegrationMgt.ActivateConnection(), 'Connection activation failed.');
        // [THEN] Connection is active
        Assert.IsTrue(CDSIntegrationMgt.IsConnectionActive(), 'Connection is not active.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RegisterConnectionFailed()
    begin
        // [FEATURE] [CDS Integration Management] [Registed Connection]
        Initialize();
        // [GIVEN] CDS Connection is not enabled
        InitializeSetup(TestServerAddressTok, false);
        Assert.AreEqual('', GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM), 'Default connection exists.');
        // [GIVEN] Connection is not registered
        Assert.IsFalse(HasTableConnection(TABLECONNECTIONTYPE::CRM, CDSIntegrationImpl.GetConnectionDefaultName()), 'Connection is registered.');

        // [WHEN] Register connection
        Assert.IsFalse(CDSIntegrationMgt.RegisterConnection(), 'Connection registration succeed.');
        // [THEN] Connection is registered
        Assert.IsFalse(HasTableConnection(TABLECONNECTIONTYPE::CRM, CDSIntegrationImpl.GetConnectionDefaultName()), 'Connection is registered.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UnregisterConnection()
    begin
        // [FEATURE] [CDS Integration Management] [Unregister Connection]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        InitializeSetup(true);
        // [GIVEN] Connection is registered
        Assert.IsTrue(CDSIntegrationMgt.RegisterConnection(), 'Connection registration failed.');
        Assert.IsTrue(HasTableConnection(TABLECONNECTIONTYPE::CRM, CDSIntegrationImpl.GetConnectionDefaultName()), 'Connection is not registered.');

        // [WHEN] Unregister connection
        Assert.IsTrue(CDSIntegrationImpl.UnregisterConnection(), 'Connection unregistration failed.');
        // [THEN] Connection is unregistered
        Assert.IsFalse(HasTableConnection(TABLECONNECTIONTYPE::CRM, CDSIntegrationImpl.GetConnectionDefaultName()), 'Connection is registered.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ActivateConnectionSucceed()
    begin
        // [FEATURE] [CDS Integration Management] [Coupled Business Unit]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        InitializeSetup(true);
        // [GIVEN] Connection is registered
        Assert.IsTrue(CDSIntegrationMgt.RegisterConnection(), 'Connection registration failed.');
        Assert.IsTrue(HasTableConnection(TABLECONNECTIONTYPE::CRM, CDSIntegrationImpl.GetConnectionDefaultName()), 'Connection is not registered.');

        // [WHEN] Activate connection
        Assert.IsTrue(CDSIntegrationMgt.ActivateConnection(), 'Connection activation failed.');
        // [THEN] Connection is active
        Assert.AreEqual(CDSIntegrationImpl.GetConnectionDefaultName(), GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM), 'Connection is not active.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ActivateConnectionFailed()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [CDS Integration Management] [Coupled Business Unit]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        InitializeSetup(true);
        // [GIVEN] Connection is registered
        Assert.IsTrue(CDSIntegrationMgt.RegisterConnection(), 'Connection registration failed.');
        Assert.IsTrue(HasTableConnection(TABLECONNECTIONTYPE::CRM, CDSIntegrationImpl.GetConnectionDefaultName()), 'Connection is not registered.');

        // [WHEN] Connection is disabled
        CDSConnectionSetup.Get();
        CDSConnectionSetup."Is Enabled" := false;
        CDSConnectionSetup.Modify();
        // [WHEN] Activate connection
        Assert.IsFalse(CDSIntegrationMgt.ActivateConnection(), 'Connection activation succeed.');
        // [THEN] Connection is not active
        Assert.AreNotEqual(CDSIntegrationImpl.GetConnectionDefaultName(), GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM), 'Connection is active.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ActivateNotRegisteredConnection()
    begin
        // [FEATURE] [CDS Integration Management] [Coupled Business Unit]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        InitializeSetup(true);
        // [GIVEN] Connection is not registered
        UnregisterTableConnection(TableConnectionType::CRM, CDSIntegrationImpl.GetConnectionDefaultName());
        Assert.IsFalse(HasTableConnection(TABLECONNECTIONTYPE::CRM, CDSIntegrationImpl.GetConnectionDefaultName()), 'Connection is registered.');

        // [WHEN] Activate connection
        Assert.IsFalse(CDSIntegrationMgt.ActivateConnection(), 'Connection activation succeed.');
        // [THEN] Connection is not active
        Assert.AreEqual('', GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM), 'Connection is active.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IsConnectionActivated()
    begin
        // [FEATURE] [CDS Integration Management] [Coupled Business Unit]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        InitializeSetup(true);
        // [GIVEN] Connection is registered
        CDSIntegrationMgt.RegisterConnection();
        Assert.IsTrue(HasTableConnection(TABLECONNECTIONTYPE::CRM, CDSIntegrationImpl.GetConnectionDefaultName()), 'Connection is not registered.');

        // [WHEN] Connection is not active
        // [THEN] Calling IsConnectionActive returns false
        Assert.IsFalse(CDSIntegrationMgt.IsConnectionActive(), 'Connection is active.');

        // [WHEN] Connection is active
        CDSIntegrationMgt.ActivateConnection();
        // [THEN] Calling IsConnectionActive returns true
        Assert.IsTrue(CDSIntegrationMgt.IsConnectionActive(), 'Connection is not active.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RegisterAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        CDSIntegrationMgt.RegisterAssistedSetup();
        Assert.IsTrue(GuidedExperience.Exists("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"CDS Connection Setup Wizard"), 'Assisted Setup is not registered');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetCoupledBusinessUnit()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [CDS Integration Management] [Coupled Business Unit]
        Initialize();
        // [GIVEN] CDS Connection is not enabled
        InitializeSetup(false);
        // [GIVEN] Coupled Business Unit is not empty
        CDSConnectionSetup.Get();
        CDSConnectionSetup.Init();
        CDSConnectionSetup."Business Unit Id" := CreateGuid();
        CDSConnectionSetup."Business Unit Name" := 'Test Business Unit';
        CDSConnectionSetup.Modify(true);

        // [THEN] GetCoupledBusinessUnitId returns correct Coupled Business Unit ID is returned
        Assert.AreEqual(CDSConnectionSetup."Business Unit Id", CDSIntegrationImpl.GetCoupledBusinessUnitId(), 'Incorrect Coupled Business Unit ID.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmNo')]
    [Scope('OnPrem')]
    procedure InsertBusinessUnitCouplingFailure()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [CDS Integration Management] [Coupled Business Unit]
        Initialize();
        // [GIVEN] CDS Connection is not enabled
        InitializeSetup(false);
        // [GIVEN] Coupled Business Unit is not empty
        CDSConnectionSetup.Get();
        CDSConnectionSetup.Init();
        CDSConnectionSetup."Business Unit Id" := CreateGuid();
        CDSConnectionSetup."Business Unit Name" := 'Test Business Unit';
        CDSConnectionSetup.Modify(true);

        // [WHEN] Try to insert coupling for the same business unit
        // [THEN] Runtime error
        asserterror CDSIntegrationImpl.InsertBusinessUnitCoupling(CDSConnectionSetup);
        // [THEN] Empty error message
        Assert.ExpectedError('');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure InsertBusinessUnitCoupling()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [CDS Integration Management] [Coupled Business Unit]
        Initialize();
        // [GIVEN] CDS Connection is not enabled
        InitializeSetup(false);
        // [GIVEN] Coupled Business Unit is not empty
        CDSConnectionSetup.Get();
        CDSConnectionSetup.Init();
        CDSConnectionSetup."Business Unit Id" := CreateGuid();
        CDSConnectionSetup."Business Unit Name" := 'Test Business Unit';
        CDSConnectionSetup.Modify(true);

        // [WHEN] Try to insert coupling for the same business unit
        // [THEN] No error
        CDSIntegrationImpl.InsertBusinessUnitCoupling(CDSConnectionSetup);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyBusinessUnitCoupling()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [CDS Integration Management] [Coupled Business Unit]
        Initialize();
        // [GIVEN] CDS Connection is not enabled
        InitializeSetup(false);
        // [GIVEN] Coupled Business Unit is not empty
        CDSConnectionSetup.Get();
        CDSConnectionSetup.Init();
        CDSConnectionSetup."Business Unit Id" := CreateGuid();
        CDSConnectionSetup."Business Unit Name" := 'Test Business Unit 1';
        CDSConnectionSetup.Modify(true);

        // [WHEN] Modify business unit coupling
        // [THEN] No error
        CDSConnectionSetup."Business Unit Id" := CreateGuid();
        CDSConnectionSetup."Business Unit Name" := 'Test Business Unit 2';
        CDSConnectionSetup.Modify();
        CDSIntegrationImpl.ModifyBusinessUnitCoupling(CDSConnectionSetup);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeleteBusinessUnitCoupling()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [CDS Integration Management] [Coupled Business Unit]
        Initialize();
        // [GIVEN] CDS Connection is not enabled
        InitializeSetup(false);
        // [GIVEN] Coupled Business Unit is not empty
        CDSConnectionSetup.Get();
        CDSConnectionSetup.Init();
        CDSConnectionSetup."Business Unit Id" := CreateGuid();
        CDSConnectionSetup."Business Unit Name" := 'Test Business Unit';
        CDSConnectionSetup.Modify(true);

        // [WHEN] Delete coupling for the business unit
        // [THEN] No error
        CDSIntegrationImpl.DeleteBusinessUnitCoupling(CDSConnectionSetup);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckBaseSolutionInstalled()
    var
        CDSSolution: Record "CDS Solution";
    begin
        // [FEATURE] [CDS Integration Management] [Base Integration Solution]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] CDS Base Integration Solution is installed
        LibraryCRMIntegration.CreateCDSSolution(CDSSolution, BaseSolutionUniqueNameTxt, BaseSolutionUniqueNameTxt, '1.2.3.4');

        // [THEN] IsSolutionInstalled returns true
        Assert.IsTrue(CDSIntegrationMgt.IsSolutionInstalled(), 'Base Solution is not installed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckBaseSolutionNotInstalled()
    var
        CDSSolution: Record "CDS Solution";
    begin
        // [FEATURE] [CDS Integration Management] [Base Integration Solution]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] CDS Base Integration Solution is not installed
        CDSSolution.DeleteAll();

        // [THEN] IsSolutionInstalled returns false
        Assert.IsFalse(CDSIntegrationMgt.IsSolutionInstalled(), 'Base Solution is installed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckSolutionInstalled()
    var
        CDSSolution: Record "CDS Solution";
    begin
        // [FEATURE] [CDS Integration Management] [Base Integration Solution]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] Test Solution is installed
        LibraryCRMIntegration.CreateCDSSolution(CDSSolution, 'test1', 'Test 1', '1.2.3.4');

        // [THEN] IsSolutionInstalled returns true
        Assert.IsTrue(CDSIntegrationMgt.IsSolutionInstalled('test1'), 'Test Solution is not installed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckSolutionNotInstalled()
    var
        CDSSolution: Record "CDS Solution";
    begin
        // [FEATURE] [CDS Integration Management] [Base Integration Solution]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] Test Solution is not installed
        CDSSolution.DeleteAll();

        // [THEN] IsSolutionInstalled returns false
        Assert.IsFalse(CDSIntegrationMgt.IsSolutionInstalled('test1'), 'Test Solution is installed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetBaseSolutionVersion()
    var
        CDSSolution: Record "CDS Solution";
        Version: Text;
    begin
        // [FEATURE] [CDS Integration Management] [Base Integration Solution]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] CDS Base Integration Solution installed
        LibraryCRMIntegration.CreateCDSSolution(CDSSolution, BaseSolutionUniqueNameTxt, BaseSolutionUniqueNameTxt, '1.2.3.4');

        // [WHEN] Get CDS Base Integration Solution Version
        CDSIntegrationMgt.GetSolutionVersion(Version);

        // [THEN] CDS Base Integration Solution version is correct
        Assert.AreEqual('1.2.3.4', Version, 'Icorrect Base Solution Version.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetSolutionVersion()
    var
        CDSSolution: Record "CDS Solution";
        Version: Text;
    begin
        // [FEATURE] [CDS Integration Management] [Base Integration Solution]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] Solution exists
        LibraryCRMIntegration.CreateCDSSolution(CDSSolution, 'test1', 'Test 1', '5.6.7.8');

        // [WHEN] Get Test Solution Version
        CDSIntegrationMgt.GetSolutionVersion('test1', Version);

        // [THEN] Solution version is correct
        Assert.AreEqual('5.6.7.8', Version, 'Icorrect Solution Version.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetCDSCompany()
    var
        CDSCompany: Record "CDS Company";
        ResultCDSCompany: Record "CDS Company";
    begin
        // [FEATURE] [CDS Integration Management] [CDS Company Entity]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] CDS Company exists
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);

        // [WHEN] Run GetCDSCompany
        CDSIntegrationImpl.GetCDSCompany(ResultCDSCompany);

        // [THEN] Correct CDS company is returned
        Assert.AreEqual(CDSCompany.SystemId, ResultCDSCompany.SystemId, 'Unexpected Dataverse Company SystemId.');
        Assert.AreEqual(CDSCompany.ExternalId, ResultCDSCompany.ExternalId, 'Unexpected Dataverse Company ExternalId.');
        Assert.AreEqual(CDSCompany.Name, ResultCDSCompany.Name, 'Unexpected Dataverse Company Name.');
        Assert.AreEqual(CDSCompany.OwningBusinessUnit, ResultCDSCompany.OwningBusinessUnit, 'Unexpected Dataverse Company OwningBusinessUnit.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetCompanyId()
    var
        CDSCompany: Record "CDS Company";
        CRMSystemUser: Record "CRM Systemuser";
        CRMAccount: Record "CRM Account";
        RecRef: RecordRef;
    begin
        // [FEATURE] [CDS Integration Management] [CDS Company Entity]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] CDS Company exists
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);

        // [GIVEN] CRM Account exists
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemUser);
        CRMAccount.OwnerId := CRMSystemUser.SystemUserId;
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);

        // [WHEN] Set CompanyId
        RecRef.GetTable(CRMAccount);
        Assert.IsTrue(CDSIntegrationMgt.SetCompanyId(RecRef), 'CompanyId is not set.');

        // [THEN] CompanyId is set correctly
        RecRef.SetTable(CRMAccount);
        Assert.AreEqual(CDSCompany.CompanyId, CRMAccount.CompanyId, 'Unexpected CompanyId.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetOwningUserWithBusinessUnitCheck()
    var
        CDSCompany: Record "CDS Company";
        CRMTeam: Record "CRM Team";
        CRMSystemUser: Record "CRM Systemuser";
        CRMAccount: Record "CRM Account";
        RecRef: RecordRef;
    begin
        // [FEATURE] [CDS Integration Management] [Entity Ownership]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] CDS Company exists
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);

        // [GIVEN] CRM Account exists
        LibraryCRMIntegration.CreateCRMTeam(CRMTeam);
        CRMAccount.OwnerIdType := CRMAccount.OwnerIdType::team;
        CRMAccount.OwnerId := CRMTeam.TeamId;
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);

        // [WHEN] Set owning user with matching business unit
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemUser);
        CRMSystemUser.BusinessUnitId := CDSCompany.OwningBusinessUnit;
        CRMSystemUser.Modify();
        RecRef.GetTable(CRMAccount);
        Assert.IsTrue(CDSIntegrationMgt.SetOwningUser(RecRef, CRMSystemUser.SystemUserId), 'Owner is not set.');

        // [THEN] Owner is set correctly
        RecRef.SetTable(CRMAccount);
        Assert.AreEqual(CRMAccount.OwnerIdType::systemuser, CRMAccount.OwnerIdType, 'Unexpected OwnerIdType.');
        Assert.AreEqual(CRMSystemUser.SystemUserId, CRMAccount.OwnerId, 'Unexpected OwnerId.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetOwningUserSkipBusinessUnitCheck()
    var
        CDSCompany: Record "CDS Company";
        CRMTeam: Record "CRM Team";
        CRMSystemUser: Record "CRM Systemuser";
        CRMAccount: Record "CRM Account";
        RecRef: RecordRef;
    begin
        // [FEATURE] [CDS Integration Management] [Entity Ownership]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] CDS Company exists
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);

        // [GIVEN] CRM Account exists
        LibraryCRMIntegration.CreateCRMTeam(CRMTeam);
        CRMAccount.OwnerIdType := CRMAccount.OwnerIdType::team;
        CRMAccount.OwnerId := CRMTeam.TeamId;
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);

        // [WHEN] Set Owning user
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemUser);
        RecRef.GetTable(CRMAccount);
        Assert.IsTrue(CDSIntegrationMgt.SetOwningUser(RecRef, CRMSystemUser.SystemUserId, true), 'Owner is not set.');

        // [THEN] Owner is set correctly
        RecRef.SetTable(CRMAccount);
        Assert.AreEqual(CRMAccount.OwnerIdType::systemuser, CRMAccount.OwnerIdType, 'Unexpected OwnerIdType.');
        Assert.AreEqual(CRMSystemUser.SystemUserId, CRMAccount.OwnerId, 'Unexpected OwnerId.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetOwningTeam()
    var
        CDSCompany: Record "CDS Company";
        CRMSystemUser: Record "CRM Systemuser";
        CRMAccount: Record "CRM Account";
        RecRef: RecordRef;
    begin
        // [FEATURE] [CDS Integration Management] [Entity Ownership]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] CDS Company exists
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);

        // [GIVEN] CRM Account exists
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemUser);
        CRMAccount.OwnerIdType := CRMAccount.OwnerIdType::systemuser;
        CRMAccount.OwnerId := CRMSystemUser.SystemUserId;
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);

        // [WHEN] Set Owning team
        RecRef.GetTable(CRMAccount);
        Assert.IsTrue(CDSIntegrationMgt.SetOwningTeam(RecRef), 'Owner is not set.');

        // [THEN] Owner is set correctly
        RecRef.SetTable(CRMAccount);
        Assert.AreEqual(CRMAccount.OwnerIdType::team, CRMAccount.OwnerIdType, 'Unexpected OwnerIdType.');
        Assert.AreEqual(CDSCompany.DefaultOwningTeam, CRMAccount.OwnerId, 'Unexpected OwnerId.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckCompanyId()
    var
        CDSCompany: Record "CDS Company";
        CRMSystemUser: Record "CRM Systemuser";
        CRMAccount: Record "CRM Account";
        RecRef: RecordRef;
    begin
        // [FEATURE] [CDS Integration Management] [CDS Company Entity]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] CDS Company exists
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);

        // [GIVEN] CRM Account exists
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemUser);
        CRMAccount.OwnerId := CRMSystemUser.SystemUserId;
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);

        // [WHEN] CompanyId is not the current one
        // [THEN] CheckCompanyId returns false
        RecRef.GetTable(CRMAccount);
        Assert.IsFalse(CDSIntegrationMgt.CheckCompanyId(RecRef), 'CompanyId is valid.');

        // [WHEN] Set current CompanyId
        Assert.IsTrue(CDSIntegrationMgt.SetCompanyId(RecRef), 'CompanyId is not set.');
        // [THEN] CheckCompanyId returns true
        Assert.IsTrue(CDSIntegrationMgt.CheckCompanyId(RecRef), 'CompanyId is invalid.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckOwningTeam()
    var
        CDSCompany: Record "CDS Company";
        CRMSystemUser: Record "CRM Systemuser";
        CRMAccount: Record "CRM Account";
        RecRef: RecordRef;
    begin
        // [FEATURE] [CDS Integration Management] [Entity Ownership]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] Default owning team exists, i.e CDSCompany.DefaultOwningTeam is not empty
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);

        // [WHEN] Account team is not the default team
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemUser);
        CRMAccount.OwnerIdType := CRMAccount.OwnerIdType::systemuser;
        CRMAccount.OwnerId := CRMSystemUser.SystemUserId;
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        // [THEN] CheckOwningTeam returns false
        RecRef.GetTable(CRMAccount);
        Assert.IsFalse(CDSIntegrationMgt.CheckOwningTeam(RecRef), 'Owner is valid.');

        // [WHEN] Account owning team is not the default one
        Assert.IsTrue(CDSIntegrationMgt.SetOwningTeam(RecRef), 'Owner is not set.');
        // [THEN] CheckOwningTeam returns false
        Assert.IsTrue(CDSIntegrationMgt.CheckOwningTeam(RecRef), 'Owner is invlid.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckOwningUserWithBusinessUnitCheck()
    var
        CDSCompany: Record "CDS Company";
        CRMTeam: Record "CRM Team";
        CRMBusinessunit: Record "CRM Businessunit";
        CRMSystemUser: Record "CRM Systemuser";
        CRMAccount: Record "CRM Account";
        RecRef: RecordRef;
    begin
        // [FEATURE] [CDS Integration Management] [Entity Ownership]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] Business Unit linked to the Default Owning Team exists
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);
        Assert.IsTrue(CRMTeam.Get(CDSCompany.DefaultOwningTeam), 'Team does not exist.');
        Assert.IsTrue(CRMBusinessunit.Get(CRMTeam.BusinessUnitId), 'Business Unit does not exist.');

        // [GIVEN] User with matching business unit exists
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemUser);
        CRMSystemUser.BusinessUnitId := CRMBusinessunit.BusinessUnitId;
        CRMSystemUser.Modify();

        // [WHEN] Account owning is a team
        LibraryCRMIntegration.CreateCRMTeam(CRMTeam);
        CRMAccount.OwnerIdType := CRMAccount.OwnerIdType::team;
        CRMAccount.OwnerId := CRMTeam.TeamId;
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        // [THEN] CheckOwningUser returns false
        RecRef.GetTable(CRMAccount);
        Assert.IsFalse(CDSIntegrationMgt.CheckOwningUser(RecRef, CRMSystemUser.SystemUserId), 'Owner is valid.');

        // [WHEN] Set account owning user with matching business unit
        Assert.IsTrue(CDSIntegrationMgt.SetOwningUser(RecRef, CRMSystemUser.SystemUserId), 'Owner is not set.');
        // [THEN] CheckOwningUser returns true
        Assert.IsTrue(CDSIntegrationMgt.CheckOwningUser(RecRef, CRMSystemUser.SystemUserId), 'Owner is not set.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckOwningUserSkipBusinessUnitCheck()
    var
        CDSCompany: Record "CDS Company";
        CRMTeam: Record "CRM Team";
        CRMSystemUser: Record "CRM Systemuser";
        CRMAccount: Record "CRM Account";
        RecRef: RecordRef;
    begin
        // [FEATURE] [CDS Integration Management] [Entity Ownership]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] Default owning team exists, i.e CDSCompany.DefaultOwningTeam is not empty
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);

        // [GIVEN] User withouit matching business unit exists
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemUser);

        // [WHEN] Account owning is a team
        LibraryCRMIntegration.CreateCRMTeam(CRMTeam);
        CRMAccount.OwnerIdType := CRMAccount.OwnerIdType::team;
        CRMAccount.OwnerId := CRMTeam.TeamId;
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        // [THEN] CheckOwningUser returns false
        RecRef.GetTable(CRMAccount);
        Assert.IsFalse(CDSIntegrationMgt.CheckOwningUser(RecRef, CRMSystemUser.SystemUserId), 'Owner is valid.');

        // [WHEN] Set account owning user with matching business unit
        Assert.IsTrue(CDSIntegrationMgt.SetOwningUser(RecRef, CRMSystemUser.SystemUserId, true), 'Owner is not set.');
        // [THEN] CheckOwningUser returns true
        Assert.IsTrue(CDSIntegrationMgt.CheckOwningUser(RecRef, CRMSystemUser.SystemUserId, true), 'Owner is not set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCompanyCache()
    var
        CDSCompany: Record "CDS Company";
        CRMSystemuser: Record "CRM Systemuser";
        CRMAccount: Record "CRM Account";
        RecRef: RecordRef;
        CachedCompanyId: Guid;
    begin
        // [FEATURE] [CDS Integration Management] [Entity Ownership]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] CDS Company exists
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);
        CachedCompanyId := CDSCompany.CompanyId;

        // [GIVEN] CRM Account exists
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemUser);
        CRMAccount.OwnerIdType := CRMAccount.OwnerIdType::systemuser;
        CRMAccount.OwnerId := CRMSystemUser.SystemUserId;
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);

        // [WHEN] Set Account Compny ID
        RecRef.GetTable(CRMAccount);
        Assert.IsTrue(CDSIntegrationMgt.SetCompanyId(RecRef), 'CompanyId is not set.');
        // [THEN] Account Owner is the Default Owning Team
        RecRef.SetTable(CRMAccount);
        Assert.AreEqual(CachedCompanyId, CRMAccount.CompanyId, 'Unexpected CompanyId.');
        Assert.AreEqual(CDSCompany.CompanyId, CRMAccount.CompanyId, 'Unexpected CompanyId.');

        // [WHEN] Delete the old company and create a new one
        CDSCompany.DeleteAll();
        Clear(CDSCompany);
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);
        Assert.AreNotEqual(CachedCompanyId, CDSCompany.CompanyId, 'CompanyId is not changed.');
        // [WHEN] Set Account Company ID again
        Assert.IsTrue(CDSIntegrationMgt.SetCompanyId(RecRef), 'CompanyId is not set.');
        // [THEN] Account Company ID is set to the Cached Company ID instead of the new one
        RecRef.SetTable(CRMAccount);
        Assert.AreEqual(CachedCompanyId, CRMAccount.CompanyId, 'Unexpected CompanyId before cache reset.');

        // [WHEN] Reset the cache
        CDSIntegrationMgt.ResetCache();
        // [WHEN] Set Account Company ID again
        Assert.IsTrue(CDSIntegrationMgt.SetCompanyId(RecRef), 'CompanyId is not set.');
        // [THEN] Account Company ID is the New Company ID
        RecRef.SetTable(CRMAccount);
        Assert.AreEqual(CDSCompany.CompanyId, CRMAccount.CompanyId, 'Unexpected CompanyId after cache reset.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDefaultOwningTeamCache()
    var
        CDSCompany: Record "CDS Company";
        CRMTeam: Record "CRM Team";
        CRMSystemuser: Record "CRM Systemuser";
        CRMAccount: Record "CRM Account";
        RecRef: RecordRef;
        CachedDefaultOwningTeamId: Guid;
    begin
        // [FEATURE] [CDS Integration Management] [Entity Ownership]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] CDS Default Owning Team exists
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);
        Assert.IsTrue(CRMTeam.Get(CDSCompany.DefaultOwningTeam), 'Team does not exist.');
        CachedDefaultOwningTeamId := CDSCompany.DefaultOwningTeam;

        // [GIVEN] CRM Account exists
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemUser);
        CRMAccount.OwnerIdType := CRMAccount.OwnerIdType::systemuser;
        CRMAccount.OwnerId := CRMSystemUser.SystemUserId;
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);

        // [WHEN] Set Account Owning Team
        RecRef.GetTable(CRMAccount);
        Assert.IsTrue(CDSIntegrationMgt.SetOwningTeam(RecRef), 'Owner is not set.');
        // [THEN] Account Owner is the Default Owning Team
        RecRef.SetTable(CRMAccount);
        Assert.AreEqual(CachedDefaultOwningTeamId, CRMAccount.OwnerId, 'Unexpected OwnerId.');

        // [WHEN] Delete the old Team and the old Company
        CRMTeam.DeleteAll();
        CDSCompany.DeleteAll();
        Clear(CRMTeam);
        Clear(CDSCompany);
        // [WHEN] Create a new company and and a new team
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);
        Assert.IsTrue(CRMTeam.Get(CDSCompany.DefaultOwningTeam), 'Team does not exist.');
        Assert.AreNotEqual(CachedDefaultOwningTeamId, CDSCompany.DefaultOwningTeam, 'DefaultOwningTeam is not changed.');
        // [WHEN] Set Account Owning Team again
        Assert.IsTrue(CDSIntegrationMgt.SetOwningTeam(RecRef), 'Owner is not set.');
        // [THEN] Account Owner is set to the Cached Default Owning Team instead of the new one
        RecRef.SetTable(CRMAccount);
        Assert.AreEqual(CachedDefaultOwningTeamId, CRMAccount.OwnerId, 'Unexpected OwnerId before cache reset.');

        // [WHEN] Reset the cache
        CDSIntegrationMgt.ResetCache();
        // [WHEN] Set Account Owning Team again
        Assert.IsTrue(CDSIntegrationMgt.SetOwningTeam(RecRef), 'Owner is not set.');
        // [THEN] Account Owner is the New Default Owning Team
        RecRef.SetTable(CRMAccount);
        Assert.AreEqual(CDSCompany.DefaultOwningTeam, CRMAccount.OwnerId, 'Unexpected OwnerId after cache reset.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBusinessUnitCache()
    var
        CDSCompany: Record "CDS Company";
        CRMTeam: Record "CRM Team";
        CRMSystemUser: Record "CRM Systemuser";
        CRMBusinessunit: Record "CRM Businessunit";
        CRMAccount: Record "CRM Account";
        RecRef: RecordRef;
        CachedBusinessUnitId: Guid;
    begin
        // [FEATURE] [CDS Integration Management] [Entity Ownership]
        Initialize();
        // [GIVEN] CDS Connection is enabled
        RegisterTestTableConnection();

        // [GIVEN] Business Unit linked to the Default Owning Team exists
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);
        Assert.IsTrue(CRMTeam.Get(CDSCompany.DefaultOwningTeam), 'Team does not exist.');
        Assert.IsTrue(CRMBusinessunit.Get(CRMTeam.BusinessUnitId), 'Business unit does not exist.');
        CachedBusinessUnitId := CRMBusinessunit.BusinessUnitId;

        // [GIVEN] User with matching business unit exists
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemUser);
        CRMSystemUser.BusinessUnitId := CRMBusinessunit.BusinessUnitId;
        CRMSystemUser.Modify();

        // [GIVEN] CRM Account exists
        LibraryCRMIntegration.CreateCRMTeam(CRMTeam);
        CRMAccount.OwnerIdType := CRMAccount.OwnerIdType::team;
        CRMAccount.OwnerId := CRMTeam.TeamId;
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);

        // [GIVEN] Account Owning User is set
        RecRef.GetTable(CRMAccount);
        Assert.IsTrue(CDSIntegrationMgt.SetOwningUser(RecRef, CRMSystemUser.SystemUserId, true), 'Owner is not set.');
        Assert.IsTrue(CDSIntegrationMgt.CheckOwningUser(RecRef, CRMSystemUser.SystemUserId, false), 'Owning User Business Unit is incorrect.');

        // [WHEN] Delete the old Business Unit, Team and Company
        CRMBusinessunit.DeleteAll();
        CRMTeam.DeleteAll();
        CDSCompany.DeleteAll();
        Clear(CRMBusinessunit);
        Clear(CRMTeam);
        Clear(CDSCompany);
        // [WHEN] Create a new Company, Team and Business Unit
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);
        Assert.IsTrue(CRMTeam.Get(CDSCompany.DefaultOwningTeam), 'Team does not exist.');
        Assert.IsTrue(CRMBusinessunit.Get(CRMTeam.BusinessUnitId), 'Business unit does not exist.');
        Assert.AreNotEqual(CachedBusinessUnitId, CRMBusinessunit.BusinessUnitId, 'Business Unit is not changed.');
        // [WHEN] Set new Owning User without Business Unit check
        RecRef.GetTable(CRMAccount);
        Assert.IsTrue(CDSIntegrationMgt.SetOwningUser(RecRef, CRMSystemUser.SystemUserId, true), 'Owner is not set.');
        // [THEN] Business Unit Check is still successful
        Assert.IsTrue(CDSIntegrationMgt.CheckOwningUser(RecRef, CRMSystemUser.SystemUserId, false), 'Owning User Business Unit is not cached.');

        // [WHEN] Reset the cache
        CDSIntegrationMgt.ResetCache();
        // [THEN] Business Unit Check is failed
        Assert.IsFalse(CDSIntegrationMgt.CheckOwningUser(RecRef, CRMSystemUser.SystemUserId, false), 'Owning User Business Unit is not updated in the cached.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingSalesPerson()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [Salesperson] [Direction]
        Initialize();
        RegisterTestTableConnection();
        ResetDefaultCDSSetupConfiguration();
        // [WHEN] Find Integration Table Mapping for "Salesperson/Purchaser"
        // [THEN] Mapped to "CRM Systemuser", Direction is "From Integration Table",
        // [THEN] no "Table Filter", no "Integration Table Filter", not "Integration user mode", is "Lisenced User", "Synch. Only Coupled Records" is Yes
        VerifyTableMapping(
          DATABASE::"Salesperson/Purchaser", DATABASE::"CRM Systemuser", IntegrationTableMapping.Direction::FromIntegrationTable,
          '', 'VERSION(1) SORTING(Field1) WHERE(Field31=1(0),Field96=1(0),Field107=1(1))', true);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure DefaultInactivityTimeoutPeriodOwnershipModelTeam()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [Inactivity Timeout Period]
        // [SCENARIO] Inactivity Timeout Period has value on Reset Default CDS Setup Configuration
        Initialize();
        RegisterTestTableConnection();
        // [GIVEN] Ownership model is team
        CDSConnectionSetup.Get();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Team;
        CDSConnectionSetup.Modify();

        // [WHEN] Reset Default CRM Setup Configuration
        ResetDefaultCDSSetupConfiguration();

        // [THEN] Job queue entries with respective No. of Minutes between Runs & Inactivity Timeout Period
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720, ' CUSTOMER - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720, ' VENDOR - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720, ' CONTACT - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720, ' CURRENCY - Dataverse synchronization job.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultInactivityTimeoutPeriodOwnershipModelPerson()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        // [FEATURE] [Inactivity Timeout Period]
        // [SCENARIO] Inactivity Timeout Period has value on Reset Default CDS Setup Configuration
        Initialize();
        RegisterTestTableConnection();
        // [GIVEN] Ownership model is team
        CDSConnectionSetup.Get();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Person;
        CDSConnectionSetup.Modify();

        // [WHEN] Reset Default CRM Setup Configuration
        ResetDefaultCDSSetupConfiguration();

        // [THEN] Job queue entries with respective No. of Minutes between Runs & Inactivity Timeout Period
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720, ' CUSTOMER - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720, ' VENDOR - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720, ' CONTACT - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720, ' CURRENCY - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 1440, ' SALESPEOPLE - Dataverse synchronization job.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManIntTableMappingEmptyIntegrationMappingName()
    var
        CDSNewManIntTableWizard: TestPage "CDS New Man. Int. Table Wizard";
    begin
        // [SCENARIO] Give error when Integration Mapping Name is empty
        Initialize();
        // [GIVEN] Manual Integration Table Mapping Wizard is opened
        CDSNewManIntTableWizard.OpenEdit();

        // [WHEN] Integration Mapping Name is empty
        CDSNewManIntTableWizard.Name.SetValue('');

        // [THEN] Error message is shown on Next
        asserterror CDSNewManIntTableWizard.ActionNext.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManIntTableMappingEmptyIntegrationTableID()
    var
        CDSNewManIntTableWizard: TestPage "CDS New Man. Int. Table Wizard";
    begin
        // [SCENARIO] Give error when Integration TableId is empty
        Initialize();
        // [GIVEN] Manual Integration Table Mapping Wizard is opened and filled
        CDSNewManIntTableWizard.OpenEdit();
        CDSNewManIntTableWizard.Name.SetValue('TEST');
        CDSNewManIntTableWizard.ActionNext.Invoke();
        CDSNewManIntTableWizard.TableId.SetValue('Customer');
        CDSNewManIntTableWizard.IntegrationTableUID.SetValue('');
        CDSNewManIntTableWizard.IntTblModifiedOnId.SetValue('');

        // [WHEN] Integration TableId is empty
        CDSNewManIntTableWizard.IntegrationTableID.SetValue('');

        // [THEN] Error message is shown on Next
        asserterror CDSNewManIntTableWizard.ActionNext.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManIntTableMappingEmptyTableId()
    var
        CDSNewManIntTableWizard: TestPage "CDS New Man. Int. Table Wizard";
    begin
        // [SCENARIO] Give error when Integration Mapping Int TableId is empty
        Initialize();
        // [GIVEN] Manual Integration Table Mapping Wizard is opened and filled
        CDSNewManIntTableWizard.OpenEdit();
        CDSNewManIntTableWizard.Name.SetValue('TEST');
        CDSNewManIntTableWizard.ActionNext.Invoke();
        CDSNewManIntTableWizard.IntegrationTableID.SetValue('Dataverse Contact');
        CDSNewManIntTableWizard.IntegrationTableUID.SetValue('1');
        CDSNewManIntTableWizard.IntTblModifiedOnId.SetValue('59');

        // [WHEN] TableId is empty
        CDSNewManIntTableWizard.TableId.SetValue('');

        // [THEN] Error message is shown on Next
        asserterror CDSNewManIntTableWizard.ActionNext.Invoke();
    end;

    local procedure Initialize()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        if CryptographyManagement.IsEncryptionEnabled() then
            CryptographyManagement.DisableEncryption(true);
        Assert.IsFalse(EncryptionEnabled(), 'Encryption should be disabled');

        CDSIntegrationMgt.ResetCache();
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, '');
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, CDSIntegrationImpl.GetConnectionDefaultName());
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST');
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM));
        Assert.AreEqual('', GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM), 'DEFAULTTABLECONNECTION should not be registered');

        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();

        LibraryVariableStorage.Clear();
        LibraryMockCRMConnection.MockConnection();

        if IsInitialized then
            exit;

        IsInitialized := true;
        SetTenantLicenseStateToTrial();
    end;

    local procedure SetTenantLicenseStateToTrial()
    var
        TenantLicenseState: Record "Tenant License State";
    begin
        TenantLicenseState."Start Date" := CurrentDateTime();
        TenantLicenseState.State := TenantLicenseState.State::Trial;
        TenantLicenseState.Insert();
    end;

    local procedure ResetDefaultCDSSetupConfiguration()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
    begin
        CDSConnectionSetup.Get();
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
    end;

    local procedure VerifyTableMapping(TableID: Integer; IntegrationTableID: Integer; IntegrationDirection: Option; TableFilter: Text; IntegrationTableFilter: Text; SynchOnlyCoupledRecords: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.SetRange("Table ID", TableID);
        IntegrationTableMapping.FindFirst();
        Assert.AreEqual(IntegrationDirection, IntegrationTableMapping.Direction, IntegrationTableMapping.FieldName(Direction));
        Assert.AreEqual(IntegrationTableID, IntegrationTableMapping."Integration Table ID", IntegrationTableMapping.FieldName("Integration Table ID"));
        Assert.AreEqual(TableFilter, IntegrationTableMapping.GetTableFilter(), IntegrationTableMapping.FieldName("Table Filter"));
        Assert.AreEqual(IntegrationTableFilter, IntegrationTableMapping.GetIntegrationTableFilter(), IntegrationTableMapping.FieldName("Integration Table Filter"));
        Assert.AreEqual(SynchOnlyCoupledRecords, IntegrationTableMapping."Synch. Only Coupled Records", IntegrationTableMapping.FieldName("Synch. Only Coupled Records"));
    end;

    local procedure VerifyJobQueueEntriesInactivityTimeoutPeriod(NoOfMinutesBetweenRuns: Integer; ExpectedInactivityTimeoutPeriod: Integer; JobDescription: Text[250])
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Integration Synch. Job Runner");
        JobQueueEntry.SetRange("No. of Minutes between Runs", NoOfMinutesBetweenRuns);
        JobQueueEntry.SetRange(Description, JobDescription);
        JobQueueEntry.FindFirst();
        Assert.AreEqual(ExpectedInactivityTimeoutPeriod, JobQueueEntry."Inactivity Timeout Period",
          'Inactivity time out period different from default.');
    end;

    local procedure InitializeSetup(IsEnabled: Boolean)
    begin
        InitializeSetup(TestServerAddressTok, IsEnabled);
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
    var
        CDSCompany: Record "CDS Company";
        CRMBusinessUnit: Record "CRM Businessunit";
        CRMTeam: Record "CRM Team";
        CRMSystemuser: Record "CRM Systemuser";
    begin
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST');
        RegisterTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST', TestServerAddressTok);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST');
        InitializeSetup(true);
        CRMSystemuser.DeleteAll();
        CRMTeam.DeleteAll();
        CRMBusinessUnit.DeleteAll();
        CDSCompany.DeleteAll();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageDequeue(Message: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
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
}
