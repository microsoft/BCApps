codeunit 139321 "Teams Centralized Depl. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Teams Centralized Deployment]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenExitRightAway()
    var
        GuidedExperience: Codeunit "Guided Experience";
        TeamsCentralizedDeployment: TestPage "Teams Centralized Deployment";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [GIVEN] A newly setup company in Saas
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] The Teams Centralized Deployment is completed
        TeamsCentralizedDeployment.Trap();
        Page.Run(Page::"Teams Centralized Deployment");
        TeamsCentralizedDeployment.Close();
        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Teams Centralized Deployment"), 'Teams Centralized Deployment Setup status should be completed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenFinishedOnPrem()
    var
        GuidedExperience: Codeunit "Guided Experience";
        TeamsCentralizedDeployment: TestPage "Teams Centralized Deployment";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [GIVEN] A newly setup company in Saas
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] The Teams Centralized Deployment is completed
        TeamsCentralizedDeployment.Trap();
        Page.Run(Page::"Teams Centralized Deployment");
        Assert.IsFalse(TeamsCentralizedDeployment.ActionBack.Visible(), 'Back is visible');
        Assert.IsFalse(TeamsCentralizedDeployment.ActionDone.Visible(), 'Done is visible');
        Assert.IsFalse(TeamsCentralizedDeployment.ActionNext.Visible(), 'Next is visible');
        Assert.IsTrue(TeamsCentralizedDeployment.ActionOkay.Visible(), 'Okay is not visible');
        TeamsCentralizedDeployment.ActionOkay.Invoke();
        // [THEN] Status of the setup step is not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Teams Centralized Deployment"), 'Teams Centralized Deployment Setup status should be completed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyStatusCompletedWhenFinishedOnSaaS()
    var
        GuidedExperience: Codeunit "Guided Experience";
        TeamsCentralizedDeployment: TestPage "Teams Centralized Deployment";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [GIVEN] A newly setup company in Saas
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] The Teams Centralized Deployment is completed
        TeamsCentralizedDeployment.Trap();
        Page.Run(Page::"Teams Centralized Deployment");
        Assert.IsTrue(TeamsCentralizedDeployment.ActionNext.Visible(), 'Next is not visible');
        Assert.IsTrue(TeamsCentralizedDeployment.ActionBack.Visible(), 'Back is not visible');
        Assert.IsFalse(TeamsCentralizedDeployment.ActionBack.Enabled(), 'Back is enabled');
        Assert.IsFalse(TeamsCentralizedDeployment.ActionDone.Visible(), 'Done is visible');
        Assert.IsFalse(TeamsCentralizedDeployment.ActionOkay.Visible(), 'Okay is visible');
        TeamsCentralizedDeployment.ActionNext.Invoke();
        Assert.IsTrue(TeamsCentralizedDeployment.ActionNext.Visible(), 'Next is not visible');
        Assert.IsTrue(TeamsCentralizedDeployment.ActionBack.Visible(), 'Back is not visible');
        Assert.IsTrue(TeamsCentralizedDeployment.ActionBack.Enabled(), 'Back is not enabled');
        Assert.IsFalse(TeamsCentralizedDeployment.ActionDone.Visible(), 'Done is visible');
        Assert.IsFalse(TeamsCentralizedDeployment.ActionOkay.Visible(), 'Okay is visible');
        TeamsCentralizedDeployment.ActionNext.Invoke();
        Assert.IsFalse(TeamsCentralizedDeployment.ActionNext.Visible(), 'Next is visible');
        Assert.IsTrue(TeamsCentralizedDeployment.ActionBack.Visible(), 'Back is not visible');
        Assert.IsTrue(TeamsCentralizedDeployment.ActionBack.Enabled(), 'Back is not enabled');
        Assert.IsTrue(TeamsCentralizedDeployment.ActionDone.Visible(), 'Done is not visible');
        Assert.IsFalse(TeamsCentralizedDeployment.ActionOkay.Visible(), 'Okay is visible');
        TeamsCentralizedDeployment.ActionDone.Invoke();

        // [THEN] Status of the setup step is set to Completed
        if GuidedExperience.Exists("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Teams Centralized Deployment") then
            Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Teams Centralized Deployment"), 'Teams Centralized Deployment Setup status should be completed.');
    end;

    local procedure Initialize()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
    end;
}
