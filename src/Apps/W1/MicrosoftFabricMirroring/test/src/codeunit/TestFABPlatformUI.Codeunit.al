namespace Microsoft.FabricExport;

using System.Fabric;

//[FEATURE] Fabric platform setup UI
codeunit 140014 "Test FAB Platform UI"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Assert: Codeunit "Assert";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        DestinationChangeBlockedErr: Label 'You cannot change the Fabric workspace or Open Mirroring database while setup is complete or export is enabled.';

    [Test]
    procedure SetupPagesHideCustomCredentialsForFirstParty()
    begin
        VerifySetupAuthenticationFieldsVisible(false);
    end;

    [Test]
    procedure SetupPagesShowCustomCredentialsForCustomApp()
    begin
        VerifySetupAuthenticationFieldsVisible(true);
    end;

    [Test]
    procedure RejectWorkspaceSelectionAfterSetupCompleted()
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
        SetupPage: TestPage "Fabric Platform Setup";
    begin
        //[SCENARIO] Select a workspace on the setup page after setup completes
        //[GIVEN] Completed setup with export disabled
        CreateDestinationSetup(TenantFabricSetup, true, false);
        //[GIVEN] Setup committed so it survives the expected error's rollback
        Commit();
        //[GIVEN] Lower permissions and open the setup page
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');
        SetupPage.OpenEdit();

        //[WHEN] Workspace selection is requested
        asserterror SetupPage."Fabric Workspace Name".AssistEdit();

        //[THEN] Reset is required before browsing and the destination is unchanged
        VerifyDestinationChangeRejected(TenantFabricSetup);
        SetupPage.Close();
    end;

    [Test]
    procedure RejectDatabaseSelectionAfterSetupCompleted()
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
        SetupPage: TestPage "Fabric Platform Setup";
    begin
        //[SCENARIO] Select a mirrored database on the setup page after setup completes
        //[GIVEN] Completed setup with export disabled
        CreateDestinationSetup(TenantFabricSetup, true, false);
        //[GIVEN] Setup committed so it survives the expected error's rollback
        Commit();
        //[GIVEN] Lower permissions and open the setup page
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');
        SetupPage.OpenEdit();

        //[WHEN] Mirrored database selection is requested
        asserterror SetupPage."Fabric Open Mirroring Name".AssistEdit();

        //[THEN] Reset is required before browsing and the destination is unchanged
        VerifyDestinationChangeRejected(TenantFabricSetup);
        SetupPage.Close();
    end;

    [Test]
    procedure RejectWizardWorkspaceSelectionAfterSetupCompleted()
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
        SetupWizard: TestPage "Fabric Platform Setup Wizard";
    begin
        //[SCENARIO] Select a workspace in the wizard after setup completes
        //[GIVEN] Completed setup with export disabled
        CreateDestinationSetup(TenantFabricSetup, true, false);
        //[GIVEN] Setup committed so it survives the expected error's rollback
        Commit();
        //[GIVEN] Lower permissions and navigate to workspace selection
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');
        SetupWizard.OpenEdit();
        SetupWizard.ActionNext.Invoke();
        SetupWizard.ActionNext.Invoke();

        //[WHEN] Workspace selection is requested
        asserterror SetupWizard."Fabric Workspace Name".AssistEdit();

        //[THEN] Reset is required before browsing and the destination is unchanged
        VerifyDestinationChangeRejected(TenantFabricSetup);
        SetupWizard.Close();
    end;

    [Test]
    procedure RejectWizardDatabaseSelectionAfterSetupCompleted()
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
        SetupWizard: TestPage "Fabric Platform Setup Wizard";
    begin
        //[SCENARIO] Select a mirrored database in the wizard after setup completes
        //[GIVEN] Completed setup with export disabled
        CreateDestinationSetup(TenantFabricSetup, true, false);
        //[GIVEN] Setup committed so it survives the expected error's rollback
        Commit();
        //[GIVEN] Lower permissions and navigate to mirrored database selection
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');
        SetupWizard.OpenEdit();
        SetupWizard.ActionNext.Invoke();
        SetupWizard.ActionNext.Invoke();
        SetupWizard.ActionNext.Invoke();
        SetupWizard.ActionNext.Invoke();

        //[WHEN] Mirrored database selection is requested
        asserterror SetupWizard."Fabric Open Mirroring Name".AssistEdit();

        //[THEN] Reset is required before browsing and the destination is unchanged
        VerifyDestinationChangeRejected(TenantFabricSetup);
        SetupWizard.Close();
    end;

    local procedure VerifySetupAuthenticationFieldsVisible(UseCustomApp: Boolean)
    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        SetupPage: TestPage "Fabric Platform Setup";
        SetupWizard: TestPage "Fabric Platform Setup Wizard";
    begin
        Initialize();
        CredMgt.SetCustomAppEnabled(UseCustomApp);
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        SetupPage.OpenEdit();
        Assert.AreEqual(UseCustomApp, SetupPage.ClientId.Visible(), 'Unexpected Client ID visibility on the setup page.');
        Assert.AreEqual(UseCustomApp, SetupPage.ClientSecret.Visible(), 'Unexpected Client Secret visibility on the setup page.');
        Assert.IsTrue(SetupPage.PrincipalId.Visible(), 'Principal ID must be visible for both authentication modes.');
        SetupPage.Close();

        SetupWizard.OpenEdit();
        Assert.IsFalse(SetupWizard.PrincipalId.Visible(), 'Welcome must not show authentication fields.');
        SetupWizard.ActionNext.Invoke();
        Assert.IsTrue(SetupWizard.PrincipalId.Visible(), 'Principal ID must be visible on the authentication step for both modes.');
        Assert.AreEqual(UseCustomApp, SetupWizard.ClientId.Visible(), 'Unexpected Client ID visibility in the setup wizard.');
        Assert.AreEqual(UseCustomApp, SetupWizard.ClientSecret.Visible(), 'Unexpected Client Secret visibility in the setup wizard.');
        Assert.IsFalse(SetupWizard."Fabric Workspace Name".Visible(), 'Both modes must show authentication before workspace selection.');
        SetupWizard.ActionNext.Invoke();
        Assert.IsTrue(SetupWizard."Fabric Workspace Name".Visible(), 'Authentication must be followed by workspace selection.');
        SetupWizard.ActionBack.Invoke();
        Assert.IsTrue(SetupWizard.PrincipalId.Visible(), 'Back must return to authentication for both modes.');
        Assert.AreEqual(UseCustomApp, SetupWizard.ClientId.Visible(), 'Unexpected custom credentials when returning to authentication.');
        SetupWizard.ActionBack.Invoke();
        Assert.IsFalse(SetupWizard.ActionBack.Enabled(), 'Back from authentication must return to Welcome.');
        Assert.IsFalse(SetupWizard.PrincipalId.Visible(), 'Authentication fields must not be shown when returning to Welcome.');
        SetupWizard.Close();
        Assert.AreEqual(UseCustomApp, CredMgt.IsCustomAppEnabled(), 'Opening setup must not change the authentication mode.');
    end;

    local procedure Initialize()
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
        TenantFabricTables: Record "Tenant Fabric Tables";
        TenantFabricTableFields: Record "Tenant Fabric Table Fields";
        TenantFabricCompanies: Record "Tenant Fabric Companies";
        FabricTableClaim: Record "Fabric Table Claim";
        TenantFabricExportSummary: Record "Tenant Fabric Export Summary";
        TenantFabricExportDetails: Record "Tenant Fabric Export Details";
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        PlatformTestSub: Codeunit "Fabric Platform Test Sub";
        LookupState: Codeunit "Fabric Platform Lookup State";
    begin
        // Required selections persist across cleanup.
        TenantFabricTables.SetFilter("Table ID", '<>%1&<>%2', Database::"Tenant Fabric Export Details", Database::"Tenant Fabric Export Summary");
        TenantFabricTables.DeleteAll(false);
        TenantFabricTableFields.DeleteAll(false);
        TenantFabricSetup.DeleteAll(false);
        TenantFabricCompanies.DeleteAll(false);
        FabricTableClaim.DeleteAll(false);
        TenantFabricExportSummary.DeleteAll(false);
        TenantFabricExportDetails.DeleteAll(false);
        PlatformTestSub.Reset();
        LookupState.ClearFabricApiToken();
        // Isolated Storage is not rolled back between tests, unlike table data.
        CredMgt.ClearEnvironmentCredentials();
    end;

    local procedure CreateDestinationSetup(var TenantFabricSetup: Record "Tenant Fabric Setup"; SetupComplete: Boolean; ExportEnabled: Boolean)
    begin
        TenantFabricSetup.DeleteAll(false);
        TenantFabricSetup.Init();
        TenantFabricSetup."Fabric Workspace ID" := CreateGuid();
        TenantFabricSetup."Fabric Workspace Name" := 'Original workspace';
        TenantFabricSetup."Fabric Lakehouse ID" := CreateGuid();
        TenantFabricSetup."Fabric Data Namespace" := 'BusinessCentral';
        TenantFabricSetup."Fabric Logging Namespace" := 'BusinessCentral_log';
        TenantFabricSetup."Minutes Between Exports" := 5;
        TenantFabricSetup."Max Consecutive Failed Runs" := 2;
        TenantFabricSetup."Setup Complete" := SetupComplete;
        TenantFabricSetup."Export Enabled" := ExportEnabled;
        TenantFabricSetup.Insert(false);
    end;

    local procedure VerifyDestinationChangeRejected(ExpectedSetup: Record "Tenant Fabric Setup")
    begin
        Assert.ExpectedError(DestinationChangeBlockedErr);
        Assert.ExpectedErrorCode('Dialog');
        VerifyDestinationUnchanged(ExpectedSetup);
    end;

    local procedure VerifyDestinationUnchanged(ExpectedSetup: Record "Tenant Fabric Setup")
    var
        ActualSetup: Record "Tenant Fabric Setup";
    begin
        ActualSetup.Get(ExpectedSetup."Setup ID");
        Assert.AreEqual(ExpectedSetup."Fabric Workspace ID", ActualSetup."Fabric Workspace ID", 'Unexpected workspace ID.');
        Assert.AreEqual(ExpectedSetup."Fabric Workspace Name", ActualSetup."Fabric Workspace Name", 'Unexpected workspace name.');
        Assert.AreEqual(ExpectedSetup."Fabric Lakehouse ID", ActualSetup."Fabric Lakehouse ID", 'Unexpected mirrored database ID.');
        Assert.AreEqual(ExpectedSetup."Setup Complete", ActualSetup."Setup Complete", 'Unexpected setup completion state.');
        Assert.AreEqual(ExpectedSetup."Export Enabled", ActualSetup."Export Enabled", 'Unexpected export enablement state.');
        Assert.AreEqual(ExpectedSetup."Minutes Between Exports", ActualSetup."Minutes Between Exports", 'Unexpected export interval.');
    end;
}
