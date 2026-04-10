// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using System.Azure.Identity;
using System.Environment;
using System.Environment.Configuration;
using System.Reflection;
using System.Security.AccessControl;
using System.Upgrade;

codeunit 104030 "Upgrade Plan Permissions"
{
    Subtype = Upgrade;
    Permissions = TableData "User Group Plan" = rimd;

    var
        AutomationTok: Label 'D365 AUTOMATION', MaxLength = 20, Locked = true;
        BackupRestoreTok: Label 'D365 BACKUP/RESTORE', Locked = true;
        BackupRestoreDescriptionTxt: Label 'Backup or restore database', Comment = 'Maximum length is 30';
        BasicTok: Label 'D365 BASIC', Locked = true;
        BasicISVTok: Label 'D365 BASIC ISV', Locked = true;
        BusFullTok: Label 'D365 BUS FULL ACCESS', Locked = true;
        PremiumBusFullTok: Label 'D365 BUS PREMIUM', Locked = true;
        FullTok: Label 'D365 FULL ACCESS', Locked = true;
        OnPremBasicTok: Label 'BASIC', Locked = true;
        ReadTok: Label 'D365 READ', Locked = true;
        SecurityTok: Label 'SECURITY', Locked = true;
        TeamMemberTok: Label 'D365 TEAM MEMBER', Locked = true;
        EditInExcelTok: Label 'Edit in Excel - View', Locked = true, MaxLength = 20;
        ExcelExportActionTok: Label 'EXCEL EXPORT ACTION', Locked = true, MaxLength = 20;
        ExcelExportActionDescriptionTxt: Label 'D365 Excel Export Action', Locked = true, MaxLength = 30;
        AutomateExecPermissionSetTok: Label 'Automate - Exec', Locked = true, MaxLength = 20;
        AutomateActionUserGroupTok: Label 'AUTOMATE ACTION', Locked = true;
        AutomateActionUserGroupDescriptionTxt: Label 'Allow action Automate', Locked = true, MaxLength = 30;
        D365MonitorFieldsTxt: Label 'D365 Monitor Fields', Locked = true;
        SecurityUserGroupTok: Label 'D365 SECURITY', Locked = true;
        TeamsUsersTok: Label 'TEAMS USERS', Locked = true;
        TeamsUsersDescriptionTxt: Label 'Microsoft Teams internal users', Locked = true, MaxLength = 30;
        EmployeeTok: Label 'EMPLOYEE', Locked = true;
        LoginTok: Label 'LOGIN', Locked = true;
        CannotCreatePermissionSetLbl: Label 'Permission Set %1 is missing from this environment and cannot be created.', Locked = true;
        CouldNotInsertAccessControlTelemetryErr: Label 'Could not insert Access Control with App ID %1', Locked = true;
        BaseApplicationAppIdTok: Label '{437dbf0e-84ff-417a-965d-ed2bb9650972}', Locked = true;
        SystemApplicationAppIdTok: Label '{63ca2fa4-4f03-4f2b-a480-172fef340d3f}', Locked = true;
        EmptyAppId: Guid;


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

        SetBackupRestorePermissions();
        SetExcelExportActionPermissions();
        SetAutomateActionPermissions();
        SetAutomateAccessControl();
        RemoveExtensionManagementFromPlan();
        RemoveExtensionManagementFromUsers();
        SetMonitorSensitiveFieldPermissions();
        AddFeatureDataUpdatePermissions();
        CreateMicrosoft365Permissions();
        CreateD365EssentialAttachPermissions();
        CreateBCAdminPermissions();
    end;

    local procedure AddFeatureDataUpdatePermissions()
    var
        Permission: Record Permission;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAddFeatureDataUpdatePermissionsUpgradeTag()) then
            exit;

        InsertPermission(AutomationTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 1, 1, 1, 0);
        InsertPermission(BasicTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 1, 1, 1, 0);
        InsertPermission(BasicISVTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 1, 1, 1, 0);
        InsertPermission(BusFullTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 1, 1, 1, 0);
        InsertPermission(PremiumBusFullTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 1, 1, 1, 0);
        InsertPermission(FullTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 1, 1, 1, 0);
        InsertPermission(ReadTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 0, 0, 0, 0);
        InsertPermission(TeamMemberTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 0, 1, 0, 0);
        InsertPermission(OnPremBasicTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 1, 1, 1, 0);
        InsertPermission(SecurityTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 1, 1, 1, 0);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetAddFeatureDataUpdatePermissionsUpgradeTag());
    end;

    local procedure RemoveExtensionManagementFromPlan()
    var
        UserGroupPlan: Record "User Group Plan";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetRemoveExtensionManagementFromPlanUpgradeTag()) then
            exit;

        UserGroupPlan.SetRange("User Group Code", 'D365 EXTENSION MGT');
        UserGroupPlan.DeleteAll();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetRemoveExtensionManagementFromPlanUpgradeTag());
    end;

    local procedure RemoveExtensionManagementFromUsers()
    var
        AccessControl: Record "Access Control";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetRemoveExtensionManagementFromUsersUpgradeTag()) then
            exit;

        AccessControl.SetRange("Role ID", 'D365 EXTENSION MGT');
        AccessControl.DeleteAll();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetRemoveExtensionManagementFromUsersUpgradeTag());
    end;

    local procedure SetBackupRestorePermissions()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAddBackupRestorePermissionSetUpgradeTag()) then
            exit;

        if RunUserGroupUpgrade() then begin
            AddBackupRestorePermissionSet();
            AddBackupRestoreUserGroup();
            AddBackupRestorePermissionSetToGroup();
            AddBackupRestoreUserGroupToDelegatedAdminPlan();
            AddBackupRestoreUserGroupToNavInternalAdmin();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetAddBackupRestorePermissionSetUpgradeTag());
    end;

    local procedure AddBackupRestorePermissionSet(): Boolean
    var
        PermissionSet: Record "Permission Set";
        Permission: Record Permission;
    begin
        if TryInsertPermissionSet(CopyStr(BackupRestoreTok, 1, MaxStrLen(PermissionSet."Role ID")),
            CopyStr(BackupRestoreDescriptionTxt, 1, MaxStrLen(PermissionSet.Name))) then begin
            InsertPermission(CopyStr(BackupRestoreTok, 1, MaxStrLen(Permission."Role ID")), 10, 5410, 1, 1, 1, 1, 1);
            InsertPermission(CopyStr(BackupRestoreTok, 1, MaxStrLen(Permission."Role ID")), 10, 5420, 1, 1, 1, 1, 1);
            exit(true);
        end;
    end;

    local procedure AddBackupRestoreUserGroup();
    var
        UserGroup: Record "User Group";
    begin
        InsertUserGroup(CopyStr(BackupRestoreTok, 1, MaxStrLen(UserGroup.Code)),
            CopyStr(BackupRestoreDescriptionTxt, 1, MaxStrLen(UserGroup.Name)), false);
    end;

    local procedure AddBackupRestorePermissionSetToGroup();
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        AddPermissionSetToUserGroup(CopyStr(BackupRestoreTok, 1, MaxStrLen(UserGroupPermissionSet."Role ID")),
            CopyStr(BackupRestoreTok, 1, MaxStrLen(UserGroupPermissionSet."User Group Code")));
    end;

    local procedure AddBackupRestoreUserGroupToDelegatedAdminPlan();
    var
        UserGroupPlan: Record "User Group Plan";
        PlanIds: Codeunit "Plan Ids";
    begin
        AddUserGroupToPlan(CopyStr(BackupRestoreTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetDelegatedAdminPlanId());
    end;

    local procedure AddBackupRestoreUserGroupToNavInternalAdmin();
    var
        UserGroupPlan: Record "User Group Plan";
        PlanIds: Codeunit "Plan Ids";
    begin
        AddUserGroupToPlan(CopyStr(BackupRestoreTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetGlobalAdminPlanId());
    end;

    local procedure TryInsertPermissionSet(PermissionSetID: Code[20]; PermissionSetName: Text[30]): Boolean
    var
        PermissionSet: Record "Permission Set";
        EnvironmentInformation: Codeunit "Environment Information";
        ServerSetting: Codeunit "Server Setting";
        TelemetryCustomDimensions: Dictionary of [Text, Text];
    begin
        if ServerSetting.GetUsePermissionSetsFromExtensions() then
            exit(false);

        if PermissionSet.Get(PermissionSetID) then
            exit(false);

        if EnvironmentInformation.IsSaaS() then begin
            TelemetryCustomDimensions.Add(PermissionSet.FieldCaption("Role ID"), PermissionSetID);
            TelemetryCustomDimensions.Add(PermissionSet.FieldCaption(Name), PermissionSetName);
            Session.LogMessage('0000DW1', StrSubstNo(CannotCreatePermissionSetLbl, PermissionSetID), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryCustomDimensions);
            exit(false);
        end;

        PermissionSet."Role ID" := PermissionSetID;
        PermissionSet.Name := PermissionSetName;
        PermissionSet.Insert();
        exit(true);
    end;

    local procedure InsertPermission(PermissionSetID: Code[20]; ObjType: Option; ObjId: Integer; ReadPerm: Option; InsertPerm: Option; ModifyPerm: Option; DeletePerm: Option; ExecutePerm: Option)
    var
        Permission: Record Permission;
        PermissionSet: Record "Permission Set";
        EnvironmentInformation: Codeunit "Environment Information";
        ServerSetting: Codeunit "Server Setting";
    begin
        if not PermissionSet.Get(PermissionSetID) then
            exit;
        if Permission.Get(PermissionSetID, ObjType, ObjId) then
            exit;

        if EnvironmentInformation.IsSaaS() then
            exit;

        if ServerSetting.GetUsePermissionSetsFromExtensions() then
            exit;

        Permission."Role ID" := PermissionSetID;
        Permission."Object Type" := ObjType;
        Permission."Object ID" := ObjId;
        Permission."Read Permission" := ReadPerm;
        Permission."Insert Permission" := InsertPerm;
        Permission."Modify Permission" := ModifyPerm;
        Permission."Delete Permission" := DeletePerm;
        Permission."Execute Permission" := ExecutePerm;
        Permission.Insert();
    end;

    local procedure InsertUserGroup(UserGroupCode: Code[20]; UserGroupName: Text[50]; AssignToAllNewUsers: Boolean)
    var
        UserGroup: Record "User Group";
    begin
        if UserGroup.Get(UserGroupCode) then
            exit;

        UserGroup.Code := UserGroupCode;
        UserGroup.Name := UserGroupName;
        UserGroup."Assign to All New Users" := AssignToAllNewUsers;
        UserGroup.Insert();
    end;

    local procedure AddPermissionSetToUserGroup(PermissionSetId: Code[20]; UserGroupCode: Code[20])
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AggregatePermissionSet.SetRange("Role ID", PermissionSetId);
        if not AggregatePermissionSet.FindFirst() then
            exit;
        if UserGroupPermissionSet.Get(UserGroupCode, PermissionSetId, UserGroupPermissionSet.Scope::System, AggregatePermissionSet."App Id") then
            exit;

        UserGroupPermissionSet."Role ID" := PermissionSetId;
        UserGroupPermissionSet."User Group Code" := UserGroupCode;
        UserGroupPermissionSet.Scope := UserGroupPermissionSet.Scope::System;
        UserGroupPermissionSet."App ID" := AggregatePermissionSet."App Id";
        UserGroupPermissionSet.Insert();

        // User Group Access Control needs to be updated explicitly in v25+
        AddUserGroupPermissionSet(UserGroupCode, PermissionSetId, AggregatePermissionSet."App Id", UserGroupPermissionSet.Scope::System);
    end;

    local procedure AddPermissionSetToPlan(PlanId: Guid; RoleId: Code[20]; AppId: Guid)
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PlanConfiguration: Codeunit "Plan Configuration";
        Scope: Option System,Tenant;
    begin
        if AggregatePermissionSet.Get(Scope::System, AppId, RoleId) then
            PlanConfiguration.AddDefaultPermissionSetToPlan(PlanId, RoleId, AppId, Scope::System);
    end;

    local procedure AddUserGroupToPlan(UserGroupCode: Code[20]; PlanId: Guid)
    var
        UserGroupPlan: Record "User Group Plan";
    begin
        if UserGroupPlan.Get(PlanId, UserGroupCode) then
            exit;

        UserGroupPlan."Plan ID" := PlanId;
        UserGroupPlan."User Group Code" := UserGroupCode;
        UserGroupPlan.Insert();
    end;

    local procedure AddUserGroupToUsers(UserGroupCode: Code[20])
    var
        UserGroupMember: Record "User Group Member";
    begin
        UserGroupMember.SetCurrentKey("User Security ID", "Company Name");
        UserGroupMember.SetFilter("User Group Code", '<>%1', UserGroupCode);

        if UserGroupMember.FindSet() then
            repeat
                AddUserToUserGroupForCompany(UserGroupMember."User Security ID", UserGroupCode, UserGroupMember."Company Name");

                if UserGroupMember."Company Name" = '' then
                    UserGroupMember.SetFilter("User Security ID", '<>%1', UserGroupMember."User Security ID");
            until UserGroupMember.Next() = 0;
    end;

    local procedure AddUserToUserGroupForCompany(UserSID: Guid; UserGroupCode: Code[20]; CompanyName: Text[30])
    var
        UserGroupMember: Record "User Group Member";
    begin
        if UserGroupMember.Get(UserGroupCode, UserSID, CompanyName) then
            exit;

        UserGroupMember."User Security ID" := UserSID;
        UserGroupMember."User Group Code" := UserGroupCode;
        UserGroupMember."Company Name" := CompanyName;
        UserGroupMember.Insert(true);

        // The trigger code is removed in v25+, update manually if needed
        AddUserGroupMember(UserGroupCode, UserSID, CompanyName);
    end;

    local procedure SetExcelExportActionPermissions()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetExcelExportActionPermissionSetUpgradeTag()) then
            exit;

        if RunUserGroupUpgrade() then begin
            AddExcelExportActionPermissionSet();
            AddExcelExportActionUserGroup();
            AddExcelExportActionPermissionSetToGroup();
            AddExcelExportActionUserGroupToExistingPlans();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetExcelExportActionPermissionSetUpgradeTag());
    end;

    local procedure AddExcelExportActionPermissionSet(): Boolean
    begin
        if TryInsertPermissionSet(EditInExcelTok, ExcelExportActionDescriptionTxt) then begin
            InsertPermission(EditInExcelTok, 10, 6110, 0, 0, 0, 0, 1);
            exit(true);
        end;
    end;

    local procedure AddExcelExportActionUserGroup();
    begin
        InsertUserGroup(ExcelExportActionTok, ExcelExportActionDescriptionTxt, true);
    end;

    local procedure AddExcelExportActionPermissionSetToGroup();
    begin
        AddPermissionSetToUserGroup(EditInExcelTok, ExcelExportActionTok);
    end;

    local procedure AddExcelExportActionUserGroupToExistingPlans();
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetBasicPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetTeamMemberPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetEssentialPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetPremiumPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetViralSignupPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetExternalAccountantPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetDelegatedAdminPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetGlobalAdminPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetTeamMemberISVPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetEssentialISVPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetPremiumISVPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetDeviceISVPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetDevicePlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetBasicFinancialsISVPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetAccountantHubPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetHelpDeskPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetInfrastructurePlanId());
    end;

    local procedure SetAutomateActionPermissions()
    var
        UserGroup: Record "User Group";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeUserGroups: Codeunit "Upgrade User Groups";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAutomateActionPermissionSetUpgradeTag()) then
            exit;

        if (not UserGroup.IsEmpty()) and (not UpgradeUserGroups.IsUserGroupObsoleteStateRemoved()) then
            if EnvironmentInformation.IsSaaS() then begin
                AddAutomateActionUserGroup();
                AddAutomateActionPermissionSetToGroup();
                AddAutomateActionUserGroupToExistingPlans();
                AddUserGroupToUsers(AutomateActionUserGroupTok);
            end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetAutomateActionPermissionSetUpgradeTag());
    end;

    local procedure SetAutomateAccessControl()
    var
        UserGroupMember: Record "User Group Member";
        AccessControl: Record "Access Control";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAutomateActionAccessControlUpgradeTag()) then
            exit;

        if EnvironmentInformation.IsSaaS() then begin
            UserGroupMember.SetRange("User Group Code", AutomateActionUserGroupTok);

            if UserGroupMember.FindSet() then
                repeat
                    AccessControl.SetRange("Role ID", AutomateExecPermissionSetTok);
                    AccessControl.SetRange("User Security ID", UserGroupMember."User Security ID");
                    AccessControl.SetRange("Company Name", UserGroupMember."Company Name");

                    if AccessControl.IsEmpty() then begin
                        // Bug 460562: Automate user group was inserted without trigger, so the related access control records were never created
                        UserGroupMember.Delete();
                        AddUserToUserGroupForCompany(UserGroupMember."User Security ID", UserGroupMember."User Group Code", UserGroupMember."Company Name");
                    end;
                until UserGroupMember.Next() = 0;
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetAutomateActionAccessControlUpgradeTag());
    end;

    local procedure AddAutomateActionUserGroup();
    begin
        InsertUserGroup(AutomateActionUserGroupTok, AutomateActionUserGroupDescriptionTxt, true);
    end;

    local procedure AddAutomateActionPermissionSetToGroup();
    begin
        AddPermissionSetToUserGroup(AutomateExecPermissionSetTok, AutomateActionUserGroupTok);
    end;

    local procedure AddAutomateActionUserGroupToExistingPlans();
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetBasicPlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetTeamMemberPlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetEssentialPlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetPremiumPlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetViralSignupPlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetExternalAccountantPlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetDelegatedAdminPlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetGlobalAdminPlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetTeamMemberISVPlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetEssentialISVPlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetPremiumISVPlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetDeviceISVPlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetDevicePlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetBasicFinancialsISVPlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetAccountantHubPlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetHelpDeskPlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetInfrastructurePlanId());
        AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetPremiumPartnerSandboxPlanId());
    end;

    local procedure SetMonitorSensitiveFieldPermissions()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetMonitorSensitiveFieldPermissionUpgradeTag()) then
            exit;

        AddD365MonitorFieldsToSecurityGroup();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetMonitorSensitiveFieldPermissionUpgradeTag());
    end;

    local procedure AddD365MonitorFieldsToSecurityGroup()
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        AddPermissionSetToUserGroup(CopyStr(D365MonitorFieldsTxt, 1, MaxStrLen(UserGroupPermissionSet."Role ID")),
           CopyStr(SecurityUserGroupTok, 1, MaxStrLen(UserGroupPermissionSet."User Group Code")));
    end;

    local procedure CreateMicrosoft365Permissions()
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        PlanIds: Codeunit "Plan Ids";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetTeamsUsersUserGroupUpgradeTag()) then
            exit;

        if RunUserGroupUpgrade() then begin
            // Insert TEAMS USERS user group and add it to the plan
            InsertUserGroup(TeamsUsersTok, TeamsUsersDescriptionTxt, false);
            UpdateUserGroupProfile(TeamsUsersTok, Page::"Blank Role Center");
            AddUserGroupToPlan(TeamsUsersTok, PlanIds.GetMicrosoft365PlanId());

            // Add LOGIN permission sets to TEAMS USERS user group
            AddPermissionSetToUserGroup(CopyStr(LoginTok, 1, MaxStrLen(UserGroupPermissionSet."Role ID")),
                CopyStr(TeamsUsersTok, 1, MaxStrLen(UserGroupPermissionSet."User Group Code")));
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetTeamsUsersUserGroupUpgradeTag());
    end;

    local procedure CreateD365EssentialAttachPermissions()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        PlanIds: Codeunit "Plan Ids";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetEssentialAttachUserGroupUpgradeTag()) then
            exit;

        if RunUserGroupUpgrade() then begin
            AddPermissionSetToPlan(PlanIDs.GetEssentialAttachPlanId(), 'AUTOMATE - EXEC', SystemApplicationAppIdTok);
            AddPermissionSetToPlan(PlanIDs.GetEssentialAttachPlanId(), 'D365 BUS FULL ACCESS', BaseApplicationAppIdTok);
            AddPermissionSetToPlan(PlanIDs.GetEssentialAttachPlanId(), 'EXCEL EXPORT ACTION', SystemApplicationAppIdTok);
            AddPermissionSetToPlan(PlanIDs.GetEssentialAttachPlanId(), 'LOCAL', BaseApplicationAppIdTok);
            AddPermissionSetToPlan(PlanIDs.GetEssentialAttachPlanId(), 'LOGIN', SystemApplicationAppIdTok);
        end else begin
            AddUserGroupToPlan(AutomateActionUserGroupTok, PlanIds.GetEssentialAttachPlanId());
            AddUserGroupToPlan(BusFullTok, PlanIds.GetEssentialAttachPlanId());
            AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetEssentialAttachPlanId());
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetEssentialAttachUserGroupUpgradeTag());
    end;

    local procedure CreateBCAdminPermissions()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        PlanIds: Codeunit "Plan Ids";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetBCUserGroupUpgradeTag()) then
            exit;

        AddPermissionSetToPlan(PlanIDs.GetDelegatedBCAdminPlanId(), 'AUTOMATE - EXEC', SystemApplicationAppIdTok);
        AddPermissionSetToPlan(PlanIDs.GetDelegatedBCAdminPlanId(), 'D365 BACKUP/RESTORE', SystemApplicationAppIdTok);
        AddPermissionSetToPlan(PlanIDs.GetDelegatedBCAdminPlanId(), 'D365 FULL ACCESS', BaseApplicationAppIdTok);
        AddPermissionSetToPlan(PlanIDs.GetDelegatedBCAdminPlanId(), 'D365 RAPIDSTART', BaseApplicationAppIdTok);
        AddPermissionSetToPlan(PlanIDs.GetDelegatedBCAdminPlanId(), 'EXCEL EXPORT ACTION', SystemApplicationAppIdTok);
        AddPermissionSetToPlan(PlanIDs.GetDelegatedBCAdminPlanId(), 'LOCAL', BaseApplicationAppIdTok);
        AddPermissionSetToPlan(PlanIDs.GetDelegatedBCAdminPlanId(), 'LOGIN', SystemApplicationAppIdTok);
        AddPermissionSetToPlan(PlanIDs.GetDelegatedBCAdminPlanId(), 'TROUBLESHOOT TOOLS', SystemApplicationAppIdTok);

        AddPermissionSetToPlan(PlanIDs.GetBCAdminPlanId(), 'AUTOMATE - EXEC', SystemApplicationAppIdTok);
        AddPermissionSetToPlan(PlanIDs.GetBCAdminPlanId(), 'D365 BACKUP/RESTORE', SystemApplicationAppIdTok);
        AddPermissionSetToPlan(PlanIDs.GetBCAdminPlanId(), 'D365 READ', BaseApplicationAppIdTok);
        AddPermissionSetToPlan(PlanIDs.GetBCAdminPlanId(), 'EXCEL EXPORT ACTION', SystemApplicationAppIdTok);
        AddPermissionSetToPlan(PlanIDs.GetBCAdminPlanId(), 'LOCAL', BaseApplicationAppIdTok);
        AddPermissionSetToPlan(PlanIDs.GetBCAdminPlanId(), 'LOGIN', SystemApplicationAppIdTok);
        AddPermissionSetToPlan(PlanIDs.GetBCAdminPlanId(), 'SECURITY', EmptyAppId);
        AddPermissionSetToPlan(PlanIDs.GetBCAdminPlanId(), 'TROUBLESHOOT TOOLS', SystemApplicationAppIdTok);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetBCUserGroupUpgradeTag());
    end;

    local procedure UpdateUserGroupProfile(UserGroupCode: Code[20]; RoleCenterId: Integer)
    var
        AllProfile: Record "All Profile";
        UserGroup: Record "User Group";
    begin
        // Both Teams Users and Blank profile uses Blank Role Center. So we need to get the profile by Profile ID explicitly. Rest we can find by role center id.
        if (UserGroupCode = TeamsUsersTok) then begin
            AllProfile.SetRange("Profile ID", EmployeeTok);
            AllProfile.FindFirst();
        end else begin
            AllProfile.SetRange("Role Center ID", RoleCenterId);
            AllProfile.FindFirst();
        end;

        UserGroup.Get(UserGroupCode);
        UserGroup."Default Profile ID" := AllProfile."Profile ID";
        UserGroup."Default Profile App ID" := AllProfile."App ID";
        UserGroup."Default Profile Scope" := AllProfile.Scope;
        UserGroup.Modify();
    end;

    internal procedure ReplaceUserGroupPermissionSets(UserGroupCode: Code[20]; NewComposedPermissionSet: Code[20]; Scope: Option System,Tenant)
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        UserGroupPermissionSet: Record "User Group Permission Set";
        UserGroupAccessControl: Record "User Group Access Control";
    begin
        AggregatePermissionSet.SetRange(Scope, Scope);
        AggregatePermissionSet.SetRange("Role ID", NewComposedPermissionSet);
        if not AggregatePermissionSet.FindFirst() then
            exit;

        // Leave LOGIN and LOCAL assigned to users, but disconnect them from user groups
        UserGroupAccessControl.SetRange("User Group Code", UserGroupCode);
        UserGroupAccessControl.SetRange(Scope, Scope::System);
        UserGroupAccessControl.SetFilter("Role ID", '%1|%2', 'LOGIN', 'LOCAL');
        UserGroupAccessControl.DeleteAll();

        UserGroupPermissionSet.SetRange("User Group Code", UserGroupCode);
        // In v25+ need to update User Group Access Control manually
        if UserGroupPermissionSet.FindSet() then
            repeat
                RemoveUserGroupPermissionSet(UserGroupCode, UserGroupPermissionSet."Role ID", UserGroupPermissionSet."App ID", UserGroupPermissionSet.Scope);
            until UserGroupPermissionSet.Next() = 0;

        UserGroupPermissionSet.DeleteAll();

        UserGroupPermissionSet."User Group Code" := UserGroupCode;
        UserGroupPermissionSet."Role ID" := NewComposedPermissionSet;
        UserGroupPermissionSet."App ID" := AggregatePermissionSet."App ID";
        UserGroupPermissionSet.Scope := Scope;
        UserGroupPermissionSet.Insert();

        // In v25+ need to update User Group Access Control manually
        AddUserGroupPermissionSet(UserGroupCode, NewComposedPermissionSet, AggregatePermissionSet."App ID", Scope);
    end;

    internal procedure AddUserGroupMember(UserGroupCode: Code[20]; UserSecurityID: Guid; SelectedCompany: Text[30])
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        UserGroupPermissionSet.SetRange("User Group Code", UserGroupCode);
        if UserGroupPermissionSet.FindSet() then
            repeat
                AddPermissionSetToUser(
                  UserGroupCode, UserSecurityID, SelectedCompany, UserGroupPermissionSet."Role ID", UserGroupPermissionSet."App ID",
                  UserGroupPermissionSet.Scope);
            until UserGroupPermissionSet.Next() = 0;
    end;

    local procedure AddUserGroupPermissionSet(UserGroupCode: Code[20]; RoleID: Code[20]; AppID: Guid; ItemScope: Integer)
    var
        UserGroupMember: Record "User Group Member";
    begin
        UserGroupMember.SetRange("User Group Code", UserGroupCode);
        if UserGroupMember.FindSet() then
            repeat
                AddPermissionSetToUser(
                  UserGroupCode, UserGroupMember."User Security ID", UserGroupMember."Company Name", RoleID, AppID, ItemScope);
            until UserGroupMember.Next() = 0;
    end;

    local procedure RemoveUserGroupPermissionSet(UserGroupCode: Code[20]; RoleID: Code[20]; AppID: Guid; ItemScope: Integer)
    var
        UserGroupMember: Record "User Group Member";
    begin
        UserGroupMember.SetRange("User Group Code", UserGroupCode);
        if UserGroupMember.FindSet() then
            repeat
                RemovePermissionSetFromUser(
                  UserGroupCode, UserGroupMember."User Security ID", UserGroupMember."Company Name", RoleID, AppID, ItemScope);
            until UserGroupMember.Next() = 0;
    end;

    local procedure RunUserGroupUpgrade(): boolean
    var
        UserGroup: Record "User Group";
        UpgradeUserGroups: Codeunit "Upgrade User Groups";
    begin
        if UserGroup.IsEmpty() then
            exit(false);

        if UpgradeUserGroups.IsUserGroupObsoleteStateRemoved() then
            exit(false);

        exit(true);
    end;

    local procedure AddPermissionSetToUser(UserGroupCode: Code[20]; UserSecurityID: Guid; SelectedCompany: Text[30]; RoleID: Code[20]; AppID: Guid; ItemScope: Integer)
    var
        UserGroupAccessControl: Record "User Group Access Control";
        AccessControl: Record "Access Control";
        ServerSetting: Codeunit "Server Setting";
        AccessControlExists: Boolean;
        NullGuid: Guid;
    begin
        if UserGroupAccessControl.Get(UserGroupCode, UserSecurityID, RoleID, SelectedCompany, ItemScope, AppID) then
            exit;

        // Filter on an App ID only when UsePermissionSetsFromExtensions is set to true.
        // The following filtering is to try find the correct Access Control since there has been cases of corrupt data,
        // such as System permission sets with NULL GUID-s
        if ServerSetting.GetUsePermissionSetsFromExtensions() then begin
            AccessControl.SetRange("User Security ID", UserSecurityID);
            AccessControl.SetRange("Role ID", RoleID);
            AccessControl.SetRange("Company Name", SelectedCompany);
            AccessControl.SetRange(Scope, ItemScope);

            // SUPER and SECURITY always have null guids
            if RoleID in ['SUPER', 'SECURITY'] then
                AccessControl.SetRange("App ID", NullGuid)
            else
                // If scope is system and App ID is null, filter to non-null App IDs
                if (ItemScope = AccessControl.Scope::System) and IsNullGuid(AppID) then
                    AccessControl.SetFilter("App ID", '<>%1', NullGuid)
                else
                    AccessControl.SetRange("App ID", AppID);

            AccessControlExists := not AccessControl.IsEmpty();
        end else
            AccessControlExists := AccessControl.Get(UserSecurityID, RoleID, SelectedCompany, ItemScope, AppID);

        UserGroupAccessControl.Reset();
        UserGroupAccessControl.Init();
        UserGroupAccessControl."User Group Code" := '';
        UserGroupAccessControl."User Security ID" := UserSecurityID;
        UserGroupAccessControl."Role ID" := RoleID;
        UserGroupAccessControl."Company Name" := SelectedCompany;
        UserGroupAccessControl."App ID" := AppID;
        UserGroupAccessControl.Scope := ItemScope;
        if AccessControlExists then begin
            UserGroupAccessControl.SetRange("User Security ID", UserSecurityID);
            UserGroupAccessControl.SetRange("Role ID", RoleID);
            UserGroupAccessControl.SetRange("Company Name", SelectedCompany);
            UserGroupAccessControl.SetRange(Scope, ItemScope);
            UserGroupAccessControl.SetRange("App ID", AppID);

            // If this is the first assignment via a user group and the user already had a manually defined access control,
            // we add a 'null' record for it.
            if UserGroupAccessControl.IsEmpty() then
                UserGroupAccessControl.Insert();
        end;
        UserGroupAccessControl."User Group Code" := UserGroupCode;
        UserGroupAccessControl.Insert();
        if not AccessControlExists then begin
            AccessControl.Init();
            AccessControl."User Security ID" := UserSecurityID;
            AccessControl."Role ID" := RoleID;
            AccessControl."Company Name" := SelectedCompany;
            AccessControl.Scope := ItemScope;
            AccessControl."App ID" := AppID;
            if not AccessControl.Insert() then
                Session.LogMessage('0000JSY', StrSubstNo(CouldNotInsertAccessControlTelemetryErr, AppID), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Upgrade');
        end;
    end;

    local procedure RemovePermissionSetFromUser(UserGroupCode: Code[20]; UserSecurityID: Guid; SelectedCompany: Text[30]; RoleID: Code[20]; AppID: Guid; ItemScope: Integer)
    var
        UserGroupAccessControl: Record "User Group Access Control";
        AccessControl: Record "Access Control";
        AccessControlExists: Boolean;
        ReferenceExists: Boolean;
    begin
        // If this is the last assignment via a user group and the user does not have a manually defined access control,
        // we remove the 'null' record for it if it exists.
        if not UserGroupAccessControl.Get(UserGroupCode, UserSecurityID, RoleID, SelectedCompany, ItemScope, AppID) then
            exit;
        UserGroupAccessControl.Delete();
        AccessControlExists := AccessControl.Get(UserSecurityID, RoleID, SelectedCompany, ItemScope, AppID);
        if AccessControlExists then begin
            UserGroupAccessControl.Reset();
            UserGroupAccessControl.SetRange("User Security ID", UserSecurityID);
            UserGroupAccessControl.SetRange("Role ID", RoleID);
            UserGroupAccessControl.SetRange("Company Name", SelectedCompany);
            UserGroupAccessControl.SetRange(Scope, ItemScope);
            UserGroupAccessControl.SetRange("App ID", AppID);
            ReferenceExists := UserGroupAccessControl.FindLast();
            if not ReferenceExists then
                AccessControl.Delete(true);
            if ReferenceExists and (UserGroupAccessControl."User Group Code" = '') then
                UserGroupAccessControl.Delete();
        end;
    end;
}
