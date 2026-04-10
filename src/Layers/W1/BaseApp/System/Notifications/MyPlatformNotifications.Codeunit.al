namespace System.Environment.Configuration;

using System.Environment;

codeunit 1518 "My Platform Notifications"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        WorkDateNotificationNameTxt: Label 'Work Date Reminder';
        WorkDateNotificationDescTxt: Label 'Notifies the user that the work date in the system is different from today''s date and provides a link to change the work date.';

    local procedure GetNotificationStatus(NotificationId: Guid): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Get(UserId, NotificationId) then
            InsertDefaultNotification(NotificationId, true);

        exit(MyNotifications.IsEnabled(NotificationId));
    end;

    local procedure GetWorkDateNotificationId(): Guid
    begin
        exit('53C1D678-1994-4981-97CE-D12D9EB887B0');
    end;

    local procedure InsertDefaultNotification(NotificationId: Guid; Enable: Boolean)
    var
        MyNotifications: Record "My Notifications";
        TenantLicenseState: Codeunit "Tenant License State";
    begin
        case NotificationId of
            GetWorkDateNotificationId():
                begin
                    // work date notification should be disabled in evaluation mode by default unless changed by user later
                    if not MyNotifications.Get(UserId, NotificationId) and TenantLicenseState.IsEvaluationMode() then
                        Enable := false;

                    MyNotifications.InsertDefault(NotificationId, WorkDateNotificationNameTxt, WorkDateNotificationDescTxt, Enable);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    begin
        InsertDefaultNotification(GetWorkDateNotificationId(), true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetNotificationStatus', '', false, false)]
    local procedure OnGetNotificationStatus(NotificationId: Guid; var IsEnabled: Boolean)
    begin
        IsEnabled := GetNotificationStatus(NotificationId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'SetNotificationStatus', '', false, false)]
    local procedure OnSetNotificationStatus(NotificationId: Guid; Enable: Boolean)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.SetStatus(NotificationId, Enable) then
            InsertDefaultNotification(NotificationId, Enable);
    end;
}

