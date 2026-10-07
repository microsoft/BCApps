// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

using Microsoft.RoleCenters;
using System.Azure.Identity;
using System.Environment.Configuration;

codeunit 257 "Experience Tier"
{
    Access = Internal;
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    var
        BasicCannotAccessPremiumCompanyErr: Label 'You cannot access company %1 as the experience tier of the company is premium and you are using a basic license.', Comment = '%1 - Company name';
        DontShowAgainTxt: Label 'Don''t show again.';
        EssentialsCannotAccessPremiumCompanyErr: Label 'You cannot access company %1 as the experience tier of the company is premium and you are using an essentials license.', Comment = '%1 - Company name';
        PremiumAccessEssentialCompanyTelemetryMsg: Label 'Premium user accessing non-premium company. Disabling premium functionality.', Locked = true;
        PremiumAccessEssentialCompanyMsg: Label 'Premium features are blocked since you are accessing a non-premium company.';
        PremiumAccessEssentialWarningNameTxt: Label 'Experience tier mismatch';
        PremiumAccessEssentialWarningDescTxt: Label 'Warns user when accessing a non-premium company using a premium license.';
        ExperienceTierCategoryTok: Label 'Experience Tier', Locked = true;

    procedure CheckExperienceTier()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        AzureADPlan: Codeunit "Azure AD Plan";
        UserPlanExperience: Enum "User Plan Experience";
    begin
        UserPlanExperience := AzureADPlan.GetUserPlanExperience();

        if ApplicationAreaMgmtFacade.IsPremiumExperienceEnabled() then
            case UserPlanExperience of
                UserPlanExperience::Basic:
                    Error(BasicCannotAccessPremiumCompanyErr, CompanyName());
                UserPlanExperience::Essentials:
                    Error(EssentialsCannotAccessPremiumCompanyErr, CompanyName());
                UserPlanExperience::Premium:
                    exit;
            end;

        if UserPlanExperience = UserPlanExperience::Premium then begin
            Session.LogMessage('0000MHE', PremiumAccessEssentialCompanyTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExperienceTierCategoryTok);
            OnCheckExperienceTierForUserPlanPremium();
        end;
    end;

    procedure ShowExperienceMismatchNotification()
    var
        MyNotifications: Record "My Notifications";
        ExperienceNotification: Notification;
    begin
        if not MyNotifications.IsEnabled(GetExperienceMismatchNotificationId()) then
            exit;

        ExperienceNotification.Id := GetExperienceMismatchNotificationId();
        ExperienceNotification.Recall();
        ExperienceNotification.Message := PremiumAccessEssentialCompanyMsg;
        ExperienceNotification.AddAction(DontShowAgainTxt, Codeunit::"Experience Tier", 'DisableExperienceMismatchNotification');
        ExperienceNotification.Send();
    end;

    procedure DisableExperienceMismatchNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetExperienceMismatchNotificationId()) then
            MyNotifications.InsertDefault(GetExperienceMismatchNotificationId(), PremiumAccessEssentialWarningNameTxt, PremiumAccessEssentialWarningDescTxt, false);
    end;

    local procedure GetExperienceMismatchNotificationId(): Guid
    begin
        exit('3c50c1eb-cb7b-403f-bf5f-af0405547750');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Role Center Notification Mgt.", 'OnBeforeShowNotifications', '', false, false)]
    local procedure SendExperienceMismatchNotification()
    begin
        ShowExperienceMismatchNotification();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckExperienceTierForUserPlanPremium()
    begin
    end;
}

