codeunit 134614 "Test App Permissions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        User: Record User;
        TenantPermission: Record "Tenant Permission";
        TenantPermissionSet: Record "Tenant Permission Set";
        AppPermissionSet: Record "Tenant Permission Set";
        Assert: Codeunit Assert;
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryUtility: Codeunit "Library - Utility";
        NullGuid: Guid;
        PermissionRoles: array[2] of Code[20];
        PermissionAppIds: array[2] of Guid;
        TenantPermissionRoles: array[2] of Code[20];
        AppPermissionRoles: array[2] of Code[20];
        AppGUIDs: array[2] of Guid;
        LibrarySingleServer: Codeunit "Library - Single Server";
        MockGraphQueryTestLibrary: Codeunit "MockGraphQuery Test Library";
        AzureADGraphTestLibrary: Codeunit "Azure AD Graph Test Library";
        SecurityGroupsTestLibrary: Codeunit "Security Groups Test Library";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";

    local procedure InitializeData()
    var
        SecurityGroup: Codeunit "Security Group";
        i: Integer;
        Sg1CodeTxt: Label 'SG1';
        Sg2CodeTxt: Label 'SG2';
        Sg3CodeTxt: Label 'SG3';
        Sg1IdTxt: Label 'AAD SG1 ID';
        Sg2IdTxt: Label 'AAD SG2 ID';
        Sg3IdTxt: Label 'AAD SG3 ID';
        Sg1NameTxt: Label 'AAD SG1 Name';
        Sg2NameTxt: Label 'AAD SG2 Name';
        Sg3NameTxt: Label 'AAD SG3 Name';
    begin
        Clear(NullGuid); // Ensure the null GUID is cleared
        Clear(AzureADGraphTestLibrary);
        Clear(MockGraphQueryTestLibrary);
        User.DeleteAll();

        BindSubscription(AzureADGraphTestLibrary);
        BindSubscription(SecurityGroupsTestLibrary);

        MockGraphQueryTestLibrary.SetupMockGraphQuery();
        AzureADGraphTestLibrary.SetMockGraphQuery(MockGraphQueryTestLibrary);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // Need to add at least one super user.
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");

        // Set up 3 users
        for i := 1 to 3 do
            LibraryPermissions.CreateUser(User, LibraryUtility.GenerateRandomAlphabeticText(10, 0), false);

        // 3 AAD security group exist
        MockGraphQueryTestLibrary.AddGroup(Sg1NameTxt, Sg1IdTxt);
        MockGraphQueryTestLibrary.AddGroup(Sg2NameTxt, Sg2IdTxt);
        MockGraphQueryTestLibrary.AddGroup(Sg3NameTxt, Sg3IdTxt);

        // A BC security group is created for each of them
        SecurityGroup.Create(Sg1CodeTxt, Sg1IdTxt);
        SecurityGroup.Create(Sg2CodeTxt, Sg2IdTxt);
        SecurityGroup.Create(Sg3CodeTxt, Sg3IdTxt);

        // Set up 2 system permission sets
        PermissionRoles[1] := 'TestSet';
        PermissionAppIds[1] := LibrarySingleServer.GetAppIdGuid();
        PermissionRoles[2] := 'TestSet';
        PermissionAppIds[2] := LibrarySingleServer.GetAppIdGuid();

        // Set up 2 tenant permission sets (non-app)
        for i := 1 to 2 do begin
            TenantPermissionRoles[i] :=
              LibraryUtility.GenerateRandomCode(TenantPermissionSet.FieldNo("Role ID"), DATABASE::"Tenant Permission Set");
            LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, TenantPermissionRoles[i], NullGuid);
        end;

        // Add permissions to the new permission sets
        LibraryPermissions.AddTenantPermission(NullGuid, TenantPermissionRoles[1], TenantPermission."Object Type"::Table, DATABASE::Customer);
        LibraryPermissions.AddTenantPermission(NullGuid, TenantPermissionRoles[1], TenantPermission."Object Type"::Table, DATABASE::Vendor);
        LibraryPermissions.AddTenantPermission(NullGuid, TenantPermissionRoles[2], TenantPermission."Object Type"::Table, DATABASE::"Sales Header");
        LibraryPermissions.AddTenantPermission(NullGuid, TenantPermissionRoles[2], TenantPermission."Object Type"::Table, DATABASE::"Sales Invoice Header");

        // Set up 2 Nav App permission sets
        AppGUIDs[1] := LibrarySingleServer.GetAppIdGuid();
        AppGUIDs[2] := LibrarySingleServer.GetTestLibraryAppIdGuid();
        for i := 1 to 2 do begin
            AppPermissionRoles[i] := LibraryUtility.GenerateRandomCode(AppPermissionSet.FieldNo("Role ID"), DATABASE::"Tenant Permission Set");
            LibraryPermissions.CreateTenantPermissionSet(AppPermissionSet, AppPermissionRoles[i], AppGUIDs[i]);
        end;

        // Add permissions to the new permission sets
        LibraryPermissions.AddTenantPermission(AppGUIDs[1], AppPermissionRoles[1], TenantPermission."Object Type"::Table, PAGE::"Customer Card");
        LibraryPermissions.AddTenantPermission(AppGUIDs[1], AppPermissionRoles[1], TenantPermission."Object Type"::Table, PAGE::"Vendor Card");
        LibraryPermissions.AddTenantPermission(AppGUIDs[2], AppPermissionRoles[2], TenantPermission."Object Type"::Table, PAGE::"Customer Statistics");
        LibraryPermissions.AddTenantPermission(AppGUIDs[2], AppPermissionRoles[2], TenantPermission."Object Type"::Table, PAGE::"Vendor Statistics");
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

    local procedure CleanupData()
    var
        User: Record User;
        UserSetup: Record "User Setup";
        AccessControl: Record "Access Control";
    begin
        // When we add any user into User table Server switches authentication mode
        // and further tests fail with permission error until Server is restarted.
        // Automatic rollback in test isolation does not revert Server's authentication mode.
        // In this case we need manually clean up User table if test passed and User table
        // is modified during this test.
        // User Setup must cleaned too, due to reference to User table.
        User.SetFilter("User Name", '<>%1', UserId);
        User.DeleteAll();
        UserSetup.DeleteAll();
        AccessControl.DeleteAll();

        UnbindSubscription(SecurityGroupsTestLibrary);
        UnbindSubscription(AzureADGraphTestLibrary);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAggregatePermissionSetsTable()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        // Test that the aggregate permission set table contains permission sets from the system
        // and the Nav App

        // Init
        InitializeData();

        // Execute

        // Verify

        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::System, PermissionAppIds[1], PermissionRoles[1]);
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::System, PermissionAppIds[2], PermissionRoles[2]);

        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, NullGuid, TenantPermissionRoles[1]);
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, NullGuid, TenantPermissionRoles[2]);

        // Ensure the App-level permissions are set appropriate and visibile in both tables.
        AppPermissionSet.Get(AppGUIDs[1], AppPermissionRoles[1]);
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, AppPermissionSet."App ID", AppPermissionSet."Role ID");
        AppPermissionSet.Get(AppGUIDs[2], AppPermissionRoles[2]);
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, AppPermissionSet."App ID", AppPermissionSet."Role ID");

        CleanupData();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestViewAggregatePermissionsSets()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetBuffer: Record "Permission Set Buffer";
        PermissionSets: TestPage "Permission Sets";
    begin
        // Test that the aggregate permission sets are viewable in the Permission Sets page
        // Init
        InitializeData();

        // Execute
        PermissionSets.OpenView();

        // Find a system permission set
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::System);
        AggregatePermissionSet.FindFirst();
        PointPermissionSetPageToRole(PermissionSets, Format(PermissionSetBuffer.Type::System), AggregatePermissionSet."Role ID");

        // Find a tenant permission set

        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.SetRange("App ID", NullGuid);
        AggregatePermissionSet.FindFirst();
        PointPermissionSetPageToRole(PermissionSets, Format(PermissionSetBuffer.Type::"User-Defined"), AggregatePermissionSet."Role ID");

        // Find the application permission sets

        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.FindFirst();
        PointPermissionSetPageToRole(PermissionSets, Format(PermissionSetBuffer.Type::Extension), AggregatePermissionSet."Role ID");
        Assert.AreEqual(AggregatePermissionSet."App Name", PermissionSets."App Name".Value, 'App Name mismatched');
        Assert.AreEqual(AggregatePermissionSet."Role ID", PermissionSets.PermissionSet.Value, 'Role ID mismatch');

        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.SetRange("App ID", AppGUIDs[2]);
        AggregatePermissionSet.FindFirst();
        PointPermissionSetPageToRole(PermissionSets, Format(PermissionSetBuffer.Type::Extension), AggregatePermissionSet."Role ID");
        Assert.AreEqual(AggregatePermissionSet."App Name", PermissionSets."App Name".Value, 'App Name mismatched');
        Assert.AreEqual(AggregatePermissionSet."Role ID", PermissionSets.PermissionSet.Value, 'Role ID mismatch');

        CleanupData();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestViewAggregatePermissionsSetsByUser()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUser: TestPage "Permission Set by User";
    begin
        // Test that the aggregate permission sets are viewable in the Permission Sets By User page
        // Init
        InitializeData();

        // User is SUPER
        AssignSuperToCurrentUser();

        // Execute
        PermissionSetByUser.OpenView();

        // Verify

        // Find the application permission sets
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.FindFirst();
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Assert.AreEqual(AggregatePermissionSet."App Name", PermissionSetByUser."App Name".Value, 'App Name mismatched');
        Assert.AreEqual(AggregatePermissionSet."Role ID", PermissionSetByUser."Role ID".Value, 'Role ID mismatch');

        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.SetRange("App ID", AppGUIDs[2]);
        AggregatePermissionSet.FindFirst();
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Assert.AreEqual(AggregatePermissionSet."App Name", PermissionSetByUser."App Name".Value, 'App Name mismatched');
        Assert.AreEqual(AggregatePermissionSet."Role ID", PermissionSetByUser."Role ID".Value, 'Role ID mismatch');

        CleanupData();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestViewAggregatePermissionsSetsBySecurityGroup()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetBySecurityGroup: TestPage "Permission Set By Sec. Group";
    begin
        // Test that the aggregate permission sets are viewable in the Permission Sets By Security Group page
        // Init
        InitializeData();

        // User is SUPER
        AssignSuperToCurrentUser();

        // Execute
        PermissionSetBySecurityGroup.OpenView();

        // Verify
        // Find the application permission sets
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.FindFirst();
        PermissionSetBySecurityGroup.GotoRecord(AggregatePermissionSet);
        Assert.AreEqual(AggregatePermissionSet."App Name", PermissionSetBySecurityGroup."App Name".Value, 'App Name mismatched');
        Assert.AreEqual(AggregatePermissionSet."Role ID", PermissionSetBySecurityGroup."Role ID".Value, 'Role ID mismatch');

        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.SetRange("App ID", AppGUIDs[2]);
        AggregatePermissionSet.FindFirst();
        PermissionSetBySecurityGroup.GotoRecord(AggregatePermissionSet);
        Assert.AreEqual(AggregatePermissionSet."App Name", PermissionSetBySecurityGroup."App Name".Value, 'App Name mismatched');
        Assert.AreEqual(AggregatePermissionSet."Role ID", PermissionSetBySecurityGroup."Role ID".Value, 'Role ID mismatch');

        CleanupData();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAddPermissionSet()
    var
        PermissionSets: TestPage "Permission Sets";
    begin
        // Test that a permission set can be added through the Permission Set Page
        // Init
        InitializeData();

        // Execute
        PermissionSets.OpenEdit();
        PermissionSets.New();

        asserterror PermissionSets.PermissionSet.SetValue('MyRole');
        PermissionSets.Close();

        // Verify
        CleanupData();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAddPermissionsByUser()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUser: TestPage "Permission Set by User";
        PermSetEnabled: Boolean;
    begin
        // Test that users can be assigned Nav App permissions in the Permission Sets By User page
        // Init
        InitializeData();

        // User is SUPER
        AssignSuperToCurrentUser();

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst();

        // Execute
        PermissionSetByUser.OpenView();
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.Column1.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID", PermissionSetByUser.Column1.Caption));
        PermissionSetByUser.Column1.SetValue(true);
        PermissionSetByUser.Close();

        // Verify
        PermissionSetByUser.OpenView();
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.Column1.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo('Expected permission set %1 to be enabled for %2', PermissionSetByUser."Role ID", PermissionSetByUser.Column1.Caption));

        PermissionSetByUser.Close();
        CleanupData();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAddPermissionsByUserAll()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUser: TestPage "Permission Set by User";
        PermSetEnabled: Boolean;
    begin
        // Test that permissions can be added to Nav App permissions in the Permission Sets By User page by selecting the item to select all
        // Init
        InitializeData();

        // User is SUPER
        AssignSuperToCurrentUser();

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst();

        // Execute
        PermissionSetByUser.OpenView();
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.AllUsersHavePermission.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID",
            PermissionSetByUser.AllUsersHavePermission.Caption));
        PermissionSetByUser.AllUsersHavePermission.SetValue(true);
        PermissionSetByUser.Close();

        // Verify
        PermissionSetByUser.OpenView();
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.AllUsersHavePermission.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetByUser."Role ID",
            PermissionSetByUser.AllUsersHavePermission.Caption));

        Evaluate(PermSetEnabled, PermissionSetByUser.Column1.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo('Expected permission set %1 to be enabled for %2', PermissionSetByUser."Role ID", PermissionSetByUser.Column1.Caption));

        Evaluate(PermSetEnabled, PermissionSetByUser.Column2.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo('Expected permission set %1 to be enabled for %2', PermissionSetByUser."Role ID", PermissionSetByUser.Column2.Caption));

        PermissionSetByUser.Close();
        CleanupData();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAddPermissionsBySecurityGroup()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetBySecurityGroup: TestPage "Permission Set By Sec. Group";
        PermSetEnabled: Boolean;
    begin
        // Test that users can be assigned Nav App permissions in the Permission Sets By User page
        // Init
        InitializeData();

        // User is SUPER
        AssignSuperToCurrentUser();

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst();

        // Execute
        PermissionSetBySecurityGroup.OpenView();
        PermissionSetBySecurityGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetBySecurityGroup.Column1.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetBySecurityGroup."Role ID",
            PermissionSetBySecurityGroup.Column1.Caption));
        PermissionSetBySecurityGroup.Column1.SetValue(true);
        PermissionSetBySecurityGroup.Close();

        // Verify
        PermissionSetBySecurityGroup.OpenView();
        PermissionSetBySecurityGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetBySecurityGroup.Column1.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetBySecurityGroup."Role ID", PermissionSetBySecurityGroup.Column1.Caption));

        PermissionSetBySecurityGroup.Close();
        CleanupData();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAddPermissionsBySecurityGroupAll()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetBySecurityGroup: TestPage "Permission Set By Sec. Group";
        PermSetEnabled: Boolean;
    begin
        // Test that permissions can be added to Nav App permissions in the Permission Sets By User page by selecting the item to select all
        // Init
        InitializeData();

        // User is SUPER
        AssignSuperToCurrentUser();

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst();

        // Execute
        PermissionSetBySecurityGroup.OpenView();
        PermissionSetBySecurityGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetBySecurityGroup.AllUsersHavePermission.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetBySecurityGroup."Role ID",
            PermissionSetBySecurityGroup.AllUsersHavePermission.Caption));
        PermissionSetBySecurityGroup.AllUsersHavePermission.SetValue(true);
        PermissionSetBySecurityGroup.Close();

        // Verify
        PermissionSetBySecurityGroup.OpenView();
        PermissionSetBySecurityGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetBySecurityGroup.AllUsersHavePermission.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetBySecurityGroup."Role ID",
            PermissionSetBySecurityGroup.AllUsersHavePermission.Caption));

        Evaluate(PermSetEnabled, PermissionSetBySecurityGroup.Column1.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetBySecurityGroup."Role ID", PermissionSetBySecurityGroup.Column1.Caption));

        Evaluate(PermSetEnabled, PermissionSetBySecurityGroup.Column2.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetBySecurityGroup."Role ID", PermissionSetBySecurityGroup.Column2.Caption));

        PermissionSetBySecurityGroup.Close();
        CleanupData();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRemovePermissionsByUser()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUser: TestPage "Permission Set by User";
        PermSetEnabled: Boolean;
    begin
        // Test removing a permission for a given user through the UI
        // Init
        InitializeData();

        // User is SUPER
        AssignSuperToCurrentUser();

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst();

        // Execute
        PermissionSetByUser.OpenView();
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.Column1.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID", PermissionSetByUser.Column1.Caption));
        PermissionSetByUser.Column1.SetValue(true);
        PermissionSetByUser.Close();

        // Delete the permission
        PermissionSetByUser.OpenView();
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        PermissionSetByUser.Column1.SetValue(false);
        PermissionSetByUser.Close();

        // Verify
        PermissionSetByUser.OpenView();
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.Column1.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID", PermissionSetByUser.Column1.Caption));
        PermissionSetByUser.Close();

        CleanupData();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRemovePermissionsByUserAll()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUser: TestPage "Permission Set by User";
        PermSetEnabled: Boolean;
    begin
        // Test that permissions can be added to Nav App permissions in the Permission Sets By User page by selecting the item to select all
        // Init
        InitializeData();

        // User is SUPER
        AssignSuperToCurrentUser();

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst();

        // Execute
        PermissionSetByUser.OpenView();
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.AllUsersHavePermission.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID",
            PermissionSetByUser.AllUsersHavePermission.Caption));
        PermissionSetByUser.AllUsersHavePermission.SetValue(true);
        PermissionSetByUser.Close();

        PermissionSetByUser.OpenView();
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.AllUsersHavePermission.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetByUser."Role ID",
            PermissionSetByUser.AllUsersHavePermission.Caption));
        PermissionSetByUser.AllUsersHavePermission.SetValue(false);
        PermissionSetByUser.Close();

        // Verify
        PermissionSetByUser.OpenView();
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.AllUsersHavePermission.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID",
            PermissionSetByUser.AllUsersHavePermission.Caption));
        Evaluate(PermSetEnabled, PermissionSetByUser.Column1.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID", PermissionSetByUser.Column1.Caption));
        Evaluate(PermSetEnabled, PermissionSetByUser.Column2.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID", PermissionSetByUser.Column2.Caption));

        PermissionSetByUser.Close();
        CleanupData();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRemoveSUPERPermissionsByUserAll()
    var
        SuperPermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUser: TestPage "Permission Set by User";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        IsPermissionSetEnabled: Boolean;
    begin
        // [Scenario] User is not able to remove the SUPER permission set from all users.
        // Init
        InitializeData();

        // User is SUPER
        AssignSuperToCurrentUser();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // Find SUPER permission set
        SuperPermissionSet.SetRange("Role ID", 'SUPER');
        SuperPermissionSet.SetRange(Scope, SuperPermissionSet.Scope::System);
        Assert.IsTrue(SuperPermissionSet.FindFirst(), 'Aggregate Permission Set must have a SUPER entry');

        // Execute
        PermissionSetByUser.OpenView();
        PermissionSetByUser.GotoRecord(SuperPermissionSet);
        Evaluate(IsPermissionSetEnabled, PermissionSetByUser.AllUsersHavePermission.Value);

        // Verify
        Assert.IsFalse(
          IsPermissionSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID",
            PermissionSetByUser.AllUsersHavePermission.Caption));

        // Execute
        PermissionSetByUser.AllUsersHavePermission.SetValue(true);
        PermissionSetByUser.Close();
        PermissionSetByUser.OpenView();
        PermissionSetByUser.GotoRecord(SuperPermissionSet);
        Evaluate(IsPermissionSetEnabled, PermissionSetByUser.AllUsersHavePermission.Value);

        // Verify
        Assert.IsTrue(
          IsPermissionSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetByUser."Role ID",
            PermissionSetByUser.AllUsersHavePermission.Caption));

        // Execute
        asserterror PermissionSetByUser.AllUsersHavePermission.SetValue(false);

        // Verify
        Assert.AreEqual(1, PermissionSetByUser.AllUsersHavePermission.ValidationErrorCount(), 'Wrong number of validation errors');
        Assert.AreEqual('There should be at least one enabled ''SUPER'' user.', PermissionSetByUser.AllUsersHavePermission.GetValidationError(1), 'Wrong validation error message');

        PermissionSetByUser.Close();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        CleanupData();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRemovePermissionsBySecurityGroup()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetBySecurityGroup: TestPage "Permission Set By Sec. Group";
        PermSetEnabled: Boolean;
    begin
        // Test that users can be assigned Nav App permissions in the Permission Sets By User page
        // Init
        InitializeData();

        // User is SUPER
        AssignSuperToCurrentUser();

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst();

        // Execute
        PermissionSetBySecurityGroup.OpenView();
        PermissionSetBySecurityGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetBySecurityGroup.Column1.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetBySecurityGroup."Role ID",
            PermissionSetBySecurityGroup.Column1.Caption));
        PermissionSetBySecurityGroup.Column1.SetValue(true);
        PermissionSetBySecurityGroup.Close();

        // Verify
        PermissionSetBySecurityGroup.OpenView();
        PermissionSetBySecurityGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetBySecurityGroup.Column1.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetBySecurityGroup."Role ID", PermissionSetBySecurityGroup.Column1.Caption));
        PermissionSetBySecurityGroup.Column1.SetValue(false);
        PermissionSetBySecurityGroup.Close();

        PermissionSetBySecurityGroup.OpenView();
        PermissionSetBySecurityGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetBySecurityGroup.Column1.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetBySecurityGroup."Role ID",
            PermissionSetBySecurityGroup.Column1.Caption));

        PermissionSetBySecurityGroup.Close();
        CleanupData();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRemovePermissionsBySecurityGroupAll()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetBySecurityGroup: TestPage "Permission Set By Sec. Group";
        PermSetEnabled: Boolean;
    begin
        // Test that permissions can be added to Nav App permissions in the Permission Sets By User page by selecting the item to select all
        // Init
        InitializeData();

        // User is SUPER
        AssignSuperToCurrentUser();

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst();

        // Execute
        PermissionSetBySecurityGroup.OpenView();
        PermissionSetBySecurityGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetBySecurityGroup.AllUsersHavePermission.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetBySecurityGroup."Role ID",
            PermissionSetBySecurityGroup.AllUsersHavePermission.Caption));
        PermissionSetBySecurityGroup.AllUsersHavePermission.SetValue(true);
        PermissionSetBySecurityGroup.Close();

        PermissionSetBySecurityGroup.OpenView();
        PermissionSetBySecurityGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetBySecurityGroup.AllUsersHavePermission.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetBySecurityGroup."Role ID",
            PermissionSetBySecurityGroup.AllUsersHavePermission.Caption));
        PermissionSetBySecurityGroup.AllUsersHavePermission.SetValue(false);
        PermissionSetBySecurityGroup.Close();

        // Verify
        PermissionSetBySecurityGroup.OpenView();
        PermissionSetBySecurityGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetBySecurityGroup.AllUsersHavePermission.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetBySecurityGroup."Role ID",
            PermissionSetBySecurityGroup.AllUsersHavePermission.Caption));
        Evaluate(PermSetEnabled, PermissionSetBySecurityGroup.Column1.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetBySecurityGroup."Role ID",
            PermissionSetBySecurityGroup.Column1.Caption));
        Evaluate(PermSetEnabled, PermissionSetBySecurityGroup.Column2.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetBySecurityGroup."Role ID",
            PermissionSetBySecurityGroup.Column2.Caption));

        PermissionSetBySecurityGroup.Close();
        CleanupData();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestPermissionSetByUserGroupPage()
    var
        AccessControl: Record "Access Control";
        User: Record User;
        SecurityGroupBuffer: Record "Security Group Buffer";
        TenantPermissionSet: Record "Tenant Permission Set";
        SecurityGroup: Codeunit "Security Group";
        PermissionSetBySecurityGroup: TestPage "Permission Set By Sec. Group";
        FirstUserGroupCode: Text;
        LastSecurityGroupCode: Text;
    begin
        CreateUsersAndPermissionSets();

        // User is SUPER
        AssignSuperToCurrentUser();

        LibraryPermissions.GetMyUser(User);
        // Execute
        PermissionSetBySecurityGroup.OpenEdit();
        PermissionSetBySecurityGroup.First();
        while PermissionSetBySecurityGroup."Role ID".Value <> 'TEST1' do
            PermissionSetBySecurityGroup.Next();
        // test setup guarantees uniqueness
        TenantPermissionSet.SetRange("Role ID", 'TEST1');
        TenantPermissionSet.FindFirst();

        AccessControl.SetRange("Role ID", TenantPermissionSet."Role ID");
        Assert.RecordIsEmpty(AccessControl);

        PermissionSetBySecurityGroup.AllUsersHavePermission.SetValue(true);
        PermissionSetBySecurityGroup.AllUsersHavePermission.SetValue(false);
        PermissionSetBySecurityGroup.Column1.SetValue(true);
        PermissionSetBySecurityGroup.Column2.SetValue(true);
        PermissionSetBySecurityGroup.Column3.SetValue(true);

        FirstUserGroupCode := PermissionSetBySecurityGroup.Column1.Caption;
        LastSecurityGroupCode := FirstUserGroupCode;
        PermissionSetBySecurityGroup.ColumnRight.Invoke();
        while LastSecurityGroupCode <> PermissionSetBySecurityGroup.Column1.Caption do begin
            PermissionSetBySecurityGroup.Column3.SetValue(true);
            LastSecurityGroupCode := PermissionSetBySecurityGroup.Column1.Caption;
            PermissionSetBySecurityGroup.ColumnRight.Invoke();
        end;
        LastSecurityGroupCode := PermissionSetBySecurityGroup.Column3.Caption;
        PermissionSetBySecurityGroup.AllColumnsLeft.Invoke();
        PermissionSetBySecurityGroup.ColumnLeft.Invoke();
        PermissionSetBySecurityGroup.AllColumnsRight.Invoke();

        // Validate
        SecurityGroup.GetGroups(SecurityGroupBuffer);
        SecurityGroupBuffer.FindFirst();
        Assert.AreEqual(SecurityGroupBuffer.Code, FirstUserGroupCode, '');
        SecurityGroupBuffer.FindLast();
        Assert.AreEqual(SecurityGroupBuffer.Code, LastSecurityGroupCode, '');
        Assert.AreEqual(SecurityGroupBuffer.Count, AccessControl.Count, '');
        PermissionSetBySecurityGroup.AllUsersHavePermission.SetValue(false);

        Assert.RecordIsEmpty(AccessControl);
        PermissionSetBySecurityGroup.Close();

        CleanupData();
    end;

    local procedure CreateUsersAndPermissionSets()
    var
        User: Record User;
        TenantPermissionSet: Record "Tenant Permission Set";
        i: Integer;
        NewCode: Text[20];
    begin
        // Creates a batch of test data, using other functions in this library
        TenantPermissionSet.SetFilter("Role ID", 'TEST*');
        TenantPermissionSet.DeleteAll(true);
        InitializeData();
        for i := 1 to 15 do begin
            NewCode := StrSubstNo('TEST%1', i);
            User.SetRange("User Name", NewCode);
            if User.IsEmpty() then
                LibraryPermissions.CreateUser(User, NewCode, false);
            TenantPermissionSet."App ID" := LibrarySingleServer.GetAppIdGuid();
            if not TenantPermissionSet.Get(TenantPermissionSet."App ID", NewCode) then
                LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, NewCode, TenantPermissionSet."App ID");
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PermissionSetLookupHandler(var LookupPermissionSet: TestPage "Lookup Permission Set")
    begin
        LookupPermissionSet.Last();
        LookupPermissionSet.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Answer: Boolean)
    begin
        Answer := true;
    end;

    [Scope('OnPrem')]
    procedure PointPermissionSetPageToRole(var PermissionSetsPage: TestPage "Permission Sets"; TypeText: Text; RoleId: Code[20])
    begin
        PermissionSetsPage.First();
        if PermissionSetsPage.PermissionSet.Value = RoleId then
            if PermissionSetsPage.Type.Value = TypeText then
                exit;

        while PermissionSetsPage.Next() do
            if PermissionSetsPage.PermissionSet.Value = RoleId then
                if PermissionSetsPage.Type.Value = TypeText then
                    exit;

        Assert.Fail('Newly created tenant permission set not found.');
    end;
}