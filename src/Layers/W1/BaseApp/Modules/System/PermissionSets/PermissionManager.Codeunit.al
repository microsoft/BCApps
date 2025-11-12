namespace System.Security.AccessControl;

using System.Azure.Identity;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Reflection;
using System.Security.Encryption;
using System.Security.User;
using System.Telemetry;

codeunit 9002 "Permission Manager"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    Permissions = TableData "Permission Set Link" = rd,
                  TableData "Aggregate Permission Set" = rimd;

    SingleInstance = true;

    var
        EnvironmentInfo: Codeunit "Environment Information";
        OfficePortalUserAdministrationUrlTxt: Label 'https://portal.office.com/admin/default.aspx#ActiveUsersPage', Locked = true;
        IntelligentCloudTok: Label 'INTELLIGENT CLOUD', Locked = true;
        LocalTok: Label 'LOCAL', Locked = true;
        TestabilityIntelligentCloud: Boolean;
        CannotModifyOtherUsersErr: Label 'You cannot change settings for another user.';
#if not CLEAN26
        FoundProfileFromPlanTxt: Label 'Found default profile from plan: %1.', Locked = true;
        NoProfileFromPlanTxt: Label 'No profile could be determined from user plans, picking system wide defaults.', Locked = true;
        TelemetryCategoryTxt: Label 'AL Perm Mgr', Locked = true;
