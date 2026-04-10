codeunit 139460 "User Access in SaaS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Permissions] [SaaS]
    end;

    var
        Assert: Codeunit Assert;
        PermissionManager: Codeunit "Permission Manager";
        UserEuropeDcst1FullTok: Label 'EUROPE\DCST1';
        ErrorKeyNotSetErr: Label 'WebServiceKey has not been set.';
        LibraryPermissions: Codeunit "Library - Permissions";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        WsNeverExpiresToenter: Boolean;
        WsExpirationDateToEnter: DateTime;
        WsInvokeCancelToEnter: Boolean;
        NewUsersCannotLoginQst: Label 'You have not specified a user group that will be assigned automatically to new users. If users are not assigned a user group, they cannot sign in. \\Do you want to continue?';
        CannotEditForOtherUsersErr: Label 'You can only change your own web service access keys.';

    [Test]
    [HandlerFunctions('SetWebServiceAccessConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CannotAccessWebServiceKeyForAnotherUserInSaaS()
    var
        TestUserPermissionsSubs: Codeunit "Test User Permissions Subs.";
    begin
        // [SCENARIO] In SaaS, a user cannot access another user's web service key
        Initialize();
        BindSubscription(TestUserPermissionsSubs);
        // [GIVEN] Running in SaaS
        // [WHEN] The current user opens another user's card
        // [THEN] The user cannnot see the other user's current web service key
        // [THEN] The action to change the web service access key is disabled
        asserterror TestWebServiceKeyAccessibility(UserEuropeDcst1FullTok, true, false);
        Assert.AreEqual(CannotEditForOtherUsersErr, GetLastErrorText(), 'User should not access another user''s web service key.');
    end;

    [Test]
    [HandlerFunctions('SetWebServiceAccessHandler,SetWebServiceAccessConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CanAccessWebServiceKeyForSelfInSaaS()
    begin
        // [SCENARIO] In SaaS, a user can access his/her own web service key (read/edit)
        Initialize();
        // [GIVEN] Running in SaaS
        // [WHEN] The current user opens another user's card
        // [THEN] The current user can see his/her own current web service key
        // [THEN] The action to change the web service access key is enabled
        TestWebServiceKeyAccessibility(UserId(), true, false);
    end;

    [Test]
    [HandlerFunctions('SetWebServiceAccessHandler,SetWebServiceAccessConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AdminCanAlterWebServiceKeyForAnotherUserInSaaS()
    var
        TestUserPermissionsSubs: Codeunit "Test User Permissions Subs.";
    begin
        // [SCENARIO] In SaaS, an admin user can change another user's web service key, but cannot read it
        Initialize();
        TestUserPermissionsSubs.SetCanManageUser(UserSecurityId()); // admin
        BindSubscription(TestUserPermissionsSubs);

        // [GIVEN] Running in SaaS
        // [WHEN] The current user opens another user's card
        // [THEN] The current user cannot see another user's web service key
        // [THEN] The action to change the web service access key is enabled
        TestWebServiceKeyAccessibility(UserEuropeDcst1FullTok, true, true);
    end;

    [Test]
    [HandlerFunctions('SetWebServiceAccessConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CannotAccessWebServiceKeyForAnotherUserOnPrem()
    begin
        // [SCENARIO] On-prem and in PaaS, a user cannot access another user's web service key
        Initialize();
        // [GIVEN] Running on-premise or in PaaS
        // [WHEN] The current user opens another user's card
        // [THEN] The current user cannot see another user's current web service key
        // [THEN] The action to change the web service access key is disabled
        asserterror TestWebServiceKeyAccessibility(UserEuropeDcst1FullTok, true, false);
        Assert.AreEqual(CannotEditForOtherUsersErr, GetLastErrorText(), 'User should not access another user''s web service key.');
    end;

    [Test]
    [HandlerFunctions('SetWebServiceAccessHandler,SetWebServiceAccessConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AdminCanAlterWebServiceKeyForAnotherUserOnPrem()
    var
        TestUserPermissionsSubs: Codeunit "Test User Permissions Subs.";
    begin
        // [SCENARIO] In SaaS, an admin user can change another user's web service key, but cannot read it
        Initialize();
        TestUserPermissionsSubs.SetCanManageUser(UserSecurityId()); // admin
        BindSubscription(TestUserPermissionsSubs);

        // [GIVEN] Running on-premise or in PaaS
        // [WHEN] The current user opens another user's card
        // [THEN] The current user cannot see another user's web service key
        // [THEN] The action to change the web service access key is enabled
        TestWebServiceKeyAccessibility(UserEuropeDcst1FullTok, false, true);
    end;

    [Test]
    [HandlerFunctions('SetWebServiceAccessHandler,SetWebServiceAccessConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CanAccessWebServiceKeyForSelfOnPrem()
    begin
        // [SCENARIO] On-prem and in PaaS, a user can access his/her own web service key (read/edit)
        Initialize();
        // [GIVEN] Running on-premise or in PaaS
        // [WHEN] The current user opens his/her user's card
        // [THEN] The current user can see his/her own current web service key
        // [THEN] The action to change the web service access key is enabled
        TestWebServiceKeyAccessibility(UserId(), false, false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CannotAddNewUserSaaS()
    begin
        // [SCENARIO] in SaaS, users can only be added through the Office 365 portal
        Initialize();
        // [GIVEN] NAV running in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [WHEN] The admin attempts to add a new user through the UI of NAV
        asserterror CreateUserFromUI(UserEuropeDcst1FullTok);
        // [THEN] The user cannot be added
        Assert.ExpectedError('Page New - User Card has to close');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUpdateUserAccessForSaaSWithExistingUserPersonalization()
    var
        User: Record User;
        AccessControl: Record "Access Control";
        UserPersonalization: Record "User Personalization";
        LibraryPermissions: Codeunit "Library - Permissions";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        Plan: Query Plan;
    begin
        // [SCENARIO] Upgraded user from 1.5 without user login entry
        Initialize();
        // [GIVEN] A existing user with no user login entry

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryPermissions.CreateUser(User, UserEuropeDcst1FullTok, true);
        AccessControl.SetRange("User Security ID", User."User Security ID");
        AccessControl.DeleteAll();

        Plan.Open();
        Plan.Read();
        AzureADPlanTestLibrary.AssignUserToPlan(User."User Security ID", Plan.Plan_ID, true);

        UserPersonalization.Validate("User SID", User."User Security ID");
        UserPersonalization.Insert(true);

        // [WHEN] UpdateUserAccessForSaaS
        PermissionManager.UpdateUserAccessForSaaS(User."User Security ID");

        // [THEN] Permission sets are assigned
        Assert.RecordIsNotEmpty(AccessControl);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUpdateUserAccessForSaaSWithInvalidRoleCenter()
    var
        User: Record User;
        AccessControl: Record "Access Control";
        LibraryPermissions: Codeunit "Library - Permissions";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        PlanID: Guid;
    begin
        // [SCENARIO] Upgraded user from 1.5 without 2.0 Plans in the db
        Initialize();
        // [GIVEN] A existing user with a plan that is missing a rolecenter (old plan)
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryPermissions.CreateUser(User, UserEuropeDcst1FullTok, true);

        // Create a Plan and update "User Plan" table
        PlanID := AzureADPlanTestLibrary.CreatePlan('TestPlan');
        AzureADPlanTestLibrary.ChangePlanRoleCenterID(PlanID, 0);
        AzureADPlanTestLibrary.AssignUserToPlan(User."User Security ID", PlanID, true);

        // [WHEN] UpdateUserAccessForSaaS
        PermissionManager.UpdateUserAccessForSaaS(User."User Security ID");

        // [THEN] Permission sets are not assigned
        Assert.RecordIsEmpty(AccessControl);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CannotAddNewUserOfLimitedLicenseTypeInSaaS()
    var
        DummyUser: Record User;
    begin
        // [SCENARIO] in SaaS, users of limited license type cannot be added
        Initialize();
        // [GIVEN] NAV running in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] The an extension attempts to add a new user through the code
        asserterror CreateUserWithLicenseType(CreateGuid(), DummyUser."License Type"::"Limited User");

        // [THEN] The user cannot be created
        Assert.ExpectedError('are supported in the online environment.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CannotModifyUserLicenseTypeToLimitedInSaaS()
    var
        User: Record User;
    begin
        // [SCENARIO] in SaaS, user's license type cannot be set to limited
        Initialize();
        // [GIVEN] NAV running in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] The an extension attempts to modify a user through the code
        LibraryPermissions.CreateUser(User, UserEuropeDcst1FullTok, false);
        User."License Type" := User."License Type"::"Limited User";
        asserterror User.Modify();

        // [THEN] The user cannot be modified
        Assert.ExpectedError('are supported in the online environment.');
    end;

    local procedure CreateUser(UserName: Code[50]): Guid
    var
        User: Record User;
    begin
        exit(CreateUserWithLicenseType(UserName, User."License Type"::"Full User"));
    end;

    local procedure CreateUserWithLicenseType(UserName: Text[250]; LicenseType: Option): Guid
    var
        User: Record User;
        UserPersonalization: Record "User Personalization";
    begin
        User.SetRange("User Name", UserName);
        if User.FindFirst() then begin
            UserPersonalization.SetRange("User SID", User."User Security ID");
            if UserPersonalization.FindFirst() then
                UserPersonalization.Delete(true);
            User.Validate("License Type", LicenseType);
            User.Modify(true);
        end else begin
            User.Init();
            User.Validate("User Name", UserName);
            User.Validate("License Type", LicenseType);
            if UserName = UserId() then
                User.Validate("User Security ID", UserSecurityId())
            else
                User.Validate("User Security ID", CreateGuid());
            User.Insert(true);
        end;
        exit(User."User Security ID");
    end;

    local procedure CreateUserFromUI(UserName: Code[50])
    var
        UserCardPage: TestPage "User Card";
    begin
        UserCardPage.OpenNew();
        UserCardPage."Windows User Name".Value := UserName;
        UserCardPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetWebServiceAccessHandler(var SetWebServiceAccess: TestPage "Set Web Service Access Key")
    begin
        if WsNeverExpiresToenter then
            SetWebServiceAccess.NeverExpires.SetValue(WsNeverExpiresToenter)
        else
            SetWebServiceAccess.ExpirationDate.SetValue(WsExpirationDateToEnter);

        if WsInvokeCancelToEnter then
            SetWebServiceAccess.Cancel().Invoke()
        else
            SetWebServiceAccess.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure SetWebServiceAccessConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure NewUsersCannotLoginConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if Question <> NewUsersCannotLoginQst then
            exit;
        Reply := true;
    end;

    local procedure TestWebServiceKeyAccessibility(UserName: Code[50]; SoftwareAsAService: Boolean; IsCurrentUserAdmin: Boolean)
    var
        WsCompareKey: Text;
        ChangeWebServiceAccessKeyEnabled: Boolean;
    begin
        CreateUser(UserName);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(SoftwareAsAService);
        WebServiceAccessHelper(CreateDateTime(Today, 0T), true, false, UserName);
        GetUserWebServiceParametersFromUserCard(UserName, WsCompareKey, ChangeWebServiceAccessKeyEnabled);
        if UserName <> UserId then begin
            Assert.AreEqual(
              '*************************************', WsCompareKey, 'The Webservice Key should not be visible to another user in SaaS');
            if IsCurrentUserAdmin then
                Assert.AreEqual(true, ChangeWebServiceAccessKeyEnabled, 'Change Webservice Key should be enabled for admin users')
            else
                Assert.AreEqual(false, ChangeWebServiceAccessKeyEnabled, 'Change Webservice Key should not be enabled for non-admin users');
        end else begin
            Assert.AreNotEqual('*************************************', WsCompareKey, ErrorKeyNotSetErr);
            Assert.AreEqual(true, ChangeWebServiceAccessKeyEnabled, 'Change Webservice Key should be enabled');
        end;
    end;

    local procedure WebServiceAccessHelper(KeyExpirationDate: DateTime; KeyNeverExpires: Boolean; InvokeCancel: Boolean; UserName: Text)
    var
        UserCardPage: TestPage "User Card";
    begin
        WsNeverExpiresToenter := KeyNeverExpires;
        WsExpirationDateToEnter := KeyExpirationDate;
        WsInvokeCancelToEnter := InvokeCancel;
        UserCardPage.OpenEdit();
        UserCardPage.FindFirstField("User Name", UserName);
        UserCardPage."User Name".AssertEquals(UserName);
        UserCardPage.WebServiceID.AssistEdit();
        UserCardPage.Close();
    end;

    local procedure GetUserWebServiceParametersFromUserCard(UserName: Code[50]; var WsCompareKey: Text; var ChangeWebServiceAccessKeyEnabled: Boolean)
    var
        UserCardPage: TestPage "User Card";
    begin
        UserCardPage.OpenEdit();
        UserCardPage.FindFirstField("User Name", UserName);
        UserCardPage."User Name".AssertEquals(UserName);
        UserCardPage.WebServiceExpiryDate.AssertEquals('');
        WsCompareKey := UserCardPage.WebServiceID.Value();
        ChangeWebServiceAccessKeyEnabled := UserCardPage.ChangeWebServiceAccessKey.Enabled();
        UserCardPage.Close();
    end;

    local procedure Initialize()
    var
        UserPersonalization: Record "User Personalization";
        User: Record User;
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        UserPersonalization.DeleteAll(true);
        User.DeleteAll(true);
    end;
}
