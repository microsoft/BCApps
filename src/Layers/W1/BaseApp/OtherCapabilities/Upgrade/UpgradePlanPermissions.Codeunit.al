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

        RemoveExtensionManagementFromUsers();
        AddFeatureDataUpdatePermissions();
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



    local procedure AddPermissionSetToPlan(PlanId: Guid; RoleId: Code[20]; AppId: Guid)
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PlanConfiguration: Codeunit "Plan Configuration";
        Scope: Option System,Tenant;
    begin
        if AggregatePermissionSet.Get(Scope::System, AppId, RoleId) then
            PlanConfiguration.AddDefaultPermissionSetToPlan(PlanId, RoleId, AppId, Scope::System);
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








}
