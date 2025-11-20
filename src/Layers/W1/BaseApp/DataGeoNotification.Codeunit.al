// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using System.Environment.Configuration;
using System.Apps;
using System.Environment;
using Microsoft.Foundation.Company;

codeunit 1760 "Data Geo. Notification"
{
    Permissions = TableData "NAV App Installed App" = r;

    var
        DontShowAgainMsg: Label 'Don''t show me again';
        LearnMoreMsg: Label 'Click here to learn more about what that means';
        GeoNotificationsExistingAppsMsg: Label 'Your Dynamics 365 Business Central environment has apps installed that may transfer data to other geographies than the current geography of your Dynamics 365 Business Central environment. This is to ensure proper functionality of the apps.';
        GeoNotificationTxt: Label 'Data out of geolocation apps';
        GeoNotificationDescTxt: Label 'Show a warning when there are apps installed that may possibly transfer data outside your countries'' jurisdiction';
        GeoNotificationExistingAppsIdTxt: Label 'c414a6bd-a8f2-4182-9059-0c4e88238046';
        LearnMoreUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2153389';

    procedure ShowExistingAppsNotification()
    var
        DataOutOfGeoApp: Codeunit "Data Out Of Geo. App";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if IsNotificationDisabled() then
            exit;

        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;

        if IsDemoCompany() then
            exit;

        if not DataOutOfGeoApp.AlreadyInstalled() then
            exit;

        FireExistingAppsNotification();
    end;

    [Scope('OnPrem')]
    procedure DisableNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if MyNotifications.WritePermission then
            if not MyNotifications.Disable(Notification.Id) then
                MyNotifications.InsertDefault(Notification.Id, GeoNotificationTxt,
                              GeoNotificationDescTxt, false);
    end;

    [Scope('OnPrem')]
    procedure LearnMoreNotification(Notification: Notification)
    begin
        Hyperlink(LearnMoreUrlTxt);
    end;

    local procedure FireExistingAppsNotification()
    var
        Notification: Notification;
    begin
        CreateNotification(Notification, GeoNotificationExistingAppsIdTxt, GeoNotificationsExistingAppsMsg);
        Notification.Send();
    end;

    local procedure CreateNotification(var Notification: Notification; ID: Text; Message: Text)
    begin
        Notification.Id(ID);
        Notification.Message(Message);
        Notification.AddAction(DontShowAgainMsg, CODEUNIT::"Data Geo. Notification", 'DisableNotification');
        Notification.AddAction(LearnMoreMsg, CODEUNIT::"Data Geo. Notification", 'LearnMoreNotification');
    end;

    local procedure IsDemoCompany(): Boolean
    var
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        exit(CompanyInformationMgt.IsDemoCompany());
    end;

    local procedure IsNotificationDisabled(): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(not MyNotifications.IsEnabled(GeoNotificationExistingAppsIdTxt));
    end;


}