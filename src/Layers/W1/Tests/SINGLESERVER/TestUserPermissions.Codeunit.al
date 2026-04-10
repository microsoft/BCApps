codeunit 134610 "Test User Permissions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UT] [Permission Set]
    end;

    var
        Assert: Codeunit Assert;
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        GlobalSourcePermissionSetRoleID: Code[20];
        CopyToPermissionSet: Code[20];
        CopySuccessMsg: Label 'New permission set, %1, has been created.', Comment = 'New permission set, D365 Basic Set, has been created.';
        LibrarySingleServer: Codeunit "Library - Single Server";

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCreateSuperUser()
    var
        User: Record User;
        AccessControl: Record "Access Control";
        Permission: Record Permission;
        Users: TestPage Users;
    begin
        // Tests codeunit 9000 - creation of an admin/SUPER user for currently logged in user.
        // Init: Not possible to delete existing users, so this will only give full coverage in a clean DB

        // Execute
        Users.OpenEdit();
        Users.AddMeAsSuper.Invoke();
        Users.Close();

        // Verify
        LibraryPermissions.GetMyUser(User);
        AccessControl.Get(User."User Security ID", 'SUPER');
        Permission.SetRange("Role ID", 'SUPER');
        Assert.IsTrue(Permission.Count >= 8, '');
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestPermissionSetByUserPage1()
    var
        User: Record User;
        TenantPermissionSet: Record "Tenant Permission Set";
        AccessControl: Record "Access Control";
        PermissionSetbyUser: TestPage "Permission Set by User";
        MoreRecords: Boolean;
        FirstUserID: Text;
        SelectedPermissionSet: Code[20];
    begin
        // Test page 9816 which is a 'matrix'-like presentation of permission sets by users.
        // Init
        AssignSuperToCurrentUser();
        CreateUsersAndPermissionSets();
        LibraryPermissions.GetMyUser(User);

        // Execute
        PermissionSetbyUser.OpenEdit();
        PermissionSetbyUser.Filter.SetFilter(Scope, 'Tenant');
        PermissionSetbyUser.ShowDomainName.SetValue(false);
        PermissionSetbyUser.SelectedCompany.SetValue(CompanyName);
        MoreRecords := PermissionSetbyUser.First();
        while MoreRecords and (CopyStr(PermissionSetbyUser."Role ID".Value, 1, 4) <> 'TEST') do
            MoreRecords := PermissionSetbyUser.Next();
        SelectedPermissionSet := PermissionSetbyUser."Role ID".Value();
        // test setup ensures Role Id is unique in tenant permissions
        TenantPermissionSet.Setrange("Role ID", SelectedPermissionSet);
        TenantPermissionSet.FindFirst();

        AccessControl.SetRange("Company Name", CompanyName);
        AccessControl.SetRange("Role ID", TenantPermissionSet."Role ID");
        Assert.AreEqual(0, AccessControl.Count, '');

        PermissionSetbyUser.AllUsersHavePermission.SetValue(true);
        PermissionSetbyUser.AllUsersHavePermission.SetValue(false);
        PermissionSetbyUser.Column1.SetValue(true);
        PermissionSetbyUser.Column2.SetValue(true);
        PermissionSetbyUser.Column3.SetValue(true);
        PermissionSetbyUser.Column4.SetValue(true);
        PermissionSetbyUser.Column5.SetValue(true);
        PermissionSetbyUser.Column6.SetValue(true);
        PermissionSetbyUser.Column7.SetValue(true);
        PermissionSetbyUser.Column8.SetValue(true);
        PermissionSetbyUser.Column9.SetValue(true);
        PermissionSetbyUser.Column10.SetValue(true);
        FirstUserID := PermissionSetbyUser.Column1.Caption;
        PermissionSetbyUser.ColumnRight.Invoke();
        while FirstUserID <> PermissionSetbyUser.Column1.Caption do begin
            PermissionSetbyUser.Column10.SetValue(true);
            FirstUserID := PermissionSetbyUser.Column1.Caption;
            PermissionSetbyUser.ColumnRight.Invoke();
        end;
        PermissionSetbyUser.AllColumnsLeft.Invoke();
        PermissionSetbyUser.ColumnLeft.Invoke();
        PermissionSetbyUser.AllColumnsRight.Invoke();

        // Validate
        Assert.AreEqual(User.Count, AccessControl.Count, '');
        PermissionSetbyUser.AllUsersHavePermission.SetValue(false);
        Assert.AreEqual(0, AccessControl.Count, '');
        PermissionSetbyUser.Close();
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetHandler,CopyPermissionSetSuccessMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestPermissionSetByUserPageInvokeCopy()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        PermissionSetbyUser: TestPage "Permission Set by User";
        ZeroGUID: Guid;
    begin
        // Tests that invoking action Copy Permission Set starts report 9802.
        // Init
        LibraryVariableStorage.Clear();

        CopyToPermissionSet := CopyStr(GetGuidString(), 1, 20);

        // Execute
        LibraryVariableStorage.Enqueue(CopyToPermissionSet);

        AssignSuperToCurrentUser();
        PermissionSetbyUser.OpenEdit();
        PermissionSetbyUser.First();
        PermissionSetbyUser.CopyPermissionSet.Invoke();
        PermissionSetbyUser.Close();

        // Verification: PageHandler is executed.

        TenantPermissionSet.Get(ZeroGUID, CopyToPermissionSet);
        TestCleanup();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AddSubractPermissionSetHandlerAdd,PermissionSetListHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAddPermissionSet()
    var
        SourceTenantPermissionSet: Record "Tenant Permission Set";
        DestTenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        AggregatePermissionSet: Record "Aggregate Permission Set";
        AddSubtractPermissionSet: Report "Add/Subtract Permission Set";
        ZeroGuid: Guid;
    begin
        // Verifies that report 9000 adds another permission set to the current
        // Init
        LibraryPermissions.CreateTenantPermissionSet(SourceTenantPermissionSet, '', ZeroGuid);
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, SourceTenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", DATABASE::"Sales Header");
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, SourceTenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", DATABASE::"Purchase Header");
        LibraryPermissions.CreateTenantPermissionSet(DestTenantPermissionSet, '', ZeroGuid);
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, DestTenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", DATABASE::"Purchase Header");
        TenantPermission.SetRange("Role ID", DestTenantPermissionSet."Role ID");
        Assert.AreEqual(1, TenantPermission.Count, '');

        // Execute
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, ZeroGuid, DestTenantPermissionSet."Role ID");
        GlobalSourcePermissionSetRoleID := SourceTenantPermissionSet."Role ID";
        AddSubtractPermissionSet.SetDestination(AggregatePermissionSet);
        AddSubtractPermissionSet.RunModal(); // triggers AddSubractPermissionSetHandler

        // Verify
        Assert.AreEqual(2, TenantPermission.Count, '');
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('AddSubractPermissionSetHandlerAdd,PermissionSetListHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAddTenantPermissionSetToTenantPermissionSet()
    var
        SourceTenantPermissionSet: Record "Tenant Permission Set";
        DestTenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        DestTenantPermission: Record "Tenant Permission";
        AggregatePermissionSet: Record "Aggregate Permission Set";
        AddSubtractPermissionSet: Report "Add/Subtract Permission Set";
        ZeroGuid: Guid;
    begin
        // [SCENARIO 292106] Add tenant permission set to system permission set via report 9000 "Add/Subtract Permission Set"
        // [GIVEN] System permission set "PS1"
        LibraryPermissions.CreateTenantPermissionSet(DestTenantPermissionSet, '', LibrarySingleServer.GetAppIdGuid());
        // [GIVEN] Tenant permission set "PS2" with permissions "PS2_1", "PS2_2", "PS2_3"
        LibraryPermissions.CreateTenantPermissionSet(SourceTenantPermissionSet, '', ZeroGuid);
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, SourceTenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", DATABASE::"Sales Header");
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, SourceTenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", DATABASE::"Purchase Header");
        // [WHEN] Run "Add/Substract Permission Set" report
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, DestTenantPermissionSet."App ID", DestTenantPermissionSet."Role ID");
        GlobalSourcePermissionSetRoleID := SourceTenantPermissionSet."Role ID";
        AddSubtractPermissionSet.SetDestination(AggregatePermissionSet);
        AddSubtractPermissionSet.RunModal(); // triggers AddSubractPermissionSetHandler
        // [THEN] "PS1" has permissions "PS1_1", "PS1_2", "PS1_3" equal to "PS2_1", "PS2_2", "PS2_3"
        DestTenantPermission.SetRange("Role ID", DestTenantPermissionSet."Role ID");
        DestTenantPermission.SetRange("App ID", DestTenantPermissionSet."App ID");
        Assert.AreEqual(2, DestTenantPermission.Count(), '');
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('AddSubractPermissionSetHandlerSubtract,PermissionSetListHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestSubtractPermissionSet()
    var
        SourceTenantPermissionSet: Record "Tenant Permission Set";
        DestTenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        AggregatePermissionSet: Record "Aggregate Permission Set";
        AddSubtractPermissionSet: Report "Add/Subtract Permission Set";
        ZeroGuid: Guid;
    begin
        // Verifies that report 9000 adds another permission set to the current
        // Init
        LibraryPermissions.CreateTenantPermissionSet(SourceTenantPermissionSet, '', ZeroGuid);
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, SourceTenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", DATABASE::"Sales Header");
        LibraryPermissions.CreateTenantPermissionSet(DestTenantPermissionSet, '', ZeroGuid);
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, DestTenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", DATABASE::"Sales Header");
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, DestTenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", DATABASE::"Purchase Header");
        TenantPermission.SetRange("Role ID", DestTenantPermissionSet."Role ID");
        Assert.AreEqual(2, TenantPermission.Count, '');

        // Execute
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, ZeroGuid, DestTenantPermissionSet."Role ID");
        GlobalSourcePermissionSetRoleID := SourceTenantPermissionSet."Role ID";
        AddSubtractPermissionSet.SetDestination(AggregatePermissionSet);
        AddSubtractPermissionSet.RunModal(); // triggers AddSubractPermissionSetHandler

        // Verify
        Assert.AreEqual(1, TenantPermission.Count, '');
        TestCleanup();
    end;

    local procedure Initialize()
    begin
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UserLookupHandler(var UserLookup: TestPage "User Lookup")
    var
        RecordExists: Boolean;
    begin
        // Selects current user and clicks OK
        RecordExists := UserLookup.First();

        while RecordExists and (UserLookup."User Name".Value <> UserId) do
            RecordExists := UserLookup.Next();
        Assert.IsTrue(RecordExists, '');
        UserLookup.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPermissionSetHandler(var CopyPermissionSet: TestRequestPage "Copy Permission Set")
    begin
        CopyPermissionSet.NewPermissionSet.Value := CopyToPermissionSet;
        CopyPermissionSet.CopyType.SetValue("Permission Set Copy Type"::Flat);
        CopyPermissionSet.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CopyPermissionSetSuccessMessageHandler(Message: Text[1024])
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        CopiedRoleID: Code[20];
    begin
        CopiedRoleID := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(TenantPermissionSet."Role ID"));
        Assert.ExpectedMessage(StrSubstNo(CopySuccessMsg, CopiedRoleID), Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYes(Question: Text[1024]; var Answer: Boolean)
    begin
        Answer := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AddSubractPermissionSetHandlerAdd(var AddSubractPermissionSet: TestRequestPage "Add/Subtract Permission Set")
    begin
        AddSubractPermissionSetHandlerCommon(AddSubractPermissionSet, 1);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AddSubractPermissionSetHandlerSubtract(var AddSubractPermissionSet: TestRequestPage "Add/Subtract Permission Set")
    begin
        AddSubractPermissionSetHandlerCommon(AddSubractPermissionSet, 2);
    end;

    local procedure AddSubractPermissionSetHandlerCommon(var AddSubractPermissionSet: TestRequestPage "Add/Subtract Permission Set"; SetOperationValue: Integer)
    begin
        Assert.IsTrue(AddSubractPermissionSet.DstnAggregatePermissionSet.Value <> GlobalSourcePermissionSetRoleID, '');
        AddSubractPermissionSet.SetOperation.SetValue(AddSubractPermissionSet.SetOperation.GetOption(SetOperationValue));
        AddSubractPermissionSet.SourceAggregatePermissionSet.AssistEdit();
        AddSubractPermissionSet.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ImportedMessageHandler(MessageText: Text)
    begin
        Assert.IsTrue(StrPos(MessageText, 'user groups with a total of') > 0, '');
    end;

    local procedure TestCleanup()
    var
        UserSetup: Record "User Setup";
        AccessControl: Record "Access Control";
    begin
        // When we add any user into User table Server switches authentication mode
        // and further tests fail with permission error until Server is restarted.
        // Automatic rollback in test isolation does not revert Server's authentication mode.
        // In this case we need manually clean up User table if test passed and User table
        // is modified during this test.
        // User Setup must cleaned too, due to reference to User table.
        DeleteAllUsers();
        UserSetup.DeleteAll();
        AccessControl.DeleteAll();
    end;

    local procedure GetGuidString(): Text
    begin
        exit(DelChr(Format(CreateGuid()), '=', '{-}'));
    end;

    local procedure DeleteAllUsers()
    var
        User: Record User;
        UserPersonalization: Record "User Personalization";
    begin
        if User.FindFirst() then begin
            if UserPersonalization.Get(User."User Security ID") then
                UserPersonalization.Delete();
            User.Delete();
        end;
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PermissionSetListHandler(var PermissionSetList: TestPage "Permission Set List")
    begin
        PermissionSetList.FILTER.SetFilter("Role ID", GlobalSourcePermissionSetRoleID);
        PermissionSetList.First();
        PermissionSetList.OK().Invoke();
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
        Initialize();
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
}
