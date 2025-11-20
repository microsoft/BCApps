namespace System.Security.AccessControl;

using System.Azure.Identity;
using System.Environment;
using System.Environment.Configuration;
using System.IO;
using System.Reflection;
using System.Security.User;
using System;

codeunit 9852 "Effective Permissions Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        UserAccountHelper: DotNet NavUserAccountHelper;
        DialogFormatMsg: Label 'Reading objects...@1@@@@@@@@@@@@@@@@@@';
        CannotViewEffectivePermissionsForOtherUserErr: Label 'Only users with the SUPER or the SECURITY permission set can view effective permissions for other users.';
        ChangeAffectsOthersMsg: Label 'Your change in permission set %1 will affect other users that the permission set is assigned to.', Comment = '%1 = permission set ID that was changed';
        ChangeAffectsOthersNameTxt: Label 'Changing permission sets for other users';
        ChangeAffectsOthersDescTxt: Label 'Show a warning when changing a permission set that is assigned to other users.';
        DirectConflictWithIndirectMsg: Label 'This user has been given the Yes permission for the selected object, but their license allows them only the Indirect permission.';
        DirectConflictWithNoneMsg: Label 'This user has been given the Yes permission to the selected object, but the object is not included in their license.';
        IndirectConflictWithNoneMsg: Label 'This user has been given the Indirect permission for the selected object, but the object is not included in their license.';
        UserListLbl: Label 'See users affected';
        UndoChangeLbl: Label 'Undo change';
        DontShowAgainLbl: Label 'Never show again';
        RevertChangeQst: Label 'Do you want to revert the recent change to permission set %1?', Comment = '%1 = the permission set ID that has been changed.';
        ConflictLbl: Label '%1 (reduced)', Comment = '%1 = permission set type, e.g. Indirect';

    procedure OpenPageForUser(UserSID: Guid)
    var
        EffectivePermissions: Page "Effective Permissions";
    begin
        EffectivePermissions.SetUserSID(UserSID);
        EffectivePermissions.Run();
    end;

    procedure DisallowViewingEffectivePermissionsForNonAdminUsers(OtherUserSecurityId: Guid)
    var
        UserPermissions: Codeunit "User Permissions";
    begin
        if not UserPermissions.CanManageUsersOnTenant(UserSecurityId()) then
            if OtherUserSecurityId <> UserSecurityId() then
                Error(CannotViewEffectivePermissionsForOtherUserErr);
    end;

    local procedure GetPlanId(PlanOrRole: Enum Licenses): guid
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        case PlanOrRole of
            Enum::Licenses::Basic:
                exit(PlanIds.GetBasicPlanId());
            Enum::Licenses::"Delegated Admin":
                exit(PlanIDs.GetDelegatedAdminPlanId());
            Enum::Licenses::Device:
                exit(PlanIds.GetDevicePlanId());
            Enum::Licenses::Essential:
                exit(PlanIds.GetEssentialPlanId());
            Enum::Licenses::"External Accountant":
                exit(PlanIds.GetExternalAccountantPlanId());
            Enum::Licenses::HelpDesk:
                exit(PlanIds.GetHelpDeskPlanId());
            Enum::Licenses::"Internal Admin":
                exit(PlanIds.GetGlobalAdminPlanId());
            Enum::Licenses::"D365 Admin":
                exit(PlanIds.GetD365AdminPlanId());
            Enum::Licenses::Premium:
                exit(PlanIds.GetPremiumPlanId());
            Enum::Licenses::"Team Member":
                exit(PlanIds.GetTeamMemberPlanId());
            Enum::Licenses::Viral:
                exit(PlanIds.GetViralSignupPlanId());
        end;
    end;

    internal procedure PopulatePermissionConflictsTable(PlanOrRole: Enum Licenses; RoleId: Code[20]; var PermissionConflicts: Record "Permission Conflicts" temporary)
    var
        ExpandedPermission: Record "Expanded Permission";
        EntitlementPermissionsCommaStr: Text;
        Read: Integer;
        Insert: Integer;
        Modify: Integer;
        Delete: Integer;
        Execute: Integer;
    begin
        PermissionConflicts.Reset();
        PermissionConflicts.DeleteAll();

        ExpandedPermission.SetRange("Role ID", RoleId);
        ExpandedPermission.SetRange("Object Type", ExpandedPermission."Object Type"::"Table Data");
        if ExpandedPermission.FindSet() then
            repeat
                EntitlementPermissionsCommaStr := UserAccountHelper.GetEntitlementPermissionForObjectAndPlan(GetPlanId(PlanOrRole), ExpandedPermission."Object Type"::"Table Data", ExpandedPermission."Object ID");
                ExtractPermissionsFromText(EntitlementPermissionsCommaStr, Read, Insert, Modify, Delete, Execute);

                InitializePermissionConflicts(ExpandedPermission."Object Type", ExpandedPermission."Object ID", ExpandedPermission."Read Permission",
                    ExpandedPermission."Insert Permission", ExpandedPermission."Modify Permission", ExpandedPermission."Delete Permission",
                    ExpandedPermission."Execute Permission", ExpandedPermission.Scope = ExpandedPermission.Scope::System, PermissionConflicts);

                UpdatePermissionIfHigherPermission(Read, PermissionConflicts."Entitlement Read Permission");
                UpdatePermissionIfHigherPermission(Insert, PermissionConflicts."Entitlement Insert Permission");
                UpdatePermissionIfHigherPermission(Modify, PermissionConflicts."Entitlement Modify Permission");
                UpdatePermissionIfHigherPermission(Delete, PermissionConflicts."Entitlement Delete Permission");
                UpdatePermissionIfHigherPermission(Execute, PermissionConflicts."Entitlement Execute Permission");

                InsertPermissionConflictIfConflictExists(PermissionConflicts);
            until ExpandedPermission.Next() = 0;
    end;

    local procedure InitializePermissionConflicts(PermissionObjectType: Option; PermissionObjectID: Integer;
                                                    ReadPerm: Option; InsertPerm: Option; ModifyPerm: Option; DeletePerm: Option; ExecutePerm: Option; UserDefined: Boolean;
                                                    var PermissionConflicts: Record "Permission Conflicts")
    begin
        PermissionConflicts.Init();
        PermissionConflicts."Object Type" := PermissionObjectType;
        PermissionConflicts."Object ID" := PermissionObjectID;
        PermissionConflicts."Read Permission" := ConvertToPermission(ReadPerm);
        PermissionConflicts."Insert Permission" := ConvertToPermission(InsertPerm);
        PermissionConflicts."Modify Permission" := ConvertToPermission(ModifyPerm);
        PermissionConflicts."Delete Permission" := ConvertToPermission(DeletePerm);
        PermissionConflicts."Execute Permission" := ConvertToPermission(ExecutePerm);
        PermissionConflicts."Entitlement Read Permission" := PermissionConflicts."Entitlement Read Permission"::None;
        PermissionConflicts."Entitlement Insert Permission" := PermissionConflicts."Entitlement Read Permission"::None;
        PermissionConflicts."Entitlement Modify Permission" := PermissionConflicts."Entitlement Read Permission"::None;
        PermissionConflicts."Entitlement Delete Permission" := PermissionConflicts."Entitlement Read Permission"::None;
        PermissionConflicts."Entitlement Execute Permission" := PermissionConflicts."Entitlement Read Permission"::None;
        PermissionConflicts."User Defined" := UserDefined;
    end;

    local procedure UpdatePermissionIfHigherPermission(Permission: Option; var UpdatePermission: Enum Permission)
    var
        ConvertedPermission: Enum Permission;
    begin
        ConvertedPermission := ConvertToPermission(Permission);
        if ConvertedPermission.AsInteger() > UpdatePermission.AsInteger() then
            UpdatePermission := ConvertedPermission;
    end;

    local procedure InsertPermissionConflictIfConflictExists(var PermissionConflicts: Record "Permission Conflicts")
    var
        RIMDConflict: Boolean;
        ExecuteConflict: Boolean;
    begin
        if (PermissionConflicts."Read Permission".AsInteger() > PermissionConflicts."Entitlement Read Permission".AsInteger()) or
            (PermissionConflicts."Insert Permission".AsInteger() > PermissionConflicts."Entitlement Insert Permission".AsInteger()) or
            (PermissionConflicts."Modify Permission".AsInteger() > PermissionConflicts."Entitlement Modify Permission".AsInteger()) or
            (PermissionConflicts."Delete Permission".AsInteger() > PermissionConflicts."Entitlement Delete Permission".AsInteger()) then
            RIMDConflict := true;

        if (PermissionConflicts."Object Type" = PermissionConflicts."Object Type"::System) and
            (PermissionConflicts."Execute Permission".AsInteger() > PermissionConflicts."Entitlement Execute Permission".AsInteger()) then
            ExecuteConflict := true;

        if RIMDConflict or ExecuteConflict then
            PermissionConflicts.Insert();
    end;

    internal procedure PopulatePermissionConflictsOverviewTable(var PermissionConflictsOverview: Record "Permission Conflicts Overview" temporary; PlansExist: Dictionary of [Guid, Boolean])
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
        TenantPermissionSet: Record "Tenant Permission Set";
        ProgressBar: Codeunit "Config. Progress Bar";
        PlanIds: Codeunit "Plan Ids";
        PlanOrRole: Enum Licenses;
        CurrentPermissionSet: Integer;
        TotalPermissionSets: Integer;
        ProgressBarTitleLbl: Label 'Loading permission sets';
        ProgressLbl: Label '#1#### of #2####', Comment = '#1 - Current permission set, #2 - Total number of permission sets';
    begin
        TotalPermissionSets := MetadataPermissionSet.Count() + TenantPermissionSet.Count();

        ProgressBar.Init(TotalPermissionSets, 1, ProgressBarTitleLbl);
        PermissionConflictsOverview.Reset();
        PermissionConflictsOverview.DeleteAll();

        MetadataPermissionSet.SetRange(Assignable, true);
        if MetadataPermissionSet.FindSet() then
            repeat
                CurrentPermissionSet += 1;
                ProgressBar.Update(StrSubstNo(ProgressLbl, CurrentPermissionSet, TotalPermissionSets));
                PermissionConflictsOverview.PermissionSetID := CopyStr(MetadataPermissionSet."Role ID", 1, 20); // Assignable permission sets are always limited to length 20 
                PermissionConflictsOverview.Type := PermissionConflictsOverview.Type::System;
                if PlansExist.ContainsKey(PlanIds.GetBasicPlanId()) then
                    PermissionConflictsOverview.Basic := IsPermissionSetCoveredByLicense(PlanOrRole::Basic, MetadataPermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetTeamMemberPlanId()) then
                    PermissionConflictsOverview."Team Member" := IsPermissionSetCoveredByLicense(PlanOrRole::"Team Member", MetadataPermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetEssentialPlanId()) then
                    PermissionConflictsOverview.Essential := IsPermissionSetCoveredByLicense(PlanOrRole::Essential, MetadataPermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetPremiumPlanId()) then
                    PermissionConflictsOverview.Premium := IsPermissionSetCoveredByLicense(PlanOrRole::Premium, MetadataPermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetDevicePlanId()) then
                    PermissionConflictsOverview.Device := IsPermissionSetCoveredByLicense(PlanOrRole::Device, MetadataPermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetExternalAccountantPlanId()) then
                    PermissionConflictsOverview."External Accountant" := IsPermissionSetCoveredByLicense(PlanOrRole::"External Accountant", MetadataPermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetGlobalAdminPlanId()) then
                    PermissionConflictsOverview."Internal Admin" := IsPermissionSetCoveredByLicense(PlanOrRole::"Internal Admin", MetadataPermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetD365AdminPlanId()) then
                    PermissionConflictsOverview."D365 Admin" := IsPermissionSetCoveredByLicense(PlanOrRole::"D365 Admin", MetadataPermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetDelegatedAdminPlanId()) then
                    PermissionConflictsOverview."Delegated Admin" := IsPermissionSetCoveredByLicense(PlanOrRole::"Delegated Admin", MetadataPermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetHelpDeskPlanId()) then
                    PermissionConflictsOverview.HelpDesk := IsPermissionSetCoveredByLicense(PlanOrRole::HelpDesk, MetadataPermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetViralSignupPlanId()) then
                    PermissionConflictsOverview.Viral := IsPermissionSetCoveredByLicense(PlanOrRole::Viral, MetadataPermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                PermissionConflictsOverview.Insert();
            until MetadataPermissionSet.Next() = 0;

        if TenantPermissionSet.FindSet() then
            repeat
                CurrentPermissionSet += 1;
                ProgressBar.Update(StrSubstNo(ProgressLbl, CurrentPermissionSet, TotalPermissionSets));
                PermissionConflictsOverview.PermissionSetID := TenantPermissionSet."Role ID";
                PermissionConflictsOverview.Type := PermissionConflictsOverview.Type::User;
                if PlansExist.ContainsKey(PlanIds.GetBasicPlanId()) then
                    PermissionConflictsOverview.Basic := IsPermissionSetCoveredByLicense(PlanOrRole::Basic, TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetTeamMemberPlanId()) then
                    PermissionConflictsOverview."Team Member" := IsPermissionSetCoveredByLicense(PlanOrRole::"Team Member", TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetEssentialPlanId()) then
                    PermissionConflictsOverview.Essential := IsPermissionSetCoveredByLicense(PlanOrRole::Essential, TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetPremiumPlanId()) then
                    PermissionConflictsOverview.Premium := IsPermissionSetCoveredByLicense(PlanOrRole::Premium, TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetDevicePlanId()) then
                    PermissionConflictsOverview.Device := IsPermissionSetCoveredByLicense(PlanOrRole::Device, TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetExternalAccountantPlanId()) then
                    PermissionConflictsOverview."External Accountant" := IsPermissionSetCoveredByLicense(PlanOrRole::"External Accountant", TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetGlobalAdminPlanId()) then
                    PermissionConflictsOverview."Internal Admin" := IsPermissionSetCoveredByLicense(PlanOrRole::"Internal Admin", TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetD365AdminPlanId()) then
                    PermissionConflictsOverview."D365 Admin" := IsPermissionSetCoveredByLicense(PlanOrRole::"D365 Admin", TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetDelegatedAdminPlanId()) then
                    PermissionConflictsOverview."Delegated Admin" := IsPermissionSetCoveredByLicense(PlanOrRole::"Delegated Admin", TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetHelpDeskPlanId()) then
                    PermissionConflictsOverview.HelpDesk := IsPermissionSetCoveredByLicense(PlanOrRole::HelpDesk, TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetViralSignupPlanId()) then
                    PermissionConflictsOverview.Viral := IsPermissionSetCoveredByLicense(PlanOrRole::Viral, TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                PermissionConflictsOverview.Insert();
            until TenantPermissionSet.Next() = 0;
        ProgressBar.Close();
    end;

    local procedure IsPermissionSetCoveredByLicense(PlanOrRole: Enum Licenses; PermissionSetID: Code[30]; PermissionType: Option): Boolean
    var
        ExpandedPermission: Record "Expanded Permission";
        PermissionConflictsOverview: Record "Permission Conflicts Overview";
        PermissionBuffer: Record "Permission Buffer";
    begin
        if PermissionType = PermissionConflictsOverview.Type::System then
            ExpandedPermission.SetRange(Scope, ExpandedPermission.Scope::System)
        else
            ExpandedPermission.SetRange(Scope, ExpandedPermission.Scope::Tenant);

        ExpandedPermission.SetRange("Role ID", PermissionSetID);
        ExpandedPermission.SetRange("Object Type", ExpandedPermission."Object Type"::"Table Data");
        if ExpandedPermission.FindSet() then
            repeat
                FillPermissionBufferFromExpandedPermission(PermissionBuffer, ExpandedPermission);
                if IsPermissionRestrictedByLicense(PermissionBuffer, ExpandedPermission."Object Type", ExpandedPermission."Object ID", PlanOrRole) then
                    exit(false);
            until ExpandedPermission.Next() = 0;
        exit(true);
    end;

    local procedure IsPermissionRestrictedByLicense(Permission: Record "Permission Buffer"; PermissionObjectType: Option; PermissionObjectId: Integer; PlanOrRole: Enum Licenses) Result: Boolean
    var
        DummyExpandedPermission: Record "Expanded Permission";
        PermissionManager: Codeunit "Permission Manager";
        EntitlementPermissionsCommaStr: Text;
        Read: Integer;
        Insert: Integer;
        Modify: Integer;
        Delete: Integer;
        Execute: Integer;
    begin
        EntitlementPermissionsCommaStr := UserAccountHelper.GetEntitlementPermissionForObjectAndPlan(GetPlanId(PlanOrRole), PermissionObjectType, PermissionObjectId);
        ExtractPermissionsFromText(EntitlementPermissionsCommaStr, Read, Insert, Modify, Delete, Execute);

        if PermissionObjectType = DummyExpandedPermission."Object Type"::"Table Data" then begin
            Result := PermissionManager.IsFirstPermissionHigherThanSecond(Permission."Read Permission", Read);
            Result := Result or PermissionManager.IsFirstPermissionHigherThanSecond(Permission."Insert Permission", Insert);
            Result := Result or PermissionManager.IsFirstPermissionHigherThanSecond(Permission."Modify Permission", Modify);
            Result := Result or PermissionManager.IsFirstPermissionHigherThanSecond(Permission."Delete Permission", Delete);
        end else
            Result := PermissionManager.IsFirstPermissionHigherThanSecond(Permission."Execute Permission", Execute);

        exit(Result);
    end;

    procedure PopulatePermissionBuffer(var PermissionBuffer: Record "Permission Buffer"; PassedUserID: Guid; PassedCompanyName: Text[50]; PassedObjectType: Integer; PassedObjectId: Integer)
    var
        AccessControl: Record "Access Control";
        EffectivePermission: Record Permission;
        ExpandedPermission: Record "Expanded Permission";
        PermissionSetBuffer: Record "Permission Set Buffer";
        AssignedRead, AssignedInsert, AssignedModify, AssignedDelete, AssignedExecute : Integer;
    begin
        PermissionBuffer.Reset();
        PermissionBuffer.DeleteAll();

        ExpandedPermission.SetRange("Object Type", PassedObjectType);
        ExpandedPermission.SetFilter("Object ID", '%1|%2', 0, PassedObjectId);

        // find permissions from all permission sets for this user
        AccessControl.SetFilter("User Security ID", GetAccessControlFilterForUser(PassedUserID));
        AccessControl.SetFilter("Company Name", '%1|%2', '', PassedCompanyName);
        if AccessControl.FindSet() then
            repeat
                // do not show permission sets for hidden extensions
                if StrPos(UpperCase(AccessControl."App Name"), UpperCase('_Exclude_')) <> 1 then begin
                    PermissionBuffer.Init();
                    PermissionBuffer."Permission Set" := AccessControl."Role ID";
                    PermissionBuffer.Type := PermissionSetBuffer.GetType(AccessControl.Scope, AccessControl."App ID");

                    if AccessControl."User Security ID" = PassedUserID then
                        PermissionBuffer.Source := PermissionBuffer.Source::Normal
                    else
                        PermissionBuffer.Source := PermissionBuffer.Source::"Security Group";

                    if AccessControl.Scope = AccessControl.Scope::System then
                        ExpandedPermission.SetRange(Scope, ExpandedPermission.Scope::System)
                    else
                        ExpandedPermission.SetRange(Scope, ExpandedPermission.Scope::Tenant);

                    ExpandedPermission.SetRange("App ID", AccessControl."App ID");
                    ExpandedPermission.SetRange("Role ID", AccessControl."Role ID");
                    if ExpandedPermission.FindFirst() then begin
                        FillPermissionBufferFromExpandedPermission(PermissionBuffer, ExpandedPermission);
                        SetHighestAssignedPermission(PermissionBuffer, AssignedRead, AssignedInsert, AssignedModify, AssignedDelete, AssignedExecute);
                        PermissionBuffer.Order := PermissionBuffer.Source;
                        if PermissionBuffer.Insert() then; // avoid errors in case the user was assigned same role both a specific company and globally
                    end;
                end;
            until AccessControl.Next() = 0;

        // find inherent permissions
        PopulatePermissionRecordWithEffectivePermissionsForObject(EffectivePermission, PassedUserID, PassedCompanyName, PassedObjectType, PassedObjectId);
        PopulatePermissionBufferWithInherentPermission(AssignedRead, AssignedInsert, AssignedModify, AssignedDelete, AssignedExecute, EffectivePermission, PermissionBuffer);

        // find entitlement permission
        PopulatePermissionBufferWithEntitlementPermissionsForObject(PermissionBuffer, PassedUserID, PassedObjectType, PassedObjectId);
    end;

    procedure PopulatePermissionBufferWithEntitlementPermissionsForObject(var PermissionBuffer: Record "Permission Buffer"; PassedUserID: Guid; PassedObjectType: Option; PassedObjectId: Integer)
    var
        EnvironmentInfo: Codeunit "Environment Information";
        PermissionCommaStr: Text;
        Read, Insert, Modify, Delete, Execute : Integer;
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;
        PermissionBuffer.Init();
        PermissionBuffer.Source := PermissionBuffer.Source::Entitlement;
        PermissionBuffer."Permission Set" := '';
        PermissionBuffer.Type := PermissionBuffer.Type::System;
        PermissionCommaStr := UserAccountHelper.GetEntitlementPermissionForObject(PassedUserID, PassedObjectType, PassedObjectId);
        ExtractPermissionsFromText(PermissionCommaStr, Read, Insert, Modify, Delete, Execute);
        PermissionBuffer."Read Permission" := Read;
        PermissionBuffer."Insert Permission" := Insert;
        PermissionBuffer."Modify Permission" := Modify;
        PermissionBuffer."Delete Permission" := Delete;
        PermissionBuffer."Execute Permission" := Execute;
        PermissionBuffer.Order := 10000; // order entitlement last
        PermissionBuffer.Insert();
    end;

    local procedure PopulatePermissionBufferWithInherentPermission(AssignedRead: Integer; AssignedInsert: Integer; AssignedModify: Integer; AssignedDelete: Integer; AssignedExecute: Integer; var EffectivePermission: Record Permission; var PermissionBuffer: Record "Permission Buffer")
    begin
        if (EffectivePermission."Read Permission" > AssignedRead) or
           (EffectivePermission."Insert Permission" > AssignedInsert) or
           (EffectivePermission."Modify Permission" > AssignedModify) or
           (EffectivePermission."Delete Permission" > AssignedDelete) or
           (EffectivePermission."Execute Permission" > AssignedExecute)
            then begin
            PermissionBuffer.Init();
            PermissionBuffer.Source := PermissionBuffer.Source::Inherent;
            PermissionBuffer."Permission Set" := '_';
            PermissionBuffer.Type := PermissionBuffer.Type::System;
            PermissionBuffer.Order := PermissionBuffer.Source;

            if EffectivePermission."Read Permission" > AssignedRead then
                PermissionBuffer."Read Permission" := EffectivePermission."Read Permission"
            else
                PermissionBuffer."Read Permission" := EffectivePermission."Read Permission"::" ";

            if EffectivePermission."Insert Permission" > AssignedInsert then
                PermissionBuffer."Insert Permission" := EffectivePermission."Insert Permission"
            else
                PermissionBuffer."Insert Permission" := EffectivePermission."Insert Permission"::" ";

            if EffectivePermission."Modify Permission" > AssignedModify then
                PermissionBuffer."Modify Permission" := EffectivePermission."Modify Permission"
            else
                PermissionBuffer."Modify Permission" := EffectivePermission."Modify Permission"::" ";

            if EffectivePermission."Delete Permission" > AssignedDelete then
                PermissionBuffer."Delete Permission" := EffectivePermission."Delete Permission"
            else
                PermissionBuffer."Delete Permission" := EffectivePermission."Delete Permission"::" ";

            if EffectivePermission."Execute Permission" > AssignedExecute then
                PermissionBuffer."Execute Permission" := EffectivePermission."Execute Permission"
            else
                PermissionBuffer."Execute Permission" := EffectivePermission."Execute Permission"::" ";

            PermissionBuffer.Insert();
        end;
    end;

    local procedure SetHighestAssignedPermission(PermissionBuffer: Record "Permission Buffer"; var AssignedRead: Integer; var AssignedInsert: Integer; var AssignedModify: Integer; var AssignedDelete: Integer; var AssignedExecute: Integer)
    begin
        if PermissionBuffer."Read Permission" > AssignedRead then
            AssignedRead := PermissionBuffer."Read Permission";

        if PermissionBuffer."Insert Permission" > AssignedInsert then
            AssignedInsert := PermissionBuffer."Insert Permission";

        if PermissionBuffer."Modify Permission" > AssignedModify then
            AssignedModify := PermissionBuffer."Modify Permission";

        if PermissionBuffer."Delete Permission" > AssignedDelete then
            AssignedDelete := PermissionBuffer."Delete Permission";

        if PermissionBuffer."Execute Permission" > AssignedExecute then
            AssignedExecute := PermissionBuffer."Execute Permission";
    end;

    local procedure GetAccessControlFilterForUser(UserSecId: Guid): Text
    var
        SecurityGroupMemberBuffer: Record "Security Group Member Buffer";
        SecurityGroup: Codeunit "Security Group";
        FilterTextBuilder: TextBuilder;
    begin
        // Consider permissions assigned to the user directly.
        FilterTextBuilder.Append(UserSecId);

        // Consider permissions assigned to the user through security groups.
        SecurityGroup.GetMembers(SecurityGroupMemberBuffer);
        SecurityGroupMemberBuffer.SetRange("User Security ID", UserSecId);
        if SecurityGroupMemberBuffer.FindSet() then
            repeat
                FilterTextBuilder.Append('|');
                FilterTextBuilder.Append(SecurityGroup.GetGroupUserSecurityId(SecurityGroupMemberBuffer."Security Group Code"));
            until SecurityGroupMemberBuffer.Next() = 0;

        exit(FilterTextBuilder.ToText());
    end;

    procedure PopulateEffectivePermissionsBuffer(var Permission: Record Permission; PassedUserID: Guid; PassedCompanyName: Text[50]; PassedObjectType: Integer; PassedObjectId: Integer; ShowAllObjects: Boolean)
    var
        AllObj: Record AllObj;
        Window: Dialog;
        TotalCount: Integer;
        NumObjectsProcessed: Integer;
        TimesToUpdate: Integer;
    begin
        Permission.Reset();
        Permission.DeleteAll();

        if PassedObjectId = 0 then begin
            Window.Open(DialogFormatMsg);
            AllObj.SetFilter("Object Type", '%1|%2|%3|%4|%5|%6|%7|%8|%9',
              Permission."Object Type"::"Table Data",
              Permission."Object Type"::Table,
              Permission."Object Type"::Report,
              Permission."Object Type"::Codeunit,
              Permission."Object Type"::XMLport,
              Permission."Object Type"::MenuSuite,
              Permission."Object Type"::Page,
              Permission."Object Type"::Query,
              Permission."Object Type"::System);
            if not ShowAllObjects then
                FilterOnlyObjectsPresentInUserPermissionSets(AllObj, PassedUserID, PassedCompanyName);
            if AllObj.FindSet() then begin
                TotalCount := AllObj.Count();
                // Only update every 10 %
                TimesToUpdate := TotalCount div 10;
                if TimesToUpdate = 0 then
                    TimesToUpdate := 1;

                repeat
                    InsertEffectivePermissionForObject(Permission, PassedUserID, PassedCompanyName,
                      AllObj."Object Type", AllObj."Object ID");
                    NumObjectsProcessed += 1;
                    if (NumObjectsProcessed mod TimesToUpdate) = 0 then
                        Window.Update(1, Round(NumObjectsProcessed * 10000 / TotalCount, 1));
                until AllObj.Next() = 0;
                Permission.FindFirst();
            end;
            Window.Close();
        end else
            InsertEffectivePermissionForObject(Permission, PassedUserID, PassedCompanyName, PassedObjectType, PassedObjectId);
    end;

    local procedure FilterOnlyObjectsPresentInUserPermissionSets(var AllObj: Record AllObj; PassedUserID: Guid; PassedCompanyName: Text[50])
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetFilter("User Security ID", GetAccessControlFilterForUser(PassedUserID));
        AccessControl.SetFilter("Company Name", '%1|%2', '', PassedCompanyName);
        if AccessControl.FindSet() then
            repeat
                MarkAllObjFromPermissionSet(AllObj, AccessControl."Role ID", AccessControl."App ID", AccessControl.Scope);
            until AccessControl.Next() = 0;

        AllObj.MarkedOnly(true);
    end;

    local procedure InsertEffectivePermissionForObject(var Permission: Record Permission; PassedUserID: Guid; PassedCompanyName: Text[50]; PassedObjectType: Integer; PassedObjectId: Integer)
    begin
        Permission.Init();
        Permission."Object Type" := PassedObjectType;
        Permission."Object ID" := PassedObjectId;
        PopulatePermissionRecordWithEffectivePermissionsForObject(Permission, PassedUserID, PassedCompanyName,
          PassedObjectType, PassedObjectId);
        Permission.Insert();
    end;

    local procedure FillPermissionBufferFromExpandedPermission(var PermissionBuffer: Record "Permission Buffer"; ExpandedPermission: Record "Expanded Permission")
    begin
        PermissionBuffer."Read Permission" := ExpandedPermission."Read Permission";
        PermissionBuffer."Insert Permission" := ExpandedPermission."Insert Permission";
        PermissionBuffer."Modify Permission" := ExpandedPermission."Modify Permission";
        PermissionBuffer."Delete Permission" := ExpandedPermission."Delete Permission";
        PermissionBuffer."Execute Permission" := ExpandedPermission."Execute Permission";
        PermissionBuffer."Security Filter" := ExpandedPermission."Security Filter";
    end;

    local procedure MarkAllObjFromPermissionSet(var AllObj: Record AllObj; PermissionSetID: Code[20]; AppID: Guid; ObjScope: Option)
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        ExpandedPermission.SetRange("App ID", AppID);
        ExpandedPermission.SetRange("Role ID", PermissionSetID);
        ExpandedPermission.SetRange(Scope, ObjScope);
        if ExpandedPermission.FindSet() then
            repeat
                MarkAllObj(AllObj, ExpandedPermission."Object Type", ExpandedPermission."Object ID");
            until ExpandedPermission.Next() = 0;
    end;

    local procedure MarkAllObj(var AllObj: Record AllObj; ObjectTypePassed: Integer; ObjectIDPassed: Integer)
    begin
        if ObjectIDPassed = 0 then begin
            AllObj.SetRange("Object Type", ObjectTypePassed);
            if AllObj.FindSet() then
                repeat
                    AllObj.Mark(true);
                until AllObj.Next() = 0;
            AllObj.SetRange("Object Type");
            exit;
        end;

        if AllObj.Get(ObjectTypePassed, ObjectIDPassed) then
            AllObj.Mark(true);
    end;

    procedure PopulatePermissionRecordWithEffectivePermissionsForObject(var Permission: Record Permission; PassedUserID: Guid; PassedCompanyName: Text[50]; PassedObjectType: Option; PassedObjectId: Integer)
    var
        PermissionCommaStr: Text;
        Read: Integer;
        Insert: Integer;
        Modify: Integer;
        Delete: Integer;
        Execute: Integer;
    begin
        PermissionCommaStr := UserAccountHelper.GetEffectivePermissionForObject(
            PassedUserID, PassedCompanyName, PassedObjectType, PassedObjectId);
        ExtractPermissionsFromText(PermissionCommaStr, Read, Insert, Modify, Delete, Execute);
        Permission."Read Permission" := Read;
        Permission."Insert Permission" := Insert;
        Permission."Modify Permission" := Modify;
        Permission."Delete Permission" := Delete;
        Permission."Execute Permission" := Execute;
    end;

    local procedure ExtractPermissionsFromText(PermissionCommaStr: Text; var Read: Integer; var Insert: Integer; var Modify: Integer; var Delete: Integer; var Execute: Integer)
    begin
        Evaluate(Read, SelectStr(1, PermissionCommaStr));
        Evaluate(Insert, SelectStr(2, PermissionCommaStr));
        Evaluate(Modify, SelectStr(3, PermissionCommaStr));
        Evaluate(Delete, SelectStr(4, PermissionCommaStr));
        Evaluate(Execute, SelectStr(5, PermissionCommaStr));
    end;

    procedure ModifyPermission(FieldNumChanged: Integer; PermissionBuffer: Record "Permission Buffer"; PassedObjectType: Integer; PassedObjectId: Integer; PassedUserID: Guid)
    var
        TenantPermission: Record "Tenant Permission";
        CallModify: Boolean;
        OldValue: Integer;
    begin
        TenantPermission.Get(PermissionBuffer.GetAppID(), PermissionBuffer."Permission Set", PassedObjectType, PassedObjectId);
        case FieldNumChanged of
            TenantPermission.FieldNo("Read Permission"):
                begin
                    OldValue := TenantPermission."Read Permission";
                    CallModify := TenantPermission."Read Permission" <> PermissionBuffer."Read Permission";
                    TenantPermission."Read Permission" := PermissionBuffer."Read Permission";
                end;
            TenantPermission.FieldNo("Insert Permission"):
                begin
                    OldValue := TenantPermission."Insert Permission";
                    CallModify := TenantPermission."Insert Permission" <> PermissionBuffer."Insert Permission";
                    TenantPermission."Insert Permission" := PermissionBuffer."Insert Permission";
                end;
            TenantPermission.FieldNo("Modify Permission"):
                begin
                    OldValue := TenantPermission."Modify Permission";
                    CallModify := TenantPermission."Modify Permission" <> PermissionBuffer."Modify Permission";
                    TenantPermission."Modify Permission" := PermissionBuffer."Modify Permission";
                end;
            TenantPermission.FieldNo("Delete Permission"):
                begin
                    OldValue := TenantPermission."Delete Permission";
                    CallModify := TenantPermission."Delete Permission" <> PermissionBuffer."Delete Permission";
                    TenantPermission."Delete Permission" := PermissionBuffer."Delete Permission";
                end;
            TenantPermission.FieldNo("Execute Permission"):
                begin
                    OldValue := TenantPermission."Execute Permission";
                    CallModify := TenantPermission."Execute Permission" <> PermissionBuffer."Execute Permission";
                    TenantPermission."Execute Permission" := PermissionBuffer."Execute Permission";
                end;
        end;
        if not CallModify then
            exit;
        TenantPermission.Modify();
        SendNotification(PermissionBuffer."Permission Set", PassedObjectType, PassedObjectId, PassedUserID, FieldNumChanged, OldValue);
        OnTenantPermissionModified(TenantPermission."Role ID");
    end;

    local procedure SendNotification(PermissionSetID: Code[20]; PassedObjectType: Integer; PassedObjectId: Integer; UserOnPage: Guid; FieldNumChanged: Integer; OldValue: Integer)
    var
        User: Record User;
        MyNotifications: Record "My Notifications";
        Notification: Notification;
        NotificationID: Guid;
    begin
        MarkUsersWithAssignedPermissionSet(User, PermissionSetID);
        User.SetFilter("User Security ID", '<>%1', UserOnPage);
        if User.IsEmpty() then
            exit;

        NotificationID := GetPermissionChangeNotificationId();
        if not MyNotifications.IsEnabled(NotificationID) then
            exit;

        Notification.Id := NotificationID;
        Notification.Message := StrSubstNo(ChangeAffectsOthersMsg, PermissionSetID);
        Notification.SetData('UserOnPage', UserOnPage);
        Notification.SetData('PermissionSetID', PermissionSetID);
        Notification.SetData('ObjectType', Format(PassedObjectType));
        Notification.SetData('ObjectID', Format(PassedObjectId));
        Notification.SetData('FieldNumChanged', Format(FieldNumChanged));
        Notification.SetData('OldValue', Format(OldValue));
        Notification.AddAction(UserListLbl, CODEUNIT::"Effective Permissions Mgt.", 'NotificationShowUsers');
        Notification.AddAction(UndoChangeLbl, CODEUNIT::"Effective Permissions Mgt.", 'NotificationUndoChange');
        Notification.AddAction(DontShowAgainLbl, CODEUNIT::"Effective Permissions Mgt.", 'DisableNotification');
        Notification.Send();
    end;

    procedure NotificationShowUsers(Notification: Notification)
    var
        User: Record User;
        PermissionSetID: Code[20];
    begin
        PermissionSetID := CopyStr(Notification.GetData('PermissionSetID'), 1, 20);
        MarkUsersWithAssignedPermissionSet(User, PermissionSetID);
        User.SetFilter("User Security ID", '<>%1', Notification.GetData('UserOnPage'));
        PAGE.RunModal(PAGE::Users, User);
        if Confirm(StrSubstNo(RevertChangeQst, PermissionSetID), false) then
            NotificationUndoChange(Notification);
    end;

    procedure NotificationUndoChange(Notification: Notification)
    var
        TenantPermission: Record "Tenant Permission";
        ZeroGUID: Guid;
        ObjType: Integer;
        ObjID: Integer;
        FieldNumChanged: Integer;
        OldValue: Integer;
    begin
        Evaluate(ObjType, Notification.GetData('ObjectType'));
        Evaluate(ObjID, Notification.GetData('ObjectID'));
        TenantPermission.Get(ZeroGUID, Notification.GetData('PermissionSetID'), ObjType, ObjID);

        Evaluate(FieldNumChanged, Notification.GetData('FieldNumChanged'));
        Evaluate(OldValue, Notification.GetData('OldValue'));
        case FieldNumChanged of
            TenantPermission.FieldNo("Read Permission"):
                TenantPermission."Read Permission" := OldValue;
            TenantPermission.FieldNo("Insert Permission"):
                TenantPermission."Insert Permission" := OldValue;
            TenantPermission.FieldNo("Modify Permission"):
                TenantPermission."Modify Permission" := OldValue;
            TenantPermission.FieldNo("Delete Permission"):
                TenantPermission."Delete Permission" := OldValue;
            TenantPermission.FieldNo("Execute Permission"):
                TenantPermission."Execute Permission" := OldValue;
        end;
        TenantPermission.Modify();
    end;

    procedure DisableNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.Disable(GetPermissionChangeNotificationId());
    end;

    procedure ConvertToPermission(PermissionOption: Option) Permission: enum Permission
    var
        PermissionBuffer: Record "Permission Buffer";
    begin
        case PermissionOption of
            PermissionBuffer."Read Permission"::" ":
                exit(Permission::None);
            PermissionBuffer."Read Permission"::Yes:
                exit(Permission::Direct);
            PermissionBuffer."Read Permission"::Indirect:
                exit(Permission::Indirect);
        end;
    end;

    internal procedure ShowPermissionConflict(Permissions: Enum Permission; EntitlementPermissions: Enum Permission; IsSourceEntitlement: Boolean)
    var
        ConflictMsg: Text;
    begin
        if IsSourceEntitlement then
            exit;

        if not ArePermissionsInConflict(Permissions, EntitlementPermissions) then
            exit;

        if (Permissions = Permissions::Direct) and (EntitlementPermissions = EntitlementPermissions::Indirect) then
            ConflictMsg := DirectConflictWithIndirectMsg;

        if (Permissions = Permissions::Direct) and (EntitlementPermissions = EntitlementPermissions::None) then
            ConflictMsg := DirectConflictWithNoneMsg;

        if (Permissions = Permissions::Indirect) and (EntitlementPermissions = EntitlementPermissions::None) then
            ConflictMsg := IndirectConflictWithNoneMsg;

        Message(ConflictMsg);
    end;

    internal procedure GetPermissionStatus(Permissions: Enum Permission; EntitlementPermissions: Enum Permission; IsSourceEntitlement: Boolean): Text
    begin
        if IsSourceEntitlement then
            exit(Format(Permissions));

        if not ArePermissionsInConflict(Permissions, EntitlementPermissions) then
            exit(Format(Permissions));

        // Show the effective permission (the one that comes from the entitlement) and an indication that the permission has been reduced
        exit(StrSubstNo(ConflictLbl, Format(EntitlementPermissions)));
    end;

    local procedure ArePermissionsInConflict(PermissionsFromPermissionSet: Enum Permission; PermissionsFromEntitlement: Enum Permission): Boolean
    begin
        exit(PermissionsFromPermissionSet.AsInteger() > PermissionsFromEntitlement.AsInteger());
    end;

    internal procedure OpenPermissionConflicts(PermissionSetID: Code[20]; PlanOrRole: Enum Licenses)
    var
        PermissionConflictsPage: Page "Permission Conflicts";
    begin
        PermissionConflictsPage.SetPermissionSetId(PermissionSetID);
        PermissionConflictsPage.SetEntitlementId(PlanOrRole);
        PermissionConflictsPage.Run();
    end;

    local procedure MarkUsersWithAssignedPermissionSet(var User: Record User; PermissionSetID: Code[20])
    var
        AccessControl: Record "Access Control";
        SecurityGroupBuffer: Record "Security Group Buffer";
        SecurityGroupMemberBuffer: Record "Security Group Member Buffer";
        SecurityGroup: Codeunit "Security Group";
        GroupUserSecId: Guid;
    begin
        AccessControl.SetRange("Role ID", PermissionSetID);
        if AccessControl.FindSet() then
            repeat
                if User.Get(AccessControl."User Security ID") then
                    User.Mark(true);
            until AccessControl.Next() = 0;

        SecurityGroup.GetGroups(SecurityGroupBuffer);
        SecurityGroup.GetMembers(SecurityGroupMemberBuffer);
        if SecurityGroupBuffer.FindSet() then
            repeat
                GroupUserSecId := SecurityGroup.GetGroupUserSecurityId(SecurityGroupBuffer.Code);
                AccessControl.SetRange("User Security ID", GroupUserSecId);
                AccessControl.SetRange("Role ID", PermissionSetID);
                // If the permission set is assigned to the security group
                if not AccessControl.IsEmpty() then begin
                    // Mark all the security group members
                    SecurityGroupMemberBuffer.SetRange("Security Group Code", SecurityGroupBuffer.Code);
                    if SecurityGroupMemberBuffer.FindSet() then
                        repeat
                            if User.Get(SecurityGroupMemberBuffer."User Security ID") then
                                User.Mark(true);
                        until SecurityGroupMemberBuffer.Next() = 0;
                end;
            until SecurityGroupBuffer.Next() = 0;

        User.MarkedOnly(true);
    end;

    local procedure GetPermissionChangeNotificationId(): Guid
    begin
        exit('7E18A509-6579-471A-BF8D-4A9BDABB6008');
    end;

    /// <summary>
    /// Checks if the user has direct read, insert and modify permissions on the given table id.
    /// </summary>
    /// <param name="TableId">Id of the table</param>
    /// <returns>True if user has direct read, insert and modify permissions on table.</returns>
    internal procedure HasDirectRIMPermissionsOnTableData(TableId: Integer): Boolean
    var
        MetadataPermission: Record "Metadata Permission";
        EntitlementPermissionsCommaStr: Text;
        Read: Integer;
        Insert: Integer;
        Modify: Integer;
        Delete: Integer;
        Execute: Integer;
    begin
        EntitlementPermissionsCommaStr := UserAccountHelper.GetEntitlementPermissionForObject(UserSecurityId(), MetadataPermission."Object Type"::"Table Data", TableId);
        ExtractPermissionsFromText(EntitlementPermissionsCommaStr, Read, Insert, Modify, Delete, Execute);

        if ((Read = MetadataPermission."Read Permission"::Yes) and
            (Insert = MetadataPermission."Insert Permission"::Yes) and
            (Modify = MetadataPermission."Modify Permission"::Yes)) then
            exit(true);

        exit(false);
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetPermissionChangeNotificationId(), ChangeAffectsOthersNameTxt, ChangeAffectsOthersDescTxt, true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTenantPermissionModified(PermissionSetId: Code[20])
    begin
    end;
}

