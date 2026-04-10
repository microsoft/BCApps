codeunit 134912 "ERM User Personalization"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [User] [Profile]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ProfileDefaultRCMustBeUniqueErr: Label 'There must be one default Role Center.';
        WrongExpectedRoleCenter: Label 'Unexpected Default Role Center.';
        UserCassieTxt: Label 'USER-CASSIE';
        NotDefaultRoleCenterIDErr: Label 'Default Role Center ID wasn''t assigned to a newly created Profile.';

    [Test]
    [Scope('OnPrem')]
    procedure RenameProfile()
    var
        AllProfile: Record "All Profile";
        TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
        UserPersonalization: Record "User Personalization";
        OriginalProfileID: Code[30];
        ProfileMetadataCountBefore: Integer;
        NewProfileID: Code[30];
    begin
        // Setup
        Initialize();

        OriginalProfileID := LibraryUtility.GenerateRandomText(MaxStrLen(AllProfile."Profile ID"));
        CreateNewProfile(OriginalProfileID, Page::"Business Manager Role Center", false);
        AllProfile.Get(AllProfile.Scope::Tenant, AllProfile."App ID", OriginalProfileID);

        if not UserPersonalization.FindFirst() then begin
            UserPersonalization.Init();
            UserPersonalization."Profile ID" := AllProfile."Profile ID";
            UserPersonalization.Scope := AllProfile.Scope;
            UserPersonalization."App ID" := AllProfile."App ID";
            UserPersonalization.Insert();
        end else begin
            UserPersonalization."Profile ID" := AllProfile."Profile ID";
            UserPersonalization.Scope := AllProfile.Scope;
            UserPersonalization."App ID" := AllProfile."App ID";
            UserPersonalization.Modify();
        end;

        TenantProfilePageMetadata."Profile ID" := AllProfile."Profile ID";
        TenantProfilePageMetadata."App ID" := AllProfile."App ID";
        TenantProfilePageMetadata.Owner := AllProfile.Scope;
        TenantProfilePageMetadata."Page ID" := Page::"Business Manager Role Center";
        TenantProfilePageMetadata.Insert();

        // Exercise: Rename profile and check that ProfileMetadata and USerPersonalzation entries are updated
        TenantProfilePageMetadata.SetRange("Profile ID", AllProfile."Profile ID");
        TenantProfilePageMetadata.SetRange("App ID", AllProfile."App ID");
        ProfileMetadataCountBefore := TenantProfilePageMetadata.Count();

        Assert.IsFalse(0 = ProfileMetadataCountBefore, 'There must be ProfileMetadata entries to rename.');

        NewProfileID := 'RenamedProfile';
        AllProfile.Rename(AllProfile.Scope::Tenant, AllProfile."App ID", NewProfileID);

        TenantProfilePageMetadata.SetRange("Profile ID", NewProfileID);
        Assert.AreEqual(
          ProfileMetadataCountBefore, TenantProfilePageMetadata.Count,
          'Renaming Profile must also rename all ProfileMetaData entries for that Profile');

        UserPersonalization.SetRange("Profile ID", NewProfileID);
        Assert.AreEqual(
          1, UserPersonalization.Count, 'Renaming Profile must also rename all UserPersonalization entries for that Profile');

        // Tear Down: Setup default values.
        UserPersonalization.FindFirst();
        UserPersonalization.Validate("Profile ID", '');
        UserPersonalization.Modify(true);

        AllProfile.Rename(AllProfile.Scope::Tenant, AllProfile."App ID", OriginalProfileID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDefaultRoleCenterExist()
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange("Default Role Center", true);
        Assert.AreEqual(1, AllProfile.Count, ProfileDefaultRCMustBeUniqueErr);
        AllProfile.FindFirst();
        Assert.AreEqual(Page::"Order Processor Role Center", AllProfile."Role Center ID", WrongExpectedRoleCenter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDefaultRoleCenterOnListPage()
    var
        DefaultProfile: Record "All Profile";
        AllProfile: Record "All Profile";
        ProfileList: TestPage "Profile List";
    begin
        // [FEATURE] [UI]
        EnsureDefaultRoleCenterExists();
        // [SCENARIO] Action 'Set Default Role Center' should set 'Default Role Center' to Yes in the current profile in the list

        // [GIVEN] A Profile 'A', where 'Default Role Center' is 'Yes'
        DefaultProfile.SetRange("Default Role Center", true);
        DefaultProfile.FindFirst();
        // [GIVEN] A Profile 'B', where 'Default Role Center' is 'No'
        AllProfile.SetRange("Default Role Center", false);
        AllProfile.SetRange(Enabled, true);
        AllProfile.FindFirst();
        // [GIVEN] Open Profile List page and focus on Profile 'B'
        ProfileList.OpenView();
        ProfileList.GotoRecord(AllProfile);

        // [WHEN] Run action 'Set Default Role Center'
        ProfileList.SetDefaultRoleCenterAction.Invoke();

        // [THEN] the Profile 'B', where 'Default Role Center' is 'Yes'
        ProfileList.DefaultRoleCenterField.AssertEquals(true);
        // [THEN] the Profile 'A', where 'Default Role Center' is 'No'
        ProfileList.GotoRecord(DefaultProfile);
        ProfileList.DefaultRoleCenterField.AssertEquals(false);

        // Set back to the previous values
        DefaultProfile.Find();
        DefaultProfile."Default Role Center" := true;
        DefaultProfile.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProfileRoleCenterID()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ProfileCard: TestPage "Profile Card";
    begin
        // Check created Profile through page.

        // Setup.
        Initialize();
        FindAnyRoleCenter(AllObjWithCaption);

        // Exercise: Create a Profile.
        CreateProfile(AllObjWithCaption);

        // Verify: Verify created Role Center ID.
        ProfileCard.OpenView();
        ProfileCard.FILTER.SetFilter("Profile ID", Format(AllObjWithCaption."Object ID"));
        ProfileCard.RoleCenterIdField.AssertEquals(AllObjWithCaption."Object ID");

        // Tear Down: Setup default values.
        DeleteProfile(AllObjWithCaption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewProfileDefaultRoleCenterID()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ProfileCard: TestPage "Profile Card";
    begin
        // [FEATURE] [Role Center]
        // [SCENARIO 299013] Create a new Profile with default 'Role Center ID'
        Initialize();
        FindAnyRoleCenter(AllObjWithCaption);

        // [GIVEN] Created a new Profile
        CreateProfileDefault(AllObjWithCaption);

        // [WHEN] Open its 'Profile Card'
        ProfileCard.OpenView();
        ProfileCard.FILTER.SetFilter("Profile ID", Format(AllObjWithCaption."Object ID"));

        // [THEN] 'Role Center ID' is set for Default one
        Assert.AreEqual(Format(ConfPersonalizationMgt.DefaultRoleCenterID()), ProfileCard.RoleCenterIdField.Value, NotDefaultRoleCenterIDErr);
        DeleteProfile(AllObjWithCaption);
    end;

    internal procedure RestartSession()
    var
        UserPersonalization: Record "User Personalization";
        CurrentUserSessionSettings: SessionSettings;
        ProfileScope: Option System,Tenant;
    begin
        UserPersonalization.Get(UserSecurityId());

        CurrentUserSessionSettings.Init();
        CurrentUserSessionSettings.ProfileId := UserPersonalization."Profile ID";
        CurrentUserSessionSettings.ProfileAppId := UserPersonalization."App ID";
#pragma warning disable AL0667
        CurrentUserSessionSettings.ProfileSystemScope := UserPersonalization.Scope = ProfileScope::System;
#pragma warning restore AL0667
        CurrentUserSessionSettings.LanguageId := UserPersonalization."Language ID";
        CurrentUserSessionSettings.LocaleId := UserPersonalization."Locale ID";
        CurrentUserSessionSettings.Timezone := UserPersonalization."Time Zone";

        CurrentUserSessionSettings.RequestSessionUpdate(true);
    end;

    [Test]
    [HandlerFunctions('RolesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CopyProfile()
    var
        OldAllProfile: Record "All Profile";
        NewAllProfile: Record "All Profile";
        ProfileID: Code[30];
    begin
        // Check that a Profile can be copied into a new profile.
        Initialize();

        OldAllProfile.SetRange(Enabled, true);
        OldAllProfile.FindFirst();
        // Setup : Generate a random code for the new profile in which existing profile will get copied.
        ProfileID :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(NewAllProfile.FieldNo("Profile ID"), DATABASE::"All Profile"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"All Profile", NewAllProfile.FieldNo("Profile ID")));

        // Exercise : Copy the profile into the new Profile.
        RunCopyProfile(OldAllProfile, ProfileID, NewAllProfile);

        // Verify : Verify the newly created Profile.
        VerifyProfile(OldAllProfile, ProfileID, NewAllProfile);

        // Cleanup
        NewAllProfile.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetCurrentProfileID()
    var
        AllProfile: Record "All Profile";
        UserPersonalization: Record "User Personalization";
        AllProfileAfter: Record "All Profile";
        AllObjWithCaption: Record AllObjWithCaption;
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ProfileID: Code[30];
    begin
        // [SCENARIO] Setting the current profile ID works
        Initialize();

        // [GIVEN] A profile ID, set for the current user
        FindAnyRoleCenter(AllObjWithCaption);
        CreateProfile(AllObjWithCaption);
        ProfileID := Format(AllObjWithCaption."Object ID");

        // [WHEN] The profile ID is assigned
        AllProfile.SetRange("Profile ID", ProfileID);
        AllProfile.FindFirst();
        ConfPersonalizationMgt.SetCurrentProfile(AllProfile);

        // [THEN] The change is persisted
        ConfPersonalizationMgt.GetCurrentProfile(AllProfileAfter);
        Assert.AreEqual(ProfileID, AllProfileAfter."Profile ID", 'Unexpected profile ID in user personalization');
        Assert.AreEqual(AllProfile.Scope, AllProfileAfter.Scope, 'Unexpected profile scope in user personalization');
        Assert.AreEqual(AllProfile."App ID", AllProfileAfter."App ID", 'Unexpected profile app ID in user personalization');

        // Cleanup
        UserPersonalization.SetRange("Profile ID", Format(AllObjWithCaption."Object ID"));
        UserPersonalization.FindFirst();
        UserPersonalization.Validate("Profile ID", '');
        Clear(UserPersonalization."App ID");
        Clear(UserPersonalization.Scope);
        UserPersonalization.Modify(true);
        DeleteProfile(AllObjWithCaption);
    end;

    [Test]
    [HandlerFunctions('ThirtyDayTrialDialogPageHandler')]
    [Scope('OnPrem')]
    procedure ShowTermsAndConditions()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        LogInManagement: Codeunit LogInManagement;
        OldTestability: Boolean;
    begin
        // [SCENARIO] "Thirty Day Trial Dialog" page is shown when change company for the user in PROD
        Initialize();
        OldTestability := EnvironmentInfo.IsSaaS();

        // [GIVEN] SaaS, the company is not the evaluation company
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetCompanyToEvaluation(false);

        // [WHEN] Open Company
        LogInManagement.CompanyOpen();

        // [THEN] "Thirty Day Trial Dialog" page is shown (ThirtyDayTrialDialogPageHandler)
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(OldTestability);
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HideTermsAndConditionsInSandbox()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        LogInManagement: Codeunit LogInManagement;
    begin
        // [SCENARIO] "Thirty Day Trial Dialog" page is not shown when opening company for the user in Sandbox
        Initialize();

        // [GIVEN] Sandbox, SaaS, the company is not the evaluation company
        SetSandboxValue(true);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetCompanyToEvaluation(false);

        // [WHEN] Open Company
        LogInManagement.CompanyOpen();

        // [THEN] "Thirty Day Trial Dialog" page is not shown
        // No Handler

        SetSandboxValue(false);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    // Helper functions

    local procedure Initialize()
    var
        AllProfile: Record "All Profile";
    begin
        DeleteUser(UserCassieTxt);

        AllProfile.SetRange("App ID", AllProfile."App ID");
        if AllProfile.FindSet() then
            repeat
                AllProfile.Delete();
            until AllProfile.Next() = 0;

        EnsureUserPersonalizationExists(UserSecurityId());
    end;

    local procedure EnsureUserPersonalizationExists(UserSID: Guid)
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.DeleteAll();

        UserPersonalization.Reset();
        UserPersonalization.Init();
        UserPersonalization."User SID" := UserSID;
        UserPersonalization.Insert();
    end;

    local procedure CreateProfile(AllObjWithCaption: Record AllObjWithCaption)
    var
        ProfileCard: TestPage "Profile Card";
    begin
        // Ensure it doesn't already exist
        DeleteProfile(AllObjWithCaption);

        ProfileCard.OpenNew();
        ProfileCard.ProfileIdField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.DescriptionField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.CaptionField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.RoleCenterIdField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.OK().Invoke();
    end;

    local procedure CreateProfileDefault(AllObjWithCaption: Record AllObjWithCaption)
    var
        ProfileCard: TestPage "Profile Card";
    begin
        // Ensure it doesn't already exist
        DeleteProfile(AllObjWithCaption);

        ProfileCard.OpenNew();
        ProfileCard.ProfileIdField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.DescriptionField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.CaptionField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.OK().Invoke();
    end;

    local procedure DeleteProfile(AllObjWithCaption: Record AllObjWithCaption)
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetFilter("Profile ID", Format(AllObjWithCaption."Object ID"));
        if AllProfile.FindFirst() then
            AllProfile.Delete(true);
    end;

    local procedure RunCopyProfile(OldAllProfile: Record "All Profile"; NewProfileID: Code[30]; var NewAllProfile: Record "All Profile")
    var
        CopyProfileTestPage: TestPage "Copy Profile";
    begin
        NewAllProfile.SetRange("Profile ID", NewProfileID);
        Assert.RecordCount(NewAllProfile, 0);

        // Run Copy Profile.
        CopyProfileTestPage.OpenEdit();
        LibraryVariableStorage.Enqueue(OldAllProfile."Profile ID");
        CopyProfileTestPage.SourceProfileID.AssistEdit();
        CopyProfileTestPage.DestinationProfileID.Value := NewProfileID;
        CopyProfileTestPage.DestinationProfileCaption.Value := LibraryUtility.GenerateGUID();
        CopyProfileTestPage.OK().Invoke();

        Assert.RecordCount(NewAllProfile, 1);
        NewAllProfile.FindFirst();
        NewAllProfile.SetRange("Profile ID");
    end;

    local procedure VerifyProfile(OldAllProfile: Record "All Profile"; ProfileID: Code[30]; NewAllProfile: Record "All Profile")
    var
        AllProfileInDatabase: Record "All Profile";
        TableField: Record Field;
        RecRef1: RecordRef;
        RecRef2: RecordRef;
    begin
        // Get the profile from the DB
        AllProfileInDatabase.SetRange("Profile ID", ProfileID);
        Assert.RecordCount(AllProfileInDatabase, 1);
        AllProfileInDatabase.FindFirst();

        // Step 1: the profile from the DB is the same as the profile returned from the copy profile page
        TableField.SetRange("No.", -1);
        RecRef1.GetTable(AllProfileInDatabase);
        RecRef2.GetTable(NewAllProfile);
        Assert.RecordsAreEqualExceptCertainFields(RecRef1, RecRef2, TableField, 'Copied profile in DB is different from the one returned by the Copy Profile page.');

        // Step 2: the source profile and the destination profile have the same fields, except the one that have changed (profile ID, description, and default RC)
        TableField.SetRange(TableNo, Database::"All Profile");
        if OldAllProfile."Default Role Center" then begin
            Assert.IsFalse(NewAllProfile."Default Role Center", 'Copied profile should not be default.');
            TableField.SetFilter("No.", '%1|%2|%3', OldAllProfile.FieldNo("Profile ID"), OldAllProfile.FieldNo(Description), OldAllProfile.FieldNo("Default Role Center"));
        end else
            TableField.SetFilter("No.", '%1|%2', OldAllProfile.FieldNo("Profile ID"), OldAllProfile.FieldNo(Description));
        RecRef1.GetTable(OldAllProfile);
        RecRef2.GetTable(NewAllProfile);
        Assert.RecordsAreEqualExceptCertainFields(RecRef1, RecRef2, TableField, 'Copied profile is different from source profile.');
    end;

    local procedure FindAnyRoleCenter(var AllObjWithCaption: Record AllObjWithCaption)
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
        AllObjWithCaption.SetRange("Object Subtype", 'RoleCenter');  // Here RoleCenter is needed for Object Subtype.
        AllObjWithCaption.FindFirst();
    end;

    local procedure EnsureDefaultRoleCenterExists()
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange(Enabled, true);
        AllProfile.FindLast();
        SetProfileDefaultRoleCenter(AllProfile);
    end;

    local procedure SetProfileDefaultRoleCenter(var AllProfile: Record "All Profile")
    begin
        AllProfile.Validate("Default Role Center", true);
        AllProfile.Modify(true);
    end;

    local procedure DeleteUser(UserName: Code[50])
    var
        User: Record User;
        UserPersonalization: Record "User Personalization";
    begin
        User.SetRange("User Name", UserName);
        if User.FindFirst() then begin
            if UserPersonalization.Get(User."User Security ID") then
                UserPersonalization.Delete(true);
            User.Delete(true);
        end;
    end;

    local procedure CreateNewProfile(ProfileID: Code[30]; RoleCenterID: Integer; IsDefault: Boolean)
    var
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        AllProfile.SetRange("Profile ID", ProfileID);
        Assert.RecordCount(AllProfile, 0);

        Clear(AllProfile);
        AllProfile.Init();
        AllProfile."Profile ID" := ProfileID;
        AllProfile.Description := ProfileID;
        AllProfile.Scope := AllProfile.Scope::Tenant;
        AllProfile."Default Role Center" := IsDefault;
        AllProfile."Role Center ID" := RoleCenterID;
        AllProfile.Insert(true);

        if IsDefault then
            ConfPersonalizationMgt.SetOtherProfilesAsNonDefault(AllProfile);
    end;

    local procedure SetSandboxValue(Enable: Boolean)
    var
        LibraryPermissions: Codeunit "Library - Permissions";
    begin
        LibraryPermissions.SetTestTenantEnvironmentType(Enable);
    end;

    local procedure SetCompanyToEvaluation(IsEvaluationCompany: Boolean)
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName);
        Company."Evaluation Company" := IsEvaluationCompany;
        Company.Modify();
    end;

    // Handlers

    [ModalPageHandler]
    procedure RolesModalPageHandler(var Roles: TestPage Roles)
    var
        ProfileId: Code[30];
        AllProfile: Record "All Profile";
    begin
        ProfileId := LibraryVariableStorage.DequeueText();
        AllProfile.SetRange(Scope, AllProfile.Scope::Tenant);
        AllProfile.SetRange("Profile ID", ProfileId);
        AllProfile.FindFirst();
        Roles.GoToRecord(AllProfile);
        Roles.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ThirtyDayTrialDialogPageHandler(var ThirtyDayTrialDialog: TestPage "Thirty Day Trial Dialog")
    begin
        ThirtyDayTrialDialog.TermsAndConditionsCheckBox.SetValue(true);
        ThirtyDayTrialDialog.ActionStartTrial.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableProfilesPageHandler(var Roles: TestPage Roles)
    begin
        Roles.Filter.SetFilter("Profile ID", LibraryVariableStorage.DequeueText());
        Roles.OK().Invoke();
    end;

    [SessionSettingsHandler]
    [Scope('OnPrem')]
    procedure RestartHandler(var SessionSettings: SessionSettings): Boolean
    begin
        exit(false);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}
