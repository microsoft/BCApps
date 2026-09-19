namespace System.Security.AccessControl;

using Microsoft.Upgrade;
using System.Azure.Identity;
using System.Environment;
using System.Reflection;
using System.Upgrade;

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

        OnMigrateUserGroups();
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