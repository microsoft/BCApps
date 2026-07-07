// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Apps;
using System.Environment;
using System.Environment.Configuration;

/// <summary>
/// Codeunit Shpfy Belgian Localization (ID 30410).
/// Notifies the user, on Belgian localizations, that the Shopify Connector BE
/// extension is required to synchronize Belgian companies and customers (which
/// must use the Enterprise No.), and offers to install it from the marketplace.
/// </summary>
codeunit 30410 "Shpfy Belgian Localization"
{
    Access = Internal;

    var
        BelgianCountryCodeTok: Label 'BE', Locked = true;
        InstallActionLbl: Label 'Install';
        DontShowThisAgainMsg: Label 'Don''t show this again.';
        InstallNotificationMsg: Label 'Belgian customers use the Enterprise No. as their tax registration identifier. Install the Shopify Connector BE extension to synchronize Belgian companies and customers.';
        InstallNotificationNameTok: Label 'Notify user to install the Shopify Connector BE extension.';
        InstallNotificationDescTok: Label 'Show a notification informing the user that the Shopify Connector BE extension is required for Belgian localizations.';

    /// <summary>
    /// Sends the install notification when the environment is a Belgian localization
    /// and the Shopify Connector BE extension is not installed.
    /// </summary>
    internal procedure ShowInstallNotificationIfNeeded()
    var
        MyNotifications: Record "My Notifications";
        InstallNotification: Notification;
    begin
        if not IsBelgianLocalization() then
            exit;

        if IsExtensionInstalled() then
            exit;

        if not MyNotifications.IsEnabled(GetNotificationId()) then
            exit;

        InstallNotification.Id := GetNotificationId();
        InstallNotification.Message := InstallNotificationMsg;
        InstallNotification.Scope := NotificationScope::LocalScope;
        InstallNotification.AddAction(InstallActionLbl, Codeunit::"Shpfy Belgian Localization", 'InstallExtension');
        InstallNotification.AddAction(DontShowThisAgainMsg, Codeunit::"Shpfy Belgian Localization", 'DisableNotification');
        InstallNotification.Send();
    end;

    procedure InstallExtension(Notification: Notification)
    var
        ExtensionManagement: Codeunit "Extension Management";
    begin
        ExtensionManagement.InstallMarketplaceExtension(GetExtensionAppId());
    end;

    procedure DisableNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if MyNotifications.WritePermission() then
            if not MyNotifications.Disable(GetNotificationId()) then
                MyNotifications.InsertDefault(GetNotificationId(), InstallNotificationNameTok, InstallNotificationDescTok, false);
    end;

    local procedure IsBelgianLocalization(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.GetApplicationFamily() = BelgianCountryCodeTok);
    end;

    local procedure IsExtensionInstalled(): Boolean
    var
        ExtensionManagement: Codeunit "Extension Management";
    begin
        exit(ExtensionManagement.IsInstalledByAppId(GetExtensionAppId()));
    end;

    local procedure GetExtensionAppId(): Guid
    begin
        exit('c2d93c78-f87a-4b0e-b71f-570f578d78de');
    end;

    local procedure GetNotificationId(): Guid
    begin
        exit('ca66423d-4607-4a81-8805-2f5e58e70373');
    end;
}
