// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Apps;
using System.Environment;
using System.Environment.Configuration;
using System.Feedback;

codeunit 30211 "Shpfy Shop Mgt."
{
    var
        BelgianCountryCodeTok: Label 'BE', Locked = true;
        BelgianLocalizationAppIdTok: Label 'c2d93c78-f87a-4b0e-b71f-570f578d78de', Locked = true;
        InstallActionLbl: Label 'Install';
        DontShowThisAgainMsg: Label 'Don''t show this again.';
        ExpirationNotificationMsg: Label 'The Shopify Admin API used by your current Shopify connector will go out of support on %1. Please upgrade your Business Central environment.', Comment = '%1 - expiry date';
        BlockedNotificationMsg: Label 'The Shopify Admin API used by your current Shopify connector is no longer supported. To continue using the Shopify connector, please upgrade your Business Central environment.';
        ExpirationNotificationNameTok: Label 'Notify user of Shopify connector going out of support.';
        ExpirationNotificationDescTok: Label 'Show a notification informing the user that Shopify connector going out of support.';
        BlockedNotificationNameTok: Label 'Notify user of Shopify connector is out of support.';
        BlockedNotificationDescTok: Label 'Show a notification informing the user that Shopify connector is out of support.';
        NoItemNotificationNameTok: Label 'Notify user of Shopify connector has no items.';
        NoItemNotificationDescTok: Label 'Show a notification informing the user that Shopify connector has no items.';
        BelgianLocalizationNotificationMsg: Label 'Belgian customers use the Enterprise No. as their tax registration identifier. Install the Shopify Connector BE extension to synchronize Belgian companies and customers.';
        BelgianLocalizationNotificationNameTok: Label 'Notify user to install the Shopify Connector BE extension.';
        BelgianLocalizationNotificationDescTok: Label 'Show a notification informing the user that the Shopify Connector BE extension is required for Belgian localizations.';

    internal procedure IsEnabled(): Boolean
    var
        Shop: Record "Shpfy Shop";
    begin
        if not Shop.ReadPermission() then
            exit(false);

        Shop.SetRange(Enabled, true);
        exit(not Shop.IsEmpty());
    end;

    internal procedure SendExpirationNotification(ExpiryDate: Date)
    var
        MyNotifications: Record "My Notifications";
        ExpirationNotification: Notification;
    begin
        if MyNotifications.IsEnabled(GetExpirationNotificationId()) then begin
            ExpirationNotification.Id := GetExpirationNotificationId();
            ExpirationNotification.Message := StrSubstNo(ExpirationNotificationMsg, Format(ExpiryDate));
            ExpirationNotification.Scope := NotificationScope::LocalScope;
            ExpirationNotification.AddAction(DontShowThisAgainMsg, Codeunit::"Shpfy Shop Mgt.", 'DisableExpirationNotification');
            ExpirationNotification.Send();
        end;
    end;

    internal procedure SendBlockedNotification()
    var
        MyNotifications: Record "My Notifications";
        BlockedNotification: Notification;
    begin
        if MyNotifications.IsEnabled(GetBlockedNotificationId()) then begin
            BlockedNotification.Id := GetBlockedNotificationId();
            BlockedNotification.Message := BlockedNotificationMsg;
            BlockedNotification.Scope := NotificationScope::LocalScope;
            BlockedNotification.AddAction(DontShowThisAgainMsg, Codeunit::"Shpfy Shop Mgt.", 'DisableBlockedNotification');
            BlockedNotification.Send();
        end;
    end;

    local procedure GetExpirationNotificationId(): Guid
    begin
        exit('89b04070-dfda-435b-9e28-7370fd019d1b');
    end;

    local procedure GetBlockedNotificationId(): Guid
    begin
        exit('ab9b0be3-4755-4e72-bcbd-b0b19b453d10');
    end;

    internal procedure GetNoItemNotificationId(): Guid
    begin
        exit('f1e3f868-2c4c-4b0b-bdca-4e305a8a9154');
    end;

    procedure DisableExpirationNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if MyNotifications.WritePermission() then
            if not MyNotifications.Disable(GetExpirationNotificationId()) then
                MyNotifications.InsertDefault(GetExpirationNotificationId(), ExpirationNotificationNameTok, ExpirationNotificationDescTok, false);
    end;

    procedure DisableBlockedNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if MyNotifications.WritePermission() then
            if not MyNotifications.Disable(GetBlockedNotificationId()) then
                MyNotifications.InsertDefault(GetBlockedNotificationId(), BlockedNotificationNameTok, BlockedNotificationDescTok, false);
    end;

    internal procedure RequestFeedback()
    var
        Feedback: Codeunit "Microsoft User Feedback";
    begin
        Feedback.RequestFeedback('Shopify Connector', 'ShopifyConnector', 'Shopify Connector');
    end;

    procedure DisableNoItemNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if MyNotifications.WritePermission() then
            if not MyNotifications.Disable(GetNoItemNotificationId()) then
                MyNotifications.InsertDefault(GetNoItemNotificationId(), NoItemNotificationNameTok, NoItemNotificationDescTok, false);
    end;

    internal procedure SendBelgianLocalizationNotification()
    var
        MyNotifications: Record "My Notifications";
        EnvironmentInformation: Codeunit "Environment Information";
        ExtensionManagement: Codeunit "Extension Management";
        BelgianLocalizationNotification: Notification;
    begin
        if EnvironmentInformation.GetApplicationFamily() <> BelgianCountryCodeTok then
            exit;

        if ExtensionManagement.IsInstalledByAppId(GetBelgianLocalizationAppId()) then
            exit;

        if not MyNotifications.IsEnabled(GetBelgianLocalizationNotificationId()) then
            exit;

        BelgianLocalizationNotification.Id := GetBelgianLocalizationNotificationId();
        BelgianLocalizationNotification.Message := BelgianLocalizationNotificationMsg;
        BelgianLocalizationNotification.Scope := NotificationScope::LocalScope;
        BelgianLocalizationNotification.AddAction(InstallActionLbl, Codeunit::"Shpfy Shop Mgt.", 'InstallBelgianLocalization');
        BelgianLocalizationNotification.AddAction(DontShowThisAgainMsg, Codeunit::"Shpfy Shop Mgt.", 'DisableBelgianLocalizationNotification');
        BelgianLocalizationNotification.Send();
    end;

    procedure InstallBelgianLocalization(Notification: Notification)
    var
        ExtensionManagement: Codeunit "Extension Management";
    begin
        ExtensionManagement.InstallMarketplaceExtension(GetBelgianLocalizationAppId());
    end;

    procedure DisableBelgianLocalizationNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if MyNotifications.WritePermission() then
            if not MyNotifications.Disable(GetBelgianLocalizationNotificationId()) then
                MyNotifications.InsertDefault(GetBelgianLocalizationNotificationId(), BelgianLocalizationNotificationNameTok, BelgianLocalizationNotificationDescTok, false);
    end;

    local procedure GetBelgianLocalizationNotificationId(): Guid
    begin
        exit('ca66423d-4607-4a81-8805-2f5e58e70373');
    end;

    local procedure GetBelgianLocalizationAppId(): Guid
    begin
        exit(BelgianLocalizationAppIdTok);
    end;
}