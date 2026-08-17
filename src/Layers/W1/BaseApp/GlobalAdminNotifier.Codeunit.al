// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

using Microsoft.RoleCenters;
using System.Azure.Identity;

/// <summary>
/// The purpose of this codeunit is to notify users with only Global Administration role that their capabilities in Business Central are limited. 
/// </summary>

codeunit 1444 "Global Admin Notifier"
{
    Access = Internal;

    var
        NotificationIdTxt: Label '73e599ef-135f-44da-9fa5-00d3fe3ba32c', Locked = true;
        InternalAdminNotificationCategoryTok: Label 'Internal Admin Notification', Locked = true;
        MessageMsg: Label 'You are assigned to the %1 role in Business Central but you are not assigned to a product license.', Comment = '%1 - The assigned role, either the GlobalAdminLbl or D365AdminLbl';
        GlobalAdminLbl: Label 'Global Administrator', Comment = 'Refers to the Global Administrator role of Microsoft Entra ID';
        D365AdminLbl: Label 'Dynamics 365 Administrator', Comment = 'Refers to the Dynamics 365 Administrator role of Microsoft Entra ID';
        ActionTxt: Label 'Learn more';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Role Center Notification Mgt.", 'OnBeforeShowNotifications', '', false, false)]
    local procedure SendGlobalAdminNotification()
    var
        GlobalAdminNotification: Notification;
        Message: Text;
        IsUserGlobalAdmin: Boolean;
    begin
        if not IsUserInternalAdminOnly(IsUserGlobalAdmin) then
            exit;

        if IsUserGlobalAdmin then
            Message := StrSubstNo(MessageMsg, GlobalAdminLbl)
        else
            Message := StrSubstNo(MessageMsg, D365AdminLbl);

        GlobalAdminNotification.Id := NotificationIdTxt;
        GlobalAdminNotification.Message := Message;
        GlobalAdminNotification.AddAction(ActionTxt, Codeunit::"Global Admin Notifier", 'DetailedMessage');
        GlobalAdminNotification.SetData('IsGlobalAdmin', Format(IsUserGlobalAdmin));
        GlobalAdminNotification.Send();

        Session.LogMessage('0000C0T', 'Notification was sent to user.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InternalAdminNotificationCategoryTok);
    end;

    internal procedure DetailedMessage(var Notification: Notification)
    var
        GlobalAdminMessagePage: Page "Global Admin Message";
        IsUserGlobalAdmin: Boolean;
    begin
        Evaluate(IsUserGlobalAdmin, Notification.GetData('IsGlobalAdmin'));

        Session.LogMessage('0000C0U', 'User clicked on notification action.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InternalAdminNotificationCategoryTok);

        GlobalAdminMessagePage.SetIsGlobalAdmin(IsUserGlobalAdmin);
        GlobalAdminMessagePage.RunModal();
    end;

    // checks if the current user has only the Global Admin plan assigned
    local procedure IsUserInternalAdminOnly(IsUserGlobalAdmin: Boolean): Boolean
    var
        PlanIds: Codeunit "Plan Ids";
        UsersInPlans: Query "Users In Plans";
        IsUserD365Admin: Boolean;
        DoesUserHaveOtherPlans: Boolean;
    begin
        UsersInPlans.SetFilter(User_Security_ID, UserSecurityId());

        if not UsersInPlans.Open() then
            exit(false);

        while UsersInPlans.Read() do
            case UsersInPlans.Plan_ID of
                PlanIds.GetGlobalAdminPlanId():
                    IsUserGlobalAdmin := true;
                PlanIds.GetD365AdminPlanId():
                    IsUserD365Admin := true;
                else
                    DoesUserHaveOtherPlans := true;
            end;

        exit((IsUserGlobalAdmin or IsUserD365Admin) and (not DoesUserHaveOtherPlans));
    end;
}
