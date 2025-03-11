// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System;
using System.Privacy;

codeunit 7757 "Copilot Notifications"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        ReviewPrivacyNoticeLbl: Label 'Review the privacy notice';
        PrivacyNoticeDisagreedNotificationMessageLbl: Label 'To enable Copilot, please review and accept the privacy notice.';
        CapabilitiesNotAvailableOnPremNotificationMessageLbl: Label 'Copilot capabilities published by Microsoft are not available on-premises. You can extend Copilot with custom capabilities and use them on-premises for development purposes only.';
        NotificationPrivacyNoticeDisagreedLbl: Label 'bd91b436-29ba-4823-824c-fc926c9842c2', Locked = true;
        NotificationCapabilitiesNotAvailableOnPremLbl: Label 'ada1592d-9728-485c-897e-8d18e8dd7dee', Locked = true;
        BillingInTheFutureNotificationGuidTok: Label 'cb577f99-d252-4de7-a1ab-922ac2af12b7', Locked = true;
        BillingInTheFutureNotificationMsg: Label 'By activating AI capabilities, you understand your organization may be billed for its use in the future.';
        BillingInTheFutureLearnMoreLinkLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2302317', Locked = true;
        AIQuotaUsedUpNotificationGuidTok: Label 'eced148b-4721-4ff9-b4c8-a8b5b1209692', Locked = true;
        AIQuotaUsedUpNotificationMsg: Label 'AI capabilities are currently unavailable because your organization has used up its AI quota.';
        AIQuotaUsedUpLearnMoreLinkLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2302511', Locked = true;
        AIQuotaUsedUpAdminMsg: Label 'AI capabilities in Business Central require AI quota.\\Your organization has used up its AI quota, so AI capabilities are currently unavailable.\\Would you like to open the Business Central administration center to set up billing?';
        AIQuotaNearlyUsedUpNotificationGuidTok: Label '4a15b17c-1f88-4cc6-a342-4300ba400c8a', Locked = true;
        AIQuotaNearlyUsedUpNotificationMsg: Label 'The AI quota in this environment is nearly used up. When it is, AI capabilities will be unavailable.';
        AIQuotaNearlyUsedUpLearnMoreLinkLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2302603', Locked = true;
        AIQuotaNearlyUsedUpAdminMsg: Label 'AI capabilities in Business Central require AI quota, and your organization has a limited amount remaining.\\When it''s used up, AI capabilities will be unavailable until AI quota is available again.\\Would you like to open the Business Central administration center to set up billing?';
        BCAdminCenterSaaSLinkTxt: Label '%1/admin', Comment = '%1 - BC url', Locked = true;
        LearnMoreLbl: Label 'Learn more', Locked = true;

    procedure CheckAIQuotaAndShowNotification()
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        ALCopilotQuotaDetails: Dotnet ALCopilotQuotaDetails;
    begin
        ALCopilotQuotaDetails := ALCopilotFunctions.GetCopilotQuotaDetails();

        if IsNull(ALCopilotQuotaDetails) then
            exit;

        if not ALCopilotQuotaDetails.CanConsume() then begin
            ShowAIQuotaUsedUpNotification();
            exit;
        end;

        if ALCopilotQuotaDetails.HasSetupBilling() then
            exit;

        if ALCopilotQuotaDetails.QuotaUsedPercentage() >= 80.0 then
            ShowAIQuotaNearlyUsedUpNotification();
    end;

    procedure ShowPrivacyNoticeDisagreedNotification()
    var
        Notification: Notification;
        NotificationGuid: Guid;
    begin
        NotificationGuid := NotificationPrivacyNoticeDisagreedLbl;
        Notification.Id(NotificationGuid);
        Notification.Message(PrivacyNoticeDisagreedNotificationMessageLbl);
        Notification.AddAction(ReviewPrivacyNoticeLbl, Codeunit::"Copilot Notifications", 'OpenPrivacyNotice');
        Notification.Send();
    end;

    procedure OpenPrivacyNotice(Notification: Notification)
    begin
        Page.Run(Page::"Privacy Notices");
    end;

    procedure ShowCapabilitiesNotAvailableOnPremNotification()
    var
        Notification: Notification;
        NotificationGuid: Guid;
    begin
        NotificationGuid := NotificationCapabilitiesNotAvailableOnPremLbl;
        Notification.Id(NotificationGuid);
        Notification.Message(CapabilitiesNotAvailableOnPremNotificationMessageLbl);
        Notification.Send();
    end;

    procedure ShowBillingInTheFutureNotification()
    var
        BillingInTheFutureNotification: Notification;
    begin
        BillingInTheFutureNotification.Id := BillingInTheFutureNotificationGuidTok;
        BillingInTheFutureNotification.Message := BillingInTheFutureNotificationMsg;
        BillingInTheFutureNotification.Scope := NotificationScope::LocalScope;
        BillingInTheFutureNotification.AddAction(LearnMoreLbl, Codeunit::"Copilot Notifications", 'ShowBillingInTheFutureLearnMore');
        BillingInTheFutureNotification.Send();
    end;

    procedure ShowBillingInTheFutureLearnMore(BillingInTheFutureNotification: Notification)
    begin
        Hyperlink(BillingInTheFutureLearnMoreLinkLbl);
    end;

    procedure ShowAIQuotaUsedUpNotification()
    var
        AIQuotaUsedUpNotification: Notification;
    begin
        AIQuotaUsedUpNotification.Id := AIQuotaUsedUpNotificationGuidTok;
        AIQuotaUsedUpNotification.Message := AIQuotaUsedUpNotificationMsg;
        AIQuotaUsedUpNotification.Scope := NotificationScope::LocalScope;
        AIQuotaUsedUpNotification.AddAction(LearnMoreLbl, Codeunit::"Copilot Notifications", 'ShowAIQuotaUsedUpLearnMore');
        AIQuotaUsedUpNotification.Send();
    end;

    procedure ShowAIQuotaUsedUpLearnMore(AIQuotaUsedUpNotification: Notification)
    begin
        if CopilotCapabilityImpl.IsAdmin() then begin
            if Dialog.Confirm(AIQuotaUsedUpAdminMsg) then
                OpenBCAdminCenter();
        end
        else
            Hyperlink(AIQuotaUsedUpLearnMoreLinkLbl);
    end;

    procedure ShowAIQuotaNearlyUsedUpNotification()
    var
        AIQuotaNearlyUsedUpNotification: Notification;
    begin
        AIQuotaNearlyUsedUpNotification.Id := AIQuotaNearlyUsedUpNotificationGuidTok;
        AIQuotaNearlyUsedUpNotification.Message := AIQuotaNearlyUsedUpNotificationMsg;
        AIQuotaNearlyUsedUpNotification.Scope := NotificationScope::LocalScope;
        AIQuotaNearlyUsedUpNotification.AddAction(LearnMoreLbl, Codeunit::"Copilot Notifications", 'ShowAIQuotaNearlyUsedUpLearnMore');
        AIQuotaNearlyUsedUpNotification.Send();
    end;

    procedure ShowAIQuotaNearlyUsedUpLearnMore(AIQuotaNearlyUsedUpNotification: Notification)
    begin
        if CopilotCapabilityImpl.IsAdmin() then begin
            if Dialog.Confirm(AIQuotaNearlyUsedUpAdminMsg) then
                OpenBCAdminCenter();
        end
        else
            Hyperlink(AIQuotaNearlyUsedUpLearnMoreLinkLbl);
    end;

    local procedure OpenBCAdminCenter()
    var
        Url: Text;
    begin
        Url := GetUrl(ClientType::Web);
        Url := StrSubstNo(BCAdminCenterSaaSLinkTxt, CopyStr(Url, 1, Url.LastIndexOf('/') - 1));
        Hyperlink(Url);
    end;
}