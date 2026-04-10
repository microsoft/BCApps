codeunit 139322 "Teams User Deployment Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Teams Individual Deployment]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySetupWhenFinishedOnPrem()
    var
        GuidedExperience: Codeunit "Guided Experience";
        TeamsIndividualDeployment: TestPage "Teams Individual Deployment";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [GIVEN] A newly setup company on prem
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] The Teams Individual Deployment is completed
        TeamsIndividualDeployment.Trap();
        Page.Run(Page::"Teams Individual Deployment");
        Assert.IsTrue(TeamsIndividualDeployment.ActionOkay.Visible(), 'Okay is not visible');
        TeamsIndividualDeployment.ActionOkay.Invoke();

        // [THEN] No assisted setup entry exists
        Assert.IsFalse(GuidedExperience.Exists("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Teams Individual Deployment"), 'Teams Individual Deployment assisted setup entry should not exist.');
    end;

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    [Scope('OnPrem')]
    procedure VerifySetupWhenFinishedInSaaS()
    var
        GuidedExperience: Codeunit "Guided Experience";
        TeamsIndividualDeployment: TestPage "Teams Individual Deployment";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [GIVEN] A newly setup company in Saas
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] The Teams Individual Deployment is completed
        TeamsIndividualDeployment.Trap();
        Page.Run(Page::"Teams Individual Deployment");
        Assert.IsFalse(TeamsIndividualDeployment.ActionOkay.Visible(), 'Okay is visible');
        TeamsIndividualDeployment.ActionGetFromStore.Invoke();

        // [THEN] No assisted setup entry exists
        Assert.IsFalse(GuidedExperience.Exists("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Teams Individual Deployment"), 'Teams Individual Deployment assisted setup entry should not exist.');
    end;

    [HyperlinkHandler]
    [Scope('OnPrem')]
    procedure HyperlinkHandler(Message: Text[1024])
    begin
    end;

    local procedure Initialize()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
    end;
}
