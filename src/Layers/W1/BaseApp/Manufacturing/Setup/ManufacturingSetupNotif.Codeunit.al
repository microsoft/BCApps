// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.DataAdministration;

using Microsoft.Inventory.Setup;
#if not CLEAN29
using System.Apps;
using System.Environment;
#endif
using System.Environment.Configuration;

codeunit 99000779 "Manufacturing Setup Notif."
{
    var
        PlanningFieldsNotificationNameTxt: Label 'Planning fields setup';
        PlanningFieldsNotificationDescriptionTxt: Label 'Show warning to enter planning parameters in Inventory Setup page.';
        NotificationActionDisableTxt: Label 'Don''t show me again';
        NotificationActionOpenPageTxt: Label 'Open Inventory Setup';
        NotificationMessageMsg: Label 'Use Inventory Setup page to update Planning fields.';
#if not CLEAN29
        SubcontractingAppIdTok: Label '1f32a50d-0057-4b95-b5df-cc04d7e89470', Locked = true;
        SubcontractingAppNotificationNameTxt: Label 'Install the Subcontracting app';
        SubcontractingAppNotificationDescriptionTxt: Label 'Suggest installing the Subcontracting app when opening the obsolete Subcontracting Worksheet.';
        SubcontractingAppNotificationMsg: Label 'The Subcontracting Worksheet is being replaced by the Subcontracting app. Install it to get the new experience.';
        InstallSubcontractingAppActionTxt: Label 'Install';
#endif

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
#if not CLEAN29

    internal procedure ShowInstallSubcontractingAppNotification()
    var
        MyNotifications: Record "My Notifications";
        EnvironmentInformation: Codeunit "Environment Information";
        ExtensionManagement: Codeunit "Extension Management";
        Notification: Notification;
    begin
        if not EnvironmentInformation.IsSaaS() then
            exit;
        if ExtensionManagement.IsInstalledByAppId(GetSubcontractingAppId()) then
            exit;
        if not MyNotifications.IsEnabled(GetInstallSubcontractingAppNotificationID()) then
            exit;

        Notification.Id := GetInstallSubcontractingAppNotificationID();
        Notification.Message := SubcontractingAppNotificationMsg;
        Notification.Scope := NotificationScope::LocalScope;
        Notification.AddAction(InstallSubcontractingAppActionTxt, Codeunit::"Manufacturing Setup Notif.", 'InstallSubcontractingApp');
        Notification.AddAction(NotificationActionDisableTxt, Codeunit::"Manufacturing Setup Notif.", 'DisableInstallSubcontractingAppNotification');
        Notification.Send();
    end;

    internal procedure InstallSubcontractingApp(Notification: Notification)
    var
        ExtensionManagement: Codeunit "Extension Management";
    begin
        ExtensionManagement.InstallMarketplaceExtension(GetSubcontractingAppId());
    end;

    internal procedure DisableInstallSubcontractingAppNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(Notification.Id) then
            MyNotifications.InsertDefault(
              Notification.Id,
              SubcontractingAppNotificationNameTxt,
              SubcontractingAppNotificationDescriptionTxt,
              false);
    end;

    local procedure GetSubcontractingAppId(): Guid
    begin
        exit(SubcontractingAppIdTok);
    end;

    local procedure GetInstallSubcontractingAppNotificationID(): Guid
    begin
        exit('a3f6c1e4-9b2d-4f0a-8c5e-6d7b1f2a3c4d');
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure InitializeInstallSubcontractingAppNotification()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(
          GetInstallSubcontractingAppNotificationID(),
          SubcontractingAppNotificationNameTxt,
          SubcontractingAppNotificationDescriptionTxt,
          true);
    end;
#endif
}