#endif
        PlanConfigurationFeatureNameTxt: Label 'Custom Permissions Assignment Per Plan', Locked = true;

    procedure AssignDefaultPermissionsToUser(UserSecurityID: Guid): Boolean
    var
        Company: Text[30];
    begin
        Company := CopyStr(CompanyName(), 1, 30);
        exit(AssignDefaultPermissionsToUser(UserSecurityID, Company));
    end;

    procedure AssignDefaultPermissionsToUser(UserSecurityID: Guid; Company: Text[30]) PermissionsAdded: Boolean
    var
        PlanConfiguration: Codeunit "Plan Configuration";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        UsersInPlans: Query "Users in Plans";
    begin
        // If intelligent cloud is enabled, then assign the intelligent cloud permissions
        if IsIntelligentCloud() then begin
            AddPermissionSetToUser(UserSecurityID, IntelligentCloudTok, Company);
            PermissionsAdded := true;
            exit;
        end;

        // No plan is assigned to this user
        UsersInPlans.SetRange(User_Security_ID, UserSecurityID);
        if not UsersInPlans.Open() then begin
            PermissionsAdded := false;
            exit;
        end;

        // There is at least a plan assigned (and probably only one)
        while UsersInPlans.Read() do
            if PlanConfiguration.IsCustomized(UsersInPlans.Plan_ID) then begin
                FeatureTelemetry.LogUptake('0000HSP', PlanConfigurationFeatureNameTxt, Enum::"Feature Uptake Status"::Used);
                PlanConfiguration.AssignCustomPermissionsToUser(UsersInPlans.Plan_ID, UserSecurityID);
                PermissionsAdded := true;
            end else begin
                PlanConfiguration.AssignDefaultPermissionsToUser(UsersInPlans.Plan_ID, UserSecurityID, Company);
                PermissionsAdded := true;
            end;
    end;

    procedure ResetUserToDefaultPermissions(UserSecurityID: Guid)
    begin
        // Remove the user from any additional, manually assigned permission sets
        RemoveAllPermissionSetsFromUser(UserSecurityID);

        // Assign all permission sets associated with user's plans
        AssignDefaultPermissionsToUser(UserSecurityID);
    end;

    local procedure RemoveAllPermissionSetsFromUser(UserSecurityID: Guid)
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityID);
        AccessControl.DeleteAll(true);
    end;

    procedure GetOfficePortalUserAdminUrl(): Text
    begin
        exit(OfficePortalUserAdministrationUrlTxt);
    end;

    procedure UpdateUserAccessForSaaS(UserSID: Guid) UserGroupsAdded: Boolean
    begin
        if not AllowUpdateUserAccessForSaaS(UserSID) then
            exit;

        if AssignDefaultPermissionsToUser(UserSID) then begin
            AssignDefaultRoleCenterToUser(UserSID);
            UserGroupsAdded := true;
        end;
    end;

    local procedure AllowUpdateUserAccessForSaaS(UserSID: Guid): Boolean
    var
        User: Record User;
        Plan: Query Plan;
        UsersInPlans: Query "Users in Plans";
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit(false);

        if IsNullGuid(UserSID) then
            exit(false);

        // Don't demote external users (like the sync daemon) and AAD groups
        User.Get(UserSID);
        if User."License Type" in [User."License Type"::"External User", User."License Type"::"AAD Group"] then
            exit(false);

        // Don't demote users which don't come from Office365 (have no plans assigned)
        // Note: all users who come from O365, if they don't have a plan, they don't get a license (hence, no SUPER role)
        UsersInPlans.SetFilter(User_Security_ID, User."User Security ID");
        if not UsersInPlans.Open() then
            exit(false);

        // Don't demote users that have an invalid plan(likely coming from 1.5)
        while UsersInPlans.Read() do begin
            Plan.SetFilter(Plan_ID, UsersInPlans.Plan_ID);
            if not Plan.Open() then
                exit(false);
            Plan.Read();
            if Plan.Role_Center_ID = 0 then
                exit(false);
            Plan.Close();
        end;

        exit(true);
    end;

    local procedure AssignDefaultRoleCenterToUser(UserSecurityID: Guid)
    var
        UserPersonalization: Record "User Personalization";
        AllProfile: Record "All Profile";
        UsersInPlans: Query "Users in Plans";
        Plan: Query Plan;
        IsAllProfileFiltered: Boolean;
    begin
        UsersInPlans.SetRange(User_Security_ID, UserSecurityID);
        if not UsersInPlans.Open() then
            exit; // this user has no plans assigned, so they'll get the app-wide default role center
        UsersInPlans.Read();

        Plan.SetRange(Plan_ID, UsersInPlans.Plan_ID);
        Plan.Open();
        Plan.Read();

        if Plan.Role_Center_ID = 9022 then // 9022 = Page::"Business Manager Role Center"
            FilterProfileToBusinessManager(AllProfile, IsAllProfileFiltered)
        else
            AllProfile.SetRange("Role Center ID", Plan.Role_Center_ID);

        if not AllProfile.FindFirst() then
            exit; // the plan does not have a role center, so they'll get the app-wide default role center

        // Create the user personalization record
        if not UserPersonalization.Get(UserSecurityID) then begin
            UserPersonalization.Init();
            UserPersonalization.Validate("User SID", UserSecurityID);
            UserPersonalization.Validate("Profile ID", AllProfile."Profile ID");
            UserPersonalization.Validate("App ID", AllProfile."App ID");
            UserPersonalization.Validate(Scope, AllProfile.Scope);
            UserPersonalization.Insert();
        end else
            if IsAllProfileFiltered then begin
                UserPersonalization.Validate("Profile ID", AllProfile."Profile ID");
                UserPersonalization.Validate("App ID", AllProfile."App ID");
                UserPersonalization.Validate(Scope, AllProfile.Scope);
                UserPersonalization.Modify();
            end;
    end;

