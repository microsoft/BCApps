// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 132929 "Microsoft 365 License Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        M365ConfigurationNotificationTxt: Label 'Just trying this out? Start by adding ''D365 READ'' permissions to all objects to experience how employees across the organization can read Business Central data in Microsoft Teams using only their Microsoft 365 license.';
        SuperTok: Label 'SUPER', Locked = true;
        D365ReadTok: Label 'D365 READ', Locked = true;

    [Test]
    [HandlerFunctions('NotificationHandler')]
    [Scope('OnPrem')]
    procedure ShowGuidanceNotificationInsertM365Read()
    var
        PlanIds: Codeunit "Plan Ids";
        PlanConfigurationLibrary: Codeunit "Plan Configuration Library";
        UserPermissionsLibrary: Codeunit "User Permissions Library";
        PlanConfigurationList: TestPage "Plan Configuration List";
        PlanConfigurationCard: TestPage "Plan Configuration Card";
    begin
        // [SCENARIO] Open unconfigured Microsoft 365 license as evaluation company, see guidance notification, add 'M365 Read' Permission Set as Default Permission Set 
        LibraryVariableStorage.Clear();

        // [GIVEN] Company is an evaluation company
        SetCompanyTypeToEvaluation(true);

        // [GIVEN] User has a Microsoft 365 license available for configuration
        PlanConfigurationLibrary.ClearPlanConfigurations();
        PlanConfigurationLibrary.AddConfiguration(PlanIds.GetMicrosoft365PlanId(), false);

        // [GIVEN] User is a superuser
        UserPermissionsLibrary.CreateSuperUser('USER');
        UserPermissionsLibrary.AssignPermissionSetToUser(UserSecurityId(), SuperTok);

        // [WHEN] Plan Configuration List is opened and user drills down on Microsoft 365 license
        PlanConfigurationList.OpenView();
        Assert.IsTrue(PlanConfigurationList.First(), 'There should be a configuration on the page');
        Assert.AreEqual('Microsoft 365', PlanConfigurationList."Plan Name".Value, 'Plan name on list page is wrong');
        PlanConfigurationCard.Trap();
        PlanConfigurationList."Plan Name".DrillDown();

        // [THEN] Guidance notification shows
        Assert.IsTrue(NotificationHasBeenSent(M365ConfigurationNotificationTxt), 'Guidance notification was not sent');

        // [WHEN] User presses "Add 'D365 READ' permission" Notification-action (mocked in NotificationHandler)
        // [THEN] 'D365 READ' Permission Set is added to Custom Permission Sets

        // [THEN] A 'D365 READ' Permission Set exists in Custom Permission Sets
        Assert.IsTrue(PermissionSetExistsAsCustomPermissionSet(PlanConfigurationCard, D365ReadTok), 'Permission set does not exist as a custom permission set');

        Assert.AreEqual(D365ReadTok, PlanConfigurationCard.CustomPermissionSets.PermissionSetId.Value, 'Wrong permission set');
        Assert.AreEqual(CompanyName(), PlanConfigurationCard.CustomPermissionSets.Company.Value, 'Wrong company');
        Assert.AreEqual('Base Application', PlanConfigurationCard.CustomPermissionSets.ExtensionName.Value, 'Wrong extension name');
        Assert.AreEqual('System', PlanConfigurationCard.CustomPermissionSets.PermissionScope.Value, 'Wrong permission set scope');
        Assert.IsFalse(PlanConfigurationCard.CustomPermissionSets.Next(), 'There should not be more custom permission sets');
        PlanConfigurationCard.Close();
    end;

    [Test]
    [HandlerFunctions('NotificationHandler')]
    [Scope('OnPrem')]
    procedure NoGuidanceNotificationNonEvaluationCompany()
    var
        PlanIds: Codeunit "Plan Ids";
        PlanConfigurationLibrary: Codeunit "Plan Configuration Library";
        UserPermissionsLibrary: Codeunit "User Permissions Library";
        PlanConfigurationList: TestPage "Plan Configuration List";
        PlanConfigurationCard: TestPage "Plan Configuration Card";
    begin
        // [SCENARIO] Open unconfigured Microsoft 365 license as non-evaluation company will not show Microsoft 365 license guidance notification
        LibraryVariableStorage.Clear();

        // [GIVEN] User is a superuser
        UserPermissionsLibrary.CreateSuperUser('USER');
        UserPermissionsLibrary.AssignPermissionSetToUser(UserSecurityId(), SuperTok);

        // [GIVEN] Company is a non-evaluation company
        SetCompanyTypeToEvaluation(false);

        // [GIVEN] User has a Microsoft 365 license available for configuration
        PlanConfigurationLibrary.ClearPlanConfigurations();
        PlanConfigurationLibrary.AddConfiguration(PlanIds.GetMicrosoft365PlanId(), false);

        // [WHEN] Plan Configuration List is opened and user drills down on Microsoft 365 license
        PlanConfigurationList.OpenView();
        Assert.IsTrue(PlanConfigurationList.First(), 'There should be a configuration on the page');
        Assert.AreEqual('Microsoft 365', PlanConfigurationList."Plan Name".Value, 'Plan name on list page is wrong');
        PlanConfigurationCard.Trap();
        PlanConfigurationList."Plan Name".DrillDown();

        // [THEN] No guidance notification shows
        Assert.IsFalse(NotificationHasBeenSent(M365ConfigurationNotificationTxt), 'Guidance notification was sent');
    end;

    [Test]
    [HandlerFunctions('NotificationHandler')]
    [Scope('OnPrem')]
    procedure NoGuidanceNotificationOtherLicense()
    var
        PlanIds: Codeunit "Plan Ids";
        PlanConfigurationLibrary: Codeunit "Plan Configuration Library";
        UserPermissionsLibrary: Codeunit "User Permissions Library";
        PlanConfigurationList: TestPage "Plan Configuration List";
        PlanConfigurationCard: TestPage "Plan Configuration Card";
    begin
        // [SCENARIO] Open license other than M365 License will not show Microsoft 365 license guidance notification
        LibraryVariableStorage.Clear();

        // [GIVEN] User is a superuser
        UserPermissionsLibrary.CreateSuperUser('USER');
        UserPermissionsLibrary.AssignPermissionSetToUser(UserSecurityId(), SuperTok);

        // [GIVEN] Company is an evaluation company
        SetCompanyTypeToEvaluation(true);

        // [GIVEN] User has a Delegated Admin license available for configuration
        PlanConfigurationLibrary.ClearPlanConfigurations();
        PlanConfigurationLibrary.AddConfiguration(PlanIds.GetDelegatedAdminPlanId(), false);

        // [WHEN] Plan Configuration List is opened and user drills down on Delegated Admin license
        PlanConfigurationList.OpenView();
        Assert.IsTrue(PlanConfigurationList.First(), 'There should be a configuration on the page');
        Assert.AreEqual('Delegated Admin agent - Partner', PlanConfigurationList."Plan Name".Value, 'Plan name on list page is wrong');
        PlanConfigurationCard.Trap();
        PlanConfigurationList."Plan Name".DrillDown();

        // [THEN] No guidance notification shows
        Assert.IsFalse(NotificationHasBeenSent(M365ConfigurationNotificationTxt), 'Guidance notification was sent');

        PlanConfigurationCard.Close();
    end;

    local procedure SetCompanyTypeToEvaluation(Evaluation: Boolean)
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName());
        Company."Evaluation Company" := Evaluation;
        Company.Modify();
    end;

    local procedure NotificationHasBeenSent(NotificationTxt: Text): Boolean
    begin
        if LibraryVariableStorage.Length() = 0 then
            exit(false);

        repeat
            if LibraryVariableStorage.DequeueText() = NotificationTxt then
                exit(true);
        until LibraryVariableStorage.Length() = 0;
        exit(false);
    end;

    local procedure PermissionSetExistsAsCustomPermissionSet(var PlanConfigurationCard: TestPage "Plan Configuration Card"; PermissionTxt: Text): Boolean
    begin
        repeat
            if PlanConfigurationCard.CustomPermissionSets.PermissionSetId.Value = PermissionTxt then
                exit(true);
        until PlanConfigurationCard.CustomPermissionSets.Next();
        exit(false);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure NotificationHandler(var Notification: Notification): Boolean
    var
        PlanConfigurationLibrary: Codeunit "Plan Configuration Library";
    begin
        if Notification.Message = M365ConfigurationNotificationTxt then begin
            LibraryVariableStorage.Enqueue(Notification.Message);
            PlanConfigurationLibrary.AssignD365ReadPermission(Notification);
        end
    end;
}