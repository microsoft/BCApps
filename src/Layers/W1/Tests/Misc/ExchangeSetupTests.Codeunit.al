codeunit 139310 "Exchange Setup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Outlook Individual Deployment]
    end;

    var
        Assert: Codeunit Assert;
        LibraryAzureADAuthFlow: Codeunit "Library - Azure AD Auth Flow";
        PrivacyNotice: Codeunit "Privacy Notice";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
        OAuthInitialized: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifySetupWhenExitRightAway()
    var
        GuidedExperience: Codeunit "Guided Experience";
        OutlookIndividualDeployment: TestPage "Outlook Individual Deployment";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] The Outlook Individual Deployment wizard is exited right away
        OutlookIndividualDeployment.Trap();
        Page.Run(Page::"Outlook Individual Deployment");
        OutlookIndividualDeployment.Close();

        // [THEN] No assisted setup entry exists
        Assert.IsFalse(GuidedExperience.Exists("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Teams Individual Deployment"), 'Outlook Individual Deployment assisted setup entry should not exist.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySetupWhenFinished()
    var
        GuidedExperience: Codeunit "Guided Experience";
        OutlookIndividualDeployment: TestPage "Outlook Individual Deployment";
    begin
        // [GIVEN] A newly setup company
        Initialize();
        PrivacyNotice.SetApprovalState(PrivacyNoticeRegistrations.GetExchangePrivacyNoticeId(), "Privacy Notice Approval State"::"Not set");

        // [WHEN] The Outlook Individual Deployment is completed
        RunWizardToCompletion(OutlookIndividualDeployment);
        OutlookIndividualDeployment.ActionDone.Invoke();

        // [THEN] No assisted setup entry exists
        Assert.IsFalse(GuidedExperience.Exists("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Teams Individual Deployment"), 'Outlook Individual Deployment assisted setup entry should not exist.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyUserNotPromptedForEmailAndPasswordWithTokenOnPrem()
    var
        ExchangeAddinSetup: Codeunit "Exchange Add-in Setup";
        OutlookIndividualDeployment: TestPage "Outlook Individual Deployment";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [SCENARIO] User is not prompted for email and password when a token is available.

        // [GIVEN] An access token is available for the user.
        Initialize();
        InitializeOAuth(true);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] The user runs the Outlook Individual Deployment Page.
        OutlookIndividualDeployment.Trap();
        Page.Run(Page::"Outlook Individual Deployment");
        OutlookIndividualDeployment.ActionNext.Invoke();
        // Intro step to sample email message step
        Assert.IsFalse(OutlookIndividualDeployment.ActionNext.Visible(), 'Next should not be visible at the end of the wizard');
        // [THEN] Setup Emails is displayed
        if ExchangeAddinSetup.SampleEmailsAvailable() then
            Assert.IsTrue(OutlookIndividualDeployment.SetupSampleEmails.Visible(), 'Setup emails is not visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyUserNotPromptedForEmailAndPasswordInSaaS()
    var
        ExchangeAddinSetup: Codeunit "Exchange Add-in Setup";
        OutlookIndividualDeployment: TestPage "Outlook Individual Deployment";
    begin
        // [SCENARIO] User is not prompted for email and password when a token is available.

        // [GIVEN] An access token is available for the user.
        Initialize();
        InitializeOAuth(true);

        // [WHEN] The user runs the Outlook Individual Deployment Page.
        OutlookIndividualDeployment.Trap();
        Page.Run(Page::"Outlook Individual Deployment");
        OutlookIndividualDeployment.ActionNext.Invoke(); // Intro step to sample email message step
        Assert.IsFalse(OutlookIndividualDeployment.ActionNext.Visible(), 'Next should not be visible at the end of the wizard');
        // [THEN] Setup Emails is displayed
        if ExchangeAddinSetup.SampleEmailsAvailable() then
            Assert.IsTrue(OutlookIndividualDeployment.SetupSampleEmails.Visible(), 'Setup emails is not visible');
    end;

    local procedure RunWizardToCompletion(var OutlookIndividualDeployment: TestPage "Outlook Individual Deployment")
    var
        OutlookIndividualDeploymentPage: Page "Outlook Individual Deployment";
    begin
        OutlookIndividualDeployment.Trap();
        OutlookIndividualDeploymentPage.SkipDeploymentStage(true);
        OutlookIndividualDeploymentPage.Run();

        OutlookIndividualDeployment.ActionNext.Invoke(); // Privacy Notice step to intro step
        OutlookIndividualDeployment.ActionNext.Invoke(); // Intro step to manual instructions step
        Assert.IsFalse(OutlookIndividualDeployment.ActionNext.Visible(), 'Next should not be visible at the end of the wizard');
        Assert.IsTrue(OutlookIndividualDeployment.ActionDone.Visible(), 'Done should be visible at the end of the wizard');
    end;

    local procedure Initialize()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        PrivacyNotice.SetApprovalState(PrivacyNoticeRegistrations.GetExchangePrivacyNoticeId(), "Privacy Notice Approval State"::Agreed);
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider();
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure InitializeOAuth(CachedTokenAvailable: Boolean)
    var
        LibraryO365Sync: Codeunit "Library - O365 Sync";
    begin
        Clear(LibraryAzureADAuthFlow);
        LibraryAzureADAuthFlow.SetTokenAvailable(false); // Never invoking authorization dialog, so dont expose token from auth code.
        LibraryAzureADAuthFlow.SetCachedTokenAvailable(CachedTokenAvailable);
        BindSubscription(LibraryAzureADAuthFlow);
        SetAuthFlowProvider(CODEUNIT::"Library - Azure AD Auth Flow");

        if OAuthInitialized then
            exit;

        LibraryO365Sync.SetupNavUser();

        OAuthInitialized := true;
    end;

    local procedure SetAuthFlowProvider(ProviderCodeunit: Integer)
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
        AzureADAppSetup: Record "Azure AD App Setup";
        DummySecretGuid: Text;
    begin
        AzureADMgtSetup.Get();
        AzureADMgtSetup."Auth Flow Codeunit ID" := ProviderCodeunit;
        AzureADMgtSetup.Modify();

        if not AzureADAppSetup.Get() then begin
            AzureADAppSetup.Init();
            AzureADAppSetup."Redirect URL" := 'http://dummyurl:1234/Main_Instance1/WebClient/OAuthLanding.htm';
            AzureADAppSetup."App ID" := CreateGuid();
            DummySecretGuid := CreateGuid();
            AzureADAppSetup.SetSecretKeyToIsolatedStorage(DummySecretGuid);
            AzureADAppSetup.Insert();
        end;
    end;
}

