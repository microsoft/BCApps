// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using System.Environment.Configuration;
using System.IO;
using System.Utilities;

codeunit 8623 "Dimensions Notifications"
{
    var
        DimensionsInConfigPackageMsg: Label 'This configuration package contains dimensions. This can lead to inconsistencies.';
        DoYouWantToContinueMsg: Label ' Do you want to continue?';
        ConfigPackageNotificationTitleTxt: Label 'Configuration package contains dimensions.';
        ConfigPackageNotificationDescriptionTxt: Label 'Show a notification when a configuration package contains dimension tables, as these can lead to data inconsistencies.';
        DontShowAgainMsg: Label 'Don''t show again.';

    internal procedure DontShowAgainConfigPackageNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Get(UserId(), GetConfigPackageNotificationId()) then
            MyNotifications.InsertDefault(GetConfigPackageNotificationId(), ConfigPackageNotificationTitleTxt, ConfigPackageNotificationDescriptionTxt, false)
        else
            MyNotifications.Disable(GetConfigPackageNotificationId());
    end;

    local procedure ConfigurationPackageHasDimensionTables(PackageCode: Code[20]): Boolean
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        ConfigPackageTable.SetRange("Package Code", PackageCode);
        ConfigPackageTable.SetFilter("Table ID", '%1|%2|%3|%4', Database::Dimension, Database::"Dimension Value", Database::"Dimension Set Entry", Database::"Dimension Set Tree Node");
        exit(ConfigPackageTable.Count() > 0);
    end;

    local procedure GetConfigPackageNotificationId(): Guid
    begin
        exit('cb187683-e11b-4ccc-a4cc-51307fd6defc');
    end;

    internal procedure SendConfigPackageNotificationIfEligible(PackageCode: Code[20])
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.IsEnabled(GetConfigPackageNotificationId()) then
            exit;
        if not ConfigurationPackageHasDimensionTables(PackageCode) then
            exit;
        SendConfigPackageNotification();
    end;

    internal procedure ConfirmPackageHasDimensionsWarning(PackageCode: Code[20]): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfigurationPackageHasDimensionTables(PackageCode) then
            exit(true);

        exit(ConfirmManagement.GetResponseOrDefault(DimensionsInConfigPackageMsg + DoYouWantToContinueMsg, true));
    end;

    local procedure SendConfigPackageNotification()
    var
        DimensionsNotification: Notification;
    begin
        DimensionsNotification.Id(GetConfigPackageNotificationId());
        DimensionsNotification.Message(DimensionsInConfigPackageMsg);
        DimensionsNotification.Scope(NotificationScope::LocalScope);
        DimensionsNotification.AddAction(DontShowAgainMsg, Codeunit::"Dimensions Notifications", 'DontShowAgainConfigPackageNotification');
        DimensionsNotification.Send();
    end;
}
