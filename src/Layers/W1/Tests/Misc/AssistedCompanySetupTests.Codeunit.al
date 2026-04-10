codeunit 139301 "Assisted Company Setup Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Initial Company Setup]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        NoConfigPackageFileMsg: Label 'There are no configuration package files defined in your system. Assisted company setup will not be fully functional. Please contact your system administrator.';
        LibraryRandom: Codeunit "Library - Random";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        AssistedSetupMockEvents: Codeunit "Assisted Setup Mock Events";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        BankStatementProviderExist: Boolean;
        InvalidPhoneNumberErr: Label 'The phone number is invalid.';
        InvalidUriErr: Label 'The URI is not valid.';
        IsEventSubscriptionInitialized: Boolean;
        FirstTestPageNameTxt: Label 'FIRST TEST Page';
        SecondTestPageNameTxt: Label 'SECOND TEST Page';

    [Test]
    [Scope('OnPrem')]
    procedure IsDemoCompanyShouldBeDefinedByCompanyInfoFlag()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        // [FEATURE] [Demo Company]
        // [SCENARIO] IsDemoCompany() should return CompanyInformation."Demo Company"
        CompanyInformation.Get();
        CompanyInformation."Demo Company" := false;
        CompanyInformation.Modify();
        Assert.IsFalse(CompanyInformationMgt.IsDemoCompany(), 'IsDemoCompany should be FALSE');

        CompanyInformation.Get();
        CompanyInformation."Demo Company" := true;
        CompanyInformation.Modify();
        Assert.IsTrue(CompanyInformationMgt.IsDemoCompany(), 'IsDemoCompany should be TRUE');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAssistedSetupIsInitialized()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        // [GIVEN] A newly setup NAV company
        Initialize();

        // [THEN] Assisted Setup has records
        Assert.IsTrue(AssistedSetupTestLibrary.HasAny(), 'Should not be empty.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAssistedSetupInitialize()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        // [GIVEN] An empty assisted setup table
        AssistedSetupTestLibrary.DeleteAll();
        Assert.IsFalse(AssistedSetupTestLibrary.HasAny(), 'Should be empty.');

        // [WHEN] The Initialize function is run
        AssistedSetupTestLibrary.CallOnRegister();

        // [THEN] Assisted Setup is initialized and has records
        Assert.IsTrue(AssistedSetupTestLibrary.HasAny(), 'Should not be empty.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAssistedSetupMailStatusIsUpdated()
    var
        TempAccount: Record "Email Account" temporary;
        GuidedExperience: Codeunit "Guided Experience";
        ConnectorMock: Codeunit "Connector Mock";
        EmailScenarioMock: Codeunit "Email Scenario Mock";
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        // [GIVEN] A newly setup company where SMTP hasen't been setup
        Initialize();
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Email Account Wizard"), 'Precondition failed. Email is set up.');

        // [WHEN] A connector is installed and an account is added
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);
        EmailScenarioMock.DeleteAllMappings();
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::Default, TempAccount."Account Id", TempAccount.Connector);

        // [WHEN] The assisted setup status is updated
        AssistedSetupTestLibrary.CallOnRegister();

        // [THEN] The assisted setup status is set to completed
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Email Account Wizard"), 'The Email status was not updated correctly.');

        // [WHEN] The assisted setup status is updated again
        AssistedSetupTestLibrary.CallOnRegister();

        // [THEN] The assisted setup status remains unchanged
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Email Account Wizard"), 'The Email status changed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAssistedSetupApprovalWorkflowIsUpdated()
    var
        ApprovalUserSetup: Record "User Setup";
        GuidedExperience: Codeunit "Guided Experience";
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        // [GIVEN] A newly setup company where SMTP hasen't been setup
        Initialize();
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Approval Workflow Setup Wizard"), 'Precondition failed. Approval Workflow is set up.');

        // [WHEN] Approval User Setup is set up
        ApprovalUserSetup.Init();
        ApprovalUserSetup."Approver ID" := 'MOCKUSER';
        ApprovalUserSetup.Insert();

        // [WHEN] The assisted setup status is updated
        AssistedSetupTestLibrary.CallOnRegister();

        // [THEN] The assisted setup status is set to completed
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Approval Workflow Setup Wizard"), 'The Approval Workflow status was not updated correctly.');

        // [WHEN] The assisted setup status is updated again
        AssistedSetupTestLibrary.CallOnRegister();

        // [THEN] The assisted setup status remains unchanged
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Approval Workflow Setup Wizard"), 'The Approval Workflow status changed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCompanySetupWizardCantBeEnabledOnExistingCompany()
    var
        Companies: TestPage Companies;
    begin
        // [GIVEN] A newly setup NAV company with ledger entries (e.g. CRONUS)
        Initialize();

        // [WHEN] The user tries to enable the wizard
        Companies.OpenEdit();
        Companies.FindFirstField(CompanyNameVar, CompanyName); // Company will be CRONUS in testruns

        // [THEN] An error is thrown if that company already is set up
        asserterror Companies.EnableAssistedCompanySetup.SetValue(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCompanySetupWizardCanBeEnabledOnANewCompany()
    var
        Company: Record Company;
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        ConfigurationPackageFile: Record "Configuration Package File";
        Companies: TestPage Companies;
        NewCompanyName: Text;
    begin
        // [GIVEN] No Configuration package file exists
        ConfigurationPackageFile.DeleteAll();

        // [GIVEN] A newly setup NAV company
        NewCompanyName := LibraryUtility.GenerateGUID();

        Company.Init();
        Company.Name := NewCompanyName;
        Company.Insert();

        // [WHEN] The user tries to enable the wizard
        Companies.OpenEdit();
        Companies.FindFirstField(CompanyNameVar, NewCompanyName);
        Companies.EnableAssistedCompanySetup.SetValue(true);

        // [THEN] A wizard record was created
        AssistedCompanySetupStatus.Get(NewCompanyName);

        // [THEN] The wizard is enabled
        Assert.IsTrue(AssistedCompanySetupStatus.Enabled, 'The wizard was not enabled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestFeatureSetupStatusCanBeSetAndRetrieved()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        // [GIVEN] A feature setup record
        GuidedExperience.InsertAssistedSetup('', '', '', 0, ObjectType::Page, Page::"Assisted Company Setup Wizard", "Assisted Setup Group"::Uncategorized, '', "Video Category"::Uncategorized, '');
        // [WHEN] The system tries to update the status on a existing feature
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Assisted Company Setup Wizard");

        // [THEN] The status of the feature is actually updated
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Assisted Company Setup Wizard"), 'Feature Status not updated correctly');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestWizardVerifyStatusNotCompletedWhenNotFinished()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AssistedCompanySetupWizard: TestPage "Assisted Company Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        InitializeForWizard();

        // [WHEN] The Assisted Company Setup wizard is run to the end but not finished
        RunWizardToCompletionAndTestEvents(AssistedCompanySetupWizard);
        AssistedCompanySetupWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Assisted Company Setup Wizard"), 'Set Up Company status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestWizardVerifyStatusNotCompletedWhenExitRightAway()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AssistedCompanySetupWizard: TestPage "Assisted Company Setup Wizard";
    begin
        // [GIVEN] A newly setup
        InitializeForWizard();

        // [WHEN] The Assisted Company Setup wizard is exited right away
        AssistedCompanySetupWizard.Trap();
        PAGE.Run(PAGE::"Assisted Company Setup Wizard");
        AssistedCompanySetupWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Assisted Company Setup Wizard"), 'Set Up Company status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestWizardVerifyStatusCompletedWhenOnlineFeedAccountIsSet()
    var
        BankAccount: Record "Bank Account";
        GuidedExperience: Codeunit "Guided Experience";
        BankStatementProviderMock: Codeunit "Bank Statement Provider Mock";
        AssistedCompanySetupWizard: TestPage "Assisted Company Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        BankAccount.Reset();
        BankAccount.DeleteAll();
        InitializeForWizard();

        // [WHEN] The Assisted Company Setup wizard is completed
        SetDemoCompany(false);
        BankStatementProviderExist := true;
        BankStatementProviderMock.SetBankStatementExist(BankStatementProviderExist);
        BindSubscription(BankStatementProviderMock);

        RunWizardToCompletionAndTestEvents(AssistedCompanySetupWizard);
        AssistedCompanySetupWizard.ActionFinish.Invoke();

        // [THEN] Status of the setup step is set to Completed
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Assisted Company Setup Wizard"), 'Set Up Company status should be completed.');
        Assert.AreEqual(1, BankAccount.Count, 'Expected that one account is created');

        // Thear down
        SetDemoCompany(true);
        BankAccount.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestWizardVerifyStatusCompletedWhenFinished()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AssistedCompanySetupWizard: TestPage "Assisted Company Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        InitializeForWizard();

        // [WHEN] The Assisted Company Setup wizard is completed
        RunWizardToCompletionAndTestEvents(AssistedCompanySetupWizard);
        AssistedCompanySetupWizard.ActionFinish.Invoke();

        // [THEN] Status of the setup step is set to Completed
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Assisted Company Setup Wizard"), 'Set Up Company status should be completed.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestWizardVerifyCompanyDisplayNameChangedOnCompanyNameChange()
    var
        AssistedCompanySetupWizard: TestPage "Assisted Company Setup Wizard";
        MyCompanyName: Text[30];
    begin
        // [GIVEN] A newly setup company
        InitializeForWizard();

        // [WHEN] The Assisted Company Setup wizard is completed
        AssistedCompanySetupWizard.Trap();
        PAGE.Run(PAGE::"Assisted Company Setup Wizard");

        MyCompanyName := GetRandomCompanyName();

        AssistedCompanySetupWizard.ActionNext.Invoke(); // Start the wizard
        AssistedCompanySetupWizard.ActionBack.Invoke(); // Welcome page
        AssistedCompanySetupWizard.ActionNext.Invoke(); // Company's Address Information page
        AssistedCompanySetupWizard.Name.SetValue(MyCompanyName);
        AssistedCompanySetupWizard.ActionNext.Invoke(); // Contact Information page
        if BankStatementProviderExist then
            AssistedCompanySetupWizard.ActionNext.Invoke(); // Online Bank Account Linking page
        AssistedCompanySetupWizard.ActionNext.Invoke(); // Bank Account Information page
        AssistedCompanySetupWizard.ActionNext.Invoke(); // Costing Method
        AssistedCompanySetupWizard.ActionNext.Invoke(); // That's it page

        Assert.IsFalse(AssistedCompanySetupWizard.ActionNext.Enabled(), 'Next should not be enabled at the end of the wizard');
        AssistedCompanySetupWizard.ActionFinish.Invoke();

        // [THEN] Company Display Name equals Company Name
        Assert.AreEqual(MyCompanyName, CompanyProperty.DisplayName(), 'Company Display Name should be equal to name set in wizard');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmNoHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestWizardVerifyWizardNotExitedWhenConfirmIsNo()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AssistedCompanySetupWizard: TestPage "Assisted Company Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        InitializeForWizard();

        // [WHEN] The Assisted Company Setup wizard is closed but closing is not confirmed
        AssistedCompanySetupWizard.Trap();
        PAGE.Run(PAGE::"Assisted Company Setup Wizard");
        AssistedCompanySetupWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Assisted Company Setup Wizard"), 'Set Up Company status should not be completed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestWizardValidatesPhoneNo()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        AssistedCompanySetupWizard: TestPage "Assisted Company Setup Wizard";
    begin
        // [SCENARIO] Go to the contact information page and input different values for the phone number

        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();

        // [GIVEN] The company setup wizard is on the contact information page
        AssistedCompanySetupWizard.Trap();
        PAGE.Run(PAGE::"Assisted Company Setup Wizard");

        AssistedCompanySetupWizard.ActionNext.Invoke(); // Company's Address Information page
        AssistedCompanySetupWizard.ActionNext.Invoke(); // Contact Information page

        // [WHEN] We set the phone number with an incorrect value
        // [THEN] There is an error
        asserterror AssistedCompanySetupWizard."Phone No.".SetValue('incorrect phone number :-(');
        Assert.ExpectedError(InvalidPhoneNumberErr);

        // [WHEN] We set the phone number with a correct value
        AssistedCompanySetupWizard."Phone No.".SetValue('+45 (123)-456-789');

        // [THEN] There is no error
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestWizardValidatesCompanyHomePage()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        AssistedCompanySetupWizard: TestPage "Assisted Company Setup Wizard";
    begin
        // [SCENARIO] Go to the contact information page and input different values for the company home page

        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();

        // [GIVEN] The company setup wizard is on the contact information page
        AssistedCompanySetupWizard.Trap();
        PAGE.Run(PAGE::"Assisted Company Setup Wizard");

        AssistedCompanySetupWizard.ActionNext.Invoke(); // Company's Address Information page
        AssistedCompanySetupWizard.ActionNext.Invoke(); // Contact Information page

        // [WHEN] We set the phone number with an incorrect value
        // [THEN] There is an error
        asserterror AssistedCompanySetupWizard."Home Page".SetValue('this is not an url');
        Assert.ExpectedError(InvalidUriErr);

        // [WHEN] We set the phone number with a correct value
        AssistedCompanySetupWizard."Home Page".SetValue('www.microsoft.com');

        // [THEN] There is no error
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyUserInput()
    var
        TempConfigSetup: Record "Config. Setup" temporary;
        CompanyInformation: Record "Company Information";
        AccountingPeriod: Record "Accounting Period";
        BankAccount: Record "Bank Account";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        AccountingPeriodeStartDate: Date;
    begin
        // [GIVEN] A Configuration Setup and an accounting period start date
        CompanyInformation.Get();
        TempConfigSetup.Init();
        TempConfigSetup.TransferFields(CompanyInformation);
        TempConfigSetup.Insert();
        AccountingPeriodeStartDate := CalcDate('<-CY>', Today);

        // [GIVEN] A newly set up company (mocked)
        CompanyInformation.DeleteAll();
        AccountingPeriod.DeleteAll();
        BankAccount.DeleteAll();
        Assert.RecordIsEmpty(CompanyInformation);
        Assert.RecordIsEmpty(AccountingPeriod);
        Assert.RecordIsEmpty(BankAccount);

        // [WHEN] The ApplyUserInput function is called
        AssistedCompanySetup.ApplyUserInput(TempConfigSetup, BankAccount, AccountingPeriodeStartDate, false);

        // [THEN] Company Information is filled out
        Assert.RecordIsNotEmpty(CompanyInformation);

        // [THEN] An Accounting Period is created
        Assert.RecordIsNotEmpty(AccountingPeriod);

        // [THEN] A Bank Account is created
        Assert.RecordIsNotEmpty(BankAccount);

        // [THEN] Bank Account Posting Group has a default value
        Assert.AreEqual(
          'OPERATING', GetBankAccountPostingGroup(CompanyInformationMgt.GetCompanyBankAccount()),
          BankAccount.FieldCaption("Bank Acc. Posting Group"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyUserInputAfterEvaluationPack()
    var
        TempConfigSetup: Record "Config. Setup" temporary;
        CompanyInformation: Record "Company Information";
        AccountingPeriod: Record "Accounting Period";
        BankAccount: Record "Bank Account";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        AccountingPeriodeStartDate: Date;
        OriginalPostingGroup: Code[20];
    begin
        // [SCENARIO] ApplyUserInput() should not override Bank Account's "Bank Acc. Posting Group" if it was already defined
        // [GIVEN] A Configuration Setup and an accounting period start date
        CompanyInformation.Get();
        TempConfigSetup.Init();
        TempConfigSetup.TransferFields(CompanyInformation);
        TempConfigSetup.Insert();
        AccountingPeriodeStartDate := CalcDate('<-CY>', Today);

        // [GIVEN] A newly set up company (mocked)
        CompanyInformation.DeleteAll();
        AccountingPeriod.DeleteAll();
        BankAccount.DeleteAll();
        Assert.RecordIsEmpty(CompanyInformation);
        Assert.RecordIsEmpty(AccountingPeriod);
        Assert.RecordIsEmpty(BankAccount);

        // [GIVEN] Company Bank Account is set up, where "Bank Acc. Posting Group" = 'CHECKING'
        OriginalPostingGroup := 'CHECKING';
        BankAccount."No." := CompanyInformationMgt.GetCompanyBankAccount();
        BankAccount."Bank Acc. Posting Group" := OriginalPostingGroup;
        BankAccount.Insert();

        // [WHEN] The ApplyUserInput function is called
        AssistedCompanySetup.ApplyUserInput(TempConfigSetup, BankAccount, AccountingPeriodeStartDate, false);

        // [THEN] Company Information is filled out
        Assert.RecordIsNotEmpty(CompanyInformation);

        // [THEN] There is still one Bank Account
        Assert.AreEqual(1, BankAccount.Count, BankAccount.TableCaption());
        // [THEN] Company Information data is copied to the Bank Account: "Bank Name", "Bank Branch No.", "Bank Account No.", "SWIFT Code", IBAN
        BankAccount.Find();
        Assert.AreEqual(CompanyInformation."Bank Name", BankAccount.Name, BankAccount.FieldCaption(Name));
        Assert.AreEqual(CompanyInformation."Bank Branch No.", BankAccount."Bank Branch No.", BankAccount.FieldCaption("Bank Branch No."));
        Assert.AreEqual(
          CompanyInformation."Bank Account No.", BankAccount."Bank Account No.", BankAccount.FieldCaption("Bank Account No."));
        Assert.AreEqual(CompanyInformation."SWIFT Code", BankAccount."SWIFT Code", BankAccount.FieldCaption("SWIFT Code"));
        Assert.AreEqual(CompanyInformation.IBAN, BankAccount.IBAN, BankAccount.FieldCaption(IBAN));
        // [THEN] Bank Account Posting Group is still 'CHECKING'
        Assert.AreEqual(
          OriginalPostingGroup, GetBankAccountPostingGroup(CompanyInformationMgt.GetCompanyBankAccount()),
          BankAccount.FieldCaption("Bank Acc. Posting Group"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApprovalWorkflowSetupWizardNotVisibleInBasicApplicationArea()
    begin
        // [SCENARIO 172916] Approval Workflow Setup Wizard in not Visible in Basic Application Area

        // [GIVEN] Application Area is set to Suite
        LibraryApplicationArea.EnableFoundationSetup();

        // [WHEN] Assisted Setup is initialized
        // [THEN] Assisted Setup Approval Workflow Setup Wizard is visible in Assisted Setup
        CheckWizardVisibility(PAGE::"Approval Workflow Setup Wizard", true);

        // [WHEN] Only Basic Application Area is Enabled
        LibraryApplicationArea.EnableBasicSetup();

        // [THEN] Approval Workflow Setup Wizard is not visible in Assisted Setup
        CheckWizardVisibility(PAGE::"Approval Workflow Setup Wizard", false);
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCRMConnectionWizardNotVisibleInBasicApplicationArea()
    begin
        // [SCENARIO 172916] CRM Connection Setup Wizard in not Visible in Basic Application Area

        // [GIVEN] Application Area is set to Suite
        LibraryApplicationArea.EnableFoundationSetup();

        // [WHEN] Assisted Setup is initialized
        // [THEN] Assisted Setup CRM Connection Setup Wizard is visible in Assisted Setup
        CheckWizardVisibility(PAGE::"CRM Connection Setup Wizard", true);

        // [WHEN] Only Basic Application Area is Enabled
        LibraryApplicationArea.EnableBasicSetup();
        // [THEN] CRM Connection Setup Wizard is not visible in Assisted Setup
        CheckWizardVisibility(PAGE::"CRM Connection Setup Wizard", false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRegisterExtensionAssistedSetup()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        AssistedSetupPag: TestPage "Assisted Setup";
    begin
        InitializeEventSubscription();

        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();

        AssistedSetupPag.OpenView();
        AssistedSetupPag.FILTER.SetFilter("Object ID to Run", Format(PAGE::"Item List"));
        Assert.AreEqual(FirstTestPageNameTxt, AssistedSetupPag.Name.Value, 'Wrong page name');
        AssistedSetupPag.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRegisterMultipleExtensionAssistedSetup()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        AssistedSetupPag: TestPage "Assisted Setup";
    begin
        InitializeEventSubscription();

        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();

        AssistedSetupPag.OpenView();
        AssistedSetupPag.FILTER.SetFilter("Object ID to Run", Format(PAGE::"Item List"));
        Assert.AreEqual(FirstTestPageNameTxt, AssistedSetupPag.Name.Value, 'Wrong page name');

        AssistedSetupPag.FILTER.SetFilter("Object ID to Run", Format(PAGE::"Customer List"));
        Assert.AreEqual(SecondTestPageNameTxt, AssistedSetupPag.Name.Value, 'Wrong page name');

        AssistedSetupPag.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestDeleteInactiveExtensionAssistedSetup()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        AssistedSetupPag: TestPage "Assisted Setup";
    begin
        InitializeEventSubscription();

        AssistedSetupTestLibrary.DeleteAll();

        AssistedSetupPag.OpenView();
        AssistedSetupPag.FILTER.SetFilter("Object ID to Run", Format(PAGE::"Item List"));
        // [THEN] Assisted Setup has records
        Assert.AreEqual(FirstTestPageNameTxt, AssistedSetupPag.Name.Value, 'Wrong page name');
        AssistedSetupPag.Close();

        UnbindSubscription(AssistedSetupMockEvents);
        IsEventSubscriptionInitialized := false;

        AssistedSetupTestLibrary.DeleteAll();

        AssistedSetupPag.OpenView();
        AssistedSetupPag.FILTER.SetFilter("Object ID to Run", Format(PAGE::"Item List"));
        Assert.IsFalse(AssistedSetupPag.First(), 'Unexpected Inactive page within the filter, inactive page should have been deleted.');
        AssistedSetupPag.Close();
    end;

    [Test]
    [HandlerFunctions('ItemListHandler')]
    [Scope('OnPrem')]
    procedure TestUpdateExtensionAssistedSetupStatus()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        AssistedSetupPag: TestPage "Assisted Setup";
        GuidedExperience: Codeunit "Guided Experience";
    begin
        InitializeEventSubscription();

        AssistedSetupTestLibrary.DeleteAll();

        AssistedSetupPag.OpenView();
        AssistedSetupPag.FILTER.SetFilter("Object ID to Run", Format(PAGE::"Item List"));
        // [THEN] Assisted Setup has records
        Assert.AreEqual(FirstTestPageNameTxt, AssistedSetupPag.Name.Value, 'Wrong page name');
        AssistedSetupPag."Start Setup".Invoke();
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Item List"), 'Incorrect wizard status');
        AssistedSetupPag.Close();
    end;

    local procedure RunWizardToCompletionAndTestEvents(var AssistedCompanySetupWizard: TestPage "Assisted Company Setup Wizard")
    begin
        AssistedCompanySetupWizard.Trap();
        PAGE.Run(PAGE::"Assisted Company Setup Wizard");

        AssistedCompanySetupWizard.ActionNext.Invoke(); // Start the wizard
        AssistedCompanySetupWizard.ActionBack.Invoke(); // Welcome page
        AssistedCompanySetupWizard.ActionNext.Invoke(); // Company's Address Information page
        AssistedCompanySetupWizard.ActionNext.Invoke(); // Contact Information page
        if BankStatementProviderExist then
            AssistedCompanySetupWizard.ActionNext.Invoke(); // Online Bank Account Linking page
        AssistedCompanySetupWizard.ActionNext.Invoke(); // Bank Account Information page
        AssistedCompanySetupWizard.ActionNext.Invoke(); // Costing Method
        AssistedCompanySetupWizard.ActionNext.Invoke(); // That's it page
        Assert.IsFalse(AssistedCompanySetupWizard.ActionNext.Enabled(), 'Next should not be enabled at the end of the wizard');
    end;

    local procedure GetBankAccountPostingGroup(BankAccNo: Code[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccNo);
        exit(BankAccount."Bank Acc. Posting Group");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AssistedCompanySetupCreateAccountingPeriodWithBlankStartDate()
    var
        AccountingPeriod: Record "Accounting Period";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
    begin
        // [FEATURE] [UT] [Assisted Company Setup]
        // [SCENARIO 273424] When CreateAccountingPeriod is called with <blank> StartDate in codeunit Assisted Company Setup then Accounting Periods are not created
        InitializeForWizard();

        // [GIVEN] New company with empty Accounting Period table
        AccountingPeriod.DeleteAll();

        // [WHEN] Call CreateAccountingPeriod with <blank> StartDate in codeunit Assisted Company Setup
        AssistedCompanySetup.CreateAccountingPeriod(0D);

        // [THEN] Table Accounting Period is empty
        Assert.RecordIsEmpty(AccountingPeriod);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AssistedCompanySetupCreateAccountingPeriodWithNonBlankStartDate()
    var
        AccountingPeriod: Record "Accounting Period";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
    begin
        // [FEATURE] [UT] [Assisted Company Setup]
        // [SCENARIO 273424] When CreateAccountingPeriod is called with <non-blank> StartDate in codeunit Assisted Company Setup then 13 Accounting Periods are created
        InitializeForWizard();

        // [GIVEN] New company with empty Accounting Period table
        AccountingPeriod.DeleteAll();

        // [WHEN] Call CreateAccountingPeriod with StartDate = 1/23/2020 in codeunit Assisted Company Setup
        AssistedCompanySetup.CreateAccountingPeriod(LibraryRandom.RandDateFrom(WorkDate(), 100));

        // [THEN] Table Accounting Period has 13 records
        Assert.RecordCount(AccountingPeriod, 13);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySetupStatusNotSaaS()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CompanyFromName: Text[30];
        CompanyToName: Text[30];
    begin
        // [FEATURE] [UT] [Assisted Company Setup]
        // [SCENARIO 280317] If not SaaS then functon CopySaaSCompanySetupStatus does nothing
        Initialize();

        // [GIVEN] Not running in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [GIVEN] Mock company "FROM" setup status "Completed"
        CompanyFromName := GetRandomCompanyName();
        MockSetupStatusCompleted(CompanyFromName);

        // [WHEN] Function CopySaaSCompanySetupStatus for company "TO" is being run
        CompanyToName := GetRandomCompanyName();
        AssistedCompanySetupStatus.CopySaaSCompanySetupStatus(CompanyFromName, CompanyToName);

        // [THEN] AssistedCompanySetupStatus record is not created
        AssistedCompanySetupStatus.SetFilter("Company Name", CompanyToName);
        Assert.RecordIsEmpty(AssistedCompanySetupStatus);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySetupStatusCompletedSaaS()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CompanyFromName: Text[30];
        CompanyToName: Text[30];
        NullGuid: Guid;
    begin
        // [FEATURE] [UT] [Assisted Company Setup]
        // [SCENARIO 280317] Functon CopySaaSCompanySetupStatus copies status Completed in SaaS
        Initialize();

        // [GIVEN] Running in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Mock company "FROM" setup status "Completed"
        CompanyFromName := GetRandomCompanyName();
        MockSetupStatusCompleted(CompanyFromName);

        // [WHEN] Function CopySaaSCompanySetupStatus for company "TO" is being run
        CompanyToName := GetRandomCompanyName();
        AssistedCompanySetupStatus.CopySaaSCompanySetupStatus(CompanyFromName, CompanyToName);

        // [THEN] AssistedCompanySetupStatus record is created with "Task ID" = NullGuid
        AssistedCompanySetupStatus.Get(CompanyToName);
        Clear(NullGuid);
        AssistedCompanySetupStatus.TestField("Task ID", NullGuid);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySetupStatusEmptySaaS()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CompanyFromName: Text[30];
        CompanyToName: Text[30];
    begin
        // [FEATURE] [UT] [Assisted Company Setup]
        // [SCENARIO 280317] Functon CopySaaSCompanySetupStatus does nothing when company from has empty status in SaaS
        Initialize();

        // [GIVEN] Running in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Company "FROM" setup status empty
        CompanyFromName := GetRandomCompanyName();
        if AssistedCompanySetupStatus.Get(CompanyFromName) then
            AssistedCompanySetupStatus.Delete();

        // [WHEN] Function CopySaaSCompanySetupStatus for company "TO" is being run
        CompanyToName := GetRandomCompanyName();
        AssistedCompanySetupStatus.CopySaaSCompanySetupStatus(CompanyFromName, CompanyToName);

        // [THEN] AssistedCompanySetupStatus record is not created
        AssistedCompanySetupStatus.SetFilter("Company Name", CompanyToName);
        Assert.RecordIsEmpty(AssistedCompanySetupStatus);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmYesHandler,PostCodeModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure LookupPostCode()
    var
        PostCode: Record "Post Code";
        AssistedCompanySetupWizard: TestPage "Assisted Company Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 298121] Post code can be picked with lookup
        InitializeForWizard();

        // [GIVEN] Post Code with Code = "CODE", City = "CITY", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] The company setup wizard is on the general information page
        AssistedCompanySetupWizard.OpenEdit();

        // [WHEN] Post Code lookup is being choosen and created post code record picked
        LibraryVariableStorage.Enqueue(PostCode."Country/Region Code");
        LibraryVariableStorage.Enqueue(PostCode.Code);
        AssistedCompanySetupWizard."Post Code".Lookup();

        // [THEN] Company Wizard has Post Code = "CODE", City = "CITY", Country/Region Code = "CRC"
        AssistedCompanySetupWizard."Post Code".AssertEquals(PostCode.Code);
        AssistedCompanySetupWizard.City.AssertEquals(PostCode.City);
        AssistedCompanySetupWizard."Country/Region Code".AssertEquals(PostCode."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ValidatePostCode()
    var
        PostCode: Record "Post Code";
        AssistedCompanySetupWizard: TestPage "Assisted Company Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 298121] City and country code are copied from Post Code record when user enters existing post code
        InitializeForWizard();

        // [GIVEN] Post Code with Code = "CODE", City = "CITY", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] The company setup wizard is on the general information page
        AssistedCompanySetupWizard.OpenEdit();

        // [WHEN] Post Code is being set to "CODE"
        AssistedCompanySetupWizard."Post Code".SetValue(PostCode.Code);

        // [THEN] Company Wizard has Post Code = "CODE", City = "CITY", Country/Region Code = "CRC"
        AssistedCompanySetupWizard."Post Code".AssertEquals(PostCode.Code);
        AssistedCompanySetupWizard.City.AssertEquals(PostCode.City);
        AssistedCompanySetupWizard."Country/Region Code".AssertEquals(PostCode."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmYesHandler,PostCodeCityModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure LookupCity()
    var
        PostCode: Record "Post Code";
        AssistedCompanySetupWizard: TestPage "Assisted Company Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 298121] City can be picked with lookup
        InitializeForWizard();

        // [GIVEN] Post Code with Code = "CODE", City = "CITY", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] The company setup wizard is on the general information page
        AssistedCompanySetupWizard.OpenEdit();

        // [WHEN] City lookup is being choosen and created post code record picked
        LibraryVariableStorage.Enqueue(PostCode."Country/Region Code");
        LibraryVariableStorage.Enqueue(PostCode.City);
        AssistedCompanySetupWizard.City.Lookup();

        // [THEN] Company Wizard has Post Code = "CODE", City = "CITY", Country/Region Code = "CRC"
        AssistedCompanySetupWizard."Post Code".AssertEquals(PostCode.Code);
        AssistedCompanySetupWizard.City.AssertEquals(PostCode.City);
        AssistedCompanySetupWizard."Country/Region Code".AssertEquals(PostCode."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ValidateCity()
    var
        PostCode: Record "Post Code";
        AssistedCompanySetupWizard: TestPage "Assisted Company Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 298121] Post code and country code are copied from Post Code record when user enters existing city
        InitializeForWizard();

        // [GIVEN] Post Code with Code = "CODE", City = "CITY", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] The company setup wizard is on the general information page
        AssistedCompanySetupWizard.OpenEdit();

        // [WHEN] City is being set to "CITY"
        AssistedCompanySetupWizard.City.SetValue(PostCode.City);

        // [THEN] Company Wizard has Post Code = "CODE", City = "CITY", Country/Region Code = "CRC"
        AssistedCompanySetupWizard."Post Code".AssertEquals(PostCode.Code);
        AssistedCompanySetupWizard.City.AssertEquals(PostCode.City);
        AssistedCompanySetupWizard."Country/Region Code".AssertEquals(PostCode."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ValidateCountry()
    var
        CountryRegion: Record "Country/Region";
        PostCode: Record "Post Code";
        AssistedCompanySetupWizard: TestPage "Assisted Company Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 298121] Post code and city are cleared when user changes country/region code
        InitializeForWizard();

        // [GIVEN] Post Code with Code = "CODE", City = "CITY", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] The company setup wizard is on the general information page
        AssistedCompanySetupWizard.OpenEdit();

        // [GIVEN] Post Code = "CODE", City = "CITY", Country/Region Code = "CRC"
        AssistedCompanySetupWizard.City.SetValue(PostCode.City);

        // [WHEN] Country/Region Code is being changed to "CRC2"
        LibraryERM.CreateCountryRegion(CountryRegion);
        AssistedCompanySetupWizard."Country/Region Code".SetValue(CountryRegion.Code);

        // [THEN] Company Wizard has Post Code = "", City = "", Country/Region Code = "CRC2"
        AssistedCompanySetupWizard."Post Code".AssertEquals('');
        AssistedCompanySetupWizard.City.AssertEquals('');
        AssistedCompanySetupWizard."Country/Region Code".AssertEquals(CountryRegion.Code);
    end;

    local procedure Initialize()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
    end;

    local procedure InitializeForWizard()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        GLEntry: Record "G/L Entry";
        ConfigurationPackageFile: Record "Configuration Package File";
    begin
        // Delete G/L Entries to mock a new company which isn't in use already
        GLEntry.DeleteAll();

        // Make sure we do not have any Configuration Package Files in the system, since that would trigger import
        ConfigurationPackageFile.DeleteAll();

        AssistedCompanySetupStatus.SetEnabled(CompanyName, true, true);
        Initialize();
    end;

    [Normal]
    local procedure InitializeEventSubscription()
    begin
        if not IsEventSubscriptionInitialized then
            BindSubscription(AssistedSetupMockEvents);
        IsEventSubscriptionInitialized := true;
    end;

    local procedure CheckWizardVisibility(PageId: Integer; WizardVisibility: Boolean)
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
        Assert.AreEqual(WizardVisibility, AssistedSetupTestLibrary.Exists(PageId), 'Wizard existence mismatch');
    end;

    local procedure GetRandomCompanyName(): Text[30]
    begin
        exit(CopyStr(Format(CreateGuid()), 1, 30));
    end;

    local procedure MockSetupStatusCompleted(CompanyName: Text[30])
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        AssistedCompanySetupStatus.Init();
        AssistedCompanySetupStatus."Company Name" := CompanyName;
        AssistedCompanySetupStatus.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
        Assert.ExpectedMessage(NoConfigPackageFileMsg, Message);
    end;

    local procedure SetDemoCompany(IsDemoCompany: Boolean)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Demo Company" := IsDemoCompany;
        CompanyInformation.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemListHandler(var ItemList: TestPage "Item List")
    begin
        ItemList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostCodeModalPageHandler(var PostCodes: TestPage "Post Codes")
    begin
        PostCodes.FILTER.SetFilter("Country/Region Code", LibraryVariableStorage.DequeueText());
        PostCodes.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        PostCodes.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostCodeCityModalPageHandler(var PostCodes: TestPage "Post Codes")
    begin
        PostCodes.FILTER.SetFilter("Country/Region Code", LibraryVariableStorage.DequeueText());
        PostCodes.FILTER.SetFilter(City, LibraryVariableStorage.DequeueText());
        PostCodes.OK().Invoke();
    end;
}

