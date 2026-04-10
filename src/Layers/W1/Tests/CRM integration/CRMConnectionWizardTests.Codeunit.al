codeunit 139314 "CRM Connection Wizard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Wizard]
    end;

    var
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        InitialCRMUrlTxt: Label 'https://test.crm.dynamics.com', Locked = true;
        CorrectConnectionStringTxt: Label 'https://test.api.crm.dynamics.com/XRMServices/2011/Organization.svc';
        WrongConnectionStringErr: Label 'Wrong connection string generated';
        EmailAndServerAddressEmptyErr: Label 'The Integration User Email and Server Address fields must not be empty.';
        EnabledTxt: Label 'Enabled';
        VisibleTxt: Label 'Visible';
        ShouldBeErr: Label '%1 should be %2';
        ShouldNotBeErr: Label '%1 should not be %2';
        DynamicsCRMURLEmptyErr: Label 'You must specify the URL of your %1 solution.';
        EmptySynchUserCredentialsErr: Label 'You must specify the credentials for the user account for synchronization with %1.';
        ButtonTxt: Label 'Button';
        AllCredentialsRequiredErr: Label 'A %1 URL and user name are required to enable a connection.';
        TheRowDoesNotExistErr: Label 'The row does not exist';
        CryptographyManagement: Codeunit "Cryptography Management";
        CRMProductName: Codeunit "CRM Product Name";

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenNotFinished()
    var
        GuidedExperience: Codeunit "Guided Experience";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] The CRM Connection Setup Wizard is run to the end but not finished
        RunWizardToCompletion(CRMConnectionSetupWizard);
        CRMConnectionSetupWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"CRM Connection Setup Wizard"), 'CRM Connection Setup status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenExitRightAway()
    var
        GuidedExperience: Codeunit "Guided Experience";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] The CRM Connection Setup Wizard wizard is exited right away
        CRMConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");
        CRMConnectionSetupWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"CRM Connection Setup Wizard"), 'CRM Connection Setup status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardNotExitedWhenConfirmIsNo()
    var
        GuidedExperience: Codeunit "Guided Experience";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] The CRM Connection Setup Wizard is closed but closing is not confirmed
        CRMConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");
        CRMConnectionSetupWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"CRM Connection Setup Wizard"), 'CRM Connection Setup status should not be completed.');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CRMConnectionSetupPageHandler')]
    procedure VerifyStatusCompletedWhenFinished()
    var
        GuidedExperience: Codeunit "Guided Experience";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] The CRM Connection Setup Wizard is completed
        RunWizardToCompletion(CRMConnectionSetupWizard);
        CRMConnectionSetupWizard.ActionFinish.Invoke();

        // [THEN] Status of the setup step is set to Completed
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"CRM Connection Setup Wizard"), 'CRM Connection Setup status should be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardWithExistedSetup()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [GIVEN] CRM Connection Setup already exists
        CreateCRMConnectionSetup(CRMConnectionSetup);
        // [WHEN] The CRM Connection Setup Wizard is closed but closing is not confirmed
        CRMConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");

        // [THEN] Wizard "Server Address" = CRM Connection Setup."Server Address"
        CRMConnectionSetupWizard.ActionNext.Invoke();
        Assert.AreEqual(
          CRMConnectionSetup."Server Address", CRMConnectionSetupWizard.ServerAddress.Value, 'Values must be the same');
        // [THEN] Wizard "Email" = CRM Connection Setup."User Name"
        CRMConnectionSetupWizard.ActionNext.Invoke();
        Assert.AreEqual(
          CRMConnectionSetup."User Name", CRMConnectionSetupWizard.Email.Value, 'Values must be the same');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardEmptyCRMServerAddress()
    var
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [SCENARIO 180150] CRM Connection Wizard does not allow empty CRM URL server address
        Initialize();

        // [GIVEN] CRM Connection Setup Wizard is opened
        CRMConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");

        // [WHEN] User does not fill Dynamics CRM URL and press Next
        CRMConnectionSetupWizard.ServerAddress.SetValue('');
        asserterror CRMConnectionSetupWizard.ActionNext.Invoke();

        // [THEN] Error message appears that Dynamics CRM URL should not be empty
        Assert.ExpectedError(StrSubstNo(DynamicsCRMURLEmptyErr, CRMProductName.SHORT()));
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardWithExistedSetupCommonFieldsFalse()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [SCENARIO 180150] If common CRM Connection Setup fields are disabled then Wizard shows them as editable
        Initialize();

        // [GIVEN] CRM Connection Setup already exists
        // [GIVEN] Solution Imported = FALSE, Enable CRM Connection = FALSE, Sales Order Integration = FALSE
        CreateCRMConnectionSetup(CRMConnectionSetup);
        CRMConnectionSetup."Is Enabled" := false;
        CRMConnectionSetup."Is CRM Solution Installed" := false;
        CRMConnectionSetup.Modify();

        // [GIVEN] CRM Connection Setup Wizard is opened
        CRMConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");
        CRMConnectionSetupWizard.ActionNext.Invoke();

        // [GIVEN] User password, Admin Email and password filled
        CRMConnectionSetupWizard.ActionNext.Invoke();
        CRMConnectionSetupWizard.Password.SetValue('ABC');

        // [WHEN] When final page of wizard opened
        CRMConnectionSetupWizard.ActionNext.Invoke();

        // [THEN] Import CRM Solution = FALSE and user can change it
        Assert.IsTrue(
          CRMConnectionSetupWizard.ImportCRMSolution.Enabled(),
          StrSubstNo(ShouldBeErr, CRMConnectionSetupWizard.ImportCRMSolution.Caption, EnabledTxt));
        CRMConnectionSetupWizard.ImportCRMSolution.AssertEquals(true);

        // [THEN] Enable CRM Connection = FALSE and user can change it
        Assert.IsTrue(
          CRMConnectionSetupWizard.EnableCRMConnection.Enabled(),
          StrSubstNo(ShouldBeErr, CRMConnectionSetupWizard.EnableCRMConnection.Caption, EnabledTxt));
        CRMConnectionSetupWizard.EnableCRMConnection.AssertEquals(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardWithExistedSetupCommonFieldsTrue()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [SCENARIO 180150] If common CRM Connection Setup fields are enabled then Wizard shows them as non-editable
        Initialize();

        // [GIVEN] CRM Connection Setup already exists
        // [GIVEN] Solution Imported = TRUE, Enable CRM Connection = TRUE, Sales Order Integration = TRUE
        CreateCRMConnectionSetup(CRMConnectionSetup);
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup."Is CRM Solution Installed" := true;
        CRMConnectionSetup.Modify();

        // [GIVEN] CRM Connection Setup Wizard is opened
        CRMConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");
        CRMConnectionSetupWizard.ActionNext.Invoke();

        // [GIVEN] User password, Admin Email and password filled
        CRMConnectionSetupWizard.ActionNext.Invoke();
        CRMConnectionSetupWizard.Password.SetValue('ABC');

        // [WHEN] When final page of wizard opened
        CRMConnectionSetupWizard.ActionNext.Invoke();

        // [THEN] Import CRM Solution = TRUE and user cannot change it
        Assert.IsFalse(
          CRMConnectionSetupWizard.ImportCRMSolution.Enabled(),
          StrSubstNo(ShouldNotBeErr, CRMConnectionSetupWizard.ImportCRMSolution.Caption, EnabledTxt));
        CRMConnectionSetupWizard.ImportCRMSolution.AssertEquals(true);

        // [THEN] Enable CRM Connection = TRUE and user cannot change it
        Assert.IsFalse(
          CRMConnectionSetupWizard.EnableCRMConnection.Enabled(),
          StrSubstNo(ShouldNotBeErr, CRMConnectionSetupWizard.EnableCRMConnection.Caption, EnabledTxt));
        CRMConnectionSetupWizard.EnableCRMConnection.AssertEquals(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmCRMConnectionSetupWizardHandler')]
    [Scope('OnPrem')]
    procedure VerifyWizardActionAdvanced()
    var
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [SCENARIO 197282] Advanced action button appears on second page of Wizard
        Initialize();

        // [WHEN] CRM Connection Wizard is opened
        CRMConnectionSetupWizard.OpenEdit();

        // [THEN] Advanced action button is disabled
        Assert.IsFalse(
          CRMConnectionSetupWizard.ActionAdvanced.Visible(),
          StrSubstNo(ShouldNotBeErr, ButtonTxt, VisibleTxt));

        // [WHEN] Second page of Wizard is opened
        CRMConnectionSetupWizard.ServerAddress.SetValue('https://test.dynamics.com');
        CRMConnectionSetupWizard.ActionNext.Invoke();

        // [THEN] Advanced action button is enabled
        Assert.IsTrue(
          CRMConnectionSetupWizard.ActionAdvanced.Visible(),
          StrSubstNo(ShouldBeErr, ButtonTxt, VisibleTxt));

        // [WHEN] User presses on button "Advanced"
        CRMConnectionSetupWizard.ActionAdvanced.Invoke();

        // [THEN] Button "Simple" is visible
        Assert.IsTrue(
          CRMConnectionSetupWizard.ActionSimple.Visible(),
          StrSubstNo(ShouldBeErr, ButtonTxt, VisibleTxt));

        // [WHEN] User presses on button "Simple"
        CRMConnectionSetupWizard.ActionSimple.Invoke();

        // [THEN] Button "Advanced" is visible
        Assert.IsTrue(
          CRMConnectionSetupWizard.ActionAdvanced.Visible(),
          StrSubstNo(ShouldBeErr, ButtonTxt, VisibleTxt));

        // [WHEN] User press "Back" button
        CRMConnectionSetupWizard.ActionBack.Invoke();

        // [THEN] Both "Advanced" and "Simple" buttons not visible
        Assert.IsFalse(
          CRMConnectionSetupWizard.ActionAdvanced.Visible(),
          StrSubstNo(ShouldNotBeErr, ButtonTxt, VisibleTxt));
        Assert.IsFalse(
          CRMConnectionSetupWizard.ActionSimple.Visible(),
          StrSubstNo(ShouldNotBeErr, ButtonTxt, VisibleTxt));

        // [WHEN] User press "Back" button
        CRMConnectionSetupWizard.ActionNext.Invoke();

        // [THEN] "Advanced" is Visible, "Simple" - not visible
        Assert.IsTrue(
          CRMConnectionSetupWizard.ActionAdvanced.Visible(),
          StrSubstNo(ShouldBeErr, ButtonTxt, VisibleTxt));
        Assert.IsFalse(
          CRMConnectionSetupWizard.ActionSimple.Visible(),
          StrSubstNo(ShouldNotBeErr, ButtonTxt, VisibleTxt));
        CRMConnectionSetupWizard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyWizardEmptySynchUserCredentialsError()
    var
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [SCENARIO 197282] If synch user credentials not filled user cannot finish Wizard
        Initialize();

        // [GIVEN] CRM Connection Wizard is opened, synch user credentials not filled
        CRMConnectionSetupWizard.OpenEdit();
        CRMConnectionSetupWizard.ServerAddress.SetValue('https://test.dynamics.com');
        CRMConnectionSetupWizard.Email.SetValue('');
        CRMConnectionSetupWizard.Password.SetValue('');
        CRMConnectionSetupWizard.ActionNext.Invoke();

        // [WHEN] Finish action button is invoked
        asserterror CRMConnectionSetupWizard.ActionFinish.Invoke();

        // [THEN] Error message appears stating user should fill synch user credentials
        Assert.ExpectedError(StrSubstNo(EmptySynchUserCredentialsErr, CRMProductName.SHORT()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMConnectionSetupCheckConnectRequiredFields()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Error message apprears when user email or server address are empty
        Initialize();
        asserterror CRMIntegrationManagement.CheckConnectRequiredFields(LibraryUtility.GenerateRandomText(10), '');
        Assert.ExpectedError(EmailAndServerAddressEmptyErr);
        asserterror CRMIntegrationManagement.CheckConnectRequiredFields('', LibraryUtility.GenerateRandomText(10));
        Assert.ExpectedError(EmailAndServerAddressEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMConnectionSetupConstructConnectionString()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Construct CRM connection string from user CRM URL
        Initialize();
        Assert.AreEqual(
          CorrectConnectionStringTxt, CRMIntegrationManagement.ConstructConnectionStringForSolutionImport(InitialCRMUrlTxt),
          WrongConnectionStringErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMConnectionSetupEnableCRMConnectionFromWizard()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        TempCRMConnectionSetup: Record "CRM Connection Setup" temporary;
        DummyPassword: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] EnableCRMConnectionFromWizard() should execute on the context record
        Initialize();

        // [GIVEN] real CRMConnectionSetup has all credentials set
        CRMConnectionSetup.Init();
        CRMConnectionSetup."Server Address" := 'https://somedomain.dynamics.com';
        CRMConnectionSetup."User Name" := 'user@test.net';
        DummyPassword := 'password';
        CRMConnectionSetup.SetPassword(DummyPassword);
        CRMConnectionSetup.Insert();
        // [WHEN] EnableCRMConnectionFromWizard() on a empty CRMConnectionSetup
        TempCRMConnectionSetup.Insert();
        asserterror TempCRMConnectionSetup.EnableCRMConnectionFromWizard();
        // [THEN] Error: 'All credentials required to enable connection'
        Assert.ExpectedError(StrSubstNo(AllCredentialsRequiredErr, CRMProductName.SHORT()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMConnectionSetupUpdateFromWizard()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        TempCRMConnectionSetup: Record "CRM Connection Setup" temporary;
        DummyPassword: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] UpdateFromWizard() should set credentials on the context record
        Initialize();
        CRMConnectionSetup."Server Address" := 'https://somedomain.dynamics.com';
        CRMConnectionSetup."User Name" := 'user@test.net';

        // [WHEN] UpdateFromWizard() on the temp record
        DummyPassword := 'password';
        TempCRMConnectionSetup.UpdateFromWizard(CRMConnectionSetup, DummyPassword);

        // [THEN] The temp record got set
        Assert.IsTrue(TempCRMConnectionSetup.Get(), 'temp record should exist');
        Assert.IsTrue(TempCRMConnectionSetup.HasPassword(), 'password must be set');
        TempCRMConnectionSetup.TestField("Server Address", CRMConnectionSetup."Server Address");
        TempCRMConnectionSetup.TestField("User Name", CRMConnectionSetup."User Name");
        // [THEN] The real record is not inserted
        Assert.IsFalse(CRMConnectionSetup.Get(), 'real record should not exist');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CRMConnectionSetupPageHandler')]
    procedure CRMConnectionWizardFinishShouldUpdateRealRecord()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
        LatestSDKVersion: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Step Finish should update the real record
        Initialize();
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();

        // [GIVEN] CRM Connection Setup Wizard is opened
        CRMConnectionSetupWizard.OpenNew();
        // [GIVEN] Fill Office365 parameters
        CRMConnectionSetupWizard.ServerAddress.SetValue('@@test@@');
        CRMConnectionSetupWizard.ActionNext.Invoke();
        CRMConnectionSetupWizard.Password.SetValue('***');
        CRMConnectionSetupWizard.ActionNext.Invoke();
        CRMConnectionSetupWizard.ImportCRMSolution.SetValue(Format(false));

        // [WHEN] Finish pressed
        CRMConnectionSetupWizard.ActionFinish.Invoke();

        // [THEN] CRM Connection Setup, where password is set, connection is enabled
        CRMConnectionSetup.Get();
        CRMConnectionSetup.TestField("User Password Key");
        CRMConnectionSetup.TestField("Is Enabled");
        Assert.ExpectedMessage('Url', CRMConnectionSetup.GetConnectionString());
        CRMConnectionSetup.RefreshDataFromCRM();
        // [THEN] user mapping is disabled
        // [THEN] The latest SDK proxy version is by default
        LatestSDKVersion := LibraryCRMIntegration.GetLastestSDKVersion();
        CRMConnectionSetup.TestField("Proxy Version", LatestSDKVersion);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure CRMConnectionWizardCheckModifyCRMConnectionURL()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        Address: Text[250];
    begin
        // [FEATURE] [UT]
        // [SCENARIO] CRM Connection URL should comply with rules
        Initialize();

        // [GIVEN] Empty CRM Connection URL
        Address := '';
        // [WHEN] The URL is checked
        CRMIntegrationManagement.CheckModifyCRMConnectionURL(Address);
        // [THEN] The returned URL is empty
        Assert.AreEqual('', Address, WrongConnectionStringErr);
        // [GIVEN] CRM Connection URL = 'test.dynamics.com'
        Address := 'test.dynamics.com';
        // [WHEN] The URL is checked
        CRMIntegrationManagement.CheckModifyCRMConnectionURL(Address);
        // [THEN] The returned URL = 'https://test.dynamics.com'
        Assert.AreEqual('https://test.dynamics.com', Address, WrongConnectionStringErr);

        // [GIVEN] CRM Connection URL = 'http://test.com'
        Address := 'http://test1.com';
        // [WHEN] The URL is checked
        CRMIntegrationManagement.CheckModifyCRMConnectionURL(Address);
        // [THEN] Error message that security connection (https) is required
        Assert.AreEqual('http://test1.com', Address, WrongConnectionStringErr);

        // [GIVEN] CRM Connection URL = 'http://test.com:555/myOrg'
        Address := 'http://test2.com:555/myOrg';
        // [WHEN] The URL is checked
        CRMIntegrationManagement.CheckModifyCRMConnectionURL(Address);
        // [THEN] Error message that security connection (https) is required
        Assert.AreEqual('http://test2.com:555/myOrg', Address, WrongConnectionStringErr);

        // [GIVEN] CRM Connection URL = 'http://test.com:555/myOrg'
        Address := 'http://test3.com/myOrg';
        // [WHEN] The URL is checked
        CRMIntegrationManagement.CheckModifyCRMConnectionURL(Address);
        // [THEN] Error message that security connection (https) is required
        Assert.AreEqual('http://test3.com', Address, WrongConnectionStringErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmCRMConnectionSetupWizardHandler')]
    [Scope('OnPrem')]
    procedure CRMConnectionWizardAllowsAnyServerAddressNoSetup()
    var
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
        Email: Text;
    begin
        // [SCENARIO 211412] CRM Connection Wizard allow entering email for CRM server address not containing 'dynamics.com'
        Initialize();

        // [GIVEN] CRM Connection Setup Wizard is opened
        // [GIVEN] Server address = "https://crm.abc.com"

        CRMConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");
        CRMConnectionSetupWizard.ServerAddress.SetValue('https://crm.abc.com');
        Email := 'abc@abc.com';
        CRMConnectionSetupWizard.ActionNext.Invoke();

        // [WHEN] Sync user email entered
        CRMConnectionSetupWizard.Email.SetValue(Email);

        // [THEN] No error appear
        CRMConnectionSetupWizard.Email.AssertEquals(Email);
        CRMConnectionSetupWizard.close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMConnectionWizardAllowsAnyServerAddressSetupExists()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
        Email: Text;
    begin
        // [SCENARIO 211819] CRM Connection Wizard allow entering email for CRM server address not containing 'dynamics.com' when setup already exists
        Initialize();

        // [GIVEN] CRM Connection Setup exists and "Authentication Type" = AD
        CRMConnectionSetup.Init();
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::AD;
        CRMConnectionSetup.Insert();

        // [GIVEN] CRM Connection Setup Wizard is opened
        // [GIVEN] Server address = "https://crm.abc.com"
        CRMConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");
        CRMConnectionSetupWizard.ServerAddress.SetValue('https://crm.abc.com');
        Email := 'abc@abc.com';
        CRMConnectionSetupWizard.ActionNext.Invoke();

        // [WHEN] Sync user email entered
        CRMConnectionSetupWizard.Email.SetValue(Email);

        // [THEN] No error appear
        CRMConnectionSetupWizard.Email.AssertEquals(Email);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CRMConnectionSetupPageHandler')]
    procedure CRMConnectionWizardCheck8SDKVersion()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO 234755] Check selected sdk version 8 copied to connection setup
        Initialize();
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();

        // [GIVEN] CRM Connection Setup Wizard is opened
        CRMConnectionSetupWizard.OpenNew();
        // [GIVEN] Fill Office365 parameters, SDK Version = 8
        CRMConnectionSetupWizard.ServerAddress.SetValue('@@test@@');
        CRMConnectionSetupWizard.ActionNext.Invoke();
        CRMConnectionSetupWizard.Password.SetValue('***');
        CRMConnectionSetupWizard.ActionNext.Invoke();
        CRMConnectionSetupWizard.ImportCRMSolution.SetValue(Format(false));
        CRMConnectionSetupWizard.SDKVersion.SetValue(8);
        // [WHEN] Finish pressed
        CRMConnectionSetupWizard.ActionFinish.Invoke();

        // [THEN] CRM Connection Setup has "Proxy Version" = 8
        CRMConnectionSetup.Get();
        CRMConnectionSetup.TestField("Proxy Version", 8);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CRMConnectionSetupPageHandler')]
    procedure CRMConnectionWizardCheck9SDKVersion()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO 234755] SDK Version '8' can be changed to '9'
        Initialize();
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();

        // [GIVEN] CRM Connection Setup Wizard is opened
        CRMConnectionSetupWizard.OpenNew();
        // [GIVEN] Fill Office365 parameters
        CRMConnectionSetupWizard.ServerAddress.SetValue('@@test@@');
        CRMConnectionSetupWizard.ActionNext.Invoke();
        CRMConnectionSetupWizard.Password.SetValue('***');
        CRMConnectionSetupWizard.ActionNext.Invoke();
        CRMConnectionSetupWizard.ImportCRMSolution.SetValue(Format(false));
        // [GIVEN] SDK Version 9 is selected
        // First selected 8 as 9 is default value
        CRMConnectionSetupWizard.SDKVersion.SetValue(8);
        CRMConnectionSetupWizard.SDKVersion.SetValue(9);
        // [WHEN] Finish pressed
        CRMConnectionSetupWizard.ActionFinish.Invoke();

        // [THEN] CRM Connection Setup has "Proxy Version" = 9
        CRMConnectionSetup.Get();
        CRMConnectionSetup.TestField("Proxy Version", 9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_UpdateFromWizardSetOffice365AuthType()
    var
        TempCRMConnectionSetup: Record "CRM Connection Setup" temporary;
        CRMConnectionSetup: Record "CRM Connection Setup";
        DummyPassword: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 211819] UpdateFromWizard should set "Authentication Type" = Office365 by default
        Initialize();
        TempCRMConnectionSetup.Init();
        TempCRMConnectionSetup.Insert();

        // [WHEN] UpdateFromWizard is run
        DummyPassword := '***';
        CRMConnectionSetup.UpdateFromWizard(TempCRMConnectionSetup, DummyPassword);

        // [THEN] CRM Connection Setup "Authentication Type" = Office365 by default
        Assert.AreEqual(
          CRMConnectionSetup."Authentication Type"::Office365, CRMConnectionSetup."Authentication Type",
          StrSubstNo(ShouldBeErr, CRMConnectionSetup.FieldCaption("Authentication Type"), 'Office365'));
    end;

    local procedure Initialize()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
        ClientSecret: Text;
    begin
        LibraryVariableStorage.Clear();
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider();
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
        CRMConnectionSetup.DeleteAll();
        CDSConnectionSetup.DeleteAll();
        CDSConnectionSetup."Is Enabled" := true;
        CDSConnectionSetup."Server Address" := 'https://test.dynamics.com';
        CDSConnectionSetup."User Name" := 'test@test.com';
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        ClientSecret := 'ClientSecret';
        CDSConnectionSetup.SetClientSecret(ClientSecret);
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure RunWizardToCompletion(var CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard")
    begin
        CRMConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");

        CRMConnectionSetupWizard.ServerAddress.SetValue('https://test.dynamics.com');
        CRMConnectionSetupWizard.ActionNext.Invoke();
        // Credentials page
        CRMConnectionSetupWizard.Email.SetValue('test@test.com');
        CRMConnectionSetupWizard.Password.SetValue('test1234');
        CRMConnectionSetupWizard.ImportCRMSolution.SetValue(false);
        CRMConnectionSetupWizard.EnableBidirectionalSalesOrderIntegration.SetValue(false);
        CRMConnectionSetupWizard.EnableCRMConnection.SetValue(false);
        Assert.IsFalse(CRMConnectionSetupWizard.ActionNext.Enabled(), 'Next should not be enabled at the end of the wizard');
    end;

    local procedure CreateCRMConnectionSetup(var CRMConnectionSetup: Record "CRM Connection Setup")
    begin
        CRMConnectionSetup.DeleteAll();

        CRMConnectionSetup.Init();
        CRMConnectionSetup."Server Address" := 'https://test.dynamics.com';
        CRMConnectionSetup."User Name" := 'test@test.com';
        CRMConnectionSetup.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
        if Question <> CryptographyManagement.GetEncryptionIsNotActivatedQst() then
            Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYesNoForUsers(Question: Text[1024]; var Reply: Boolean)
    var
        User: Record User;
    begin
        Reply := not User.IsEmpty();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UsersModalPageHandler(var Users: TestPage Users)
    var
        User: Record User;
        GUIDVAR: Variant;
        UserSecurityId: Guid;
    begin
        LibraryVariableStorage.Dequeue(GUIDVAR);
        UserSecurityId := GUIDVAR;
        User.Get(UserSecurityId);
        Users.GotoRecord(User);
        Users.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UsersCancelSelectionModalPageHandler(var Users: TestPage Users)
    begin
        Users.Cancel().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmCRMConnectionSetupWizardHandler(Question: Text[1024]; VAR Reply: Boolean)
    begin
        Reply := True;
        exit;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMAdminCredentialsModalPageHandler(var CRMAdministratorCredentials: TestPage "Dynamics CRM Admin Credentials")
    begin
        CRMAdministratorCredentials.Email.SetValue('abc@def.com');
        CRMAdministratorCredentials.Password.SetValue('abc');
        CRMAdministratorCredentials.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CRMSystemUsersPageHandler(var CRMSystemuserList: TestPage "CRM Systemuser List")
    var
        CRMGuidVAR: Variant;
        CRMGuid: Guid;
        InternalEmailAddress: Text;
    begin
        LibraryVariableStorage.Dequeue(CRMGuidVAR);
        CRMGuid := CRMGuidVAR;
        CRMSystemuserList.GotoKey(CRMGuid);
        InternalEmailAddress := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(
          InternalEmailAddress, CRMSystemuserList.InternalEMailAddress.Value,
          StrSubstNo(ShouldBeErr, CRMSystemuserList.InternalEMailAddress.Caption, InternalEmailAddress));

        LibraryVariableStorage.Dequeue(CRMGuidVAR);
        CRMGuid := CRMGuidVAR;
        asserterror CRMSystemuserList.GotoKey(CRMGuid);
        Assert.ExpectedError(TheRowDoesNotExistErr);

        LibraryVariableStorage.Dequeue(CRMGuidVAR);
        CRMGuid := CRMGuidVAR;
        asserterror CRMSystemuserList.GotoKey(CRMGuid);
        Assert.ExpectedError(TheRowDoesNotExistErr);

        LibraryVariableStorage.Dequeue(CRMGuidVAR);
        CRMGuid := CRMGuidVAR;
        asserterror CRMSystemuserList.GotoKey(CRMGuid);
        Assert.ExpectedError(TheRowDoesNotExistErr);

        CRMSystemuserList.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CRMConnectionSetupPageHandler(var CRMConnectionSetup: TestPage "CRM Connection Setup")
    begin
    end;
}
