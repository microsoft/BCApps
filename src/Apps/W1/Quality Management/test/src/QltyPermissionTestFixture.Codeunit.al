namespace Microsoft.Test.QualityManagement;

using System.Security.AccessControl;
using System.Security.User;
using System.Testability;
using System.TestTools.TestRunner;

codeunit 139979 "Qlty. Permission Test Fixture" implements ITestHandler
{
    Access = Internal;
    SingleInstance = true;

    var
        UserSecurityIds: Dictionary of [Code[20], Guid];
        UsersPrepared: Boolean;

    procedure GetUserSecurityId(RoleID: Code[20]): Guid
    begin
        exit(UserSecurityIds.Get(RoleID));
    end;

    procedure OnBeforeTestCodeunitRun(Context: TestHandlerContext)
    begin
        PrepareUsers();
    end;

    procedure OnAfterTestCodeunitRun(Context: TestHandlerContext)
    begin
        RemoveUsers();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeCodeunitRun', '', false, false)]
    local procedure PrepareUsersBeforeCodeunit(var TestMethodLine: Record "Test Method Line")
    begin
        if TestMethodLine."Test Codeunit" <> Codeunit::"Qlty. Tests - Permission Mgmt." then
            exit;

        PrepareUsers();
    end;

    local procedure PrepareUsers()
    begin
        // The legacy event and native handler can prepare the same codeunit.
        if UsersPrepared then
            exit;

        RemoveUsers();
        CreateUser('QltyMgmt - Inspector');
        CreateUser('QltyMgmt - Admin');
        CreateUser('SUPER');
        Commit();
        UsersPrepared := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterCodeunitRun', '', false, false)]
    local procedure RemoveUsersAfterCodeunit(var TestMethodLine: Record "Test Method Line")
    begin
        if TestMethodLine."Test Codeunit" <> Codeunit::"Qlty. Tests - Permission Mgmt." then
            exit;

        RemoveUsers();
    end;

    local procedure RemoveUsers()
    var
        TestUser: Record User;
        AccessControl: Record "Access Control";
        TestUserSecurityId: Guid;
    begin
        UsersPrepared := false;
        if UserSecurityIds.Count() = 0 then
            exit;

        foreach TestUserSecurityId in UserSecurityIds.Values() do begin
            AccessControl.SetRange("User Security ID", TestUserSecurityId);
            AccessControl.DeleteAll(true);
            if TestUser.Get(TestUserSecurityId) then
                TestUser.Delete(true);
        end;
        Clear(UserSecurityIds);
        Commit();
    end;

    local procedure CreateUser(RoleID: Code[20])
    var
        TestUser: Record User;
        AggregatePermissionSet: Record "Aggregate Permission Set";
        LibraryPermissions: Codeunit "Library - Permissions";
        UserPermissions: Codeunit "User Permissions";
    begin
        LibraryPermissions.CreateUser(TestUser, '', false);
        // Retain the user ID even if the following permission assignment fails.
        UserSecurityIds.Add(RoleID, TestUser."User Security ID");
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::System);
        AggregatePermissionSet.SetRange("Role ID", RoleID);
        AggregatePermissionSet.FindFirst();
        AggregatePermissionSet.SetRecFilter();
        UserPermissions.AssignPermissionSets(TestUser."User Security ID", '', AggregatePermissionSet);
    end;
}