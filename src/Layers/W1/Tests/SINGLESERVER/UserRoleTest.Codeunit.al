codeunit 132900 UserRoleTest
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        // [FEATURE] [User] [Permissions]

        LibraryApplicationArea.DisableApplicationAreaSetup();
        Commit();
    end;

    var
        UserTable: Record User;
        UserPersonalization: Record "User Personalization";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        CopySuccessMsg: Label 'New permission set, %1, has been created.', Comment = 'New permission set, D365 Basic Set, has been created.';
        FailedPermissionFilterErr: Label 'Failed to find  %1.', Locked = true;
        ErrorStringCom001Err: Label 'Missing Expected error message: %1. \ Actual error recieved: %2.', Locked = true;
        UserNotFound001Err: Label 'User %1 is not in Window Login table.', Locked = true;
        LicenseTypeIsWrongErr: Label 'Expected LicenseType %1 but got %2.', Locked = true;
        RowNotfound001Err: Label 'The row does not exist on the TestPage.';
        LibraryPermissions: Codeunit "Library - Permissions";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PermissionSetsPage: TestPage "Permission Sets";
        Filters: array[10, 2] of Variant;
        UserName: array[6] of Code[50];
        ValidationError: Text;
        ErrorStringCom002Err: Label 'The validation error count is not as expected. Actual: %1 Expected %2.', Locked = true;
        NoOfFilters: Integer;
        Stages: Option Set,Validate,SetInvalidFieldNo,SetInvalidFilter;
        NewRoleId: Code[20];
        IsInitialized: Boolean;
        SUPERPermissionErr: Label 'There should be at least one enabled ''SUPER'' user.';
        LibrarySingleServer: Codeunit "Library - Single Server";

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AddUserTest()
    var
        UserCount: Integer;
        Index: Integer;
    begin
        // Test function property TransactionModel = AutoRollback
        Initialize();
        UserCount := LibraryRandom.RandIntInRange(ArrayLen(UserName) / 2, ArrayLen(UserName));

        for Index := 1 to UserCount do begin
            AddUserHelper(UserName[Index]);
            TestValidateUserHelper(UserName[Index]);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AddUserWithLicenseTypeTest()
    begin
        // Test function property TransactionModel = AutoRollback
        Initialize();
        AddUserHelper(UserName[1]);
        TestValidateUserWithLicenseTypeHelper(UserName[1], Format(UserTable."License Type"::"Full User"));

        AddAndTestUserWithLicenseType(2, Format(UserTable."License Type"::"Full User"));
        AddAndTestUserWithLicenseType(3, Format(UserTable."License Type"::"Limited User"));
        AddAndTestUserWithLicenseType(4, Format(UserTable."License Type"::"Device Only User"));
        AddAndTestUserWithLicenseType(6, Format(UserTable."License Type"::"External User"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AddFirstUserNoWindowsAuthenticationInfoShowsDialog()
    var
        UserCardPage: TestPage "User Card";
    begin
        Initialize();
        UserCardPage.OpenNew();
        UserCardPage."User Name".Value := 'Test User';
        UserCardPage."Authentication Email".Value := 'test@email.com';
        UserCardPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AddDifferentUserRemoveAuthenticationInfoShowsDialog()
    var
        UserCardPage: TestPage "User Card";
    begin
        Initialize();
        AddUserHelper(SelectRandomADUser());
        UserCardPage.OpenNew();
        UserCardPage."User Name".Value := 'Test User';
        UserCardPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AddDifferentUserAddAuthenticationInfoDifferentThanWindowsNoDialog()
    var
        UserCardPage: TestPage "User Card";
    begin
        Initialize();
        AddUserHelper(SelectRandomADUser());
        UserCardPage.OpenNew();
        UserCardPage."User Name".Value := 'Test User';
        UserCardPage."Authentication Email".Value := 'test@email.com';
        UserCardPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyUserTest()
    var
        UserCardPage: TestPage "User Card";
    begin
        // test function property TransactionModel = AutoRollback
        Initialize();
        AddUserHelper(UserName[1]);
        UserCardPage.OpenEdit();

        UserCardPage.FindFirstField("User Name", UserName[1]);
        UserCardPage."User Name".AssertEquals(UserName[1]);

        UserCardPage."User Name".SetValue(UserName[2]);
        UserCardPage.OK().Invoke();
        TestValidateUserHelper(UserName[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyLicenseTypeUserTest()
    var
        UserCardPage: TestPage "User Card";
    begin
        // test function property TransactionModel = AutoRollback
        Initialize();
        AddUserHelper(UserName[1]);
        UserCardPage.OpenEdit();

        UserCardPage.FindFirstField("User Name", UserName[1]);
        UserCardPage."User Name".AssertEquals(UserName[1]);
        UserCardPage."License Type".Value := Format(UserTable."License Type"::"External User");
        UserCardPage.OK().Invoke();
        TestValidateUserWithLicenseTypeHelper(UserName[1], Format(UserTable."License Type"::"External User"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeleteUserTest()
    var
        UserCardPage: TestPage "User Card";
    begin
        // Test function property TransactionModel = AutoRollback
        // Doesn't work can not invoke the delete button on a page - workaround implemented - deleting the record directly in the table
        Initialize();
        AddUserHelper(UserName[2]);
        UserCardPage.OpenEdit();
        UserCardPage.FindFirstField("User Name", UserName[2]);
        UserCardPage."User Name".AssertEquals(UserName[2]);
        UserCardPage.Close();
        // GETACTION is not getting the DELETE ID from the MetadataEditor bug 273002
        // UserCardPage.GETACTION(2000000152).Invoke();
        // UserCardPage.Close();}
        // Bug 273002 --Removed the UI handler until the bug is resolved."EventYesHandler"
        // Workaround deleting the user from the table
        DeleteUser(UserName[2]);
        UserTable.SetRange("User Name");
        UserCardPage.Trap();
        UserCardPage.OpenView();
        asserterror UserCardPage.FindFirstField("User Name", UserName[2]);
        if GetLastErrorText <> RowNotfound001Err then begin
            DeleteUser(UserName[2]);
            ValidationError := GetLastErrorText;
            UserCardPage.Close();
            Error(ErrorStringCom001Err, RowNotfound001Err, ValidationError);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AutofillTest()
    begin
        // Test function property TransactionModel = AutoRollback
        // Current domain
        Initialize();
        AddUserHelper(UpperCase(GetShortName(UserName[1])));
        TestValidateUserHelper(UserName[1]);
        // Forrest domain
        AddUserHelper(UpperCase(GetShortName(UserName[2])));
        TestValidateUserHelper(UserName[2])
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckPermissionSetDoNotExist()
    var
        UserCardPage: TestPage "User Card";
    begin
        // Test function property TransactionModel = AutoRollback
        Initialize();
        AddUserHelper(UserName[1]);
        UserCardPage.OpenEdit();
        UserCardPage.FindFirstField("User Name", UserName[1]);
        asserterror UserCardPage.Permissions.PermissionSet.SetValue('RoleDoNotExist');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AddMultiplePermissionSet()
    var
        UserCardPage: TestPage "User Card";
    begin
        Initialize();
        UserCardPage.OpenNew();
        UserCardPage."User Name".Value := SelectRandomADUser();
        UserCardPage.Permissions.PermissionSet.SetValue('SUPER');
        UserCardPage.Permissions.Next();
        UserCardPage.Permissions.PermissionSet.SetValue('D365 BASIC');
        UserCardPage.Permissions.First();
        if 0 <> UserCardPage.Permissions.PermissionSet.ValidationErrorCount() then begin
            UserCardPage.Close();
            Error(ErrorStringCom002Err, UserCardPage.Permissions.PermissionSet.ValidationErrorCount(), 0);
        end;

        UserCardPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AddPermissionSetDuplicateRoleID()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        UserCardPage: TestPage "User Card";
    begin
        // Init: Add two permission sets, one at system level, one at tenant level.
        //       See: TestSet.PermissionSet.al
        Initialize();
        UserCardPage.OpenNew();
        UserCardPage."User Name".Value := SelectRandomADUser();

        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, 'TESTSET', LibrarySingleServer.GetAppIdGuid());

        // Exercise: Adding the role ID should trigger a validation error
        UserCardPage.Permissions.First();
        asserterror UserCardPage.Permissions.PermissionSet.SetValue('TESTSET');

        Assert.ExpectedError('Validation error for Field');

        UserCardPage.OK().Invoke();
    end;

    //[Test]ignore 426467
    [HandlerFunctions('SystemPermissionSetLookupHandlerTestSet2,ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AddPermissionSetDuplicateRoleIDLookup()
    var
        AccessControl: Record "Access Control";
        TenantPermissionSet: Record "Tenant Permission Set";
        UserCardPage: TestPage "User Card";
        NullGUID: Guid;
    begin
        Initialize();
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, 'TESTSET3', NullGUID);
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, 'TESTSET3', LibrarySingleServer.GetAppIdGuid());

        // Init
        UserCardPage.OpenNew();
        UserCardPage."User Name".Value := SelectRandomADUser();

        // Use the lookup to select both, this should succeed
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, 'TESTSET2', NullGUID);
        UserCardPage.Permissions.First();
        UserCardPage.Permissions.PermissionSet.Lookup();

        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, 'TESTSET2', LibrarySingleServer.GetTestLibraryAppIdGuid());
        UserCardPage.Permissions.Next();
        UserCardPage.Permissions.PermissionSet.Lookup();

        UserCardPage.Permissions.Next();

        // Verify that there are no validation errors
        if UserCardPage.Permissions.PermissionSet.ValidationErrorCount() <> 0 then begin
            UserCardPage.Close();
            Error(ErrorStringCom002Err, UserCardPage.Permissions.PermissionSet.ValidationErrorCount(), 0);
        end;

        // AccessControl should now contain two entries - one for each permission set
        AccessControl.SetRange("Role ID", 'TESTSET2');
        Assert.AreEqual(2, AccessControl.Count, StrSubstNo('Expected 2 access control entires, found %1', AccessControl.Count));

        UserCardPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PermissionDetailsLookup()
    var
        UserCardPage: TestPage "User Card";
        PermissionsPage: TestPage "Permission Set";
    begin
        Initialize();
        UserCardPage.OpenNew();
        UserCardPage."User Name".Value := SelectRandomADUser();
        UserCardPage.Permissions.PermissionSet.SetValue('SUPER');

        PermissionsPage.Trap();

        UserCardPage.Permissions.Permissions.Invoke();

        PermissionsPage.Close();
        UserCardPage.Close();
    end;

    [Scope('OnPrem')]
    procedure AddMultiplePermissionValidation()
    var
        UserCardPage: TestPage "User Card";
    begin
        // TODO FIX THE DIALOG ERROR HANDLING WHEN SETTING 'SUPER'
        UserCardPage.OpenNew();
        UserCardPage."User Name".Value := SelectRandomADUser();
        asserterror UserCardPage.Permissions.PermissionSet.SetValue('AdfLL');
        if 1 <> UserCardPage.Permissions.PermissionSet.ValidationErrorCount() then begin
            UserCardPage.Close();
            Error(ErrorStringCom002Err, UserCardPage.Permissions.PermissionSet.ValidationErrorCount(), 0);
        end;

        UserCardPage.Permissions.PermissionSet.SetValue('SUPER');
        UserCardPage.Permissions.First();
        if 0 <> UserCardPage.Permissions.PermissionSet.ValidationErrorCount() then begin
            UserCardPage.Close();
            Error(ErrorStringCom002Err, UserCardPage.Permissions.PermissionSet.ValidationErrorCount(), 0);
        end;

        UserCardPage.Close();
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetHandler,CopyPermissionSetSuccessMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CopyPermissionSetTest()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        OrgPermission: Record "Expanded Permission";
        NewTenantPermission: Record "Tenant Permission";
        ZeroGUID: Guid;
        RoleId: Code[20];
        Name: Text;
        Steps: Integer;
    begin
        Initialize();
        LibraryVariableStorage.Clear();
        NewRoleId := 'NEWROLE';

        Assert.IsFalse(TenantPermissionSet.Get(ZeroGUID, NewRoleId), '''NEWROLE'' Permission Set already exists.');

        PermissionSetsPage.OpenEdit();
        PermissionSetsPage.Filter.SetFilter(Type, 'System');
        PermissionSetsPage.Filter.SetFilter("App ID", '63ca2fa4-4f03-4f2b-a480-172fef340d3f');
        // Copy first Permission Set to 'NEWROLE'
        PermissionSetsPage.First();
        RoleId := PermissionSetsPage.PermissionSet.Value();
        Name := PermissionSetsPage.Name.Value();
        LibraryVariableStorage.Enqueue(NewRoleId);
        PermissionSetsPage.CopyPermissionSet.Invoke();

        Assert.IsTrue(TenantPermissionSet.Get(ZeroGUID, NewRoleId), '''NEWROLE'' Permission Set not copied.');
        Assert.AreEqual(TenantPermissionSet.Name, Name, 'Permission Set name not copied');

        OrgPermission.SetCurrentKey("Object Type", "Object ID");
        NewTenantPermission.SetCurrentKey("Object Type", "Object ID");
        OrgPermission.SetRange("Role ID", RoleId);
        OrgPermission.FindSet();
        NewTenantPermission.SetRange("App ID", ZeroGUID);
        NewTenantPermission.SetRange("Role ID", NewRoleId);

        Assert.AreEqual(OrgPermission.Count, NewTenantPermission.Count, 'Number of permissions invalid');
        Assert.IsTrue(NewTenantPermission.FindSet(), 'Permissions not copied');

        repeat
            Assert.AreEqual(OrgPermission."Role ID", RoleId, 'System Role ID differ');
            Assert.AreEqual(NewTenantPermission."Role ID", NewRoleId, 'Tenant Role ID differ');
            Assert.AreEqual(OrgPermission."Object Type", NewTenantPermission."Object Type", 'Object Type differ');
            Assert.AreEqual(OrgPermission."Object ID", NewTenantPermission."Object ID", 'Object ID differ');
            Assert.AreEqual(OrgPermission."Read Permission", NewTenantPermission."Read Permission", 'Read Permission differ');
            Assert.AreEqual(OrgPermission."Insert Permission", NewTenantPermission."Insert Permission", 'Insert Permission differ');
            Assert.AreEqual(OrgPermission."Modify Permission", NewTenantPermission."Modify Permission", 'Modify Permission differ');
            Assert.AreEqual(OrgPermission."Delete Permission", NewTenantPermission."Delete Permission", 'Delete Permission differ');
            Assert.AreEqual(OrgPermission."Execute Permission", NewTenantPermission."Execute Permission", 'Execute Permission differ');
            Assert.IsTrue(OrgPermission."Security Filter" = NewTenantPermission."Security Filter", 'Security Filter differ');

            Steps := OrgPermission.Next();
            Assert.AreEqual(Steps, NewTenantPermission.Next(), 'Number of Permissions differ.');
        until Steps = 0;

        PermissionSetsPage.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeleteUserPermissionSetSUPERForCompany()
    var
        AccessControl: Record "Access Control";
        User: Record User;
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 265197] User is able to delete user permissionset SUPER defined for company if it has one defined for all companies
        Initialize();

        User.DeleteAll(true);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] SUPER User for all companies
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");

        // [GIVEN] User permissionset SUPER for current company
        CreateUserPermissionSetSUPERForCompany(AccessControl);

        // [WHEN] User permissionset SUPER for current company is being deleted
        AccessControl.Delete(true);

        // [THEN] User permissionset deleted successfully
        Assert.IsFalse(FindUserPermissionSetSUPER(AccessControl, CompanyName), 'User permissionset for current company must be deleted');

        // TearDown
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeleteUserPermissionSetSUPERForAllCompanies()
    var
        AccessControl: Record "Access Control";
        User: Record User;
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 265197] User is not able to delete user permissionset SUPER defined for all companies
        Initialize();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        User.DeleteAll(true);

        // [GIVEN] SUPER User for all companies
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");

        // [WHEN] User permissionset SUPER for all companies is being deleted
        FindUserPermissionSetSUPER(AccessControl, '');
        asserterror AccessControl.Delete(true);

        // [THEN] Error "At least one user must be a member of the 'SUPER'"
        Assert.ExpectedError(SUPERPermissionErr);

        // TearDown
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AddApplicationIDInSaaSTest()
    var
        User: Record User;
        UserCard: TestPage "User Card";
    begin
        // Test function property TransactionModel = AutoRollback

        // Create a full user
        Initialize();
        AddUserHelper(UserName[1]);
        User.SetRange("User Name", UserName[1]);
        User.FindFirst();

        // Setting Application ID, sets the License Type to External User
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        UserCard.OpenEdit();
        UserCard.GotoRecord(User);
        UserCard.ApplicationID.Value := CreateGuid();
        UserCard."License Type".AssertEquals(User."License Type"::"External User");

        // Setting Application ID to empty, sets the License Type to Full User
        UserCard.ApplicationID.Value := '';
        UserCard."License Type".AssertEquals(User."License Type"::"Full User");
        UserCard.OK().Invoke();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        InitializeTestUsers();
        IsInitialized := true;
    end;

    local procedure InitializeTestUsers()
    var
        Index: Integer;
        TypeName: Text;
        Counter: Integer;
    begin
        Counter := ArrayLen(UserName);
        TypeName := 'USER001';

        For Index := 1 to Counter do begin
            UserName[Index] := TypeName;
            TypeName := IncStr(TypeName);
        end;
    end;

    local procedure AddUserHelper(NewUserName: Code[50])
    var
        UserCardPage: TestPage "User Card";
    begin
        UserCardPage.OpenNew();
        UserCardPage."User Name".Value := NewUserName;
        UserCardPage.Close();
    end;

    local procedure AddUserWithLicenseTypeHelper(NewUserName: Code[50]; LicenseType: Text)
    var
        UserCardPage: TestPage "User Card";
    begin
        UserCardPage.OpenNew();
        UserCardPage."User Name".Value := NewUserName;
        UserCardPage."License Type".Value := LicenseType;
        UserCardPage.OK().Invoke();
    end;

    local procedure AddAndTestUserWithLicenseType(Index: Integer; LicenseType: Text)
    begin
        AddUserWithLicenseTypeHelper(UserName[Index], LicenseType);
        TestValidateUserWithLicenseTypeHelper(UserName[Index], LicenseType);
    end;

    local procedure SelectRandomADUser(): Code[50]
    begin
        exit(UserName[LibraryRandom.RandInt(ArrayLen(UserName))]);
    end;

    local procedure GetShortName(GivenUserName: Text): Text
    begin
        exit(CopyStr(GivenUserName, StrPos(GivenUserName, '\') + 1));
    end;

    local procedure CreateUserPermissionSetSUPERForCompany(var AccessControl: Record "Access Control")
    var
        User: Record User;
    begin
        User.FindFirst();
        AccessControl."User Security ID" := User."User Security ID";
        AccessControl."Company Name" := CompanyName;
        AccessControl."Role ID" := 'SUPER';
        AccessControl.Insert();
    end;

    local procedure FindUserPermissionSetSUPER(var AccessControl: Record "Access Control"; CompanyNameFilter: Text): Boolean
    var
        User: Record User;
    begin
        User.FindFirst();
        AccessControl.SetRange("User Security ID", User."User Security ID");
        AccessControl.SetFilter("Company Name", '=%1', CompanyNameFilter);
        exit(AccessControl.FindFirst())
    end;

    local procedure TestValidateUserHelper(ExpectedUserName: Text)
    var
        WindowLoginTab: Record User;
    begin
        WindowLoginTab.SetFilter("User Name", ExpectedUserName);
        if not WindowLoginTab.FindFirst() then
            Error(UserNotFound001Err, ExpectedUserName)
    end;

    local procedure TestValidateUserWithLicenseTypeHelper(ExpectedUserName: Text; LicenseType: Text)
    var
        WindowLoginTab: Record User;
    begin
        WindowLoginTab.SetFilter("User Name", ExpectedUserName);
        if not WindowLoginTab.FindFirst() then
            Error(UserNotFound001Err, ExpectedUserName);
        if Format(WindowLoginTab."License Type") <> LicenseType then
            Error(LicenseTypeIsWrongErr, LicenseType, Format(WindowLoginTab."License Type"));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TableFilterModalHandler(var TableFilterPage: TestPage "Table Filter")
    var
        stage: Variant;
        Stages2: Option Set,Validate,SetInvalidFieldNo,SetInvalidFilter;
        i: Integer;
    begin
        LibraryVariableStorage.Dequeue(stage);
        Stages2 := stage;
        case Stages2 of
            Stages2::Set:
                begin
                    TableFilterPage.Last();
                    for i := 1 to NoOfFilters do begin
                        TableFilterPage."Field Number".SetValue(Filters[i] [1]);
                        TableFilterPage."Field Filter".SetValue(Filters[i] [2]);
                        TableFilterPage.Next();
                    end;
                    TableFilterPage.OK().Invoke();
                end;
            Stages::Validate:
                begin
                    for i := 1 to NoOfFilters do
                        if not TableFilterPage.FindFirstField(TableFilterPage."Field Number", Filters[i] [1]) or
                           (TableFilterPage."Field Filter".Value <> Format(Filters[i] [2]))
                        then
                            Error(FailedPermissionFilterErr, Format(Filters[i] [1]));
                    TableFilterPage.OK().Invoke();
                end;
            Stages::SetInvalidFieldNo:
                begin
                    TableFilterPage.Last();
                    for i := 1 to NoOfFilters do
                        asserterror TableFilterPage."Field Number".SetValue(Filters[i] [1]);
                end;
            Stages2::SetInvalidFilter:
                begin
                    TableFilterPage.Last();
                    for i := 1 to NoOfFilters do begin
                        TableFilterPage."Field Number".SetValue(Filters[i] [1]);
                        asserterror TableFilterPage."Field Filter".SetValue(Filters[i] [2]);
                    end;
                end;
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Msg: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPermissionSetHandler(var CopyPermissionSet: TestRequestPage "Copy Permission Set")
    begin
        CopyPermissionSet.NewPermissionSet.SetValue(NewRoleId);
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

    local procedure DeleteUser(UserName: Text)
    begin
        UserTable.SetFilter("User Name", UserName);
        if UserTable.FindFirst() then
            if UserTable.State = 0 then begin
                UserPersonalization.SetRange("User ID", UserTable.GetFilter("User Name"));
                if UserPersonalization.FindFirst() then
                    UserPersonalization.Delete();
                UserTable.State := 1;
            end;
        UserTable.Delete();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SystemPermissionSetLookupHandlerTestSet2(var LookupPermissionSet: TestPage "Lookup Permission Set")
    begin
        LookupPermissionSet.FindFirstField("Role ID", 'TESTSET2');
        if not LookupPermissionSet.FindNextField("Role ID", 'TESTSET2') then; // Go to the second one if it exists.
        LookupPermissionSet.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [Scope('OnPrem')]
    procedure PointPermissionSetPageToRole(var PermissionSetsPage: TestPage "Permission Sets"; RoleId: Code[20])
    begin
        PermissionSetsPage.First();
        if PermissionSetsPage.PermissionSet.Value = RoleId then
            exit;

        while PermissionSetsPage.Next() do
            if PermissionSetsPage.PermissionSet.Value = RoleId then
                exit;

        Assert.Fail('Newly created tenant permission set not found.');
    end;
}

