// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 132907 AzureADUserMgtTest
{
    Permissions = TableData "User Property" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SaaS] [Azure AD User Management]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryPermissions: Codeunit "Library - Permissions";
        AzureADUserManagement: Codeunit "Azure AD User Management";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        AzureADGraphTestLibrary: Codeunit "Azure AD Graph Test Library";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        AzureADUserMgtTestLibrary: Codeunit "Azure AD User Mgt Test Library";
        MockGraphQueryTestLibrary: Codeunit "MockGraphQuery Test Library";
        CompanyAdminRoleTemplateIdTok: Label '62e90394-69f5-4237-9190-012177145e10', Locked = true;
        DeviceUserCannotBeFirstUser: Label 'The device user cannot be the first user to log into the system.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestDeviceUsersAsFirstUserThrowsError()
    var
        User: Record User;
        UserAuthenticationId: Guid;
    begin
        // [SCENARIO] When device user signs in and its the first user on the system, an error is thrown
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddSecurity();

        // [GIVEN] A user belonging to a device plan
        CODEUNIT.RUN(CODEUNIT::"Users - Create Super User");
        UserAuthenticationId := LibraryPermissions.CreateAzureActiveDirectoryUser(User, '');
        MockGraphQueryTestLibrary.AddGraphUserWithInDevicesGroup(UserAuthenticationId, User."User Name", '', '');

        // [WHEN] The user logs in (at first userlogin)
        asserterror AzureADUserMgtTestLibrary.Run(User."User Security ID");

        // [THEN] Error suggesting device user cannot be the first user is thrown
        Assert.ExpectedError(DeviceUserCannotBeFirstUser);
        TearDown();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    [Scope('OnPrem')]
    procedure TestDeviceUsersAreAssignedDevicesPlan()
    var
        User: Record User;
        PlanIds: Codeunit "Plan Ids";
        UserAuthenticationId: Guid;
    begin
        // [SCENARIO] When device user signs in, device plan is assigned to the user
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddSecurity();

        // [GIVEN] A user belonging to a device plan
        CODEUNIT.RUN(CODEUNIT::"Users - Create Super User");
        LibraryPermissions.AddUserToPlan(UserSecurityId(), PlanIds.GetEssentialPlanId());
        UserAuthenticationId := LibraryPermissions.CreateAzureActiveDirectoryUser(User, '');
        MockGraphQueryTestLibrary.AddGraphUserWithInDevicesGroup(UserAuthenticationId, User."User Name", '', '');

        // [WHEN] The user logs in (at first userlogin)
        AzureADUserMgtTestLibrary.Run(User."User Security ID");

        // [THEN] User is assigned devices plan
        LibraryLowerPermissions.SetO365BusFull();
        Assert.IsTrue(
        IsUserInPlan(User."User Security ID", PlanIds.GetDevicePlanId()), 'Device plan is not assigned');
        TearDown();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    [Scope('OnPrem')]
    procedure TestDeviceUsersWithEssentialPlanIsAssignedEssentialPlan()
    var
        User: Record User;
        PlanIds: Codeunit "Plan Ids";
        UserAuthenticationId: Guid;
    begin
        // [SCENARIO] When device user who also happens to have a plan assigned signs in, device plan is not assigned to the user
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddSecurity();

        // [GIVEN] A user belonging to a device plan
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");
        LibraryPermissions.AddUserToPlan(UserSecurityId(), PlanIds.GetEssentialPlanId());
        UserAuthenticationId := LibraryPermissions.CreateAzureActiveDirectoryUser(User, '');
        MockGraphQueryTestLibrary.AddGraphUserWithoutPlan(UserAuthenticationId, User."Full Name", '', User."Authentication Email");
        MockGraphQueryTestLibrary.AddUserPlan(UserAuthenticationId, PlanIds.GetEssentialPlanId(), '', 'Enabled');
        MockGraphQueryTestLibrary.AddGraphUserWithInDevicesGroup(UserAuthenticationId, User."User Name", '', '');

        // [WHEN] The user logs in (at first userlogin)
        AzureADUserMgtTestLibrary.Run(User."User Security ID");

        // [THEN] User is assigned essential plan
        LibraryLowerPermissions.SetO365BusFull();
        Assert.IsFalse(IsUserInPlan(User."User Security ID", PlanIds.GetDevicePlanId()), 'Device plan is assigned');
        Assert.IsTrue(IsUserInPlan(User."User Security ID", PlanIds.GetEssentialPlanId()), 'Essential plan is not assigned');
        TearDown();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    [Scope('OnPrem')]
    procedure TestDeviceUsersWhoHadAdminRoleIsAssignedAdminPlan()
    var
        User: Record User;
        PlanIds: Codeunit "Plan Ids";
        UserAuthenticationId: Guid;
    begin
        // [SCENARIO] When device user who also happens to have a plan assigned signs in, device plan is not assigned to the user
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddSecurity();

        // [GIVEN] A user belonging to a device plan
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");
        LibraryPermissions.AddUserToPlan(UserSecurityId(), PlanIds.GetEssentialPlanId());
        UserAuthenticationId := LibraryPermissions.CreateAzureActiveDirectoryUser(User, '');
        MockGraphQueryTestLibrary.AddGraphUserWithoutPlan(UserAuthenticationId, User."Full Name", '', User."Authentication Email");
        MockGraphQueryTestLibrary.AddUserRole(UserAuthenticationId, PlanIds.GetGlobalAdminPlanId(), 'Global administrator', 'Global administrator', true);
        MockGraphQueryTestLibrary.AddGraphUserWithInDevicesGroup(UserAuthenticationId, User."User Name", '', '');

        // [WHEN] The user logs in (at first userlogin)
        AzureADUserMgtTestLibrary.Run(User."User Security ID");

        // [THEN] User is assigned admin plan
        LibraryLowerPermissions.SetO365BusFull();
        Assert.IsFalse(IsUserInPlan(User."User Security ID", PlanIds.GetDevicePlanId()), 'Device plan is assigned');
        Assert.IsTrue(IsUserInPlan(User."User Security ID", PlanIds.GetGlobalAdminPlanId()), 'Internal Admin plan is not assigned');
        TearDown();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    [Scope('OnPrem')]
    procedure TestDeviceUsersWhoHadD365AdminRoleIsAssignedAdminPlan()
    var
        User: Record User;
        PlanIds: Codeunit "Plan Ids";
        UserAuthenticationId: Guid;
    begin
        // [SCENARIO] When device user who also happens to have a plan assigned signs in, device plan is not assigned to the user
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddSecurity();

        // [GIVEN] A user belonging to a device plan
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");
        LibraryPermissions.AddUserToPlan(UserSecurityId(), PlanIds.GetEssentialPlanId());
        UserAuthenticationId := LibraryPermissions.CreateAzureActiveDirectoryUser(User, '');
        MockGraphQueryTestLibrary.AddGraphUserWithoutPlan(UserAuthenticationId, User."Full Name", '', User."Authentication Email");
        MockGraphQueryTestLibrary.AddUserRole(UserAuthenticationId, PlanIds.GetD365AdminPlanId(), 'Dynamics 365 administrator', 'Dynamics 365 administrator', true);
        MockGraphQueryTestLibrary.AddGraphUserWithInDevicesGroup(UserAuthenticationId, User."User Name", '', '');

        // [WHEN] The user logs in (at first userlogin)
        AzureADUserMgtTestLibrary.Run(User."User Security ID");

        // [THEN] User is assigned admin plan
        LibraryLowerPermissions.SetO365BusFull();
        Assert.IsFalse(IsUserInPlan(User."User Security ID", PlanIds.GetDevicePlanId()), 'Device plan is assigned');
        Assert.IsTrue(IsUserInPlan(User."User Security ID", PlanIds.GetD365AdminPlanId()), 'Dynamics 365 admin plan is not assigned');
        TearDown();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure TestPermissionsAppendedOnUserSyncNoCustomPermissions()
    var
        User: Record User;
        TestUserPermissionsSubs: Codeunit "Test User Permissions Subs.";
        FirstAzureADUserUpdateWizard: TestPage "Azure AD User Update Wizard";
        SecondAzureADUserUpdateWizard: TestPage "Azure AD User Update Wizard";
        GraphUser: DotNet UserInfo;
        DummyGraphUser: DotNet UserInfo;
        RainyCloudPlanId, ShinySunlightPlanId : Guid;
        RainyCloudRoleId: Label 'Rainy Cloud';
        ShinySunlightRoleId: Label 'Shiny Sunlight';
    begin
        Initialize();
        BindSubscription(AzureADUserMgtTestLibrary);
        BindSubscription(TestUserPermissionsSubs);
        TestUserPermissionsSubs.SetCanManageUser(UserSecurityId());
        AssignSuperToCurrentUser();

        // [GIVEN] A permission set in a plan exists
        RainyCloudPlanId := AzureADPlanTestLibrary.CreatePlan('Rainy Cloud');
        LibraryPermissions.CreatePermissionSetInPlan(RainyCloudRoleId, RainyCloudPlanId);

        // [GIVEN] A user in Azure AD with the test plan exists
        MockGraphQueryTestLibrary.AddAndReturnGraphUser(GraphUser, CreateGuid(), 'John', 'Doe', 'john.doe@microsoft.com');
        MockGraphQueryTestLibrary.AddUserPlan(GraphUser.ObjectId, RainyCloudPlanId, '', 'Enabled');

        // [GIVEN] The user has been synced
        FirstAzureADUserUpdateWizard.Trap();
        Page.Run(Page::"Azure AD User Update Wizard");
        FirstAzureADUserUpdateWizard.Next.Invoke();
        FirstAzureADUserUpdateWizard.ApplyUpdates.Invoke();
        FirstAzureADUserUpdateWizard.Close.Invoke();

        // Verify that the user has the permission set assigned
        User.SetRange("Authentication Email", 'john.doe@microsoft.com');
        Assert.IsTrue(User.FindFirst(), 'Expected to find the user.');
        AssertPermissionSetAssignedToUser(RainyCloudRoleId, User."User Security ID");

        // [GIVEN] The user does not have custom permission sets assigned
        // [WHEN] The user has a change in assigned plans
        GraphUser.AssignedPlans := DummyGraphUser.UserInfo().AssignedPlans; // clear Azure AD plans
        ShinySunlightPlanId := AzureADPlanTestLibrary.CreatePlan('Shiny Sunlight');
        LibraryPermissions.CreatePermissionSetInPlan(ShinySunlightRoleId, ShinySunlightPlanId);
        MockGraphQueryTestLibrary.AddUserPlan(GraphUser.ObjectId, ShinySunlightPlanId, '', 'Enabled');

        // [WHEN] The sync wizard is run
        SecondAzureADUserUpdateWizard.Trap();
        Page.Run(Page::"Azure AD User Update Wizard");

        // [THEN] The wizard can be completed normally
        SecondAzureADUserUpdateWizard.Next.Invoke();
        SecondAzureADUserUpdateWizard.ApplyUpdates.Invoke();
        SecondAzureADUserUpdateWizard.Close.Invoke();

        // [THEN] The users has permission sets from both plans assigned
        AssertPermissionSetAssignedToUser(RainyCloudRoleId, User."User Security ID");
        AssertPermissionSetAssignedToUser(ShinySunlightRoleId, User."User Security ID");

        UnbindSubscription(TestUserPermissionsSubs);
        UnbindSubscription(AzureADUserMgtTestLibrary);
        TearDown();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure TestPermissionsAppendedOnUserSyncWithCustomPermissions()
    var
        User: Record User;
        AccessControl: Record "Access Control";
        TestUserPermissionsSubs: Codeunit "Test User Permissions Subs.";
        FirstAzureADUserUpdateWizard: TestPage "Azure AD User Update Wizard";
        SecondAzureADUserUpdateWizard: TestPage "Azure AD User Update Wizard";
        GraphUser: DotNet UserInfo;
        DummyGraphUser: DotNet UserInfo;
        RainyCloudPlanId, ShinySunlightPlanId : Guid;
        RainyCloudRoleId: Label 'Rainy Cloud';
        ShinySunlightRoleId: Label 'Shiny Sunlight';
    begin
        // Same scenario as in TestPermissionsAppendedOnUserSyncNoCustomPermissions, but before
        // the second round of syncing the user has been assigned a custom permission set.
        Initialize();
        BindSubscription(AzureADUserMgtTestLibrary);
        BindSubscription(TestUserPermissionsSubs);
        TestUserPermissionsSubs.SetCanManageUser(UserSecurityId());
        AssignSuperToCurrentUser();

        // [GIVEN] A permission set in a plan exists
        RainyCloudPlanId := AzureADPlanTestLibrary.CreatePlan('Rainy Cloud');
        LibraryPermissions.CreatePermissionSetInPlan(RainyCloudRoleId, RainyCloudPlanId);

        // [GIVEN] A user in Azure AD with the test plan exists
        MockGraphQueryTestLibrary.AddAndReturnGraphUser(GraphUser, CreateGuid(), 'John', 'Doe', 'john.doe@microsoft.com');
        MockGraphQueryTestLibrary.AddUserPlan(GraphUser.ObjectId, RainyCloudPlanId, '', 'Enabled');

        // [GIVEN] The user has been synced
        FirstAzureADUserUpdateWizard.Trap();
        Page.Run(Page::"Azure AD User Update Wizard");
        FirstAzureADUserUpdateWizard.Next.Invoke();
        FirstAzureADUserUpdateWizard.ApplyUpdates.Invoke();
        FirstAzureADUserUpdateWizard.Close.Invoke();

        // Verify that the user has the permission set assigned
        User.SetRange("Authentication Email", 'john.doe@microsoft.com');
        Assert.IsTrue(User.FindFirst(), 'Expected to find the user.');
        AssertPermissionSetAssignedToUser(RainyCloudRoleId, User."User Security ID");

        // [GIVEN] The user has a custom permission set assigned
        AccessControl."User Security ID" := User."User Security ID";
        AccessControl."Role ID" := 'CUSTOM';
        AccessControl.Scope := AccessControl.Scope::Tenant;
        AccessControl.Insert();

        // [WHEN] The user has a change in assigned plans
        GraphUser.AssignedPlans := DummyGraphUser.UserInfo().AssignedPlans; // clear Azure AD plans
        ShinySunlightPlanId := AzureADPlanTestLibrary.CreatePlan('Shiny Sunlight');
        LibraryPermissions.CreatePermissionSetInPlan(ShinySunlightRoleId, ShinySunlightPlanId);
        MockGraphQueryTestLibrary.AddUserPlan(GraphUser.ObjectId, ShinySunlightPlanId, '', 'Enabled');

        // [WHEN] The sync wizard is run
        SecondAzureADUserUpdateWizard.Trap();
        Page.Run(Page::"Azure AD User Update Wizard");

        // [THEN] The wizard will prompt the user to select what should be done with the custom permissions
        SecondAzureADUserUpdateWizard.Next.Invoke(); // Welcome banner
        Assert.IsTrue(SecondAzureADUserUpdateWizard.ManagePermissionUpdates.Visible(), 'Expected the manage permissions button to be visible.'); // Note: for the user the button is called "Next"
        SecondAzureADUserUpdateWizard.ManagePermissionUpdates.Invoke();

        // [THEN] The list is shown with the records that need some decision to be taken (in this case, only one row)
        // Verify the row:
        SecondAzureADUserUpdateWizard.First();
        Assert.AreEqual('JOHN DOE', SecondAzureADUserUpdateWizard.DisplayName.Value, 'Unexpected user display name.');
        Assert.AreEqual('Rainy Cloud', SecondAzureADUserUpdateWizard.CurrentLicense.Value, 'Unexpected current value.');
        Assert.AreEqual('Shiny Sunlight', SecondAzureADUserUpdateWizard.NewLicense.Value, 'Unexpected new value.');
        Assert.AreEqual(Format(Enum::"Azure AD Permission Change Action"::Select), SecondAzureADUserUpdateWizard.PermissionAction.Value, 'Unexpected default permission change action.');

        // [THEN] The 'Next' button is not enabled until all the rows with permission change action "Select" have been changed to either "Append" or "Keep current"
        Assert.IsFalse(SecondAzureADUserUpdateWizard.DoneSelectingPermissions.Enabled(), 'Expected the Finish action to be invisible.');

        // [WHEN] The permission change action is selected to be "Append"
        SecondAzureADUserUpdateWizard.PermissionAction.SetValue(Enum::"Azure AD Permission Change Action"::Append);

        // [THEN] The 'Next' button becomes visible
        Assert.IsTrue(SecondAzureADUserUpdateWizard.DoneSelectingPermissions.Enabled(), 'Expected the Finish action to be visible.');

        // [THEN] The user is able to successfully finish the wizard
        SecondAzureADUserUpdateWizard.DoneSelectingPermissions.Invoke();
        SecondAzureADUserUpdateWizard.ApplyUpdates.Invoke();
        SecondAzureADUserUpdateWizard.Close.Invoke();

        // [THEN] The user has permission sets from both plans assigned
        AssertPermissionSetAssignedToUser(RainyCloudRoleId, User."User Security ID");
        AssertPermissionSetAssignedToUser(ShinySunlightRoleId, User."User Security ID");

        UnbindSubscription(TestUserPermissionsSubs);
        UnbindSubscription(AzureADUserMgtTestLibrary);
        TearDown();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCreateNewUsersFromAzureNoPermissions()
    var
        User: Record User;
        Plan: Query Plan;
        UserAuthenticationID: Text;
    begin
        // [SCENARIO] "Download" new users from the Graph, but have no permissions to create them locally
        Initialize();

        // [GIVEN] 1 existing user in the system
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddSecurity();
        LibraryPermissions.CreateUser(User, 'NAV Test User', false);

        // [GIVEN] A user created only in the cloud
        Plan.Open();
        Plan.Read();

        UserAuthenticationID := CreateGuid();
        MockGraphQueryTestLibrary.AddGraphUser(
          UserAuthenticationID, 'Cloud-Only', 'Cloud-Only Test User',
          'bla@nothing.dk', Plan.Plan_ID, Plan.Plan_Name, 'Enabled');

        // [WHEN] Not being neither SUPER nor SECURITY
        LibraryLowerPermissions.SetBanking();

        // [WHEN] CreateNewUsersFromAzureAD is invoked with no SUPER nor SECURITY permissions
        // [THEN] The user is not created - an error stating that there are not enough permissions is thrown
        asserterror AzureADUserManagement.CreateNewUsersFromAzureAD();

        TearDown();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    [Scope('OnPrem')]
    procedure TestCreateNewUsersFromAzureADNoGraph()
    var
        User: Record User;
        InitialUserCount: Integer;
        UserName: Code[50];
    begin
        // [SCENARIO] Attempting to create new users from the Graph when the graph is not initialized
        // It should result in an error, as the DotNet GraphQuery object cannot be initialized
        // in a non-SaaS environment
        ClearGlobals();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddSecurity();

        // [GIVEN] 1 existing user in the system
        UserName := 'Cloud Test User';
        LibraryPermissions.CreateUser(User, UserName, false);
        InitialUserCount := User.Count();

        // [GIVEN] A user created only in the cloud
        // TODO - this is broken, creates the previous user in the cloud. We need to create the user ONLY in the cloud
        LibraryPermissions.CreateAzureActiveDirectoryUserCloudOnly(User);

        // [GIVEN] Not running in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryLowerPermissions.SetO365BusFull();

        // [WHEN] CreateNewUsersFromAzureAD is invoked
        AzureADUserManagement.CreateNewUsersFromAzureAD();

        // [THEN] The user count remains the same
        Assert.AreEqual(InitialUserCount, User.Count, 'The user count should have remained the same');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestOnDefaultRoleCenterIDReturnsDefaultIfNoAzureUserPresent()
    var
        User: Record User;
        Plan: Query Plan;
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        // [SCENARIO] When singning in, if the plan is disabled, default rolecenter id returned
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        Plan.Open();
        Plan.Read();

        // [GIVEN] A user with a plan exists, plan status = disabled
        CreateUserWithSubscriptionPlan(User, Plan.Plan_ID, Plan.Plan_Name, 'Disabled');
        // [WHEN] GetAzureUserPlanRoleCenterId invoked (at first userlogin)
        // [THEN] Rolecenter ID 0 is returned
        LibraryLowerPermissions.SetO365Basic();
        Assert.AreEqual(9022, ConfPersonalizationMgt.DefaultRoleCenterID(), 'Invalid Role Center Id');

        LibraryLowerPermissions.SetOutsideO365Scope();
        TearDown();
    end;

    local procedure Initialize()
    begin
        ClearGlobals();
        BindSubscription(AzureADGraphTestLibrary);
        BindSubscription(AzureADPlanTestLibrary);

        MockGraphQueryTestLibrary.SetupMockGraphQuery();
        SetupAzureADMockPlans();
        AzureADGraphTestLibrary.SetMockGraphQuery(MockGraphQueryTestLibrary);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
    end;

    local procedure TearDown()
    begin
        UnbindSubscription(AzureADGraphTestLibrary);
        UnbindSubscription(AzureADPlanTestLibrary);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure ClearGlobals()
    begin
        Clear(AzureADGraphTestLibrary);
        Clear(AzureADPlanTestLibrary);
        Clear(AzureADUserMgtTestLibrary);
        Clear(MockGraphQueryTestLibrary);
        Clear(AzureADUserManagement);
    end;

    local procedure IsUserInPlan(UserAuthenticationId: Guid; PlanId: Guid): Boolean
    var
        UsersInPlan: Query "Users in Plans";
    begin
        UsersInPlan.SetRange(User_Security_ID, UserAuthenticationId);

        if UsersInPlan.Open() then
            while UsersInPlan.Read() do
                if UsersInPlan.Plan_ID = PlanId then
                    exit(true);
    end;

    local procedure CreateUserWithSubscriptionPlan(var User: Record User; PlanID: Guid; PlanName: Text; PlanStatus: Text)
    begin
        LibraryPermissions.CreateAzureActiveDirectoryUser(User, '');
        MockGraphQueryTestLibrary.AddGraphUser(GetUserAuthenticationId(User), User."User Name", '', '', PlanID, PlanName, PlanStatus);
    end;

    local procedure GetUserAuthenticationId(User: Record User): Guid
    var
        UserProperty: Record "User Property";
    begin
        UserProperty.Get(User."User Security ID");
        exit(UserProperty."Authentication Object ID");
    end;

    local procedure SetupAzureADMockPlans()
    var
        Plan: Query Plan;
    begin
        Plan.Open();
        while Plan.Read() do
            MockGraphQueryTestLibrary.AddSubscribedSkuWithServicePlan(CreateGuid(), Plan.Plan_ID, Plan.Plan_Name);
    end;

    local procedure InsertUserProperty(UserSecurityId: Guid)
    var
        UserProperty: Record "User Property";
    begin
        UserProperty.Init();
        UserProperty."User Security ID" := UserSecurityId;
        UserProperty."Authentication Object ID" := UserSecurityId;
        UserProperty.Insert();
    end;

    local procedure AssertPermissionSetAssignedToUser(RoleId: Text; UserSecId: Guid)
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecId);
        AccessControl.SetRange("Role ID", CopyStr(RoleId, 1, MaxStrLen(AccessControl."Role ID")));
        Assert.RecordIsNotEmpty(AccessControl);
    end;

    local procedure AssignSuperToCurrentUser()
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.SetRange("Role ID", 'SUPER');
        if not AccessControl.IsEmpty() then
            exit;
        AccessControl."User Security ID" := UserSecurityId();
        AccessControl."Role ID" := 'SUPER';
        AccessControl.Insert(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestIsUserTenantAdminWhenItDoesNotExistInTheAzureADGraph()
    var
        User: Record User;
        IsUserTenantAdmin: Boolean;
    begin
        // [GIVEN] A user is created, but not added to the Azure AD Graph
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddSecurity();
        LibraryPermissions.CreateUser(User, 'username_username', true);

        // [WHEN] Checking whether the user is a tenant admin
        IsUserTenantAdmin := AzureADUserManagement.IsUserTenantAdmin();

        // [THEN] The result should be false
        Assert.IsFalse(IsUserTenantAdmin, 'The user should not be a tenant admin');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestIsUserTenantAdminWhenItDoesNotHaveAnyRoles()
    var
        IsUserTenantAdmin: Boolean;
    begin
        // [GIVEN] A user corresponding to the current user exists in the Azure AD Graph,
        // but the user does not have any roles
        MockGraphQueryTestLibrary.AddGraphUser(UserSecurityId(), 'username', 'surname', 'email@microsoft.com',
            CreateGuid(), 'Plan Service', 'Status');

        // [WHEN] Checking whether the user is a tenant admin
        IsUserTenantAdmin := AzureADUserManagement.IsUserTenantAdmin();

        // [THEN] The result should be false
        Assert.IsFalse(IsUserTenantAdmin, 'The user should not be a tenant admin');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestIsUserTenantAdminWhenItDoesNotHaveTheTenantAdminRole()
    var
        IsUserTenantAdmin: Boolean;
    begin
        // [GIVEN] A user corresponding to the current user exists in the Azure AD Graph
        MockGraphQueryTestLibrary.AddGraphUser(UserSecurityId(), 'username', 'surname', 'email@microsoft.com',
            CreateGuid(), 'Plan Service', 'Status');

        // [GIVEN] The user has two roles, but none of them is the role corresponding to the tenant admin
        MockGraphQueryTestLibrary.AddUserRole(UserSecurityId(), 'template 1', 'description', 'display name 1', true);
        MockGraphQueryTestLibrary.AddUserRole(UserSecurityId(), 'template 2', 'description', 'display name 2', true);

        // [WHEN] Checking whether the user is a tenant admin
        IsUserTenantAdmin := AzureADUserManagement.IsUserTenantAdmin();

        // [THEN] The result should be false
        Assert.IsFalse(IsUserTenantAdmin, 'The user should not be a tenant admin');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestIsUserTenantAdminWhenItHasOnlyTheTenantAdminRole()
    var
        IsUserTenantAdmin: Boolean;
    begin
        Initialize();

        // [GIVEN] A user corresponding to the current user exists in the Azure AD Graph
        MockGraphQueryTestLibrary.AddGraphUser(UserSecurityId(), 'username', 'surname', 'email@microsoft.com',
            CreateGuid(), 'Plan Service', 'Status');

        // [GIVEN] The user has a single role, corresponding to the tenant admin
        MockGraphQueryTestLibrary.AddUserRole(UserSecurityId(), CompanyAdminRoleTemplateIdTok,
            'description', 'display name 1', true);

        InsertUserProperty(UserSecurityId());

        // [WHEN] Checking whether the user is a tenant admin
        IsUserTenantAdmin := AzureADUserManagement.IsUserTenantAdmin();

        // [THEN] The result should be true
        Assert.IsTrue(IsUserTenantAdmin, 'The user should be a tenant admin');

        TearDown();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestIsUserTenantAdminWhenItHasTheTenantAdminRoleAndOtherRoles()
    var
        IsUserTenantAdmin: Boolean;
    begin
        Initialize();

        // [GIVEN] A user corresponding to the current user exists in the Azure AD Graph
        MockGraphQueryTestLibrary.AddGraphUser(UserSecurityId(), 'username', 'surname', 'email@microsoft.com',
            CreateGuid(), 'Plan Service', 'Status');

        // [GIVEN] The user has a three roles, one of which is the tenant admin one
        MockGraphQueryTestLibrary.AddUserRole(UserSecurityId(), 'template 1', 'description', 'display name 1', true);
        MockGraphQueryTestLibrary.AddUserRole(UserSecurityId(), CompanyAdminRoleTemplateIdTok,
            'description', 'display name 2', true);
        MockGraphQueryTestLibrary.AddUserRole(UserSecurityId(), 'template 2', 'description', 'display name 3', true);

        InsertUserProperty(UserSecurityId());

        // [WHEN] Checking whether the user is a tenant admin
        IsUserTenantAdmin := AzureADUserManagement.IsUserTenantAdmin();

        // [THEN] The result should be true
        Assert.IsTrue(IsUserTenantAdmin, 'The user should be a tenant admin');

        TearDown();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCreateNewUserFromGraphUserWhenTheUserHasNoAssignedPlans()
    var
        User: Record User;
        GraphUser: DotNet UserInfo;
        UserId: Guid;
    begin
        Initialize();

        // [GIVEN] An Azure AD Graph User without a corresponding User record and that is not
        // entitled from service plan
        UserId := CreateGuid();
        MockGraphQueryTestLibrary.AddGraphUser(GraphUser, UserId, 'username', 'surname', 'email@microsoft.com',
            CreateGuid(), 'Plan Service', 'Status');

        // [WHEN] Trying to create a new user from the graph user
        AzureADUserManagement.CreateNewUserFromGraphUser(GraphUser);

        // [THEN] The database should not contain a User corresponding to the graph user
        Assert.IsFalse(User.Get(UserId), 'The user should not have been created');

        TearDown();
    end;
}
