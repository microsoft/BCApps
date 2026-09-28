codeunit 135801 "Effective Permissions Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        OnlyAadUsersAllowedErr: Label 'The effective permissions content can be shown only for Microsoft Entra ID users.';

    [Test]
    procedure EffectivePermissionsCanBeShownForDelegatedAdmin()
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        // [SCENARIO 500351] Effective permissions can be shown for a delegated admin, who has no Authentication Object ID
        VerifyEffectivePermissionsCanBeShownForDelegatedUser(PlanIds.GetDelegatedAdminPlanId());
    end;

    [Test]
    procedure EffectivePermissionsCanBeShownForDelegatedHelpdesk()
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        // [SCENARIO 500351] Effective permissions can be shown for a delegated helpdesk user, who has no Authentication Object ID
        VerifyEffectivePermissionsCanBeShownForDelegatedUser(PlanIds.GetHelpDeskPlanId());
    end;

    [Test]
    procedure EffectivePermissionsCannotBeShownForNonEntraUser()
    var
        User: Record User;
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
        EffectivePermissions: TestPage "Effective Permissions";
    begin
        // [SCENARIO 500351] Effective permissions are still not shown for a non-delegated user without an Authentication Object ID

        // [GIVEN] A SaaS environment
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] A user without an Authentication Object ID and without a delegated plan
        CreateUserWithoutAuthenticationObjectId(User);

        // [WHEN] Opening the Effective Permissions page for the user
        EffectivePermissions.Trap();
        asserterror EffectivePermissionsMgt.OpenPageForUser(User."User Security ID");

        // [THEN] An error is shown that only Microsoft Entra ID users are allowed
        Assert.ExpectedError(OnlyAadUsersAllowedErr);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure VerifyEffectivePermissionsCanBeShownForDelegatedUser(PlanId: Guid)
    var
        User: Record User;
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
        EffectivePermissions: TestPage "Effective Permissions";
    begin
        // [GIVEN] A SaaS environment
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] A delegated user, which has no Authentication Object ID in the customer tenant
        CreateUserWithoutAuthenticationObjectId(User);
        AzureADPlanTestLibrary.AssignUserToPlan(User."User Security ID", PlanId);

        // [WHEN] Opening the Effective Permissions page for the delegated user
        EffectivePermissions.Trap();
        EffectivePermissionsMgt.OpenPageForUser(User."User Security ID");

        // [THEN] The page opens for the delegated user without an error
        Assert.AreEqual(User."User Name", EffectivePermissions.ChooseUser.Value(), 'The Effective Permissions page was not opened for the delegated user.');
        EffectivePermissions.Close();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure CreateUserWithoutAuthenticationObjectId(var User: Record User)
    var
        UserProperty: Record "User Property";
    begin
        User.Init();
        User."User Security ID" := CreateGuid();
        User."User Name" := CopyStr(DelChr(Format(User."User Security ID"), '=', '{}-'), 1, MaxStrLen(User."User Name"));
        User.Insert(true);

        if not UserProperty.Get(User."User Security ID") then begin
            UserProperty.Init();
            UserProperty."User Security ID" := User."User Security ID";
            UserProperty.Insert();
        end;
        UserProperty."Authentication Object ID" := '';
        UserProperty.Modify();
        Commit();
    end;
}
