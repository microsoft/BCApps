codeunit 139194 "CDS Connection Wizard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [cds Integration] [Wizard]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CryptographyManagement: Codeunit "Cryptography Management";
        NoEnvironmentSelectedErr: Label 'To sign in the administrator user you must specify an environment.';
        VisibleTxt: Label 'Visible';
        ShouldBeErr: Label '%1 should be %2', Comment = '%1=filed name, %2=visibility';
        ShouldNotBeErr: Label '%1 should not be %2', Comment = '%1=filed name, %2=visibility';
        WrongConnectionStringErr: Label 'Wrong connection string generated';
        MustUseHttpsErr: Label 'The application is set up to support secure connections (HTTPS) to the Dataverse environment only. You cannot use HTTP.';
        MissingClientIdOrSecretOnPremErr: Label 'You must register an Microsoft Entra application that will be used to connect to the Dataverse environment and specify the application id, secret and redirect URL in the Dataverse Connection Setup page.', Comment = 'Dataverse and Microsoft Entra are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
        IsInitialized: Boolean;
        IsSaaS: Boolean;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenNotFinished()
    var
        GuidedExperience: Codeunit "Guided Experience";
        CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] The CDS Connection Setup Wizard is run to the end but not finished
        RunWizardToCompletion(CDSConnectionSetupWizard);
        CDSConnectionSetupWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"CDS Connection Setup Wizard"), 'Dataverse Connection Setup status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenExitRightAway()
    var
        GuidedExperience: Codeunit "Guided Experience";
        CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] The CDS Connection Setup Wizard wizard is exited right away
        CDSConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CDS Connection Setup Wizard");
        CDSConnectionSetupWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"CDS Connection Setup Wizard"), 'Dataverse Connection Setup status should not be completed.');
    end;

    //[Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardNotExitedWhenConfirmIsNo()
    var
        GuidedExperience: Codeunit "Guided Experience";
        CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] The CDS Connection Setup Wizard is closed but closing is not confirmed
        CDSConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CDS Connection Setup Wizard");
        CDSConnectionSetupWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"CDS Connection Setup Wizard"), 'Dataverse Connection Setup status should not be completed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardEmptyCDSServerAddress()
    var
        CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard";
    begin
        // [SCENARIO 180150] CDS Connection Wizard does not allow empty CDS URL server address
        Initialize();

        // [GIVEN] cds Connection Setup Wizard is opened
        CDSConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CDS Connection Setup Wizard");

        // [WHEN] User does not fill CDS Environment URL presses Sign in with administrator user
        CDSConnectionSetupWizard.ActionNext.Invoke();
        CDSConnectionSetupWizard.ActionNext.Invoke();
        CDSConnectionSetupWizard.ServerAddress.SetValue('');

        asserterror CDSConnectionSetupWizard.SignInAdmin.Drilldown();

        // [THEN] Error message appears that an environment should be specified.
        Assert.ExpectedError(NoEnvironmentSelectedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmCDSConnectionSetupWizardHandler')]
    [Scope('OnPrem')]
    procedure VerifyWizardActionBack()
    var
        CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [SCENARIO 180150] User press back to return to previous Wizard page
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        // [GIVEN] CDS Connection Wizard is opened
        CDSConnectionSetupWizard.OpenEdit();

        // [GIVEN] Second page of Wizard is opened
        CDSConnectionSetupWizard.ActionNext.Invoke();
        CDSConnectionSetupWizard.Consent.SetValue(true);
        CDSConnectionSetupWizard.ActionNext.Invoke();

        Assert.IsTrue(
          CDSConnectionSetupWizard."Redirect URL".Visible(),
          StrSubstNo(ShouldBeErr, CDSConnectionSetupWizard."Redirect URL".Caption(), VisibleTxt));

        // [WHEN] User press Back
        CDSConnectionSetupWizard.ActionBack.Invoke();

        // [THEN] First page of Wizard is opened.
        Assert.IsFalse(
          CDSConnectionSetupWizard."Redirect URL".Visible(),
          StrSubstNo(ShouldNotBeErr, CDSConnectionSetupWizard."Redirect URL".Caption(), VisibleTxt));
        CDSConnectionSetupWizard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyWizardEmptyClientIDAndSecretError()
    var
        CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [SCENARIO 197282] If client id and secret are not filled user cannot sign in with admin 
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [GIVEN] CDS Connection Wizard is opened, client id and secret are not filled
        CDSConnectionSetupWizard.OpenEdit();
        CDSConnectionSetupWizard.ActionNext.Invoke();
        CDSConnectionSetupWizard."Client Id".SetValue('');
        CDSConnectionSetupWizard."Client Secret".SetValue('');
        CDSConnectionSetupWizard.ActionNext.Invoke();
        CDSConnectionSetupWizard.ServerAddress.SetValue('https://test.dynamics.com');

        // [WHEN] User presses Sign in with administrator
        asserterror CDSConnectionSetupWizard.SignInAdmin.Drilldown();

        // [THEN] Error message appears stating user should fill synch user credentials
        Assert.ExpectedError(MissingClientIdOrSecretOnPremErr);
        //CDSConnectionSetupWizard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure CDSConnectionWizardCheckModifyCDSConnectionURL()
    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        Address: Text[250];
    begin
        // [FEATURE] [UT]
        // [SCENARIO] CDS Connection URL should comply with rules
        Initialize();

        // [GIVEN] Empty CDS Connection URL
        Address := '';
        // [WHEN] The URL is checked
        CDSIntegrationImpl.CheckModifyConnectionURL(Address);
        // [THEN] The returned URL is empty
        Assert.AreEqual('', Address, WrongConnectionStringErr);
        // [GIVEN] CDS Connection URL = 'test.dynamics.com'
        Address := 'test.dynamics.com';
        // [WHEN] The URL is checked
        CDSIntegrationImpl.CheckModifyConnectionURL(Address);
        // [THEN] The returned URL = 'https://test.dynamics.com'
        Assert.AreEqual('https://test.dynamics.com', Address, WrongConnectionStringErr);

        // [GIVEN] CDS Connection URL = 'http://test.com'
        Address := 'http://test1.com';
        // [WHEN] The URL is checked
        asserterror CDSIntegrationImpl.CheckModifyConnectionURL(Address);
        // [THEN] Error message that security connection (https) is required
        Assert.ExpectedError(MustUseHttpsErr);

        // [GIVEN] CDS Connection URL = 'http://test.com:555/myOrg'
        Address := 'https://test2.com:555/myOrg';
        // [WHEN] The URL is checked
        CDSIntegrationImpl.CheckModifyConnectionURL(Address);
        // [THEN] Error message that security connection (https) is required
        Assert.AreEqual('https://test2.com:555/myOrg', Address, WrongConnectionStringErr);

        // [GIVEN] CDS Connection URL = 'http://test.com:555/myOrg'
        Address := 'https://test3.com/myOrg';
        // [WHEN] The URL is checked
        CDSIntegrationImpl.CheckModifyConnectionURL(Address);
        // [THEN] Error message that security connection (https) is required
        Assert.AreEqual('https://test3.com', Address, WrongConnectionStringErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure CDSConnectionWizardAllowsAnyServerAddressNoSetup()
    var
        CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Username: Text;
    begin
        // [SCENARIO 211412] CDS Connection Wizard allow entering email for CDS server address not containing 'dynamics.com'
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [GIVEN] CDS Connection Setup Wizard is opened
        // [GIVEN] Server address = "https://cds.abc.com"
        CDSConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CDS Connection Setup Wizard");
        CDSConnectionSetupWizard.ServerAddress.SetValue('https://cds.abc.com');

        Username := 'abc\abc';
        CDSConnectionSetupWizard.ActionNext.Invoke();

        // [WHEN] Sync user email entered
        CDSConnectionSetupWizard.Email.SetValue(Username);

        // [THEN] No error appear
        CDSConnectionSetupWizard.Email.AssertEquals(Username);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure CDSConnectionWizardAllowsAnyServerAddressSetupExists()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";

        Username: Text;
    begin
        // [SCENARIO 211819] CDS Connection Wizard allow entering email for CDS server address not containing 'dynamics.com' when setup already exists
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [GIVEN] CDS Connection Setup exists and "Authentication Type" = AD
        CDSConnectionSetup.Init();
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::AD;
        CDSConnectionSetup.Insert();

        // [GIVEN] CDS Connection Setup Wizard is opened
        // [GIVEN] Server address = "https://cds.abc.com"
        CDSConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CDS Connection Setup Wizard");
        CDSConnectionSetupWizard.ServerAddress.SetValue('https://cds.abc.com');
        Username := 'abc\abc';
        CDSConnectionSetupWizard.ActionNext.Invoke();

        // [WHEN] Sync user email entered
        CDSConnectionSetupWizard.Email.SetValue(Username);

        // [THEN] No error appear
        CDSConnectionSetupWizard.Email.AssertEquals(Username);
        CDSConnectionSetupWizard.Close();
    end;

    local procedure Initialize()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
        EnvironmentInformation: Codeunit "Environment Information";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        LibraryVariableStorage.Clear();
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider();
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
        CDSConnectionSetup.DeleteAll();
        if IsInitialized then begin
            EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(IsSaaS);
            exit;
        end;
        IsSaaS := EnvironmentInformation.IsSaaS();
        IsInitialized := true;
    end;

    local procedure RunWizardToCompletion(var CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard")
    begin
        CDSConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CDS Connection Setup Wizard");

        CDSConnectionSetupWizard.ServerAddress.SetValue('https://test.dynamics.com');
        CDSConnectionSetupWizard.ActionNext.Invoke();
        // Credentials page
        CDSConnectionSetupWizard.Email.SetValue('test@test.com');
        CDSConnectionSetupWizard.Password.SetValue('test1234');
        Assert.IsFalse(CDSConnectionSetupWizard.ActionNext.Enabled(), 'Next should not be enabled at the end of the wizard');
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
    procedure ConfirmCDSConnectionSetupWizardHandler(Question: Text[1024]; VAR Reply: Boolean)
    begin
        Reply := True;
        exit;
    end;
}