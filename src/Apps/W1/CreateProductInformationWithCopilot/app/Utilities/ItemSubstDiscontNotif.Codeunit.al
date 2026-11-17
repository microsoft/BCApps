// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Substitution;

using System.Environment.Configuration;

codeunit 7346 "Item Subst. Discont. Notif."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        SuggestionsDiscontinuedMsg: Label 'Copilot item substitution suggestions are no longer available. Select Use modern search in Search on the Items list to find alternative substitutions.';
        DontShowAgainLbl: Label 'Don''t show again';
        NotificationNameLbl: Label 'Copilot item substitution suggestions discontinued';
        NotificationDescriptionTxt: Label 'Show a notification on the Item Substitution Entry page that Copilot item substitution suggestions are no longer available.';
        FeatureNameTok: Label 'Item Substitution Suggestions', Locked = true;

    procedure SendNotification()
    var
        MyNotifications: Record "My Notifications";
        DiscontinuedNotification: Notification;
    begin
        if not WasFeatureUsed() then
            exit;
        if not MyNotifications.IsEnabled(GetNotificationId()) then
            exit;

        DiscontinuedNotification.Id := GetNotificationId();
        DiscontinuedNotification.Message := SuggestionsDiscontinuedMsg;
        DiscontinuedNotification.Scope := NotificationScope::LocalScope;
        DiscontinuedNotification.AddAction(DontShowAgainLbl, Codeunit::"Item Subst. Discont. Notif.", 'DisableNotification');
        DiscontinuedNotification.Send();
    end;

    procedure DisableNotification(DiscontinuedNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetNotificationId()) then
            MyNotifications.InsertDefault(GetNotificationId(), NotificationNameLbl, NotificationDescriptionTxt, false);
    end;

    local procedure GetNotificationId(): Guid
    begin
        exit('6a379e6c-ef43-4d99-85bd-479de68224ed');
    end;

    local procedure WasFeatureUsed(): Boolean
    var
        FeatureUptakeRecRef: RecordRef;
        CurrentModuleInfo: ModuleInfo;
        TenantLevelUserSecurityId: Guid;
        FeatureWasUsed: Boolean;
    begin
        FeatureUptakeRecRef.Open(8703); // Database::"Feature Uptake"
        if not FeatureUptakeRecRef.ReadPermission() then
            exit(false);

        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        FeatureUptakeRecRef.Field(1).SetRange(FeatureNameTok);
        FeatureUptakeRecRef.Field(2).SetRange(TenantLevelUserSecurityId);
        FeatureUptakeRecRef.Field(3).SetRange(CurrentModuleInfo.Publisher());
        FeatureWasUsed := not FeatureUptakeRecRef.IsEmpty();
        FeatureUptakeRecRef.Close();
        exit(FeatureWasUsed);
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", OnInitializingNotificationWithDefaultState, '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        if not WasFeatureUsed() then
            exit;

        MyNotifications.InsertDefault(GetNotificationId(), NotificationNameLbl, NotificationDescriptionTxt, true);
    end;
}