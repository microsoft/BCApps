// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Upgrade;

/// <summary>
/// Upgrade code to fix references of obsolete permission sets.
/// </summary>
codeunit 104042 "Upgrade Permission Sets"
{
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    begin
        RunUpgrade();
    end;

    internal procedure RunUpgrade()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade('') then
            exit;

        ReplaceObsoletePermissionSets();
        ReplaceObsoletePermissionSetsForEditInExcel();
    end;

    local procedure ReplaceObsoletePermissionSetsForEditInExcel()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetUpdateEditInExcelPermissionSetUpgradeTag()) then
            exit;

        ReplacePermissionSet('EXCEL EXPORT ACTION', 'Edit in Excel - View');

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetUpdateEditInExcelPermissionSetUpgradeTag());
    end;

    local procedure ReplaceObsoletePermissionSets()
    var
        ServerSettings: Codeunit "Server Setting";
    begin
        // Run the upgrade code only if the new permission system is enabled (permissions sets come from extensions) 
        if not ServerSettings.GetUsePermissionSetsFromExtensions() then
            exit;

        ReplacePermissionSet('EMAIL SETUP', 'Email - Admin');
        ReplacePermissionSet('EMAIL USAGE', 'Email - Edit');
        ReplacePermissionSet('D365 EXTENSION MGT', 'Exten. Mgt. - Admin');
        ReplacePermissionSet('RETENTION POL. SETUP', 'Retention Pol. Admin');
    end;

    local procedure ReplacePermissionSet(OldPermissionSet: Code[20]; NewPermissionSet: Code[20])
    var
        OldAccessControl, NewAccessControl, CurrentAccessControl : Record "Access Control";
        OldUserGroupPermissionSet, NewUserGroupPermissionSet, CurrentUserGroupPermissionSet : Record "User Group Permission Set";
        OldUserGroupAccessControl, NewUserGroupAccessControl, CurrentUserGroupAccessControl : Record "User Group Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::System);
        AggregatePermissionSet.SetRange("Role ID", NewPermissionSet);
        if not AggregatePermissionSet.FindFirst() then begin
            Session.LogMessage('0000FGT',
                StrSubstNo(NewPermissionSetNotFoundTxt, OldPermissionSet, NewPermissionSet),
                Verbosity::Normal,
                DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher,
                'Category',
                TelemetryCategoryTxt);
            exit;
        end;

        // User Groups need to be updated first as they result in modifications to Access Control
        // Change the User Group Permission Set entries that point to the old permission set to point to the new one
        OldUserGroupPermissionSet.SetRange("Role ID", OldPermissionSet);
        if OldUserGroupPermissionSet.FindSet() then
            repeat
                CurrentUserGroupPermissionSet.Get(OldUserGroupPermissionSet.RecordId());

                if NewUserGroupPermissionSet.Get(OldUserGroupPermissionSet."User Group Code", NewPermissionSet, AggregatePermissionSet.Scope, AggregatePermissionSet."App ID") then
                    CurrentUserGroupPermissionSet.Delete()
                else
                    CurrentUserGroupPermissionSet.Rename(OldUserGroupPermissionSet."User Group Code", NewPermissionSet, AggregatePermissionSet.Scope, AggregatePermissionSet."App ID");
            until OldUserGroupPermissionSet.Next() = 0;

        // User Group Access Control needs to be updated explicitly in v25+
        OldUserGroupAccessControl.SetRange("Role ID", OldPermissionSet);
        if OldUserGroupAccessControl.FindSet() then
            repeat
                CurrentUserGroupAccessControl.Get(OldUserGroupAccessControl.RecordId());

                if NewUserGroupAccessControl.Get(OldUserGroupAccessControl."User Group Code", OldUserGroupAccessControl."User Security ID", NewPermissionSet, OldUserGroupAccessControl."Company Name", AggregatePermissionSet.Scope, AggregatePermissionSet."App ID") then
                    CurrentUserGroupAccessControl.Delete()
                else
                    CurrentUserGroupAccessControl.Rename(OldUserGroupAccessControl."User Group Code", OldUserGroupAccessControl."User Security ID", NewPermissionSet, OldUserGroupAccessControl."Company Name", AggregatePermissionSet.Scope, AggregatePermissionSet."App ID");
            until OldUserGroupAccessControl.Next() = 0;

        // Change the Access Control entries that point to the old permission set to point to the new one
        OldAccessControl.SetRange("Role ID", OldPermissionSet);
        if OldAccessControl.FindSet() then
            repeat
                CurrentAccessControl.Get(OldAccessControl.RecordId());

                if NewAccessControl.Get(OldAccessControl."User Security ID", NewPermissionSet, OldAccessControl."Company Name", AggregatePermissionSet.Scope, AggregatePermissionSet."App ID") then
                    CurrentAccessControl.Delete()
                else
                    CurrentAccessControl.Rename(OldAccessControl."User Security ID", NewPermissionSet, OldAccessControl."Company Name", AggregatePermissionSet.Scope, AggregatePermissionSet."App ID");
            until OldAccessControl.Next() = 0;
    end;

    var
        NewPermissionSetNotFoundTxt: Label 'Skipping the upgrade of %1 to %2, as we could not find the permission set %2.', Locked = true;
        TelemetryCategoryTxt: Label 'AL SaaS upgrade', Locked = true;
}
