namespace Microsoft.Test.QualityManagement;

using System.Security.AccessControl;
using System.Security.User;
using System.TestTools.TestRunner;

codeunit 139979 "Qlty. Permission Test Fixture"
{
    Access = Internal;
    SingleInstance = true;

    var
        UserSecurityIds: Dictionary of [Code[20], Guid];

    procedure GetUserSecurityId(RoleID: Code[20]): Guid
    begin
        exit(UserSecurityIds.Get(RoleID));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeCodeunitRun', '', false, false)]
    local procedure PrepareUsers(var TestMethodLine: Record "Test Method Line")
    begin
        if TestMethodLine."Test Codeunit" <> Codeunit::"Qlty. Tests - Permission Mgmt." then
            exit;

        Clear(UserSecurityIds);
        CreateUser('QltyMgmt - Inspector');
        CreateUser('QltyMgmt - Admin');
        CreateUser('SUPER');
        Commit();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterCodeunitRun', '', false, false)]
    local procedure RemoveUsers(var TestMethodLine: Record "Test Method Line")
    var
        TestUser: Record User;
        AccessControl: Record "Access Control";
        TestUserSecurityId: Guid;
    begin
        if TestMethodLine."Test Codeunit" <> Codeunit::"Qlty. Tests - Permission Mgmt." then
            exit;

        foreach TestUserSecurityId in UserSecurityIds.Values() do begin
            AccessControl.SetRange("User Security ID", TestUserSecurityId);
            AccessControl.DeleteAll(true);
            TestUser.Get(TestUserSecurityId);
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
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::System);
        AggregatePermissionSet.SetRange("Role ID", RoleID);
        AggregatePermissionSet.FindFirst();
        AggregatePermissionSet.SetRecFilter();
        UserPermissions.AssignPermissionSets(TestUser."User Security ID", '', AggregatePermissionSet);
        UserSecurityIds.Add(RoleID, TestUser."User Security ID");
    end;
}