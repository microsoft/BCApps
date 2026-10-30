// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TDS.TDSReturnAndSettlement;

using System.Security.AccessControl;

codeunit 18749 "Upgrade TDS Return PS"
{
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    begin
        RunUpgrade();
    end;

    internal procedure RunUpgrade()
    var
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        MigratePermissionSetAssignments(OldRoleIdLbl, NewRoleIdLbl, ModuleInfo.Id);
    end;

    local procedure MigratePermissionSetAssignments(OldRoleId: Code[20]; NewRoleId: Code[20]; AppId: Guid)
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        if OldRoleId = NewRoleId then
            exit;

        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::System);
        AggregatePermissionSet.SetRange("App ID", AppId);
        AggregatePermissionSet.SetRange("Role ID", NewRoleId);
        if AggregatePermissionSet.IsEmpty() then
            Error(NewPermissionSetNotFoundErr, NewRoleId, AppId);

        MigrateUserGroupPermissionSets(OldRoleId, NewRoleId, AppId);
        MigrateUserGroupAccessControls(OldRoleId, NewRoleId, AppId);
        MigrateAccessControls(OldRoleId, NewRoleId, AppId);
        MigrateTenantPermissionSetRelations(OldRoleId, NewRoleId, AppId);
    end;

    local procedure MigrateUserGroupPermissionSets(OldRoleId: Code[20]; NewRoleId: Code[20]; AppId: Guid)
    var
        OldUserGroupPermissionSet, NewUserGroupPermissionSet, CurrentUserGroupPermissionSet : Record "User Group Permission Set";
    begin
        OldUserGroupPermissionSet.SetRange(Scope, OldUserGroupPermissionSet.Scope::System);
        OldUserGroupPermissionSet.SetRange("App ID", AppId);
        OldUserGroupPermissionSet.SetRange("Role ID", OldRoleId);
        if OldUserGroupPermissionSet.FindSet() then
            repeat
                CurrentUserGroupPermissionSet.Get(OldUserGroupPermissionSet.RecordId());
                if NewUserGroupPermissionSet.Get(OldUserGroupPermissionSet."User Group Code", NewRoleId, OldUserGroupPermissionSet.Scope, AppId) then
                    CurrentUserGroupPermissionSet.Delete()
                else
                    CurrentUserGroupPermissionSet.Rename(OldUserGroupPermissionSet."User Group Code", NewRoleId, OldUserGroupPermissionSet.Scope, AppId);
            until OldUserGroupPermissionSet.Next() = 0;
    end;

    local procedure MigrateUserGroupAccessControls(OldRoleId: Code[20]; NewRoleId: Code[20]; AppId: Guid)
    var
        OldUserGroupAccessControl, NewUserGroupAccessControl, CurrentUserGroupAccessControl : Record "User Group Access Control";
    begin
        OldUserGroupAccessControl.SetRange(Scope, OldUserGroupAccessControl.Scope::System);
        OldUserGroupAccessControl.SetRange("App ID", AppId);
        OldUserGroupAccessControl.SetRange("Role ID", OldRoleId);
        if OldUserGroupAccessControl.FindSet() then
            repeat
                CurrentUserGroupAccessControl.Get(OldUserGroupAccessControl.RecordId());
                if NewUserGroupAccessControl.Get(OldUserGroupAccessControl."User Group Code", OldUserGroupAccessControl."User Security ID", NewRoleId, OldUserGroupAccessControl."Company Name", OldUserGroupAccessControl.Scope, AppId) then
                    CurrentUserGroupAccessControl.Delete()
                else
                    CurrentUserGroupAccessControl.Rename(OldUserGroupAccessControl."User Group Code", OldUserGroupAccessControl."User Security ID", NewRoleId, OldUserGroupAccessControl."Company Name", OldUserGroupAccessControl.Scope, AppId);
            until OldUserGroupAccessControl.Next() = 0;
    end;

    local procedure MigrateAccessControls(OldRoleId: Code[20]; NewRoleId: Code[20]; AppId: Guid)
    var
        OldAccessControl, NewAccessControl, CurrentAccessControl : Record "Access Control";
    begin
        OldAccessControl.SetRange(Scope, OldAccessControl.Scope::System);
        OldAccessControl.SetRange("App ID", AppId);
        OldAccessControl.SetRange("Role ID", OldRoleId);
        if OldAccessControl.FindSet() then
            repeat
                CurrentAccessControl.Get(OldAccessControl.RecordId());
                if NewAccessControl.Get(OldAccessControl."User Security ID", NewRoleId, OldAccessControl."Company Name", OldAccessControl.Scope, AppId) then
                    CurrentAccessControl.Delete()
                else
                    CurrentAccessControl.Rename(OldAccessControl."User Security ID", NewRoleId, OldAccessControl."Company Name", OldAccessControl.Scope, AppId);
            until OldAccessControl.Next() = 0;
    end;

    local procedure MigrateTenantPermissionSetRelations(OldRoleId: Code[20]; NewRoleId: Code[20]; AppId: Guid)
    var
        OldTenantPermissionSetRel, NewTenantPermissionSetRel, CurrentTenantPermissionSetRel : Record "Tenant Permission Set Rel.";
    begin
        OldTenantPermissionSetRel.SetRange("Related Scope", OldTenantPermissionSetRel."Related Scope"::System);
        OldTenantPermissionSetRel.SetRange("Related App ID", AppId);
        OldTenantPermissionSetRel.SetRange("Related Role ID", OldRoleId);
        if OldTenantPermissionSetRel.FindSet() then
            repeat
                CurrentTenantPermissionSetRel.Get(OldTenantPermissionSetRel.RecordId());
                if NewTenantPermissionSetRel.Get(OldTenantPermissionSetRel."App ID", OldTenantPermissionSetRel."Role ID", AppId, NewRoleId) then
                    CurrentTenantPermissionSetRel.Delete()
                else
                    CurrentTenantPermissionSetRel.Rename(OldTenantPermissionSetRel."App ID", OldTenantPermissionSetRel."Role ID", AppId, NewRoleId);
            until OldTenantPermissionSetRel.Next() = 0;
    end;

    var
        OldRoleIdLbl: Label 'TDS RETURN AND SETTL', Locked = true;
        NewRoleIdLbl: Label 'TDS RETURN SETTLE', Locked = true;
        NewPermissionSetNotFoundErr: Label 'The new permission set %1 for app %2 was not found.', Locked = true;
}