#if not CLEAN26
    /// <summary>
    /// This procedure retrieves a Default Profile ID to be used for a user, in case there is no valid 
    /// custom profile set for them in their User Personalization. 
    /// </summary>
    /// <param name="UserSecurityID">The SID for the User to find a default profile for</param>
    /// <param name="AllProfile">The returned AllProfile that is the default for the specified user</param>
    /// <remarks>
    /// <list type="number">
    ///   <item><description>If we can provide a tailored default for the user (from the Plan/License), return that, otherwise</description></item>
    ///   <item><description>If there is any system-wide default AllProfile in the table, return it, otherwise</description></item>
    ///   <item><description>Find the default Role Center ID for the system (which checks the Plan/License again and has some additional 
    ///   defaulting logic), and if there is a profile for it return it, otherwise</description></item>
    ///   <item><description>Fall back to just return the first AllProfile available in the table</description></item>
    /// </list>
    /// </remarks>
    [Scope('OnPrem')]
    [Obsolete('This procedure has been moved into codeunit "Conf./Personalization Mgt."', '26.0')]
    procedure GetDefaultProfileID(UserSecurityID: Guid; var AllProfile: Record "All Profile")
    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        RoleCenterFromPlans: Query "Role Center from Plans";
    begin
        RoleCenterFromPlans.SetRange(User_Security_ID, UserSecurityID);
        if RoleCenterFromPlans.Open() then
            while RoleCenterFromPlans.Read() do begin
                AllProfile.SetRange("Role Center ID", RoleCenterFromPlans.Role_Center_ID);
                if AllProfile.FindFirst() then begin
                    Session.LogMessage('0000DUK', StrSubstNo(FoundProfileFromPlanTxt, AllProfile."Profile ID"), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
                    exit;
                end;
            end;

        Session.LogMessage('0000DUL', NoProfileFromPlanTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);

        AllProfile.Reset();
        AllProfile.SetRange("Default Role Center", true);
        if AllProfile.FindFirst() then
            exit;

        AllProfile.Reset();
        AllProfile.SetRange("Role Center ID", ConfPersonalizationMgt.DefaultRoleCenterID());
        if AllProfile.FindFirst() then
            exit;

        AllProfile.Reset();
        if AllProfile.FindFirst() then
            exit;
    end;
#endif

    procedure CanCurrentUserManagePlansAndGroups(): Boolean
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        AccessControl: Record "Access Control";
    begin
        exit(AccessControl.WritePermission());
    end;

    procedure GenerateHashForPermissionSet(PermissionSetId: Code[30]): Text[250]
    var
        MetadataPermission: Record "Metadata Permission";
        CryptographyManagement: Codeunit "Cryptography Management";
        InputText: Text;
        ObjectType: Integer;
    begin
        InputText += PermissionSetId;
        MetadataPermission.SetRange("Role ID", PermissionSetId);
        if MetadataPermission.FindSet() then
            repeat
                ObjectType := MetadataPermission."Object Type";
                InputText += Format(ObjectType);
                InputText += Format(MetadataPermission."Object ID");
                if ObjectType = MetadataPermission."Object Type"::"Table Data" then begin
                    InputText += GetCharRepresentationOfPermission(MetadataPermission."Read Permission");
                    InputText += GetCharRepresentationOfPermission(MetadataPermission."Insert Permission");
                    InputText += GetCharRepresentationOfPermission(MetadataPermission."Modify Permission");
                    InputText += GetCharRepresentationOfPermission(MetadataPermission."Delete Permission");
                end else
                    InputText += GetCharRepresentationOfPermission(MetadataPermission."Execute Permission");
                InputText += Format(MetadataPermission."Security Filter", 0, 9);
            until MetadataPermission.Next() = 0;

        exit(CopyStr(CryptographyManagement.GenerateHash(InputText, 2), 1, 250)); // 2 corresponds to SHA256
    end;

    local procedure FilterProfileToBusinessManager(var AllProfile: Record "All Profile"; var IsFiltered: Boolean)
    var
        Company: Record Company;
    begin
        if not Company.Get(CompanyName()) then
            exit;

        if Company."Evaluation Company" then begin
            if Company.Name.ToLower().StartsWith('cronus') then begin
                AllProfile.SetRange("Profile ID", 'Business Manager Evaluation');
                IsFiltered := true;
            end;
        end else begin
            AllProfile.SetRange("Profile ID", 'Business Manager');
            IsFiltered := true;
        end;
    end;

    local procedure GetCharRepresentationOfPermission(PermissionOption: Integer): Text[1]
    begin
        exit(StrSubstNo('%1', PermissionOption));
    end;

    procedure IsFirstPermissionHigherThanSecond(First: Option; Second: Option): Boolean
    var
        MetadataPermission: Record "Metadata Permission";
    begin
        case First of
            MetadataPermission."Read Permission"::" ":
                exit(false);
            MetadataPermission."Read Permission"::Indirect:
                exit(Second = MetadataPermission."Read Permission"::" ");
            MetadataPermission."Read Permission"::Yes:
                exit(Second in [MetadataPermission."Read Permission"::Indirect, MetadataPermission."Read Permission"::" "]);
        end;
    end;

    procedure ResetUsersToIntelligentCloudPermissions()
    var
        User: Record User;
        AccessControl: Record "Access Control";
        IntelligentCloud: Record "Intelligent Cloud";
        UserPermissions: Codeunit "User Permissions";
        UserSelection: Codeunit "User Selection";
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;

        if not IntelligentCloud.Get() then
            exit;

        if IntelligentCloud.Enabled then begin
            UserSelection.FilterSystemUserAndAADGroupUsers(User);
            User.SetFilter("Windows Security ID", '=''''');

            if User.Count = 0 then
                exit;

            User.FindSet();
            repeat
                if not UserPermissions.IsSuper(User."User Security ID") and not IsNullGuid(User."User Security ID") then begin
                    AccessControl.SetRange("User Security ID", User."User Security ID");
                    if AccessControl.FindSet() then
                        repeat
                            RemoveExistingPermissionsAndAddIntelligentCloud(AccessControl."User Security ID", AccessControl."Company Name");
                        until AccessControl.Next() = 0;
                end;
            until User.Next() = 0;
        end;
    end;

    procedure IsIntelligentCloud(): Boolean
    var
        IntelligentCloud: Record "Intelligent Cloud";
    begin
        if TestabilityIntelligentCloud then
            exit(true);

        if IntelligentCloud.Get() then
            exit(IntelligentCloud.Enabled);
    end;

    local procedure RemoveExistingPermissionsAndAddIntelligentCloud(UserSecurityID: Guid; CompanyName: Text[30])
    var
        AccessControl: Record "Access Control";
    begin
        // Remove User from all Permission Sets for the company
        AccessControl.SetRange("User Security ID", UserSecurityID);
        AccessControl.SetRange("Company Name", CompanyName);
        AccessControl.SetRange(Scope, AccessControl.Scope::System);
        AccessControl.SetFilter("Role ID", '<>%1', IntelligentCloudTok);
        AccessControl.SetFilter("Role ID", '<>%1', LocalTok);
        AccessControl.DeleteAll(true);

        AddPermissionSetToUser(UserSecurityID, IntelligentCloudTok, CompanyName);
    end;

    procedure SetTestabilityIntelligentCloud(EnableIntelligentCloudForTest: Boolean)
    begin
        TestabilityIntelligentCloud := EnableIntelligentCloudForTest;
    end;

    local procedure AddPermissionSetToUser(UserSecurityID: Guid; RoleID: Code[20]; Company: Text[30])
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityID);
        AccessControl.SetRange("Role ID", RoleID);
        AccessControl.SetRange("Company Name", Company);

        if not AccessControl.IsEmpty() then
            exit;

        AccessControl.Init();
        AccessControl."Company Name" := Company;
        AccessControl."User Security ID" := UserSecurityID;
        AccessControl."Role ID" := RoleID;
        AccessControl.Insert(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tenant Permission Set", OnBeforeDeleteEvent, '', false, false)]
    local procedure OnBeforeDeleteTenantPermissionSet(var Rec: Record "Tenant Permission Set")
    var
        PermissionSetLink: Record "Permission Set Link";
    begin
        if Rec.IsTemporary() then
            exit;

        PermissionSetLink.SetRange("Linked Permission Set ID", Rec."Role ID");
        PermissionSetLink.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Table, Database::User, 'OnBeforeModifyEvent', '', true, true)]
    procedure CheckCurrentUserCanModifyUser(var Rec: Record User; var xRec: Record user; RunTrigger: Boolean)
    var
        LoggedInUser: Record User;
        UserPermissions: Codeunit "User Permissions";
        CurrentUserSecurityId: Guid;
    begin
        if Rec.IsTemporary() then
            exit;

        if Rec."License Type" = Rec."License Type"::Agent then
            exit;

        Rec.TestField("User Name");
        CurrentUserSecurityId := UserSecurityId();
        if not LoggedInUser.Get(CurrentUserSecurityId) then // Current user is Super from when there were no users in the system
            exit;
        if LoggedInUser."User Security ID" = Rec."User Security ID" then
            exit;
        if not UserPermissions.CanManageUsersOnTenant(CurrentUserSecurityId) then
            Error(CannotModifyOtherUsersErr);
    end;
}

