// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 132926 "User Factboxes Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        AzureADGraphTestLibrary: Codeunit "Azure AD Graph Test Library";
        MockGraphQueryTestLibrary: Codeunit "MockGraphQuery Test Library";
        SecurityGroupsTestLibrary: Codeunit "Security Groups Test Library";
        LibraryUserSecurityGroups: Codeunit "Library - User Security Groups";
        UserPermissionsTestLibrary: Codeunit "Test User Permissions Subs.";
        TestSecurityGroupCodeTxt: Label 'TEST_SG';
        TestSecurityGroupIdTxt: Label 'security group test ID';
        TestSecurityGroupNameTxt: Label 'Test AAD group';
    
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure TestNoLoadingWhenThereAreNoGroups()
    var
        UsersTestPage: TestPage Users;
        UserSecId: Guid;
        GraphUser: DotNet UserInfo;
    begin
        // [SCENARIO] When no security group is defined in BC, the loading text
        // is not shown (as the background task is not scheduled).

        Initialize();

        // [GIVEN] An AAD security group exists, but it is not added in BC
        MockGraphQueryTestLibrary.AddGroup(TestSecurityGroupNameTxt, TestSecurityGroupIdTxt);

        // [GIVEN] A user exists in Entra and BC
        CreateUser(GraphUser, UserSecId);

        // [WHEN] Users page is opened
        UsersTestPage.Trap();
        Page.Run(Page::Users);

        // [THEN] The security groups factboxes are visible 
        AssertSecurityGroupFactboxesAreVisible(UsersTestPage, true);

        TearDown();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure TestNoLoadingWhenUserIsDisabled()
    var
        User: Record User;
        UsersTestPage: TestPage Users;
        UserSecId: Guid;
        GraphUser: DotNet UserInfo;
    begin
        // [SCENARIO] When user is disabled, the loading text is not shown (as the background task is not scheduled).

        Initialize();

        // [GIVEN] A user exists in Entra and BC
        CreateUser(GraphUser, UserSecId);

        // [GIVEN] The user is disabled in BC
        User.Get(UserSecId);
        User.State := User.State::Disabled;
        User.Modify();

        // [WHEN] Users page is opened
        UsersTestPage.Trap();
        Page.Run(Page::Users);

        // [THEN] The security groups factboxes are visible 
        AssertSecurityGroupFactboxesAreVisible(UsersTestPage, true);

        TearDown();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure TestLoadingShownWhenFetchingGroups()
    var
        SecurityGroup: Codeunit "Security Group";
        UsersTestPage: TestPage Users;
        UserSecId: Guid;
        GraphUser: DotNet UserInfo;
    begin
        // [SCENARIO] When a security group is defined in BC and the user is a member of the group, then the loading factboxes are show
        // while the group memberships are fetched. When the fetching is complete, the security group factboxes factbox are shown.

        Initialize();

        // [GIVEN] An AAD security group exists
        MockGraphQueryTestLibrary.AddGroup(TestSecurityGroupNameTxt, TestSecurityGroupIdTxt);

        // [GIVEN] A BC security group is created
        SecurityGroup.Create(TestSecurityGroupCodeTxt, TestSecurityGroupIdTxt);

        // [GIVEN] A user exists in Entra and BC
        CreateUser(GraphUser, UserSecId);

        // [GIVEN] The user is a group member
        MockGraphQueryTestLibrary.AddGraphUserToGroup(GraphUser, TestSecurityGroupNameTxt, TestSecurityGroupIdTxt);

        // [WHEN] Users page is opened
        UsersTestPage.Trap();
        Page.Run(Page::Users);

        UsersTestPage.GoToKey(UserSecId);

        // [THEN] The "loading" factboxes are shown
        AssertSecurityGroupFactboxesAreVisible(UsersTestPage, false);

        // [WHEN] The page background task is completed
        UsersTestPage.TriggerPageBackgroundTask.Invoke();

        // [THEN] The actual security group factboxes are shown
        AssertSecurityGroupFactboxesAreVisible(UsersTestPage, true);

        // [THEN] The group membership is reflected in the User Security Groups factbox
        UsersTestPage."User Security Groups".First();
        Assert.AreEqual(TestSecurityGroupNameTxt, UsersTestPage."User Security Groups"."Security Group Name".Value, 'Incorrect security group name');

        TearDown();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure TestSwitchingRecordsBeforePbtCompletion()
    var
        SecurityGroup: Codeunit "Security Group";
        UsersTestPage: TestPage Users;
        GraphUser1: DotNet UserInfo;
        GraphUser2: DotNet UserInfo;
        User1SecId: Guid;
        User2SecId: Guid;
    begin
        // [SCENARIO] When the current record is changed before PBT completes, the visibility of parts still updates as expected.

        Initialize();

        // [GIVEN] An AAD security group exists
        MockGraphQueryTestLibrary.AddGroup(TestSecurityGroupNameTxt, TestSecurityGroupIdTxt);

        // [GIVEN] A BC security group is created
        SecurityGroup.Create(TestSecurityGroupCodeTxt, TestSecurityGroupIdTxt);

        // [GIVEN] 2 users exist in Entra and BC
        CreateUser(GraphUser1, User1SecId);
        CreateUser(GraphUser2, User2SecId);

        // [GIVEN] User 2 is a group member
        MockGraphQueryTestLibrary.AddGraphUserToGroup(GraphUser2, TestSecurityGroupNameTxt, TestSecurityGroupIdTxt);

        // [WHEN] Users page is opened
        UsersTestPage.Trap();
        Page.Run(Page::Users);

        // [WHEN] The current user is User1
        UsersTestPage.GoToKey(User1SecId);

        // [THEN] The "loading" factboxes are shown
        AssertSecurityGroupFactboxesAreVisible(UsersTestPage, false);

        // [WHEN] Without waiting for PBT to finish, the current record is switched to User2
        UsersTestPage.GoToKey(User2SecId);

        // [THEN] The "loading" factboxes are still shown
        AssertSecurityGroupFactboxesAreVisible(UsersTestPage, false);

        // [WHEN] The page background task is completed for User2
        UsersTestPage.TriggerPageBackgroundTask.Invoke();

        // [THEN] The actual security group factboxes are shown for User2
        AssertSecurityGroupFactboxesAreVisible(UsersTestPage, true);

        // [THEN] The group membership is reflected in the User Security Groups factbox
        UsersTestPage."User Security Groups".First();
        Assert.AreEqual(TestSecurityGroupNameTxt, UsersTestPage."User Security Groups"."Security Group Name".Value, 'Incorrect security group name');

        // [WHEN] The current user is switched back to User1
        UsersTestPage.GoToKey(User1SecId);

        // [THEN] The "loading" factboxes are still shown (as the PBT never completed for this user)
        AssertSecurityGroupFactboxesAreVisible(UsersTestPage, false);

        TearDown();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure TestSwitchingRecordsAfterPbtCompletion()
    var
        SecurityGroup: Codeunit "Security Group";
        UsersTestPage: TestPage Users;
        GraphUser1: DotNet UserInfo;
        GraphUser2: DotNet UserInfo;
        User1SecId: Guid;
        User2SecId: Guid;
    begin
        // [SCENARIO] When the current record is changed after PBT completes, and
        // then changed back, there is no loading screen (as the results are cached).

        Initialize();

        // [GIVEN] An AAD security group exists
        MockGraphQueryTestLibrary.AddGroup(TestSecurityGroupNameTxt, TestSecurityGroupIdTxt);

        // [GIVEN] A BC security group is created
        SecurityGroup.Create(TestSecurityGroupCodeTxt, TestSecurityGroupIdTxt);

        // [GIVEN] 2 users exist in Entra and BC
        CreateUser(GraphUser1, User1SecId);
        CreateUser(GraphUser2, User2SecId);

        // [GIVEN] User 1 is a group member
        MockGraphQueryTestLibrary.AddGraphUserToGroup(GraphUser1, TestSecurityGroupNameTxt, TestSecurityGroupIdTxt);

        // [WHEN] Users page is opened
        UsersTestPage.Trap();
        Page.Run(Page::Users);

        // [WHEN] The current user is User1
        UsersTestPage.GoToKey(User1SecId);

        // [WHEN] The page background task is completed for User1
        UsersTestPage.TriggerPageBackgroundTask.Invoke();

        // [THEN] The actual security group factboxes are shown for User1
        AssertSecurityGroupFactboxesAreVisible(UsersTestPage, true);

        // [WHEN] The current user is switched to User2
        UsersTestPage.GoToKey(User2SecId);

        // [THEN] The "loading" factboxes are shown for User2
        AssertSecurityGroupFactboxesAreVisible(UsersTestPage, false);

        // [WHEN] The current user is switched back to User1
        UsersTestPage.GoToKey(User1SecId);

        // [THEN] The actual security group factboxes are shown for User1 again
        // (as there is no need to schedule a background task again, and the results are cached).
        AssertSecurityGroupFactboxesAreVisible(UsersTestPage, true);

        // [THEN] The group membership is reflected in the User Security Groups factbox
        UsersTestPage."User Security Groups".First();
        Assert.AreEqual(TestSecurityGroupNameTxt, UsersTestPage."User Security Groups"."Security Group Name".Value, 'Incorrect security group name');

        TearDown();
    end;

    local procedure AssertSecurityGroupFactboxesAreVisible(UsersTestPage: TestPage Users; DataFactboxesVisible: Boolean)
    begin
        // TestPart.IsVisible method is currently missing (bug 495300). The code below is a workaround to achieve the same result.
        Assert.AreEqual(DataFactboxesVisible, UsersTestPage."Inherited Permission Sets".PermissionSet.Visible(), 'Unexpected visibility for the Inherited Permission Sets part');
        Assert.AreEqual(DataFactboxesVisible, UsersTestPage."User Security Groups"."Security Group Name".Visible(), 'Unexpected visibility for the User Security Groups part');

        // The intended code:
        // Assert.AreEqual(DataFactboxesVisible, UsersTestPage."Inherited Permission Sets".Visible(), 'Unexpected visibility for the Inherited Permission Sets part');
        // Assert.AreEqual(DataFactboxesVisible, UsersTestPage."User Security Groups".Visible(), 'Unexpected visibility for the User Security Groups part');
        // Assert.AreEqual(not DataFactboxesVisible, UsersTestPage."Inherited Permission Sets Loading".Visible(), 'Unexpected visibility for the User Security Groups part');
        // Assert.AreEqual(not DataFactboxesVisible, UsersTestPage."User Security Groups Loading".Visible(), 'Unexpected visibility for the User Security Groups part');
    end;

    local procedure CreateUser(var GraphUser: DotNet UserInfo; var UserSecId: Guid)
    var
        User: Record User;
        NavUserAccountHelper: DotNet NavUserAccountHelper;
    begin
        UserSecId := CreateGuid();
        MockGraphQueryTestLibrary.AddAndReturnGraphUser(GraphUser, CreateGuid(), '', '', '');
        User."User Security ID" := UserSecId;
        User."User Name" := Format(UserSecId);
        User.Insert();
        NavUserAccountHelper.SetAuthenticationObjectId(UserSecId, GraphUser.ObjectId);
    end;

    local procedure Initialize()
    var
        User: Record User;
        UserProperty: Record "User Property";
    begin
        UserProperty.DeleteAll();
        User.DeleteAll();

        Clear(AzureADGraphTestLibrary);
        Clear(MockGraphQueryTestLibrary);

        BindSubscription(AzureADGraphTestLibrary);
        BindSubscription(SecurityGroupsTestLibrary);
        BindSubscription(LibraryUserSecurityGroups);
        BindSubscription(UserPermissionsTestLibrary);

        MockGraphQueryTestLibrary.SetupMockGraphQuery();
        AzureADGraphTestLibrary.SetMockGraphQuery(MockGraphQueryTestLibrary);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        UserPermissionsTestLibrary.SetCanManageUser(UserSecurityId());
    end;

    local procedure TearDown()
    begin
        UnbindSubscription(UserPermissionsTestLibrary);
        UnbindSubscription(LibraryUserSecurityGroups);
        UnbindSubscription(SecurityGroupsTestLibrary);
        UnbindSubscription(AzureADGraphTestLibrary);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;
}

