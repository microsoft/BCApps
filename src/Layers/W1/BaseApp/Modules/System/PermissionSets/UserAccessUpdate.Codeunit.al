namespace System.Security.User;

using System.Azure.Identity;
using System.Security.AccessControl;

codeunit 9020 "User Access Update"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Plan", 'OnUpdateUserAccessForSaaS', '', false, false)]
    local procedure OnUpdateUserAccessForSaaS(UserSecurityID: Guid; var UserGroupsAdded: Boolean);
    var
        PermissionManager: Codeunit "Permission Manager";
    begin
        UserGroupsAdded := PermissionManager.UpdateUserAccessForSaaS(UserSecurityID);
    end;
}