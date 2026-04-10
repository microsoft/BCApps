namespace System.Security.AccessControl;

using System.Environment.Configuration;
using System.Security.User;
using System.Text;

codeunit 9001 "Permission Pages Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        NoOfRecords: Integer;
        NoOfColumns: Integer;
        OffSet: Integer;
        CannotManagePermissionsErr: Label 'Only users with the SUPER or the SECURITY permission set can create or edit permission sets.';
        MSPermSetChangedTxt: Label 'Original System permission set changed';
        MSPermSetChangedDescTxt: Label 'Show a notification if one or more original System permission sets that you have copied to create your own set changes.';
        MSPermSetChangedMsg: Label 'One or more System permission sets that you have copied to create your own have changed. You may want to review the changed permission set in case the changes are relevant for your user-defined permission sets.';
        MSPermSetChangedShowDetailsTxt: Label 'Show more';
        MSPermSetChangedNeverShowAgainTxt: Label 'Don''t show again';
        CannotEditPermissionSetMsg: Label 'Permission sets of type System and Extension cannot be changed. Only permission sets of type User-Defined can be changed.';
        CannotEditPermissionSetDescTxt: Label 'Show a notification to inform users that permission sets of type System and Extension cannot be changed.';
        CannotEditPermissionSetTxt: Label 'Permission sets of type System and Extension cannot be changed.';
        ResolvePermissionNotificationIdTxt: Label '3301a843-3a72-4777-83a2-a1eeb2041efa', Locked = true;
        ResolvePermissionNotificationTxt: Label 'The permission sets highlighted in red no longer exist. For example, because the app that installed them has been uninstalled. It''s safe to delete these records to clean up the page.';
        ResolvePermissionsLbl: Label 'Resolve Permissions';
        UnableToRetrievePSErr: Label 'Unable to retrieve permission sets.';
        InvalidRoleIDErr: Label 'The permission set role ID cannot contain special characters such as ''&|()*@<>=.!?%.';
        RoleIDReservedCharactersTok: Label '''&|()*@<>=.!?%', Locked = true, Comment = 'Characters reserved for filter criterias or tokens.';


    procedure Init(NewNoOfRecords: Integer; NewNoOfColumns: Integer)
    begin
        OffSet := 0;
        NoOfRecords := NewNoOfRecords;
        NoOfColumns := NewNoOfColumns;
    end;

    procedure GetOffset(): Integer
    begin
        exit(OffSet);
    end;

    procedure AllColumnsLeft()
    begin
        OffSet -= NoOfColumns;
        if OffSet < 0 then
            OffSet := 0;
    end;

    procedure ColumnLeft()
    begin
        if OffSet > 0 then
            OffSet -= 1;
    end;

    procedure ColumnRight()
    begin
        if OffSet < NoOfRecords - NoOfColumns then
            OffSet += 1;
    end;

    procedure AllColumnsRight()
    begin
        OffSet += NoOfColumns;
        if OffSet > NoOfRecords - NoOfColumns then
            OffSet := NoOfRecords - NoOfColumns;
        if OffSet < 0 then
            OffSet := 0;
    end;

    procedure IsInColumnsRange(i: Integer): Boolean
    begin
        exit((i > OffSet) and (i <= OffSet + NoOfColumns));
    end;

    procedure IsPastColumnRange(i: Integer): Boolean
    begin
        exit(i >= OffSet + NoOfColumns);
    end;

    procedure IsPermissionSetEditable(AggregatePermissionSet: Record "Aggregate Permission Set"): Boolean
    begin
        exit(IsPermissionsInGivenScopeAndAppIdEditable(AggregatePermissionSet.Scope, AggregatePermissionSet."App ID"));
    end;

    local procedure IsPermissionsInGivenScopeAndAppIdEditable(AggregatePermissionSetScope: Option; AppId: Guid): Boolean
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        exit((AggregatePermissionSetScope = AggregatePermissionSet.Scope::Tenant) and IsNullGuid(AppId));
    end;

    procedure VerifyPermissionSetRoleID(RoleID: Code[20])
    begin
        if not IsPermissionSetRoleIDValid(RoleID) then
            Error(InvalidRoleIDErr);
    end;

    local procedure IsPermissionSetRoleIDValid(RoleID: Code[20]): Boolean
    begin
        exit(DelChr(RoleID, '=', RoleIDReservedCharactersTok) = RoleID);
    end;

    procedure CheckAndRaiseNotificationIfAppDBPermissionSetsChanged()
    var
        PermissionSetLink: Record "Permission Set Link";
        UserPermissions: Codeunit "User Permissions";
        Notification: Notification;
    begin
        if not UserPermissions.CanManageUsersOnTenant(UserSecurityId()) then
            exit;

        if not AppDbPermissionChangedNotificationEnabled() then
            exit;

        if not PermissionSetLink.SourceHashHasChanged() then
            exit;

        Notification.Id(GetAppDbPermissionSetChangedNotificationId());
        Notification.Message(MSPermSetChangedMsg);
        Notification.Scope(NOTIFICATIONSCOPE::LocalScope);
        Notification.AddAction(MSPermSetChangedShowDetailsTxt, CODEUNIT::"Permission Pages Mgt.",
          'AppDbPermissionSetChangedShowDetails');
        Notification.AddAction(MSPermSetChangedNeverShowAgainTxt, CODEUNIT::"Permission Pages Mgt.",
          'AppDbPermissionSetChangedDisableNotification');
        Notification.Send();
    end;

    procedure IsTenantPermissionSetEditable(TenantPermissionSet: Record "Tenant Permission Set"): Boolean
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        if AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, TenantPermissionSet."App ID", TenantPermissionSet."Role ID")
        then
            exit(IsPermissionSetEditable(AggregatePermissionSet));
    end;

    procedure ShowSecurityFilterForPermission(var OutputSecurityFilter: Text; Permission: Record Permission): Boolean
    begin
        Permission.CalcFields("Object Name");

        exit(ShowSecurityFilters(OutputSecurityFilter,
            Permission."Object ID", Permission."Object Name", Format(Permission."Security Filter"),
            false));
    end;

    procedure ShowSecurityFilterForTenantPermission(var OutputSecurityFilter: Text; TenantPermission: Record "Tenant Permission"; UserCanEditSecurityFilters: Boolean): Boolean
    begin
        TenantPermission.CalcFields("Object Name");

        exit(ShowSecurityFilters(OutputSecurityFilter,
            TenantPermission."Object ID", TenantPermission."Object Name", Format(TenantPermission."Security Filter"),
            UserCanEditSecurityFilters));
    end;

    local procedure ShowSecurityFilters(var OutputSecurityFilter: Text; InputObjectID: Integer; InputObjectName: Text; InputSecurityFilter: Text; UserCanEditSecurityFilters: Boolean): Boolean
    var
        TableFilter: Record "Table Filter";
        TableFilterPage: Page "Table Filter";
    begin
        TableFilter.FilterGroup(2);
        TableFilter.SetRange("Table Number", InputObjectID);
        TableFilter.FilterGroup(0);

        TableFilterPage.SetTableView(TableFilter);
        TableFilterPage.SetSourceTable(InputSecurityFilter, InputObjectID, InputObjectName);
        TableFilterPage.Editable := UserCanEditSecurityFilters;

        if ACTION::OK = TableFilterPage.RunModal() then begin
            OutputSecurityFilter := TableFilterPage.CreateTextTableFilter(false);
            exit(true);
        end;
    end;

    procedure AppDbPermissionSetChangedShowDetails(Notification: Notification)
    var
        PermissionSetLink: Record "Permission Set Link";
    begin
        PermissionSetLink.MarkWithChangedSource();
        PAGE.RunModal(PAGE::"Changed Permission Set List", PermissionSetLink);
        PermissionSetLink.UpdateSourceHashesOnAllLinks();
    end;

    procedure AppDbPermissionSetChangedDisableNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.Disable(GetAppDbPermissionSetChangedNotificationId());
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetAppDbPermissionSetChangedNotificationId(),
          MSPermSetChangedTxt,
          MSPermSetChangedDescTxt,
          true);

        MyNotifications.InsertDefault(GetCannotEditPermissionSetsNotificationId(),
          CannotEditPermissionSetTxt,
          CannotEditPermissionSetDescTxt,
          true);
    end;

    local procedure GetAppDbPermissionSetChangedNotificationId(): Guid
    begin
        exit('2712AD06-C48B-4C20-830E-347A60C9AE00');
    end;

    procedure AppDbPermissionChangedNotificationEnabled(): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabled(GetAppDbPermissionSetChangedNotificationId()));
    end;

    procedure DisallowEditingPermissionSetsForNonAdminUsers()
    var
        UserPermissions: Codeunit "User Permissions";
    begin
        if not UserPermissions.CanManageUsersOnTenant(UserSecurityId()) then
            Error(CannotManagePermissionsErr);
    end;

    procedure RaiseNotificationThatSecurityFilterNotEditableForSystemAndExtension()
    var
        Notification: Notification;
    begin
        if not CannotEditPermissionSetsNotificationEnabled() then
            exit;

        Notification.Id(GetCannotEditPermissionSetsNotificationId());
        Notification.Message(CannotEditPermissionSetMsg);
        Notification.Scope(NOTIFICATIONSCOPE::LocalScope);
        Notification.AddAction(MSPermSetChangedNeverShowAgainTxt, CODEUNIT::"Permission Pages Mgt.",
          'CannotEditPermissionSetsDisableNotification');
        Notification.Send();
    end;

    procedure CannotEditPermissionSetsNotificationEnabled(): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabled(GetCannotEditPermissionSetsNotificationId()));
    end;

    local procedure GetCannotEditPermissionSetsNotificationId(): Guid
    begin
        exit('687c66c9-404d-4480-9209-f46f0e34404e');
    end;

    procedure CannotEditPermissionSetsDisableNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.Disable(GetCannotEditPermissionSetsNotificationId());
    end;

    internal procedure CreateAndSendResolvePermissionNotification()
    var
        ResolvePermission: Notification;
        ResolvePermissionNotificationId: Guid;
    begin
        Evaluate(ResolvePermissionNotificationId, ResolvePermissionNotificationIdTxt);
        ResolvePermission.Id(ResolvePermissionNotificationId);
        ResolvePermission.Message := ResolvePermissionNotificationTxt;
        ResolvePermission.Scope := NOTIFICATIONSCOPE::LocalScope;
        ResolvePermission.AddAction(ResolvePermissionsLbl, Codeunit::"Permission Pages Mgt.", 'ResolvePermissionAction');
        ResolvePermission.Send();
    end;

    internal procedure ResolvePermissionAction(ResolvePermissionNotification: Notification)
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId());
        if not AccessControl.FindSet() then
            Error(UnableToRetrievePSErr);

        repeat
            if not (AccessControl."Role ID" in ['SUPER', 'SECURITY']) then
                if not AggregatePermissionSet.Get(AccessControl.Scope, AccessControl."App ID", AccessControl."Role ID") then
                    AccessControl.Mark(true);
        until AccessControl.Next() = 0;

        AccessControl.MarkedOnly(true);
        AccessControl.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Page, Page::"User Subform", 'OnPermissionSetNotFound', '', false, false)]
    local procedure ShowNotificationOnPermissionSetNotFound()
    begin
        CreateAndSendResolvePermissionNotification();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Permission Set Relation", 'OnShowSecurityFilterForTenantPermission', '', false, false)]
    local procedure ShowSecurityFilterForTenantPermissionSystem(var OutputSecurityFilter: Text; TenantPermission: Record "Tenant Permission")
    begin
        ShowSecurityFilterForTenantPermission(OutputSecurityFilter, TenantPermission, true);
    end;
}

