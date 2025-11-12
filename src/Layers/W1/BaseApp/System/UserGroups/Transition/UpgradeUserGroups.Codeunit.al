namespace System.Security.AccessControl;

using Microsoft.Upgrade;
using System.Azure.Identity;
using System.Reflection;
using System.Upgrade;
using System.Environment;

codeunit 104061 "Upgrade User Groups"
{
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        HybridDeployment: Codeunit "Hybrid Deployment";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade('') then
            exit;

        // Only forcefully migrate user groups when the feature tables are removed (v25+)
        if not IsUserGroupObsoleteStateRemoved() then
            exit;

        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetUserGroupsMigrationUpgradeTag()) then
            exit;

        RunUpgrade();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetUserGroupsMigrationUpgradeTag());
    end;

    internal procedure IsUserGroupObsoleteStateRemoved(): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        if not TableMetadata.Get(Database::"User Group") then
            exit(false);

        exit(TableMetadata.ObsoleteState = TableMetadata.ObsoleteState::Removed);
    end;

    internal procedure RunUpgrade()
    var
        UpgradePermissionSets: Codeunit "Upgrade Permission Sets";
        UpgradeAppIDPermissions: Codeunit "Upgrade App ID Permissions";
        UpgradePlanPermissions: Codeunit "Upgrade Plan Permissions";
        EmptyList: List of [Code[20]];
    begin
        // Ensure user groups are fully upgraded before being migrated
        OnBeforeUpgradeUserGroups();

        UpgradePermissionSets.RunUpgrade();
        UpgradeAppIDPermissions.RunUpgrade();
        UpgradePlanPermissions.RunUpgrade();

        // Migrate user groups
        MigrateUserGroups(EmptyList);
    end;

    internal procedure MigrateUserGroups(UserGroupsToConvert: List of [Code[20]])
    begin
        CreateTenantPermissionSetsForSelectedGroups(UserGroupsToConvert);
        TransferDefaultPermissionsPerPlan();

        OnMigrateUserGroups();
    end;

    local procedure CreateTenantPermissionSetsForSelectedGroups(UserGroupsToConvert: List of [Code[20]])
    var
        UserGroup: Record "User Group";
        UserGroupPermissionSet: Record "User Group Permission Set";
        UpgradePlanPermissions: Codeunit "Upgrade Plan Permissions";
        UserGroupCode: Code[20];
        PermissionType: Option Include,Exclude;
        ConvertedRoleId: Code[20];
    begin
        foreach UserGroupCode in UserGroupsToConvert do
            if UserGroup.Get(UserGroupCode) then begin
                UserGroupPermissionSet.SetRange("User Group Code", UserGroupCode);
                if UserGroupPermissionSet.FindSet() then begin
                    ConvertedRoleId := CreateNewTenantPermissionSet(UserGroupCode, UserGroup.Name);
                    repeat
                        CreateTenantPermissionSetRelation(ConvertedRoleId, UserGroupPermissionSet."Role ID", UserGroupPermissionSet."App ID", UserGroupPermissionSet.Scope, PermissionType::Include);
                    until UserGroupPermissionSet.Next() = 0;
                end;
                UpgradePlanPermissions.ReplaceUserGroupPermissionSets(UserGroupCode, ConvertedRoleId, UserGroupPermissionSet.Scope::Tenant);
            end;
    end;

    local procedure CreateNewTenantPermissionSet(NewDesiredRoleID: Code[20]; NewName: Text): Code[20]
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        NullGuid: Guid;
        NewRoleId: Code[20];
        Index: Integer;
        Suffix: Text;
    begin
        NewRoleId := NewDesiredRoleID;

        TenantPermissionSet.SetRange("App ID", NullGuid);
        TenantPermissionSet.SetRange("Role ID", NewRoleId);
        if not TenantPermissionSet.IsEmpty() then
            repeat
                Index += 1;
                Suffix := '_' + Format(Index);
                NewRoleId := CopyStr(NewDesiredRoleID, 1, MaxStrLen(NewDesiredRoleID) - StrLen(Suffix)) + Suffix;
                TenantPermissionSet.SetRange("Role ID", NewRoleId);
            until TenantPermissionSet.IsEmpty();

        TenantPermissionSet.Init();
        TenantPermissionSet."App ID" := NullGuid;
        TenantPermissionSet."Role ID" := NewRoleId;
        TenantPermissionSet.Name := CopyStr(NewName, 1, MaxStrLen(TenantPermissionSet.Name));
        TenantPermissionSet.Insert();
        exit(NewRoleId);
    end;

    local procedure CreateTenantPermissionSetRelation(RoleId: Code[20]; RelatedRoleID: Code[20]; RelatedAppId: Guid; RelatedScope: Option System,Tenant; PermissionType: Option Include,Exclude)
    var
        TenantPermissionSetRel: Record "Tenant Permission Set Rel.";
        NullGuid: Guid;
    begin
        TenantPermissionSetRel.Init();
        TenantPermissionSetRel."Role ID" := CopyStr(RoleId, 1, MaxStrLen(TenantPermissionSetRel."Role ID"));
        TenantPermissionSetRel."App ID" := NullGuid;
        TenantPermissionSetRel."Related Role ID" := RelatedRoleID;
        TenantPermissionSetRel."Related App ID" := RelatedAppId;
        TenantPermissionSetRel."Related Scope" := RelatedScope;
        TenantPermissionSetRel.Type := PermissionType;
        TenantPermissionSetRel.Insert();
    end;

    local procedure TransferDefaultPermissionsPerPlan()
    var
        UserGroupPlan: Record "User Group Plan";
        UserGroupPermissionSet: Record "User Group Permission Set";
        PlanConfiguration: Codeunit "Plan Configuration";
    begin
        if UserGroupPlan.FindSet() then
            repeat
                UserGroupPermissionSet.SetRange("User Group Code", UserGroupPlan."User Group Code");
                if UserGroupPermissionSet.FindSet() then
                    repeat
                        PlanConfiguration.AddDefaultPermissionSetToPlan(UserGroupPlan."Plan ID",
                            UserGroupPermissionSet."Role ID",
                            UserGroupPermissionSet."App ID",
                            UserGroupPermissionSet.Scope);
                    until UserGroupPermissionSet.Next() = 0;
            until UserGroupPlan.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateUserGroups()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpgradeUserGroups()
    begin
    end;
}