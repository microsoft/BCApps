// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Upgrade;

codeunit 104060 "Upgrade App ID Permissions"
{
    Subtype = Upgrade;

    var
        RenamingFailedTxt: Label 'Failed to rename record of type %1. Error: %2', Locked = true;
        DeleteUserGroupPermissionSetTxt: Label 'Deleted User Group Permission Set record because it has empty App ID. Code: %1; Role ID: %2; Scope: %3', Locked = true;
        DeleteAccessControlTxt: Label 'Deleted Access Control record because it has empty App ID. User Security ID: %1; Role ID: %2; Company Name: %3; Scope: %4', Locked = true;
        TelemetryCategoryTxt: Label 'AL SaaS Upgrade', Locked = true;

    trigger OnUpgradePerDatabase()
    begin
        RunUpgrade();
    end;

    internal procedure RunUpgrade()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        ServerSettings: Codeunit "Server Setting";
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade('') then
            exit;

        if not ServerSettings.GetUsePermissionSetsFromExtensions() then
            exit;

        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetUserGroupsSetAppIdUpgradeTag()) then
            exit;

        SetAppIdOnAccessControl();
        SetAppIdOnUserGroupPermissionSet();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetUserGroupsSetAppIdUpgradeTag());
    end;

    local procedure SetAppIdOnAccessControl()
    var
        AccessControl: Record "Access Control";
        AccessControlWithoutAppId: Record "Access Control";
        AccessControlWithAppId: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
        NullGuid: Guid;
    begin
        AccessControl.SetRange(Scope, AccessControl.Scope::System);
        AccessControl.SetFilter("Role ID", '<>%1&<>%2', 'SECURITY', 'SUPER');
        AccessControl.SetRange("App ID", NullGuid);

        if AccessControl.FindSet() then
            repeat
                AggregatePermissionSet.SetRange("Role Id", AccessControl."Role ID");
                if AggregatePermissionSet.FindFirst() then begin
                    // Get the current record to avoid side effects from FindSet()
                    AccessControlWithoutAppId.Get(AccessControl."User Security ID", AccessControl."Role ID", AccessControl."Company Name", AccessControl.Scope, AccessControl."App ID");

                    if AccessControlWithAppId.Get(AccessControlWithoutAppId."User Security ID", AccessControlWithoutAppId."Role ID", AccessControlWithoutAppId."Company Name", AccessControlWithoutAppId.Scope, AggregatePermissionSet."App ID") then begin
                        // In case a record with App ID already exists, delete the one without App ID
                        if AccessControlWithoutAppId.Delete() then
                            Session.LogMessage('0000F0C', StrSubstNo(DeleteAccessControlTxt, AccessControlWithoutAppId."User Security ID", AccessControlWithoutAppId."Role ID", AccessControlWithoutAppId."Company Name", AccessControlWithoutAppId.Scope), Verbosity::Normal, DataClassification::EndUserPseudonymousIdentifiers, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
                    end else // Safely add the App ID
                        if not AccessControlWithoutAppId.Rename(AccessControlWithoutAppId."User Security ID", AccessControlWithoutAppId."Role ID", AccessControlWithoutAppId."Company Name", AccessControlWithoutAppId.Scope, AggregatePermissionSet."App ID") then
                            Session.LogMessage('0000F0B', StrSubstNo(RenamingFailedTxt, AccessControl.TableName(), GetLastErrorText()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
                end;
            until AccessControl.Next() = 0;

    end;

    local procedure SetAppIdOnUserGroupPermissionSet()
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
        UserGroupPermissionSetWithoutAppId: Record "User Group Permission Set";
        UserGroupPermissionSetWithAppId: Record "User Group Permission Set";
        UserGroupAccessControl: Record "User Group Access Control";
        UserGroupAccessControlWithoutAppId: Record "User Group Access Control";
        UserGroupAccessControlWithAppId: Record "User Group Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
        NullGuid: Guid;
    begin
        UserGroupPermissionSet.SetRange(Scope, UserGroupPermissionSet.Scope::System);
        UserGroupPermissionSet.SetFilter("Role ID", '<>%1&<>%2', 'SECURITY', 'SUPER');
        UserGroupPermissionSet.SetRange("App ID", NullGuid);

        if UserGroupPermissionSet.FindSet() then
            repeat
                AggregatePermissionSet.SetRange("Role Id", UserGroupPermissionSet."Role ID");
                if AggregatePermissionSet.FindFirst() then begin
                    // Get the current record to avoid side effects from FindSet() 
                    UserGroupPermissionSetWithoutAppId.Get(UserGroupPermissionSet."User Group Code", UserGroupPermissionSet."Role ID", UserGroupPermissionSet.Scope, UserGroupPermissionSet."App ID");

                    if UserGroupPermissionSetWithAppId.Get(UserGroupPermissionSetWithoutAppId."User Group Code", UserGroupPermissionSetWithoutAppId."Role ID", UserGroupPermissionSetWithoutAppId.Scope, AggregatePermissionSet."App ID") then begin
                        // In case a record with App ID already exists, delete the one without App ID
                        if UserGroupPermissionSetWithoutAppId.Delete() then
                            Session.LogMessage('0000F0E', StrSubstNo(DeleteUserGroupPermissionSetTxt, UserGroupPermissionSetWithoutAppId."User Group Code", UserGroupPermissionSetWithoutAppId."Role ID", UserGroupPermissionSetWithoutAppId.Scope), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
                    end else // Safely add the App ID
                        if not UserGroupPermissionSetWithoutAppId.Rename(UserGroupPermissionSetWithoutAppId."User Group Code", UserGroupPermissionSetWithoutAppId."Role ID", UserGroupPermissionSetWithoutAppId.Scope, AggregatePermissionSet."App ID") then
                            Session.LogMessage('0000F0D', StrSubstNo(RenamingFailedTxt, UserGroupPermissionSet.TableName(), GetLastErrorText()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
                end;
            until UserGroupPermissionSet.Next() = 0;

        // User Group Access Control needs to be updated explicitly in v25+
        UserGroupAccessControl.SetRange(Scope, UserGroupAccessControl.Scope::System);
        UserGroupAccessControl.SetFilter("Role ID", '<>%1&<>%2', 'SECURITY', 'SUPER');
        UserGroupAccessControl.SetRange("App ID", NullGuid);

        if UserGroupAccessControl.FindSet() then
            repeat
                AggregatePermissionSet.SetRange("Role Id", UserGroupAccessControl."Role ID");
                if AggregatePermissionSet.FindFirst() then begin
                    UserGroupAccessControlWithoutAppId.GetBySystemId(UserGroupAccessControl.SystemId);

                    if UserGroupAccessControlWithAppId.Get(UserGroupAccessControlWithoutAppId."User Group Code", UserGroupAccessControlWithoutAppId."User Security ID", UserGroupAccessControlWithoutAppId."Role ID", UserGroupAccessControlWithoutAppId."Company Name", UserGroupAccessControlWithoutAppId.Scope, AggregatePermissionSet."App ID") then
                        UserGroupAccessControlWithoutAppId.Delete()
                    else
                        UserGroupAccessControlWithoutAppId.Rename(UserGroupAccessControlWithoutAppId."User Group Code", UserGroupAccessControlWithoutAppId."User Security ID", UserGroupAccessControlWithoutAppId."Role ID", UserGroupAccessControlWithoutAppId."Company Name", UserGroupAccessControlWithoutAppId.Scope, AggregatePermissionSet."App ID");
                end;
            until UserGroupAccessControl.Next() = 0;
    end;

}