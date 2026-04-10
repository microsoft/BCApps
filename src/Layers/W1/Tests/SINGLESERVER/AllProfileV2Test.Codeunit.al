codeunit 138698 "AllProfile V2 Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [AllProfile] [Roles] [Profiles]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        DescriptionFilterTxt: Label 'Navigation menu only.';

    // Demotool tests

    [Test]
    [Scope('OnPrem')]
    procedure NoAppProfilesArePresent()
    var
        AllProfile: Record "All Profile";
        TenantProfile: Record "Tenant Profile";
    begin
        // System profiles are now deprecated (moved to Tenant scope), and the metadata table that links to them
        Assert.RecordIsNotEmpty(TenantProfile);
        Assert.RecordIsNotEmpty(AllProfile);

        AllProfile.SetRange(Scope, AllProfile.Scope::System);
        Assert.RecordIsEmpty(AllProfile);

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDuplicateProfileIdsArePresent()
    var
        AllProfile: Record "All Profile";
        PreviousProfileId: Code[30];
        TenantProfile: Record "Tenant Profile";
    begin
        TenantProfile.SetCurrentKey("Profile ID");
        TenantProfile.SetAscending("Profile ID", true);
        TenantProfile.FindSet();
        repeat
            Assert.AreNotEqual(PreviousProfileId, TenantProfile."Profile ID", 'Duplicate id found.');
            PreviousProfileId := TenantProfile."Profile ID";
        until TenantProfile.Next() = 0;

        Clear(PreviousProfileId);
        AllProfile.SetCurrentKey("Profile ID");
        AllProfile.SetAscending("Profile ID", true);
        AllProfile.FindSet();
        repeat
            Assert.AreNotEqual(PreviousProfileId, AllProfile."Profile ID", 'Duplicate id found.');
            PreviousProfileId := AllProfile."Profile ID";
        until AllProfile.Next() = 0;

        Cleanup();
    end;

    // Page tests

    [Test]
    [HandlerFunctions('HandleRoles,HandleSessionSettingsChange')]
    [Scope('OnPrem')]
    procedure TestCanSetAnyProfileInMySettings()
    var
        AllProfile: Record "All Profile";
        UserPersonalization: Record "User Personalization";
        UserSettingsTestPage: TestPage "User Settings";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        PreviousAllProfileCaption: Text;
    begin
        // [GIVEN] The user has a profile assigned
        EnsureUserPersonalization();
        ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
        PreviousAllProfileCaption := AllProfile.Caption;

        // [GIVEN] A list of builtin profiles is available
        Clear(AllProfile);
        AllProfile.SetRange(Enabled, true);
        // We need here to repeat the hack in the AvailableRoles page
        AllProfile.SetFilter(Description, '<> %1', DescriptionFilterTxt);
        AllProfile.FindSet();

        repeat
            Assert.AreNotEqual(AllProfile."Profile ID", '', 'Empty profile ID!');
            Assert.AreNotEqual(AllProfile.Caption, '', 'Empty profile Caption!');

            // [WHEN] The user chooses any of those profiles from user settings
            Clear(UserSettingsTestPage);

            UserSettingsTestPage.OpenEdit();
            Assert.AreEqual(PreviousAllProfileCaption, UserSettingsTestPage.UserRoleCenter.Value, 'Unexpected profile set for the user when reopening MySettings.');
            LibraryVariableStorage.Enqueue(AllProfile."Profile ID");
            UserSettingsTestPage.UserRoleCenter.AssistEdit();
            // Handler

            // [THEN] The description is updated on the user settings page
            Assert.AreEqual(AllProfile.Caption, UserSettingsTestPage.UserRoleCenter.Value, 'Unexpected profile caption after changing profile.');
            UserSettingsTestPage.OK().Invoke();

            // [THEN] The record is updated in the database
            UserPersonalization.Get(UserSecurityId());
            Assert.AreEqual(UserPersonalization."Profile ID", AllProfile."Profile ID", 'Unexpected profile ID set for the user after changing rolecenter.');
            Assert.AreEqual(UserPersonalization."App ID", AllProfile."App ID", 'Unexpected profile app set for the user after changing rolecenter.');
            Assert.AreEqual(UserPersonalization.Scope, AllProfile.Scope, 'Unexpected profile scope set for the user after changing rolecenter.');

            PreviousAllProfileCaption := AllProfile.Caption;
        until AllProfile.Next() = 0;

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestProfileListIsNotEditable()
    var
        ProfileList: TestPage "Profile List";
    begin
        // [GIVEN] A user

        // [WHEN] The user opens the Profile List
        // [THEN] The list is not editable
        ProfileList.OpenEdit();
        Assert.IsFalse(ProfileList.Editable(), 'Profile list should not be editable.');
        ProfileList.Close();

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CopyProfileModalPageHandler')]
    procedure TestCopyProfileActionList()
    var
        SourceAllProfile: Record "All Profile";
        CopiedAllProfile: Record "All Profile";
        NewProfileId: Code[30];
        NewProfileCaption: Text;
        EmptyGuid: Guid;
        ProfileList: TestPage "Profile List";
    begin
        // [GIVEN] A user
        GetRandomAllProfile(SourceAllProfile);
        NewProfileId := LibraryRandom.RandText(MaxStrLen(SourceAllProfile."Profile ID"));
        NewProfileCaption := LibraryRandom.RandText(MaxStrLen(SourceAllProfile.Caption));
        LibraryVariableStorage.Enqueue(SourceAllProfile."Profile ID");
        LibraryVariableStorage.Enqueue(SourceAllProfile.Caption);
        LibraryVariableStorage.Enqueue(SourceAllProfile."App Name");
        LibraryVariableStorage.Enqueue(NewProfileId);
        LibraryVariableStorage.Enqueue(NewProfileCaption);
        LibraryVariableStorage.Enqueue(true);

        // [WHEN] The user opens the Profile List and triggers the Copy Profile action
        ProfileList.OpenEdit();
        ProfileList.GoToRecord(SourceAllProfile);
        ProfileList.CopyProfileAction.Invoke();

        // [THEN] The profile is correctly copied
        Clear(CopiedAllProfile);
        CopiedAllProfile.Get(CopiedAllProfile.Scope::Tenant, EmptyGuid, NewProfileId);
        Assert.AreEqual(NewProfileCaption, CopiedAllProfile.Caption, 'The copied profile has the wrong caption.');
        AssertCopySuccessful(SourceAllProfile, CopiedAllProfile);

        ProfileList.Close();
        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CopyProfileModalPageHandler')]
    procedure TestCopyDefaultProfileDoesNotCreateAnotherDefault()
    var
        SourceAllProfile: Record "All Profile";
        CopiedAllProfile: Record "All Profile";
        NewProfileId: Code[30];
        NewProfileCaption: Text;
        EmptyGuid: Guid;
        ProfileList: TestPage "Profile List";
        InitialProfileCount: Integer;
    begin
        // [GIVEN] A user, and a default profile
        InitialProfileCount := SourceAllProfile.Count();
        PickRandomAllProfileAsDefault(SourceAllProfile);
        Assert.AreEqual(true, SourceAllProfile."Default Role Center", 'Test prerequisite is that the profile is default.');
        NewProfileId := LibraryRandom.RandText(MaxStrLen(SourceAllProfile."Profile ID"));
        NewProfileCaption := LibraryRandom.RandText(MaxStrLen(SourceAllProfile.Caption));
        LibraryVariableStorage.Enqueue(SourceAllProfile."Profile ID");
        LibraryVariableStorage.Enqueue(SourceAllProfile.Caption);
        LibraryVariableStorage.Enqueue(SourceAllProfile."App Name");
        LibraryVariableStorage.Enqueue(NewProfileId);
        LibraryVariableStorage.Enqueue(NewProfileCaption);
        LibraryVariableStorage.Enqueue(true);

        // [WHEN] The user opens the Profile List and triggers the Copy Profile action on the default profile
        ProfileList.OpenEdit();
        ProfileList.GoToRecord(SourceAllProfile);
        ProfileList.CopyProfileAction.Invoke();

        // [THEN] The profile is correctly copied, but is not set as default
        Clear(CopiedAllProfile);
        Assert.AreEqual(InitialProfileCount + 1, CopiedAllProfile.Count(), 'The count of profiles is unexpected.');
        CopiedAllProfile.Get(CopiedAllProfile.Scope::Tenant, EmptyGuid, NewProfileId);
        Assert.AreEqual(NewProfileCaption, CopiedAllProfile.Caption, 'The copied profile has the wrong description.');
        AssertCopySuccessful(SourceAllProfile, CopiedAllProfile);
        Assert.AreEqual(false, CopiedAllProfile."Default Role Center", 'Copied profile should not be default.');
        Assert.AreEqual(true, SourceAllProfile."Default Role Center", 'Copy profile removed default.');

        ProfileList.Close();
        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CopyProfileModalPageHandler')]
    procedure TestCopyProfileActionCard()
    var
        SourceAllProfile: Record "All Profile";
        CopiedAllProfile: Record "All Profile";
        ProfileCard: TestPage "Profile Card";
        NewProfileId: Code[30];
        NewProfileCaption: Text;
        EmptyGuid: Guid;
        InitialProfileCount: Integer;
    begin
        // [GIVEN] A user
        InitialProfileCount := SourceAllProfile.Count();
        GetRandomAllProfile(SourceAllProfile);
        NewProfileId := LibraryRandom.RandText(MaxStrLen(SourceAllProfile."Profile ID"));
        NewProfileCaption := LibraryRandom.RandText(MaxStrLen(SourceAllProfile.Caption));
        LibraryVariableStorage.Enqueue(SourceAllProfile."Profile ID");
        LibraryVariableStorage.Enqueue(SourceAllProfile.Caption);
        LibraryVariableStorage.Enqueue(SourceAllProfile."App Name");
        LibraryVariableStorage.Enqueue(NewProfileId);
        LibraryVariableStorage.Enqueue(NewProfileCaption);
        LibraryVariableStorage.Enqueue(true);

        // [WHEN] The user opens the Profile Card and triggers the Copy Profile action
        ProfileCard.OpenEdit();
        ProfileCard.GoToRecord(SourceAllProfile);
        ProfileCard.CopyProfileAction.Invoke();
        ProfileCard.Close();

        // [THEN] The profile is correctly copied
        Clear(CopiedAllProfile);
        Assert.AreEqual(InitialProfileCount + 1, CopiedAllProfile.Count(), 'The count of profiles is unexpected.');
        CopiedAllProfile.Get(CopiedAllProfile.Scope::Tenant, EmptyGuid, NewProfileId);
        Assert.AreEqual(NewProfileCaption, CopiedAllProfile.Caption, 'The copied profile has the wrong description.');
        AssertCopySuccessful(SourceAllProfile, CopiedAllProfile);

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CopyProfileModalPageHandler')]
    procedure TestCopyProfileCancel()
    var
        SourceAllProfile: Record "All Profile";
        CopiedAllProfile: Record "All Profile";
        ProfileCard: TestPage "Profile Card";
        NewProfileId: Code[30];
        NewProfileCaption: Text;
        EmptyGuid: Guid;
        InitialProfileCount: Integer;
    begin
        // [GIVEN] A user
        InitialProfileCount := SourceAllProfile.Count();
        GetRandomAllProfile(SourceAllProfile);
        NewProfileId := LibraryRandom.RandText(MaxStrLen(SourceAllProfile."Profile ID"));
        NewProfileCaption := LibraryRandom.RandText(MaxStrLen(SourceAllProfile.Caption));
        LibraryVariableStorage.Enqueue(SourceAllProfile."Profile ID");
        LibraryVariableStorage.Enqueue(SourceAllProfile.Caption);
        LibraryVariableStorage.Enqueue(SourceAllProfile."App Name");
        LibraryVariableStorage.Enqueue(NewProfileId);
        LibraryVariableStorage.Enqueue(NewProfileCaption);
        LibraryVariableStorage.Enqueue(false); // Cancel

        // [WHEN] The user opens the Profile Card and triggers the Copy Profile action but cancels
        ProfileCard.OpenEdit();
        ProfileCard.GoToRecord(SourceAllProfile);
        ProfileCard.CopyProfileAction.Invoke();
        ProfileCard.Close();

        // [THEN] The profile is NOT copied
        Clear(CopiedAllProfile);
        Assert.IsFalse(CopiedAllProfile.Get(CopiedAllProfile.Scope::Tenant, EmptyGuid, NewProfileId), 'The record should not be inserted');
        Assert.AreEqual(InitialProfileCount, CopiedAllProfile.count(), 'The count of profiles should not have changed.');
        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestProfileCardEditOwnedProfile()
    var
        ProfileCard: TestPage "Profile Card";
        TempAllProfile: Record "All Profile" temporary;
        DBAllProfile: Record "All Profile";
        FieldTable: Record Field;
        TempRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
    begin
        // [GIVEN] A user
        DBAllProfile.Init();
        DBAllProfile."Profile ID" := LibraryRandom.RandText(MaxStrLen(DBAllProfile."Profile ID"));
        DBAllProfile.Scope := DBAllProfile.Scope::Tenant;
        DBAllProfile.Description := LibraryRandom.RandText(MaxStrLen(DBAllProfile.Description));
        DBAllProfile."Role Center ID" := Page::"Business Manager Role Center";
        DBAllProfile.Enabled := true;
        DBAllProfile.Insert();

        // [WHEN] The user opens the Profile Card on a profile owned
        ProfileCard.OpenEdit();
        ProfileCard.GoToRecord(DBAllProfile);

        // [THEN] All the fields are editable
        Assert.IsTrue(ProfileCard.ProfileIdField.Editable() and ProfileCard.ProfileIdField.Enabled(), 'Profile ID should be editable for owned profiles.');

        TempAllProfile.Description := LibraryRandom.RandText(MaxStrLen(TempAllProfile.Description));
        ProfileCard.DescriptionField.Value := TempAllProfile.Description;

        TempAllProfile."Role Center ID" := Page::"Bookkeeper Role Center";
        ProfileCard.RoleCenterIdField.Value := Format(TempAllProfile."Role Center ID");

        TempAllProfile."Disable Personalization" := true;
        ProfileCard.DisablePersonalizationField.Value := Format(TempAllProfile."Disable Personalization");

        // [THEN] The change is preserved
        DBAllProfile.SetRange("Profile ID", DBAllProfile."Profile ID");
        Assert.RecordCount(DBAllProfile, 1);
        DBAllProfile.FindFirst();

        FieldTable.SetRange(TableNo, Database::"All Profile");
        FieldTable.SetFilter("No.", '%1', DBAllProfile.FieldNo("Profile ID"));

        TempRecordRef.GetTable(TempAllProfile);
        DestinationRecordRef.GetTable(DBAllProfile);

        Assert.RecordsAreEqualExceptCertainFields(TempRecordRef, DestinationRecordRef, FieldTable, 'Editing from card did not work.');

        ProfileCard.Close();
        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestProfileCardEditExtensionProfile()
    var
        ProfileCard: TestPage "Profile Card";
        EmptyGuid: Guid;
        TempAllProfile: Record "All Profile" temporary;
        DBAllProfile: Record "All Profile";
        FieldTable: Record Field;
        TempRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
    begin
        // [GIVEN] A user
        DBAllProfile.Init();
        DBAllProfile.SetFilter("App ID", '<>%1', EmptyGuid);
        DBAllProfile.FindFirst();

        // [WHEN] The user opens the Profile Card on a profile provided by an extension
        ProfileCard.OpenEdit();
        ProfileCard.GoToRecord(DBAllProfile);

        // [THEN] The fields are editable, except the profile ID
        Assert.IsFalse(ProfileCard.ProfileIdField.Enabled() and ProfileCard.ProfileIdField.Editable(), 'Profile ID should not be editable for builtin profiles.');

        // TempAllProfile.Description := LibraryRandom.RandText(MaxStrLen(TempAllProfile.Description));
        // ProfileCard.DescriptionField.Value := TempAllProfile.Description;
        // Commented due to a bug

        TempAllProfile."Disable Personalization" := true;
        ProfileCard.DisablePersonalizationField.Value := Format(TempAllProfile."Disable Personalization");

        // [THEN] The change is preserved
        DBAllProfile.SetRange("Profile ID", DBAllProfile."Profile ID");
        Assert.RecordCount(DBAllProfile, 1);
        DBAllProfile.FindFirst();

        FieldTable.SetRange(TableNo, Database::"All Profile");
        FieldTable.SetFilter("No.", '%1|%2|%3',
            TempAllProfile.FieldNo("Profile ID"),
            TempAllProfile.FieldNo(Description),
            TempAllProfile.FieldNo("Role Center ID")
            );

        TempRecordRef.GetTable(TempAllProfile);
        DestinationRecordRef.GetTable(DBAllProfile);

        Assert.RecordsAreEqualExceptCertainFields(TempRecordRef, DestinationRecordRef, FieldTable, 'Profile editing changed the wrong fields');

        ProfileCard.Close();
        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestProfileCardNew()
    var
        ProfileCard: TestPage "Profile Card";
        AllProfile: Record "All Profile";
        ProfileId: Code[30];
        ProfileDesc: Text;
        ProfileCaption: Text;
        NullGuid: Guid;
    begin
        // Creating a new profile from the Profile Card works
        ProfileId := LibraryRandom.RandText(MaxStrLen(AllProfile."Profile ID"));
        ProfileDesc := LibraryRandom.RandText(MaxStrLen(AllProfile.Description));
        ProfileCaption := LibraryRandom.RandText(MaxStrLen(AllProfile.Caption));
        ProfileCard.OpenNew();
        ProfileCard.ProfileIdField.Value := ProfileId;
        ProfileCard.DescriptionField.Value := ProfileDesc;
        ProfileCard.CaptionField.Value := ProfileCaption;
        ProfileCard.Close();

        AllProfile.Get(AllProfile.Scope::Tenant, NullGuid, ProfileId);
        Assert.AreEqual(AllProfile.Description, ProfileDesc, 'Wrong description for the AllProfile.');
        Assert.AreEqual(AllProfile.Caption, ProfileCaption, 'Wrong caption for the AllProfile.');

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteOwnedProfileSucceeds()
    var
        EmptyGuid: Guid;
        DBAllProfile: Record "All Profile";
    begin
        // [GIVEN] A user, and a profile created by the user
        DBAllProfile.Init();
        DBAllProfile."Profile ID" := LibraryRandom.RandText(MaxStrLen(DBAllProfile."Profile ID"));
        DBAllProfile.Scope := DBAllProfile.Scope::Tenant;
        DBAllProfile.Description := LibraryRandom.RandText(MaxStrLen(DBAllProfile.Description));
        DBAllProfile."Role Center ID" := Page::"Business Manager Role Center";
        DBAllProfile.Enabled := true;
        DBAllProfile.Insert();

        // [WHEN] The user deletes the record
        DBAllProfile.Delete();

        // [THEN] The profile is deleted
        Clear(DBAllProfile);
        asserterror DBAllProfile.Get(DBAllProfile.Scope::Tenant, EmptyGuid, DBAllProfile."Profile ID");

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteExtensionProfileFails()
    var
        EmptyGuid: Guid;
        DBAllProfile: Record "All Profile";
    begin
        // [GIVEN] A user, and a profile provided by an extension
        DBAllProfile.SetFilter("App ID", '<>%1', EmptyGuid);
        GetRandomAllProfile(DBAllProfile);

        // [WHEN] The user deletes the record
        // [THEN] An error occurs
        asserterror DBAllProfile.Delete();
        Assert.ExpectedError(StrSubstNo('Cannot delete ''%1'' profile from an Installed Application.', DBAllProfile."Profile ID"));

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CustomizeHyperlinkHandler')]
    procedure TestConfigureProfileAction()
    var
        ProfileCard: TestPage "Profile Card";
        ProfileList: TestPage "Profile List";
        AllProfile: Record "All Profile";
    begin
        // [GIVEN] A user and a profile
        AllProfile.Init();
        AllProfile."Profile ID" := '/-*PR0FÍL&*-\';
        AllProfile.Caption := 'any caption';
        AllProfile.Scope := AllProfile.Scope::Tenant;
        AllProfile."Role Center ID" := Page::"Bookkeeper Role Center";
        AllProfile.Enabled := true;
        AllProfile.Insert();

        // [WHEN] The user clicks the Customize Profile action in the Profile List
        ProfileList.OpenEdit();
        ProfileList.GoToRecord(AllProfile);
        ProfileList.CustomizeRoleAction.Invoke();

        // [THEN] The URL is correct
        //Checked in Handler
        ProfileList.Close();

        // [WHEN] The user clicks the Customize Profile action in the Profile List
        ProfileCard.OpenEdit();
        ProfileCard.GoToRecord(AllProfile);
        ProfileCard.CustomizeRoleAction.Invoke();

        // [THEN] The URL is correct
        // Checked in Handler

        ProfileCard.Close();
        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatingNewDefaultRemovesOtherDefaults()
    var
        ProfileCard: TestPage "Profile Card";
        AllProfile: Record "All Profile";
        EmptyGuid: Guid;
    begin
        // [GIVEN] A user

        // [WHEN] The user creates a new default profile
        ProfileCard.OpenNew();
        ProfileCard.ProfileIdField.Value := 'My new profile 2';
        ProfileCard.DescriptionField.Value := 'My new description 2';
        ProfileCard.CaptionField.Value := 'My new caption 2';
        ProfileCard.DefaultRoleCenterField.Value := 'Yes';
        ProfileCard.Close();

        // [THEN] Any other default is removed and the profile is set as default
        AllProfile.SetRange("Default Role Center", true);
        Assert.RecordCount(AllProfile, 1);
        AllProfile.FindFirst();
        Assert.IsTrue((AllProfile.Scope = AllProfile.Scope::Tenant) and
            (AllProfile."Profile ID" = Uppercase('My new profile 2')) and
            (AllProfile."App ID" = EmptyGuid),
            'Unexpected default profile.'
        );

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanSetAnyProfileAsDefaultRoleCenter()
    var
        UserCreatedAllProfile: Record "All Profile";
        AllProfile: Record "All Profile";
        AllProfileDb: Record "All Profile";
        ProfileList: TestPage "Profile List";
        UserCreatedProfileFound: Boolean;
    begin
        // [GIVEN] A user, and a list of builtin profiles, and at least one profile user-created
        UserCreatedAllProfile.Init();
        UserCreatedAllProfile."Profile ID" := LibraryRandom.RandText(MaxStrLen(UserCreatedAllProfile."Profile ID"));
        UserCreatedAllProfile.Scope := UserCreatedAllProfile.Scope::Tenant;
        UserCreatedAllProfile.Description := LibraryRandom.RandText(MaxStrLen(UserCreatedAllProfile.Description));
        UserCreatedAllProfile.Caption := LibraryRandom.RandText(MaxStrLen(UserCreatedAllProfile.Caption));
        UserCreatedAllProfile."Role Center ID" := Page::"Business Manager Role Center";
        UserCreatedAllProfile.Enabled := true;
        UserCreatedAllProfile.Insert();
        AllProfile.SetRange(Enabled, true);
        AllProfile.FindSet();

        ProfileList.OpenEdit();
        repeat
            // [WHEN] The user chooses any of those profiles as default from the profile list
            Clear(AllProfileDb);
            ProfileList.GoToRecord(AllProfile);
            ProfileList.SetDefaultRoleCenterAction.Invoke();

            UserCreatedProfileFound := UserCreatedProfileFound or
                (
                    (UserCreatedAllProfile.Scope = AllProfile.Scope) and
                    (UserCreatedAllProfile."Profile ID" = AllProfile."Profile ID") and
                    (UserCreatedAllProfile."App ID" = AllProfile."App ID")
                );

            // [THEN] Any other default is removed and the profile is set as default
            AllProfileDb.SetRange("Default Role Center", true);
            Assert.RecordCount(AllProfileDb, 1);
            AllProfileDb.FindFirst();
            Assert.IsTrue((AllProfile.Scope = AllProfileDb.Scope) and
                (AllProfile."Profile ID" = AllProfileDb."Profile ID") and
                (AllProfile."App ID" = AllProfileDb."App ID"),
                'Unexpected default profile.'
            );
        until AllProfile.Next() = 0;

        ProfileList.Close();
        Assert.IsTrue(UserCreatedProfileFound, 'Did not find the user created profile.');
        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanSetAnyProfileAsDefaultRoleCenterCard()
    var
        AllProfile: Record "All Profile";
        AllProfileDb: Record "All Profile";
        ProfileCard: TestPage "Profile Card";
    begin
        // [GIVEN] A user, and a list of builtin profiles
        PickRandomAllProfileAsDefault(AllProfile); // Ensure there is a default
        Clear(AllProfile);
        AllProfile.SetRange("Default Role Center", false);
        GetRandomAllProfile(AllProfile);
        AllProfile.SetRange("Default Role Center");

        // [WHEN] The user chooses any of those profiles as default from the profile card
        ProfileCard.OpenEdit();
        ProfileCard.GoToRecord(AllProfile);
        ProfileCard.DefaultRoleCenterField.Value := 'Yes';
        ProfileCard.Close();

        // [THEN] Any other default is removed and the profile is set as default
        AllProfileDb.SetRange("Default Role Center", true);
        Assert.RecordCount(AllProfileDb, 1);
        AllProfileDb.FindFirst();
        Assert.IsTrue((AllProfile.Scope = AllProfileDb.Scope) and
            (AllProfile."Profile ID" = AllProfileDb."Profile ID") and
            (AllProfile."App ID" = AllProfileDb."App ID"),
            'Unexpected default profile.'
        );

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RCLookupPageHandler')]
    procedure TestSelectRoleCenterInProfilePage()
    var
        ProfileCard: TestPage "Profile Card";
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        // [GIVEN] A user

        // [WHEN] The user creates a new profile
        ProfileCard.OpenNew();
        ProfileCard.ProfileIdField.Value := 'Test';
        ProfileCard.DescriptionField.Value := 'Test Description';

        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
        AllObjWithCaption.SetRange("Object Subtype", 'RoleCenter');

        // [THEN] The user can select any Role Center, and the App Name shows up for those.
        AllObjWithCaption.FindSet();
        repeat
            LibraryVariableStorage.Enqueue(AllObjWithCaption."Object ID");
            ProfileCard.RoleCenterIdField.Lookup();
            Assert.AreEqual(Format(AllObjWithCaption."Object ID"), ProfileCard.RoleCenterIdField.Value, 'Unexpected Role Center.');
        until AllObjWithCaption.Next() = 0;

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotDisableProfileAssignedToUser()
    var
        AllProfile: Record "All Profile";
        UserPersonalization: Record "User Personalization";
        ProfileCard: TestPage "Profile Card";
    begin
        EnsureUserPersonalization();

        AllProfile.FindFirst();
        UserPersonalization.Get(UserSecurityId());
        UserPersonalization."Profile ID" := AllProfile."Profile ID";
        UserPersonalization."App ID" := AllProfile."App ID";
        UserPersonalization.Scope := AllProfile.Scope;
        UserPersonalization.Modify(true);
        ProfileCard.OpenEdit();
        ProfileCard.GoToRecord(AllProfile);
        asserterror ProfileCard.EnabledField.SetValue(false);
        Assert.ExpectedError('You cannot disable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotDisableDefaultProfile()
    var
        AllProfile: Record "All Profile";
        ProfileCard: TestPage "Profile Card";
    begin
        ProfileCard.OpenNew();
        ProfileCard.ProfileIdField.SetValue(LibraryRandom.RandText(MaxStrLen(AllProfile."Profile ID")));
        ProfileCard.CaptionField.SetValue(LibraryRandom.RandText(MaxStrLen(AllProfile.Caption)));
        ProfileCard.DefaultRoleCenterField.SetValue(true);
        asserterror ProfileCard.EnabledField.SetValue(false);
        Assert.ExpectedError('You cannot disable the profile that is used as default.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotSetDisabledProfileAsDefault()
    var
        AllProfile: Record "All Profile";
        ProfileCard: TestPage "Profile Card";
    begin
        ProfileCard.OpenNew();
        ProfileCard.ProfileIdField.SetValue(LibraryRandom.RandText(MaxStrLen(AllProfile."Profile ID")));
        ProfileCard.EnabledField.SetValue(false);
        asserterror ProfileCard.DefaultRoleCenterField.SetValue(true);
        Assert.ExpectedError('The profile must be enabled in order to set it as the default profile.');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('AcceptConfirmHandler,MessageHandler')]
    procedure TestClearCustomizedPagesIsDisabledWhenThereAreNoCustomizations()
    var
        AllProfile: Record "All Profile";
        TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
        ProfileCard: TestPage "Profile Card";
    begin
        // [GIVEN] A new profile with no customizations
        AllProfile."Profile ID" := LibraryRandom.RandText(MaxStrLen(AllProfile."Profile ID"));
        AllProfile.Scope := AllProfile.Scope::Tenant;
        AllProfile.Insert(true);
        ProfileCard.OpenEdit();
        ProfileCard.GoToRecord(AllProfile);
        Assert.IsFalse(ProfileCard.ClearCustomizedPagesAction.Enabled(), 'There should not be any customizations for newly created profiles.');
        ProfileCard.Close();

        // [WHEN] User creates a page personalization
        TenantProfilePageMetadata."Profile ID" := AllProfile."Profile ID";
        TenantProfilePageMetadata."App ID" := AllProfile."App ID";
        TenantProfilePageMetadata.Owner := TenantProfilePageMetadata.Owner::Tenant;
        TenantProfilePageMetadata.Insert(true);

        ProfileCard.OpenEdit();
        ProfileCard.GoToRecord(AllProfile);
        Assert.IsTrue(ProfileCard.ClearCustomizedPagesAction.Enabled(), 'There should be customizations to clear.');
        ProfileCard.ClearCustomizedPagesAction.Invoke();
        Assert.IsFalse(ProfileCard.ClearCustomizedPagesAction.Enabled(), 'After clearing customizations, the action should no longer be enabled.');
        ProfileCard.Close();

        ProfileCard.OpenEdit();
        ProfileCard.GoToRecord(AllProfile);
        Assert.IsFalse(ProfileCard.ClearCustomizedPagesAction.Enabled(), 'Customizations should still be clear after re-opening page.');
        ProfileCard.Close();

        // Make sure when we called ClearCustomizedPagesAction that the correct messages were sent
        Assert.AreEqual(
            'This will delete all user-made customization changes for this profile. It will not clear the customizations coming from your extensions.\\Do you want to continue?',
            LibraryVariableStorage.DequeueText(),
            'Delete customization question not shown.');
        Assert.IsTrue(
            StrPos(LibraryVariableStorage.DequeueText(), 'have been deleted successfully') > 0,
            'Succcessfully deleted message was not shown.');

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotNameANewProfileTheSameAsAnExisting()
    var
        ProfileCard: TestPage "Profile Card";
        AllProfile: Record "All Profile";
        EmptyGuid: Guid;
    begin
        AllProfile.SetFilter("App ID", '<>%1', EmptyGuid);
        AllProfile.FindFirst();
        ProfileCard.OpenNew();
        asserterror ProfileCard.ProfileIdField.SetValue(AllProfile."Profile ID");
        Assert.ExpectedError(
            StrSubstNo('A profile with Profile ID "%1" already exist, please provide another Profile ID.',
            AllProfile."Profile ID"));

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotselectANonRoleCenterPageAsRoleCenter()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ProfileCard: TestPage "Profile Card";
    begin
        // [GIVEN] A user

        // [WHEN] The user creates a new profile
        ProfileCard.OpenNew();
        ProfileCard.ProfileIdField.Value := 'Test';
        ProfileCard.DescriptionField.Value := 'Test Description';

        asserterror ProfileCard.RoleCenterIdField.Value := Format(Page::"Customer Card");
        Assert.ExpectedTestFieldError(AllObjWithCaption.FieldCaption("Object Subtype"), 'RoleCenter');
        ProfileCard.RoleCenterIdField.Value := Format(Page::"Business Manager Role Center");

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDownloadProfiles()
    var
        FileManagement: codeunit "File Management";
        ProfileZipFileName: Text;
        ZipEntries: List of [Text];
        ExpectedEntries: List of [Text];
    begin
        // Setup
        CleanupProfilesAndCustomizations();
        LibraryVariableStorage.AssertEmpty();

        // [GIVEN] User created profiles
        CreateProfilesAndGetIDs(3, ExpectedEntries);

        // [WHEN] The user exports all profiles (and customizations)
        ExportUserCreatedProfilesAndCustomizationsToZipInServer(ProfileZipFileName);
        GetZipFileContentNamesAsList(ProfileZipFileName, ZipEntries);

        // [THEN] A zip file is exported, and the user created profiles are there
        ExpectedEntries.Add('app.json');
        ExpectedEntries.Add('profiles.json');
        AssertMatchStringsFromLists(ZipEntries, ExpectedEntries);

        // Cleanup
        LibraryVariableStorage.AssertEmpty();
        FileManagement.DeleteServerFile(ProfileZipFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotEditProfilesWithDuplicateIds()
    var
        AllProfile: Record "All Profile";
        ProfileCard: TestPage "Profile Card";
        DuplicateProfileId: Code[30];
    begin
        // [GIVEN] Two profiles with the same ID
        AllProfile.SetFilter("App ID", '<>%1', AllProfile."App ID");
        GetRandomAllProfile(AllProfile);
        DuplicateProfileId := AllProfile."Profile ID";
        CreateTenantProfile(DuplicateProfileId);

        // [WHEN] The user opens the profile card for some other profile
        ProfileCard.OpenEdit();
        Clear(AllProfile);
        AllProfile.SetFilter("Profile ID", '<>%1', DuplicateProfileId);
        GetRandomAllProfile(AllProfile);
        ProfileCard.GoToRecord(AllProfile);

        // [THEN] Everything is editable and all is good
        Assert.IsTrue(ProfileCard.RoleCenterIdField.Editable(), 'The profile should be editable!');
        Assert.IsTrue(ProfileCard.CustomizeRoleAction.Enabled(), 'The profile should be customizable!');
        ProfileCard.Close();

        // [WHEN] The user opens the profile card for the user created duplicate profile
        ProfileCard.OpenEdit();
        Clear(AllProfile);
        AllProfile.SetRange("Profile ID", DuplicateProfileId);
        AllProfile.SetRange("App ID", AllProfile."App ID");
        AllProfile.FindFirst();
        ProfileCard.GoToRecord(AllProfile);

        // [THEN] Everything is editable and all is good
        Assert.IsTrue(ProfileCard.RoleCenterIdField.Editable(), 'The profile should be editable!');
        Assert.IsTrue(ProfileCard.CustomizeRoleAction.Enabled(), 'The profile should be customizable!');
        ProfileCard.Close();

        // [WHEN] The user opens the profile card for the non-user-created duplicate profile
        ProfileCard.OpenEdit();
        Clear(AllProfile);
        AllProfile.SetRange("Profile ID", DuplicateProfileId);
        AllProfile.SetFilter("App ID", '<>%1', AllProfile."App ID");
        Assert.RecordCount(AllProfile, 1);
        AllProfile.FindFirst();
        ProfileCard.GoToRecord(AllProfile);

        // [THEN] Everything is NOT editable
        Assert.IsFalse(ProfileCard.RoleCenterIdField.Editable(), 'The profile should NOT be editable!');
        Assert.IsFalse(ProfileCard.CustomizeRoleAction.Enabled(), 'The profile should NOT be customizable!');
        ProfileCard.Close();

        // [WHEN] The user opens the profile card for some other profile AGAIN
        ProfileCard.OpenEdit();
        Clear(AllProfile);
        AllProfile.SetFilter("Profile ID", '<>%1', DuplicateProfileId);
        GetRandomAllProfile(AllProfile);
        ProfileCard.GoToRecord(AllProfile);

        // [THEN] Everything is editable and all is good
        Assert.IsTrue(ProfileCard.RoleCenterIdField.Editable(), 'The profile should be editable!');
        Assert.IsTrue(ProfileCard.CustomizeRoleAction.Enabled(), 'The profile should be customizable!');
        ProfileCard.Close();

        // Cleanup
        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('AnyHyperlinkHandler')]
    procedure TestCannotCustomizeProfilesWithDuplicateIds()
    var
        AllProfile: Record "All Profile";
        ProfileList: TestPage "Profile List";
        DuplicateProfileId: Code[30];
    begin
        // [GIVEN] Two profiles with the same ID
        AllProfile.SetFilter("App ID", '<>%1', AllProfile."App ID");
        GetRandomAllProfile(AllProfile);
        DuplicateProfileId := AllProfile."Profile ID";
        CreateTenantProfile(DuplicateProfileId);

        // [WHEN] The user opens the profile list and goes to any other profile
        ProfileList.OpenEdit();
        Clear(AllProfile);
        AllProfile.SetFilter("Profile ID", '<>%1', DuplicateProfileId);
        GetRandomAllProfile(AllProfile);
        ProfileList.GoToRecord(AllProfile);

        // [THEN] Customizing works
        ProfileList.CustomizeRoleAction.Invoke();
        ProfileList.Close();

        // [WHEN] The user opens the profile list and goes to the user created duplicate profile
        ProfileList.OpenEdit();
        Clear(AllProfile);
        AllProfile.SetRange("Profile ID", DuplicateProfileId);
        AllProfile.SetRange("App ID", AllProfile."App ID");
        AllProfile.FindFirst();
        ProfileList.GoToRecord(AllProfile);

        // [THEN] Customizing works
        ProfileList.CustomizeRoleAction.Invoke();
        ProfileList.Close();

        // [WHEN] The user opens the profile list and goes to the non-user-created duplicate profile
        ProfileList.OpenEdit();
        Clear(AllProfile);
        AllProfile.SetRange("Profile ID", DuplicateProfileId);
        AllProfile.SetFilter("App ID", '<>%1', AllProfile."App ID");
        Assert.RecordCount(AllProfile, 1);
        AllProfile.FindFirst();
        ProfileList.GoToRecord(AllProfile);

        // [THEN] Customizing does NOT work
        asserterror ProfileList.CustomizeRoleAction.Invoke();
        ProfileList.Close();

        // [WHEN] The user opens the profile list and goes to some other profile AGAIN
        ProfileList.OpenEdit();
        Clear(AllProfile);
        AllProfile.SetFilter("Profile ID", '<>%1', DuplicateProfileId);
        GetRandomAllProfile(AllProfile);
        ProfileList.GoToRecord(AllProfile);

        // [THEN] Customizing works
        ProfileList.CustomizeRoleAction.Invoke();
        ProfileList.Close();

        // Cleanup
        Cleanup();
    end;

    // Helper functions

    local procedure CreateProfilesAndGetIDs(HowMany: Integer; var ProfileIDs: List of [Text])
    var
        DummyAllProfile: Record "All Profile";
        CurrentProfileID: Text;
        Index: Integer;
    begin
        // Some checks to make sure the test is not inconclusive
        Assert.AreNotEqual(HowMany, 0, 'Test would be inconclusive with 0 profiles.');
        Assert.AreEqual(ProfileIDs.Count(), 0, 'Expected empty list to use as output.');

        for Index := 1 to HowMany do begin
            CurrentProfileID := LibraryRandom.RandText(MaxStrLen(DummyAllProfile."Profile ID"));
            CreateTenantProfile(CurrentProfileID);
            ProfileIDs.Add(UpperCase(CurrentProfileID));
        end;

        Assert.AreEqual(ProfileIDs.Count(), HowMany, 'Failed to generate the right number of profiles.');
    end;

    local procedure GetZipFileContentNamesAsList(ZipFileName: Text; var OutList: List of [Text])
    var
        DataCompression: codeunit "Data Compression";
        ZipFile: File;
        ProfilesZipArchiveInstream: instream;
    begin
        // [THEN]
        ZipFile.Open(ZipFileName);
        ZipFile.CreateInStream(ProfilesZipArchiveInstream);
        DataCompression.OpenZipArchive(ProfilesZipArchiveInstream, false);
        DataCompression.GetEntryList(OutList);
    end;

    procedure DequeueText(): Text
    begin
        exit(LibraryVariableStorage.DequeueText());
    end;

    local procedure CreateTenantProfile(ProfileId: Code[30])
    var
        AllProfile: Record "All Profile";
    begin
        if AllProfile.Get(AllProfile.Scope::Tenant, AllProfile."App ID", ProfileId) then
            AllProfile.Delete(); // This profile was already duplicated previously, clean it up before re-creating
        AllProfile.Scope := AllProfile.Scope::Tenant;
        AllProfile."Profile ID" := ProfileId;
        AllProfile."Role Center ID" := page::"Business Manager Role Center";
        AllProfile.Insert(true);
    end;

    local procedure Cleanup()
    var
        AllProfile: Record "All Profile";
        UserPersonalization: Record "User Personalization";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        EmptyGuid: Guid;
    begin
        LibraryVariableStorage.AssertEmpty();
        NotificationLifecycleMgt.RecallAllNotifications();

        // Delete any custom profile
        AllProfile.SetRange("App ID", EmptyGuid);
        if AllProfile.FindSet() then
            repeat
                AllProfile.Delete(true);
            until AllProfile.Next() = 0;

        // Reset the default profile (and remove any other default)
        Clear(AllProfile);
        AllProfile.FindSet();
        repeat
            AllProfile."Default Role Center" := false;
            AllProfile.Modify();
        until AllProfile.Next() = 0;

        Clear(AllProfile);
        AllProfile.SetRange("Role Center ID", Page::"Business Manager Role Center");
        AllProfile.FindFirst();
        AllProfile."Default Role Center" := true;
        AllProfile.Modify(true);

        // Cleanup User Personalization, ensure default profile is loaded for the user
        Clear(AllProfile);
        if UserPersonalization.FindSet(true, false) then
            repeat
                ConfPersonalizationMgt.GetDefaultProfileID(UserPersonalization."User SID", AllProfile);
                UserPersonalization.Validate("Profile ID", AllProfile."Profile ID");
                UserPersonalization.Validate(Scope, AllProfile.Scope);
                UserPersonalization.Validate("App ID", AllProfile."App ID");
                UserPersonalization.Modify(true);
            until UserPersonalization.Next() = 0;
    end;

    local procedure EnsureUserPersonalization()
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.SetRange("User SID", UserSecurityId());
        if not UserPersonalization.FindFirst() then begin
            UserPersonalization.Reset();
            UserPersonalization.Init();
            UserPersonalization."User SID" := UserSecurityId();
            UserPersonalization."User ID" := UserId;
            UserPersonalization.Insert();
        end;
    end;

    local procedure GetRandomAllProfile(var AllProfile: Record "All Profile")
    var
        NextJump: Integer;
    begin
        AllProfile.SetRange(Enabled, true);
        AllProfile.FindSet();
        NextJump := LibraryRandom.RandInt(AllProfile.Count()) - 1; // 0 to AllProfile.Count - 1
        Assert.AreEqual(
            NextJump,
            AllProfile.Next(NextJump),
            'Failed to find random AllProfile (Next failed).');
    end;

    local procedure PickRandomAllProfileAsDefault(var AllProfile: Record "All Profile")
    var
        ProfileList: TestPage "Profile List";
        DbAllProfile: Record "All Profile";
    begin
        // Pick a random AllProfile from the ones in the DB
        Clear(AllProfile);
        GetRandomAllProfile(AllProfile);

        // Set it as default
        ProfileList.OpenEdit();
        ProfileList.GoToRecord(AllProfile);
        ProfileList.SetDefaultRoleCenterAction.Invoke();
        ProfileList.Close();

        // Make sure there is only one default in the DB, and it's the one I have, before returning it
        DbAllProfile.SetRange("Default Role Center", true);
        Assert.RecordCount(DbAllProfile, 1);

        AllProfile.SetRecFilter();
        AllProfile.Find();
        Assert.IsTrue(AllProfile."Default Role Center", 'Picking default failed.');
    end;

    local procedure AssertCopySuccessful(SourceAllProfile: Record "All Profile"; DestinationAllProfile: Record "All Profile")
    var
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
        FieldTable: Record Field;
        EmptyGuid: Guid;
    begin
        Assert.AreEqual(EmptyGuid, DestinationAllProfile."App ID", 'App id should be empty in the copied profile.');
        Assert.AreEqual(false, DestinationAllProfile."Default Role Center", 'The destination profile should not be set as default.');

        FieldTable.SetRange(TableNo, Database::"All Profile");
        FieldTable.SetFilter("No.", '%1|%2|%3',
            SourceAllProfile.FieldNo("Profile ID"),
            SourceAllProfile.FieldNo("App ID"),
            SourceAllProfile.FieldNo(Description)
            );

        SourceRecordRef.GetTable(SourceAllProfile);
        DestinationRecordRef.GetTable(DestinationAllProfile);

        Assert.RecordsAreEqualExceptCertainFields(SourceRecordRef, DestinationRecordRef, FieldTable, 'Copy profile populated the wrong fields');
    end;

    local procedure ExportUserCreatedProfilesAndCustomizationsToZipInServer(var ProfileZipFileName: Text)
    var
        AllProfileV2Test: codeunit "AllProfile V2 Test";
        ConfPersonalizationMgt: codeunit "Conf./Personalization Mgt.";
    begin
        BindSubscription(AllProfileV2Test);
        ConfPersonalizationMgt.DownloadProfileConfigurationPackage();
        UnbindSubscription(AllProfileV2Test);
        ProfileZipFileName := AllProfileV2Test.DequeueText();

        Assert.IsTrue(File.Exists(ProfileZipFileName), 'Profiles were not exported to a zip file');
    end;

    local procedure AssertMatchStringsFromLists(FirstListOfStrings: List of [Text]; SecondListOfStrings: List of [Text])
    var
        TextFromFirstList: Text;
        TextFromSecondList: Text;
    begin
        // This is quadratic, but currently we have 5 files so we can deal with it.
        foreach TextFromFirstList in FirstListOfStrings do begin
            if SecondListOfStrings.Count() = 0 then
                Assert.Fail(StrSubstNo('There are strings in the first list, but the second one is empty. Element %1 of %2: %3',
                    FirstListOfStrings.IndexOf(TextFromFirstList), FirstListOfStrings.Count(), TextFromFirstList));

            foreach TextFromSecondList in SecondListOfStrings do
                if TextFromFirstList.Contains(TextFromSecondList) or TextFromSecondList.Contains(TextFromFirstList) then begin
                    SecondListOfStrings.Remove(TextFromSecondList);
                    break;
                end;
        end;

        if SecondListOfStrings.Count() > 0 then
            Assert.Fail(StrSubstNo('All elements should have matched, but for example I still have: %1.', SecondListOfStrings.Get(1)));
    end;

    local procedure CleanupProfilesAndCustomizations()
    var
        TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
        TenantProfileExtension: Record "Tenant Profile Extension";
    begin
        if TenantProfileExtension.FindSet() then
            repeat
                TenantProfileExtension.Delete();
            until TenantProfileExtension.Next() = 0;

        TenantProfilePageMetadata.SetRange(Owner, TenantProfilePageMetadata.Owner::Tenant);
        if TenantProfilePageMetadata.FindSet() then
            repeat
                TenantProfilePageMetadata.Delete();
            until TenantProfilePageMetadata.Next() = 0;
    end;

    // Handlers

    [ModalPageHandler]
    procedure RCLookupPageHandler(var RcLookupPage: TestPage "All Objects with Caption")
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Page, LibraryVariableStorage.DequeueInteger());
        RcLookupPage.GoToRecord(AllObjWithCaption);
        Assert.AreNotEqual('', RcLookupPage."App Name".Value, 'Empty App name in the RC list.');
        RcLookupPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CopyProfileModalPageHandler(var CopyProfileModalPage: TestPage "Copy Profile")
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), CopyProfileModalPage.SourceProfileID.Value, 'Unexpected data in Copy Profile page');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), CopyProfileModalPage.SourceProfileCaption.Value, 'Unexpected data in Copy Profile page');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), CopyProfileModalPage.SourceProfileAppName.Value, 'Unexpected data in Copy Profile page');

        CopyProfileModalPage.DestinationProfileID.SetValue(LibraryVariableStorage.DequeueText());
        CopyProfileModalPage.DestinationProfileCaption.SetValue(LibraryVariableStorage.DequeueText());
        if LibraryVariableStorage.DequeueBoolean() then
            CopyProfileModalPage.OK().Invoke()
        else
            CopyProfileModalPage.Cancel().Invoke()
    end;

    [ModalPageHandler]
    procedure HandleRoles(var Roles: TestPage Roles)
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange("Profile ID", LibraryVariableStorage.DequeueText());
        AllProfile.FindFirst();
        Roles.GoToRecord(AllProfile);
        Roles.OK().Invoke();
    end;

    [SessionSettingsHandler]
    procedure HandleSessionSettingsChange(var ChangedSessionSettings: SessionSettings): Boolean
    begin
    end;

    [HyperlinkHandler]
    procedure CustomizeHyperlinkHandler(Message: Text[1024])
    begin
        Assert.IsSubstring(Message, '/?profile=%2F-%2APR0F%C3%8DL%26%2A-%5C&customize');
    end;

    [HyperlinkHandler]
    procedure AnyHyperlinkHandler(Message: Text[1024])
    begin
        Assert.IsSubstring(Message, 'customize');
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ConfirmHandler]
    procedure AcceptConfirmHandler(Question: Text[1024]; var reply: boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        reply := true;
    end;

    // Subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure SaveFileToDisk(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    var
        FileManagement: Codeunit "File Management";
        ServerTempFileName: Text;
    begin
        // The download handler deletes the file before we can check the content, so need to copy it for the test to succeed
        ServerTempFileName := FileManagement.ServerTempFileName('zip');
        FileManagement.CopyServerFile(FromFileName, ServerTempFileName, false);

        LibraryVariableStorage.Enqueue(ServerTempFileName);
        IsHandled := true;
    end;
}
