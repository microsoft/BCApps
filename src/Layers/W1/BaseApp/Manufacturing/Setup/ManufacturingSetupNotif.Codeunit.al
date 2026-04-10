// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.DataAdministration;

using Microsoft.Inventory.Setup;
using System.Environment.Configuration;

codeunit 99000779 "Manufacturing Setup Notif."
{
    var
        PlanningFieldsNotificationNameTxt: Label 'Planning fields setup';
        PlanningFieldsNotificationDescriptionTxt: Label 'Show warning to enter planning parameters in Inventory Setup page.';
        NotificationActionDisableTxt: Label 'Don''t show me again';
        NotificationActionOpenPageTxt: Label 'Open Inventory Setup';
        NotificationMessageMsg: Label 'Use Inventory Setup page to update Planning fields.';

    procedure ShowPlanningFieldsMoveNotification()
    var
        MyNotifications: Record "My Notifications";
        Notification: Notification;
    begin
        if not MyNotifications.IsEnabled(GetPlanningFieldsMoveNotificationID()) then
            exit;
        Notification.Id := GetPlanningFieldsMoveNotificationID();
        Notification.Message := NotificationMessageMsg;
        Notification.AddAction(NotificationActionOpenPageTxt, 99000779, 'OpenInventorySetupFromNotification');
        Notification.AddAction(NotificationActionDisableTxt, 99000779, 'DisablePlanningFieldsMoveNotification');
        Notification.Send();
    end;

    procedure OpenInventorySetupFromNotification(Notification: Notification)
    begin
        Page.RunModal(Page::"Inventory Setup");
    end;

    procedure DisablePlanningFieldsMoveNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(Notification.Id) then
            MyNotifications.InsertDefault(
              Notification.Id,
              PlanningFieldsNotificationNameTxt,
              PlanningFieldsNotificationDescriptionTxt,
              false);
    end;

    procedure GetPlanningFieldsMoveNotificationID(): Guid
    begin
        exit('6d9d1f9a-3826-4b5e-81cd-be6e1fd8849f');
    end;
}
