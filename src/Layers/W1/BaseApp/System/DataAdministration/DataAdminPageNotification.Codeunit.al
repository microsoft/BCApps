// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.DataAdministration;

using System.Environment.Configuration;
using System.Threading;

codeunit 9041 "Data Admin. Page Notification"
{
    Access = Internal;

    var
        RefreshNotificationNameTxt: Label 'Suggest the Refresh action on the Data Administration page.';
        RefreshNotificationDescriptionTxt: Label 'Suggests the Refresh action or scheduling a job queue entry on the Data Administration page';
        RefreshNotificationTxt: Label 'Use the Refresh action to update the data on the page. For large databases this can take a while.';
        RefreshActionTxt: Label 'Refresh';
        ScheduleJQActionTxt: Label 'Schedule background refresh';
        HideNotificationTxt: Label 'Don''t show again';

    procedure ShowRefreshNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        RefreshNotification: Notification;
        BlankRecordId: RecordId;
    begin
        if IsNotificationEnabledForCurrentUser() then begin
            RefreshNotification.Id(GetNotificationID());
            RefreshNotification.Message(RefreshNotificationTxt);
            RefreshNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
            RefreshNotification.AddAction(
              RefreshActionTxt, CODEUNIT::"Data Admin. Page Notification", 'RefreshTableInformationCache');
            RefreshNotification.AddAction(
              ScheduleJQActionTxt, CODEUNIT::"Data Admin. Page Notification", 'ScheduleTableInfoRefreshJobQueue');
            RefreshNotification.AddAction(
              HideNotificationTxt, CODEUNIT::"Data Admin. Page Notification", 'DontNotifyCurrentUserAgain');
            NotificationLifecycleMgt.SendNotification(RefreshNotification, BlankRecordId);
        end
    end;

    procedure RefreshTableInformationCache(Notification: Notification)
    var
        TableInformationCache: Codeunit "Table Information Cache";
    begin
        TableInformationCache.RefreshTableInformationCache();
    end;

    procedure ScheduleTableInfoRefreshJobQueue(Notification: Notification)
    var
        ScheduleTableInfoRefreshJQ: Codeunit "Schedule Table Info Refresh JQ";
    begin
        ScheduleTableInfoRefreshJQ.ScheduleTableInfoRefreshJobQueue();
    end;

    procedure DontNotifyCurrentUserAgain(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetNotificationID()) then
            MyNotifications.InsertDefault(GetNotificationID(), RefreshNotificationNameTxt, RefreshNotificationDescriptionTxt, false);
    end;

    procedure RecallNotificationForCurrentUser()
    var
        NotificationToRecall: Notification;
    begin
        NotificationToRecall.Id := GetNotificationID();
        NotificationToRecall.Recall();
    end;

    local procedure GetNotificationID(): Guid
    begin
        exit('e055ea6b-a761-4cfa-8077-37666b1bba45');
    end;

    local procedure IsNotificationEnabledForCurrentUser(): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabled(GetNotificationID()));
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure InsertDefaultStateOnInitializingNotificationWithDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetNotificationID(), RefreshNotificationNameTxt, RefreshNotificationDescriptionTxt, true);
    end;
}