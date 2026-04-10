codeunit 132214 "Library - Permissions"
{
    trigger OnRun()
    begin
    end;

    procedure AddPermissionSetToPlan(PermissionSetCode: Code[20]; PlanID: Guid)
    var
        PlanConfiguration: Codeunit "Plan Configuration";
        Scope: Option System,Tenant;
        NullGuid: Guid;
    begin
        PlanConfiguration.AddDefaultPermissionSetToPlan(PlanID, PermissionSetCode, NullGuid, Scope::Tenant);
    end;

    procedure AddPermissionSetToUser(var User: Record User; var PermissionSet: Record "Permission Set"; CompanyName: Text[30])
    begin
        AddPermissionSetNameToUser(User."User Security ID", PermissionSet."Role ID", CompanyName);
    end;

    procedure AddPermissionSetNameToUser(UserSID: Guid; PermissionSetName: Code[20]; CompanyName: Text[30])
    var
        AccessControl: Record "Access Control";
        PermissionSet: Record "Permission Set";
    begin
        AccessControl.SetRange("Role ID", PermissionSetName);
        if PermissionSet.Get(PermissionSetName) then
            AccessControl.SetRange(Scope, AccessControl.Scope::System)
        else
            AccessControl.SetRange(Scope, AccessControl.Scope::Tenant);
        AccessControl.SetRange("User Security ID", UserSID);
        AccessControl.SetRange("Company Name", CompanyName);
        if AccessControl.Count > 0 then
            AccessControl.DeleteAll(true);
        AccessControl.Init();
        AccessControl."Role ID" := PermissionSetName;
        if PermissionSet.Get(PermissionSetName) then
            AccessControl.Scope := AccessControl.Scope::System
        else
            AccessControl.Scope := AccessControl.Scope::Tenant;
        AccessControl."User Security ID" := UserSID;
        AccessControl."Company Name" := CompanyName;
        AccessControl.Insert(true);
    end;

    procedure AddPermission(RoleID: Code[20]; ObjectType: Option; ObjectID: Integer)
    var
        Permission: Record Permission;
    begin
        Permission.Init();
        Permission."Role ID" := RoleID;
        Permission."Object Type" := ObjectType;
        Permission."Object ID" := ObjectID;
        if ObjectType = Permission."Object Type"::"Table Data" then begin
            Permission."Read Permission" := Permission."Read Permission"::Yes;
            Permission."Insert Permission" := Permission."Insert Permission"::" ";
            Permission."Modify Permission" := Permission."Modify Permission"::" ";
            Permission."Delete Permission" := Permission."Delete Permission"::" ";
            Permission."Execute Permission" := Permission."Execute Permission"::" ";
        end;
        Permission.Insert(true);
    end;

    procedure AddTenantPermission(AppID: Guid; RoleID: Code[20]; ObjectType: Option; ObjectID: Integer)
    var
        TenantPermission: Record "Tenant Permission";
    begin
        TenantPermission.Init();
        TenantPermission."App ID" := AppID;
        TenantPermission."Role ID" := RoleID;
        TenantPermission."Object Type" := ObjectType;
        TenantPermission."Object ID" := ObjectID;
        if ObjectType = TenantPermission."Object Type"::"Table Data" then begin
            TenantPermission."Read Permission" := TenantPermission."Read Permission"::Yes;
            TenantPermission."Insert Permission" := TenantPermission."Insert Permission"::" ";
            TenantPermission."Modify Permission" := TenantPermission."Modify Permission"::" ";
            TenantPermission."Delete Permission" := TenantPermission."Delete Permission"::" ";
            TenantPermission."Execute Permission" := TenantPermission."Execute Permission"::" ";
        end;
        TenantPermission.Insert(true);
    end;

    procedure AddUserToPlan(UserID: Guid; PlanID: Guid)
    var
        AzureADPlan: Codeunit "Azure AD Plan";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
    begin
        if AzureADPlan.IsPlanAssignedToUser(PlanID, UserID) then
            exit;

        AzureADPlanTestLibrary.AssignUserToPlan(UserID, PlanID);
    end;

    procedure CreateUser(var User: Record User; NewUserName: Text[50]; IsWindowsUser: Boolean)
    begin
        User.Init();
        User."User Security ID" := CreateGuid();
        if NewUserName = '' then
            User."User Name" := CopyStr(GetGuidString(), 1, MaxStrLen(User."User Name"))
        else
            User."User Name" := NewUserName;
        User."Full Name" := User."User Name";
        if IsWindowsUser then
            User."Windows Security ID" := Sid(User."User Name");
        User.Insert(true);
    end;

    procedure CreateWindowsUser(var User: Record User; UserName: Code[50])
    begin
        User.SetRange("User Name", UserName);
        if not User.FindFirst() then
            CreateUser(User, UserName, true);
    end;

    procedure CreateWindowsUserSecurityID(UserName: Code[50]): Guid
    var
        User: Record User;
    begin
        CreateWindowsUser(User, UserName);
        exit(User."User Security ID");
    end;

    procedure CreateAzureActiveDirectoryUser(var User: Record User; NewUserName: Text[50]): Guid
    begin
        CreateUser(User, NewUserName, false);
        exit(CreateAzureActiveDirectoryUserCloudOnly(User));
    end;

    procedure CreateAzureActiveDirectoryUserCloudOnly(var User: Record User): Guid
    var
        UserProperty: Record "User Property";
    begin
        if UserProperty.Get(User."User Security ID") then begin
            UserProperty."Authentication Object ID" := CreateGuid();
            UserProperty.Modify(true);
        end else begin
            UserProperty.Init();
            UserProperty."Authentication Object ID" := CreateGuid();
            UserProperty."User Security ID" := User."User Security ID";
            UserProperty.Insert();
        end;
        exit(UserProperty."Authentication Object ID");
    end;

    procedure CreateUserInPlan(NewUserName: Text[50]; PlanID: Guid) UserID: Guid
    begin
        UserID := CreateUserWithName(NewUserName);
        AddUserToPlan(UserID, PlanID);
    end;

    procedure CreateUserWithName(NewUserName: Text[50]): Guid
    var
        User: Record User;
    begin
        CreateUser(User, NewUserName, false);
        exit(User."User Security ID");
    end;

    procedure GetNonExistingUserID(): Text[65]
    var
        User: Record User;
        UserID: Text[65];
    begin
        repeat
            UserID := CreateGuid();
            User.SetRange("User Name", UserID);
        until User.IsEmpty();
        exit(UserID)
    end;

    procedure CreatePermissionSet(var TenantPermissionSet: Record "Tenant Permission Set"; NewCode: Code[20])
    begin
        TenantPermissionSet.SetRange("Role ID", NewCode);
        if TenantPermissionSet.FindFirst() then
            exit;
        if NewCode <> '' then
            TenantPermissionSet."Role ID" := NewCode
        else
            TenantPermissionSet."Role ID" := CopyStr(GetGuidString(), 1, MaxStrLen(TenantPermissionSet."Role ID"));
        TenantPermissionSet.Name := TenantPermissionSet."Role ID" + ' Name';
        TenantPermissionSet.Insert(true);
    end;

    procedure CreatePermissionSetInPlan(PermissionSetCode: Code[20]; PlanID: Guid)
    begin
        CreatePermissionSetWithCode(PermissionSetCode);
        AddPermissionSetToPlan(PermissionSetCode, PlanID);
    end;

    procedure CreatePermissionSetWithCode(PermissionSetCode: Code[20])
    var
        TenantPermissionSet: Record "Tenant Permission Set";
    begin
        CreatePermissionSet(TenantPermissionSet, PermissionSetCode);
    end;

    procedure CreateTenantPermissionSet(var TenantPermissionSet: Record "Tenant Permission Set"; NewCode: Code[20]; AppID: Guid)
    begin
        if NewCode <> '' then
            TenantPermissionSet."Role ID" := NewCode
        else
            TenantPermissionSet."Role ID" := CopyStr(GetGuidString(), 1, MaxStrLen(TenantPermissionSet."Role ID"));
        TenantPermissionSet.Name := TenantPermissionSet."Role ID" + ' Name';
        TenantPermissionSet."App ID" := AppID;
        TenantPermissionSet.Insert(true);
    end;

    local procedure GetGuidString(): Text
    begin
        exit(DelChr(Format(CreateGuid()), '=', '{-}'));
    end;

    procedure GetMyUser(var User: Record User)
    begin
        Initialize();
        User.SetRange("User Name", UserId);
        User.FindFirst();
        User.SetRange("User Name");
    end;

    local procedure Initialize()
    begin
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");
    end;

    procedure SetTestTenantEnvironmentType(IsSandbox: Boolean)
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        TenantSettingsHelper: DotNet NavTenantSettingsHelper;
    begin
        TenantSettingsHelper.SetTestTenantEnvironmentType(IsSandbox);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(IsSandbox);
    end;

    procedure SetTestabilitySoftwareAsAService(EnableSoftwareAsAServiceForTest: Boolean)
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(EnableSoftwareAsAServiceForTest);
    end;
}

