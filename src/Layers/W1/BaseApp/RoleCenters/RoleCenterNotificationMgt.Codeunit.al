// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft;
using Microsoft.Utilities;
using System.DateTime;
using System.Security.User;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Security.Authentication;
using System.Reflection;

codeunit 1430 "Role Center Notification Mgt."
{
    Permissions = tabledata "User Personalization" = r,
                tabledata "All Profile" = r;

    trigger OnRun()
    begin
    end;

    var
        IsPreview: Boolean;
        TrialNotificationIdTxt: Label '9e359b60-3d2e-40c7-8680-3365d51937f7', Locked = true;
        TrialSuspendedNotificationIdTxt: Label '9e359b60-3d2e-40c7-8680-3365d51937f7', Locked = true;
        TrialExtendedNotificationIdTxt: Label '9e359b60-3d2e-40c7-8680-3365d51937f7';
        TrialExtendedSuspendedNotificationIdTxt: Label '9e359b60-3d2e-40c7-8680-3365d51937f7';
        PaidWarningNotificationIdTxt: Label '2751b488-ca52-42ef-b6d7-d7b4ba841e80', Locked = true;
        PaidSuspendedNotificationIdTxt: Label '2751b488-ca52-42ef-b6d7-d7b4ba841e80', Locked = true;
        SandboxNotificationIdTxt: Label 'd82835d9-a005-451a-972b-0d6532de2071', Locked = true;
        ChangeToPremiumExpNotificationIdTxt: Label '58982418-e1d1-4879-bda2-6033ca151b83', Locked = true;
        WSDeprecationNotificationIdTxt: Label 'a482b656-b7f4-46d9-8ca8-843083158057', Locked = true;
        TrialNotificationDaysSinceStartTxt: Label '15', Locked = true;
        TrialNotificationLinkTxt: Label 'Request partner contact...';
        TrialNotificationExtendLinkTxt: Label 'Extend trial...';
        TrialSuspendedNotificationLinkTxt: Label 'Request partner contact...';
        TrialSuspendedNotificationExtendLinkTxt: Label 'Extend trial...';
        TrialExtendedNotificationSubscribeLinkTxt: Label 'Request partner contact...';
        TrialExtendedSuspendedNotificationSubscribeLinkTxt: Label 'Request partner contact...';
        PaidWarningNotificationLinkTxt: Label 'Renew subscription...';
        PaidSuspendedNotificationLinkTxt: Label 'Renew subscription...';
        TrialNotificationMsg: Label 'Your trial period expires in %1 days. Ready to subscribe, or do you need more time?', Comment = '%1=Count of days until trial expires';
        TrialNotificationPreviewMsg: Label 'Your trial period expires in %1 days.', Comment = '%1=Count of days until trial expires';
        TrialSuspendedNotificationMsg: Label 'Your trial period has expired. You can subscribe or extend the period to get more time.';
        TrialSuspendedNotificationPreviewMsg: Label 'Your trial period has expired. You can extend the period to get more time.';
        TrialExtendedNotificationMsg: Label 'Your extended trial period will expire in %1 days.', Comment = '%1=Count of days until trial expires';
        TrialExtendedNotificationPreviewMsg: Label 'Your extended trial period will expire in %1 days. If it expires you contact a partner to get more time.', Comment = '%1=Count of days until trial expires';
        TrialExtendedSuspendedNotificationMsg: Label 'Your extended trial period has expired.';
        TrialExtendedSuspendedNotificationPreviewMsg: Label 'Your extended trial period has expired. You can contact a partner to get more time.';
        PaidWarningNotificationMsg: Label 'Your subscription expires in %1 days. Renew soon to keep your work.', Comment = '%1=Count of days until block of access';
        PaidSuspendedNotificationMsg: Label 'Your subscription has expired. Unless you renew, we will delete your data in %1 days.', Comment = '%1=Count of days until data deletion';
        SandboxNotificationMsg: Label 'This is a sandbox environment for test, demo, or development purposes only.';
        SandboxNotificationNameTok: Label 'Notify user of sandbox environment.';
        DontShowThisAgainMsg: Label 'Don''t show this again.';
        SandboxNotificationDescTok: Label 'Show a notification informing the user that they are working in a sandbox environment.';
        ChangeToPremiumExpNotificationMsg: Label 'This Role Center contains functionality that may not be visible because of your experience setting or assigned plan. For more information, see Changing Which Features are Displayed';
        ChangeToPremiumExpURLTxt: Label 'https://go.microsoft.com/fwlink/?linkid=873395', Locked = true;
        ChangeToPremiumExpNotificationDescTok: Label 'Show a notification suggesting the user to change to Premium experience.';
        ChangeToPremiumExpNotificationNameTok: Label 'Suggest to change the Experience setting.';
        ContactAPartnerURLTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2038439', Locked = true;
        BuyThroughPartnerURLTxt: Label 'https://go.microsoft.com/fwlink/?linkid=860971', Locked = true;

    procedure FixNowWSDeprecation(Notification: Notification)
    begin
        Page.Run(Page::"WS Access Key Wizard");
    end;

    local procedure CreateAndSendTrialNotification()
    var
        TrialNotification: Notification;
        RemainingDays: Integer;
    begin
        RemainingDays := GetLicenseRemainingDays();
        TrialNotification.Id := GetTrialNotificationId();
        TrialNotification.Message := StrSubstNo(TrialNotificationMessage(), RemainingDays);
        TrialNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        if (not IsPreview) then
            TrialNotification.AddAction(
                TrialNotificationLinkTxt, CODEUNIT::"Role Center Notification Mgt.", 'TrialNotificationAction');
        TrialNotification.AddAction(
          TrialNotificationExtendLinkTxt, CODEUNIT::"Role Center Notification Mgt.", 'TrialNotificationExtendAction');
        TrialNotification.Send();
    end;

    local procedure CreateAndSendTrialSuspendedNotification()
    var
        TrialSuspendedNotification: Notification;
    begin
        TrialSuspendedNotification.Id := GetTrialSuspendedNotificationId();
        TrialSuspendedNotification.Message := TrialSuspendedNotificationMessage();
        TrialSuspendedNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        if (not IsPreview) then
            TrialSuspendedNotification.AddAction(
                TrialSuspendedNotificationLinkTxt,
                CODEUNIT::"Role Center Notification Mgt.",
                'TrialSuspendedNotificationAction');
        TrialSuspendedNotification.AddAction(
          TrialSuspendedNotificationExtendLinkTxt,
          CODEUNIT::"Role Center Notification Mgt.",
          'TrialSuspendedNotificationExtendAction');
        TrialSuspendedNotification.Send();
    end;

    local procedure CreateAndSendTrialExtendedNotification()
    var
        TrialExtendedNotification: Notification;
        RemainingDays: Integer;
    begin
        RemainingDays := GetLicenseRemainingDays();
        TrialExtendedNotification.Id := GetTrialExtendedNotificationId();
        TrialExtendedNotification.Message := StrSubstNo(TrialExtendedNotificationMessage(), RemainingDays);
        TrialExtendedNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        if (not IsPreview) then
            TrialExtendedNotification.AddAction(
                TrialExtendedNotificationSubscribeLinkTxt,
                CODEUNIT::"Role Center Notification Mgt.",
                'TrialExtendedNotificationSubscribeAction');
        TrialExtendedNotification.Send();
    end;

    local procedure CreateAndSendTrialExtendedSuspendedNotification()
    var
        TrialExtendedSuspendedNotification: Notification;
    begin
        TrialExtendedSuspendedNotification.Id := GetTrialExtendedSuspendedNotificationId();
        TrialExtendedSuspendedNotification.Message := TrialExtendedSuspendedNotificationMessage();
        TrialExtendedSuspendedNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        if (not IsPreview) then
            TrialExtendedSuspendedNotification.AddAction(
                TrialExtendedSuspendedNotificationSubscribeLinkTxt,
                CODEUNIT::"Role Center Notification Mgt.",
                'TrialExtendedNotificationSubscribeAction');
        TrialExtendedSuspendedNotification.Send();
    end;

    local procedure CreateAndSendPaidWarningNotification()
    var
        PaidWarningNotification: Notification;
        RemainingDays: Integer;
    begin
        if IsPreview then
            exit;

        RemainingDays := GetLicenseRemainingDays();
        PaidWarningNotification.Id := GetPaidWarningNotificationId();
        PaidWarningNotification.Message := StrSubstNo(PaidWarningNotificationMsg, RemainingDays);
        PaidWarningNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        PaidWarningNotification.AddAction(
          PaidWarningNotificationLinkTxt, CODEUNIT::"Role Center Notification Mgt.", 'PaidWarningNotificationAction');
        PaidWarningNotification.Send();
    end;

    local procedure CreateAndSendPaidSuspendedNotification()
    var
        PaidSuspendedNotification: Notification;
        RemainingDays: Integer;
    begin
        if IsPreview then
            exit;

        RemainingDays := GetLicenseRemainingDays();
        PaidSuspendedNotification.Id := GetPaidSuspendedNotificationId();
        PaidSuspendedNotification.Message := StrSubstNo(PaidSuspendedNotificationMsg, RemainingDays);
        PaidSuspendedNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        PaidSuspendedNotification.AddAction(
          PaidSuspendedNotificationLinkTxt, CODEUNIT::"Role Center Notification Mgt.", 'PaidSuspendedNotificationAction');
        PaidSuspendedNotification.Send();
    end;

    local procedure CreateAndSendSandboxNotification()
    var
        SandboxNotification: Notification;
    begin
        SandboxNotification.Id := GetSandboxNotificationId();
        SandboxNotification.Message := SandboxNotificationMsg;
        SandboxNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        SandboxNotification.AddAction(DontShowThisAgainMsg, CODEUNIT::"Role Center Notification Mgt.", 'DisableSandboxNotification');
        SandboxNotification.Send();
    end;

    procedure GetTrialNotificationId(): Guid
    var
        TrialNotificationId: Guid;
    begin
        Evaluate(TrialNotificationId, TrialNotificationIdTxt);
        exit(TrialNotificationId);
    end;

    procedure GetTrialSuspendedNotificationId(): Guid
    var
        TrialSuspendedNotificationId: Guid;
    begin
        Evaluate(TrialSuspendedNotificationId, TrialSuspendedNotificationIdTxt);
        exit(TrialSuspendedNotificationId);
    end;

    procedure GetTrialExtendedNotificationId(): Guid
    var
        TrialExtendedNotificationId: Guid;
    begin
        Evaluate(TrialExtendedNotificationId, TrialExtendedNotificationIdTxt);
        exit(TrialExtendedNotificationId);
    end;

    procedure GetTrialExtendedSuspendedNotificationId(): Guid
    var
        TrialExtendedSuspendedNotificationId: Guid;
    begin
        Evaluate(TrialExtendedSuspendedNotificationId, TrialExtendedSuspendedNotificationIdTxt);
        exit(TrialExtendedSuspendedNotificationId);
    end;

    procedure GetPaidWarningNotificationId(): Guid
    var
        PaidWarningNotificationId: Guid;
    begin
        Evaluate(PaidWarningNotificationId, PaidWarningNotificationIdTxt);
        exit(PaidWarningNotificationId);
    end;

    procedure GetPaidSuspendedNotificationId(): Guid
    var
        PaidSuspendedNotificationId: Guid;
    begin
        Evaluate(PaidSuspendedNotificationId, PaidSuspendedNotificationIdTxt);
        exit(PaidSuspendedNotificationId);
    end;

    procedure GetWSDeprecationNotificationId(): Guid
    var
        WSDeprecationNotificationId: Guid;
    begin
        Evaluate(WSDeprecationNotificationId, WSDeprecationNotificationIdTxt);
        exit(WSDeprecationNotificationId);
    end;

    procedure GetSandboxNotificationId(): Guid
    var
        SandboxNotificationId: Guid;
    begin
        Evaluate(SandboxNotificationId, SandboxNotificationIdTxt);
        exit(SandboxNotificationId);
    end;

    procedure GetChangeToPremiumExpNotificationId(): Guid
    var
        ChangeToPremiumExpNotificationId: Guid;
    begin
        Evaluate(ChangeToPremiumExpNotificationId, ChangeToPremiumExpNotificationIdTxt);
        exit(ChangeToPremiumExpNotificationId);
    end;

    local procedure AreNotificationsSupported(): Boolean
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not GuiAllowed then
            exit(false);

        if not EnvironmentInfo.IsSaaS() then
            exit(false);

        if EnvironmentInfo.IsSandbox() then
            exit(false);

        exit(true);
    end;

    local procedure AreSandboxNotificationsSupported(): Boolean
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not GuiAllowed then
            exit(false);

        if not EnvironmentInfo.IsSaaS() then
            exit(false);

        if not EnvironmentInfo.IsSandbox() then
            exit(false);

        exit(true);
    end;

    local procedure IsTrialNotificationEnabled(): Boolean
    var
        ClientTypeManagement: Codeunit "Client Type Management";
        TenantLicenseState: Codeunit "Tenant License State";
    begin
        if not TenantLicenseState.IsTrialMode() then
            exit(false);

        if not AreNotificationsSupported() then
            exit(false);

        if ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Tablet, CLIENTTYPE::Phone] then
            exit(false);

        if GetLicenseFullyUsedDays() < GetTrialNotificationDaysSinceStart() then
            exit(false);

        exit(true);
    end;

    local procedure IsTrialSuspendedNotificationEnabled(): Boolean
    var
        ClientTypeManagement: Codeunit "Client Type Management";
        TenantLicenseState: Codeunit "Tenant License State";
    begin
        if not TenantLicenseState.IsTrialSuspendedMode() then
            exit(false);

        if TenantLicenseState.IsTrialExtendedSuspendedMode() then
            exit(false);

        if not AreNotificationsSupported() then
            exit(false);

        if ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Tablet, CLIENTTYPE::Phone] then
            exit(false);

        exit(true);
    end;

    local procedure IsTrialExtendedNotificationEnabled(): Boolean
    var
        ClientTypeManagement: Codeunit "Client Type Management";
        TenantLicenseState: Codeunit "Tenant License State";
    begin
        if not TenantLicenseState.IsTrialExtendedMode() then
            exit(false);

        if not AreNotificationsSupported() then
            exit(false);

        if ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Tablet, CLIENTTYPE::Phone] then
            exit(false);

        if GetLicenseFullyUsedDays() < GetTrialNotificationDaysSinceStart() then
            exit(false);

        exit(true);
    end;

    local procedure IsTrialExtendedSuspendedNotificationEnabled(): Boolean
    var
        TenantLicenseState: Codeunit "Tenant License State";
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        if not TenantLicenseState.IsTrialExtendedSuspendedMode() then
            exit(false);

        if not AreNotificationsSupported() then
            exit(false);

        if ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Tablet, CLIENTTYPE::Phone] then
            exit(false);

        exit(true);
    end;

    local procedure IsPaidWarningNotificationEnabled(): Boolean
    var
        RoleCenterNotifications: Record "Role Center Notifications";
        TenantLicenseState: Codeunit "Tenant License State";
    begin
        if not TenantLicenseState.IsPaidWarningMode() then
            exit(false);

        if not AreNotificationsSupported() then
            exit(false);

        if RoleCenterNotifications.IsFirstLogon() then
            exit(false);

        exit(IsBuyNotificationEnabled());
    end;

    local procedure IsPaidSuspendedNotificationEnabled(): Boolean
    var
        RoleCenterNotifications: Record "Role Center Notifications";
        TenantLicenseState: Codeunit "Tenant License State";
    begin
        if not TenantLicenseState.IsPaidSuspendedMode() then
            exit(false);

        if not AreNotificationsSupported() then
            exit(false);

        if RoleCenterNotifications.IsFirstLogon() then
            exit(false);

        exit(IsBuyNotificationEnabled());
    end;

    procedure ShowNotifications(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
        DataMigrationMgt: Codeunit "Data Migration Mgt.";
        DataClassNotificationMgt: Codeunit "Data Class. Notification Mgt.";
        DataGeoNotification: Codeunit "Data Geo. Notification";
        UserPermissions: Codeunit "User Permissions";
        ResultTrial: Boolean;
        ResultTrialSuspended: Boolean;
        ResultTrialExtended: Boolean;
        ResultTrialExtendedSuspended: Boolean;
        ResultPaidWarning: Boolean;
        ResultPaidSuspended: Boolean;
        ResultSandbox: Boolean;
    begin
        OnBeforeShowNotifications();
        IsRunningPreviewEvent();

        if UserPermissions.IsSuper(UserSecurityId()) then begin
            ResultTrial := ShowTrialNotification();
            ResultTrialSuspended := ShowTrialSuspendedNotification();
            ResultTrialExtended := ShowTrialExtendedNotification();
            ResultTrialExtendedSuspended := ShowTrialExtendedSuspendedNotification();
        end;
        ResultPaidWarning := ShowPaidWarningNotification();
        ResultPaidSuspended := ShowPaidSuspendedNotification();
        ResultSandbox := ShowSandboxNotification();

        EnvironmentInformation.ShowEarlyPreviewNotification();
        DataMigrationMgt.ShowDataMigrationRelatedGlobalNotifications();
        DataClassNotificationMgt.ShowNotifications();
        DataGeoNotification.ShowExistingAppsNotification();

        Commit();
        exit(
          ResultTrial or ResultTrialSuspended or
          ResultTrialExtended or ResultTrialExtendedSuspended or
          ResultPaidWarning or ResultPaidSuspended or
          ResultSandbox)
    end;

    procedure ShowTrialNotification(): Boolean
    begin
        IsRunningPreviewEvent();

        if not IsTrialNotificationEnabled() then
            exit(false);

        CreateAndSendTrialNotification();
        exit(true);
    end;

    procedure ShowTrialSuspendedNotification(): Boolean
    begin
        IsRunningPreviewEvent();

        if not IsTrialSuspendedNotificationEnabled() then
            exit(false);

        CreateAndSendTrialSuspendedNotification();
        exit(true);
    end;

    procedure ShowTrialExtendedNotification(): Boolean
    begin
        IsRunningPreviewEvent();

        if not IsTrialExtendedNotificationEnabled() then
            exit(false);

        CreateAndSendTrialExtendedNotification();
        exit(true);
    end;

    procedure ShowTrialExtendedSuspendedNotification(): Boolean
    begin
        IsRunningPreviewEvent();

        if not IsTrialExtendedSuspendedNotificationEnabled() then
            exit(false);

        CreateAndSendTrialExtendedSuspendedNotification();
        exit(true);
    end;

    procedure ShowPaidWarningNotification(): Boolean
    begin
        IsRunningPreviewEvent();

        if not IsPaidWarningNotificationEnabled() then
            exit(false);

        CreateAndSendPaidWarningNotification();
        exit(true);
    end;

    procedure ShowPaidSuspendedNotification(): Boolean
    begin
        IsRunningPreviewEvent();

        if not IsPaidSuspendedNotificationEnabled() then
            exit(false);

        CreateAndSendPaidSuspendedNotification();
        exit(true);
    end;

    procedure ShowSandboxNotification(): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        if not AreSandboxNotificationsSupported() then
            exit(false);

        if not MyNotifications.IsEnabled(GetSandboxNotificationId()) then
            exit(false);

        CreateAndSendSandboxNotification();
        exit(true);
    end;

    procedure TrialNotificationAction(TrialNotification: Notification)
    begin
        BuySubscription();
    end;

    procedure TrialNotificationExtendAction(TrialNotification: Notification)
    begin
        ExtendTrial();
    end;

    procedure TrialSuspendedNotificationAction(TrialSuspendedNotification: Notification)
    begin
        BuySubscription();
    end;

    procedure TrialSuspendedNotificationExtendAction(TrialSuspendedNotification: Notification)
    begin
        ExtendTrial();
    end;

    procedure TrialSuspendedNotificationPartnerAction(TrialSuspendedNotification: Notification)
    begin
        ContactAPartner();
    end;

    procedure TrialExtendedNotificationSubscribeAction(TrialExtendedNotification: Notification)
    begin
        BuySubscription();
    end;

    procedure TrialExtendedNotificationPartnerAction(TrialExtendedNotification: Notification)
    begin
        ContactAPartner();
    end;

    procedure PaidWarningNotificationAction(PaidWarningNotification: Notification)
    begin
        BuySubscription();
    end;

    procedure PaidSuspendedNotificationAction(PaidSuspendedNotification: Notification)
    begin
        BuySubscription();
    end;

    procedure GetLicenseRemainingDays(): Integer
    var
        DotNet_DateTimeOffset: Codeunit DotNet_DateTimeOffset;
        TenantLicenseState: Codeunit "Tenant License State";
        Now: DateTime;
        EndDate: DateTime;
        TimeDuration: Decimal;
        MillisecondsPerDay: BigInteger;
        RemainingDays: Integer;
    begin
        Now := DotNet_DateTimeOffset.ConvertToUtcDateTime(CurrentDateTime);
        EndDate := TenantLicenseState.GetEndDate();
        if EndDate > Now then begin
            TimeDuration := EndDate - Now;
            MillisecondsPerDay := 86400000;
            RemainingDays := Round(TimeDuration / MillisecondsPerDay, 1, '=');
            exit(RemainingDays);
        end;
        exit(0);
    end;

    local procedure GetLicenseFullyUsedDays(): Integer
    var
        TenantLicenseState: Codeunit "Tenant License State";
        DotNet_DateTimeOffset: Codeunit DotNet_DateTimeOffset;
        StartDate: DateTime;
        Now: DateTime;
        TimeDuration: Decimal;
        MillisecondsPerDay: BigInteger;
        FullyUsedDays: Integer;
    begin
        Now := DotNet_DateTimeOffset.ConvertToUtcDateTime(CurrentDateTime);
        StartDate := TenantLicenseState.GetStartDate();
        if StartDate <> 0DT then
            if Now > StartDate then begin
                TimeDuration := Now - StartDate;
                MillisecondsPerDay := 86400000;
                FullyUsedDays := Round(TimeDuration / MillisecondsPerDay, 1, '<');
                exit(FullyUsedDays);
            end;
        exit(0);
    end;

    procedure GetTrialTotalDays(): Integer
    var
        TenantLicenseState: Codeunit "Tenant License State";
        TrialTotalDays: Integer;
    begin
        TrialTotalDays := TenantLicenseState.GetPeriod("Tenant License State"::Trial);
        exit(TrialTotalDays);
    end;

    local procedure GetTrialNotificationDaysSinceStart(): Integer
    var
        DaysSinceStart: Integer;
    begin
        Evaluate(DaysSinceStart, TrialNotificationDaysSinceStartTxt);
        exit(DaysSinceStart);
    end;

    local procedure ExtendTrial()
    begin
        DisableBuyNotification();
        PAGE.Run(PAGE::"Extend Trial Wizard");
    end;

    local procedure BuySubscription()
    begin
        DisableBuyNotification();
        HyperLink(BuyThroughPartnerURLTxt);
    end;

    local procedure ContactAPartner()
    begin
        DisableBuyNotification();
        HyperLink(ContactAPartnerURLTxt);
    end;

    procedure DisableEvaluationNotification()
    var
        RoleCenterNotifications: Record "Role Center Notifications";
    begin
        RoleCenterNotifications.SetEvaluationNotificationState(RoleCenterNotifications."Evaluation Notification State"::Disabled);
    end;

    procedure EnableEvaluationNotification()
    var
        RoleCenterNotifications: Record "Role Center Notifications";
    begin
        RoleCenterNotifications.SetEvaluationNotificationState(RoleCenterNotifications."Evaluation Notification State"::Enabled);
    end;

    procedure IsEvaluationNotificationClicked(): Boolean
    var
        RoleCenterNotifications: Record "Role Center Notifications";
    begin
        exit(RoleCenterNotifications.GetEvaluationNotificationState() = RoleCenterNotifications."Evaluation Notification State"::Clicked);
    end;

    procedure DisableBuyNotification()
    var
        RoleCenterNotifications: Record "Role Center Notifications";
    begin
        RoleCenterNotifications.SetBuyNotificationState(RoleCenterNotifications."Buy Notification State"::Disabled);
    end;

    procedure EnableBuyNotification()
    var
        RoleCenterNotifications: Record "Role Center Notifications";
    begin
        RoleCenterNotifications.SetBuyNotificationState(RoleCenterNotifications."Buy Notification State"::Enabled);
    end;

    local procedure IsBuyNotificationEnabled(): Boolean
    var
        RoleCenterNotifications: Record "Role Center Notifications";
    begin
        exit(RoleCenterNotifications.GetBuyNotificationState() <> RoleCenterNotifications."Buy Notification State"::Disabled);
    end;

    procedure DisableSandboxNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if MyNotifications.WritePermission then
            if not MyNotifications.Disable(GetSandboxNotificationId()) then
                MyNotifications.InsertDefault(GetSandboxNotificationId(), SandboxNotificationNameTok, SandboxNotificationDescTok, false);
    end;

    procedure DisableChangeToPremiumExpNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetChangeToPremiumExpNotificationId()) then
            MyNotifications.InsertDefault(
              GetChangeToPremiumExpNotificationId(), ChangeToPremiumExpNotificationNameTok, ChangeToPremiumExpNotificationDescTok, false);
    end;

#if not CLEAN25
    [Obsolete('The procedure is not used and will be obsoleted', '25.0')]
    procedure CompanyNotSelectedMessage(): Text
    begin
        exit('');
    end;
#endif

    procedure TrialNotificationMessage(): Text
    begin
        if IsPreview then
            exit(TrialNotificationPreviewMsg);

        exit(TrialNotificationMsg);
    end;

    procedure TrialSuspendedNotificationMessage(): Text
    begin
        if IsPreview then
            exit(TrialSuspendedNotificationPreviewMsg);

        exit(TrialSuspendedNotificationMsg);
    end;

    procedure TrialExtendedNotificationMessage(): Text
    begin
        if IsPreview then
            exit(TrialExtendedNotificationPreviewMsg);

        exit(TrialExtendedNotificationMsg);
    end;

    procedure TrialExtendedSuspendedNotificationMessage(): Text
    begin
        if IsPreview then
            exit(TrialExtendedSuspendedNotificationPreviewMsg);

        exit(TrialExtendedSuspendedNotificationMsg);
    end;

    procedure PaidWarningNotificationMessage(): Text
    begin
        exit(PaidWarningNotificationMsg);
    end;

    procedure PaidSuspendedNotificationMessage(): Text
    begin
        exit(PaidSuspendedNotificationMsg);
    end;

    procedure SandboxNotificationMessage(): Text
    begin
        exit(SandboxNotificationMsg);
    end;

    procedure ChangeToPremiumExpNotificationMessage(): Text
    begin
        exit(ChangeToPremiumExpNotificationMsg);
    end;

    procedure ChangeToPremiumExpURL(Notification: Notification)
    begin
        HyperLink(ChangeToPremiumExpURLTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        if AreSandboxNotificationsSupported() then
            MyNotifications.InsertDefault(GetSandboxNotificationId(), SandboxNotificationNameTok, SandboxNotificationDescTok, true);
        if AreNotificationsSupported() then
            MyNotifications.InsertDefault(
              GetChangeToPremiumExpNotificationId(), ChangeToPremiumExpNotificationNameTok, ChangeToPremiumExpNotificationDescTok, true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowNotifications()
    begin
    end;

    local procedure IsRunningPreviewEvent()
    begin
        if not IsPreview then
            OnIsRunningPreview(IsPreview);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsRunningPreview(var isPreview: Boolean)
    begin
    end;
}

