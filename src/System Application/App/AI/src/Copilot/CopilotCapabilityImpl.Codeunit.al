// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System;
using System.Azure.Identity;
using System.Environment;
using System.Environment.Configuration;
using System.Globalization;
using System.Privacy;
using System.Security.User;
using System.Telemetry;

codeunit 7774 "Copilot Capability Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Copilot Settings" = rimd;

    var
        Telemetry: Codeunit Telemetry;
        CopilotCategoryLbl: Label 'Copilot', Locked = true;
        AzureOpenAiTxt: Label 'Azure OpenAI', Locked = true;
        AlreadyRegisteredErr: Label 'Capability has already been registered.';
        NotRegisteredErr: Label 'Copilot capability has not been registered by the module.';
        ReviewPrivacyNoticeLbl: Label 'Review the privacy notice';
        PrivacyNoticeDisagreedNotificationMessageLbl: Label 'To enable Copilot, please review and accept the privacy notice.';
        CapabilitiesNotAvailableOnPremNotificationMessageLbl: Label 'Copilot capabilities published by Microsoft are not available on-premises. You can extend Copilot with custom capabilities and use them on-premises for development purposes only.';
        TelemetryRegisteredNewCopilotCapabilityLbl: Label 'New copilot capability registered.', Locked = true;
        TelemetryModifiedCopilotCapabilityLbl: Label 'Copilot capability modified', Locked = true;
        TelemetryUnregisteredCopilotCapabilityLbl: Label 'Copilot capability unregistered.', Locked = true;
        TelemetryActivatedCopilotCapabilityLbl: Label 'Copilot capability activated.', Locked = true;
        TelemetryDeactivatedCopilotCapabilityLbl: Label 'Copilot capability deactivated.', Locked = true;
        NotificationPrivacyNoticeDisagreedLbl: Label 'bd91b436-29ba-4823-824c-fc926c9842c2', Locked = true;
        NotificationCapabilitiesNotAvailableOnPremLbl: Label 'ada1592d-9728-485c-897e-8d18e8dd7dee', Locked = true;
        BillingInTheFutureNotificationGuidTok: Label 'cb577f99-d252-4de7-a1ab-922ac2af12b7', Locked = true;
        BillingInTheFutureNotificationMsg: Label 'By activating AI capabilities, you understand your organization may be billed for its use in the future.';
        BillingInTheFutureLearnMoreLinkLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2302317', Locked = true;
        AIQuotaUsedUpNotificationGuidTok: Label 'eced148b-4721-4ff9-b4c8-a8b5b1209692', Locked = true;
        AIQuotaUsedUpNotificationMsg: Label 'AI capabilities are currently unavailable because your organization has used up its AI quota.';
        AIQuotaUsedUpLearnMoreLinkLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2302511', Locked = true;
        AIQuotaNearlyUsedUpNotificationGuidTok: Label '4a15b17c-1f88-4cc6-a342-4300ba400c8a', Locked = true;
        AIQuotaNearlyUsedUpNotificationMsg: Label 'The AI quota in this environment is nearly used up. When it is, AI capabilities will be unavailable.';
        AIQuotaNearlyUsedUpLearnMoreLinkLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2302603', Locked = true;

    procedure RegisterCapability(CopilotCapability: Enum "Copilot Capability"; LearnMoreUrl: Text[2048]; CallerModuleInfo: ModuleInfo)
    begin
        RegisterCapability(CopilotCapability, Enum::"Copilot Availability"::Preview, LearnMoreUrl, CallerModuleInfo);
    end;

    procedure RegisterCapability(CopilotCapability: Enum "Copilot Capability"; CopilotAvailability: Enum "Copilot Availability"; LearnMoreUrl: Text[2048]; CallerModuleInfo: ModuleInfo)
    var
        CopilotSettings: Record "Copilot Settings";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if IsCapabilityRegistered(CopilotCapability, CallerModuleInfo) then
            Error(AlreadyRegisteredErr);

        CopilotSettings.Init();
        CopilotSettings.Capability := CopilotCapability;
        CopilotSettings."App Id" := CallerModuleInfo.Id();
        CopilotSettings.Publisher := CopyStr(CallerModuleInfo.Publisher, 1, MaxStrLen(CopilotSettings.Publisher));
        CopilotSettings.Availability := CopilotAvailability;
        CopilotSettings."Learn More Url" := LearnMoreUrl;
        if CopilotSettings.Availability = Enum::"Copilot Availability"::"Early Preview" then
            CopilotSettings.Status := Enum::"Copilot Status"::Inactive
        else
            CopilotSettings.Status := Enum::"Copilot Status"::Active;
        CopilotSettings.Insert();
        Commit();

        AddTelemetryDimensions(CopilotCapability, CallerModuleInfo.Id(), CustomDimensions);
        Telemetry.LogMessage('0000LDV', TelemetryRegisteredNewCopilotCapabilityLbl, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, Enum::"AL Telemetry Scope"::All, CustomDimensions);
    end;

    procedure ModifyCapability(CopilotCapability: Enum "Copilot Capability"; CopilotAvailability: Enum "Copilot Availability"; LearnMoreUrl: Text[2048]; CallerModuleInfo: ModuleInfo)
    var
        CopilotSettings: Record "Copilot Settings";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not IsCapabilityRegistered(CopilotCapability, CallerModuleInfo) then
            Error(NotRegisteredErr);

        CopilotSettings.ReadIsolation(IsolationLevel::ReadCommitted);
        CopilotSettings.Get(CopilotCapability, CallerModuleInfo.Id());

        if CopilotSettings.Availability <> CopilotAvailability then
            CopilotSettings.Status := Enum::"Copilot Status"::Active;

        CopilotSettings.Availability := CopilotAvailability;
        CopilotSettings."Learn More Url" := LearnMoreUrl;
        CopilotSettings.Modify(true);
        Commit();

        AddTelemetryDimensions(CopilotCapability, CallerModuleInfo.Id(), CustomDimensions);
        AddStatusTelemetryDimension(CopilotSettings.Status, CustomDimensions);
        Telemetry.LogMessage('0000LDW', TelemetryModifiedCopilotCapabilityLbl, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, Enum::"AL Telemetry Scope"::All, CustomDimensions);
    end;

    procedure UnregisterCapability(CopilotCapability: Enum "Copilot Capability"; var CallerModuleInfo: ModuleInfo)
    var
        CopilotSettings: Record "Copilot Settings";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not IsCapabilityRegistered(CopilotCapability, CallerModuleInfo) then
            Error(NotRegisteredErr);

        CopilotSettings.ReadIsolation(IsolationLevel::ReadCommitted);
        CopilotSettings.LockTable();
        CopilotSettings.Get(CopilotCapability, CallerModuleInfo.Id());
        CopilotSettings.Delete();
        Commit();

        AddTelemetryDimensions(CopilotCapability, CallerModuleInfo.Id(), CustomDimensions);
        Telemetry.LogMessage('0000LDX', TelemetryUnregisteredCopilotCapabilityLbl, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, Enum::"AL Telemetry Scope"::All, CustomDimensions);
    end;

    procedure IsCapabilityRegistered(CopilotCapability: Enum "Copilot Capability"; CallerModuleInfo: ModuleInfo): Boolean
    begin
        exit(IsCapabilityRegistered(CopilotCapability, CallerModuleInfo.Id()));
    end;

    procedure IsCapabilityRegistered(CopilotCapability: Enum "Copilot Capability"; AppId: Guid): Boolean
    var
        CopilotSettings: Record "Copilot Settings";
    begin
        CopilotSettings.ReadIsolation(IsolationLevel::ReadCommitted);
        CopilotSettings.SetRange("Capability", CopilotCapability);
        CopilotSettings.SetRange("App Id", AppId);
        exit(not CopilotSettings.IsEmpty());
    end;

    procedure IsCapabilityActive(CopilotCapability: Enum "Copilot Capability"; CallerModuleInfo: ModuleInfo): Boolean
    begin
        exit(IsCapabilityActive(CopilotCapability, CallerModuleInfo.Id()));
    end;

    procedure IsCapabilityActive(CopilotCapability: Enum "Copilot Capability"; AppId: Guid): Boolean
    var
        CopilotSettings: Record "Copilot Settings";
        CopilotCapabilityCU: Codeunit "Copilot Capability";
        PrivacyNotice: Codeunit "Privacy Notice";
        RequiredPrivacyNotices: List of [Code[50]];
        RequiredPrivacyNotice: Code[50];
    begin
        CopilotSettings.ReadIsolation(IsolationLevel::ReadCommitted);
        CopilotSettings.SetLoadFields(Status);
        if not CopilotSettings.Get(CopilotCapability, AppId) then
            exit(false);

        CopilotCapabilityCU.OnGetRequiredPrivacyNotices(CopilotCapability, AppId, RequiredPrivacyNotices);

        if (CopilotSettings.Status <> Enum::"Copilot Status"::Active) or (RequiredPrivacyNotices.Count() <= 0) then
            exit(CopilotSettings.Status = Enum::"Copilot Status"::Active);

        // check privacy notices
        foreach RequiredPrivacyNotice in RequiredPrivacyNotices do
            if (PrivacyNotice.GetPrivacyNoticeApprovalState(RequiredPrivacyNotice, true) <> Enum::"Privacy Notice Approval State"::Agreed) then
                exit(false);

        exit(true);
    end;

    procedure SendActivateTelemetry(CopilotCapability: Enum "Copilot Capability"; AppId: Guid)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        AddTelemetryDimensions(CopilotCapability, AppId, CustomDimensions);
        Telemetry.LogMessage('0000LDY', TelemetryActivatedCopilotCapabilityLbl, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, Enum::"AL Telemetry Scope"::All, CustomDimensions);
    end;

    procedure SendDeactivateTelemetry(CopilotCapability: Enum "Copilot Capability"; AppId: Guid; Reason: Option)
    var
        Language: Codeunit Language;
        SavedGlobalLanguageId: Integer;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        AddTelemetryDimensions(CopilotCapability, AppId, CustomDimensions);

        SavedGlobalLanguageId := GlobalLanguage();
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());

        CustomDimensions.Add('Reason', Format(Reason));
        Telemetry.LogMessage('0000LDZ', TelemetryDeactivatedCopilotCapabilityLbl, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, Enum::"AL Telemetry Scope"::All, CustomDimensions);

        GlobalLanguage(SavedGlobalLanguageId);
    end;

    procedure CheckAIQuota()
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
        Notification.AddAction(ReviewPrivacyNoticeLbl, Codeunit::"Copilot Capability Impl", 'OpenPrivacyNotice');
        Notification.Send();
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
        BillingInTheFutureNotification.AddAction('Learn more', Codeunit::"Copilot Capability Impl", 'ShowBillingInTheFutureLearnMore');
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
        AIQuotaUsedUpNotification.AddAction('Learn more', Codeunit::"Copilot Capability Impl", 'ShowAIQuotaUsedUpLearnMore');
        AIQuotaUsedUpNotification.Send();
    end;

    procedure ShowAIQuotaUsedUpLearnMore(AIQuotaUsedUpNotification: Notification)
    begin
        if IsAdmin() then begin
            if Dialog.Confirm('AI capabilities in Business Central require AI quota.\\Your organization has used up its AI quota, so AI capabilities are currently unavailable.\\Would you like to open the <BC Admin Center?> to learn more about AI quota?') then
                Hyperlink('https://aka.ms');
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
        AIQuotaNearlyUsedUpNotification.AddAction('Learn more', Codeunit::"Copilot Capability Impl", 'ShowAIQuotaNearlyUsedUpLearnMore');
        AIQuotaNearlyUsedUpNotification.Send();
    end;

    procedure ShowAIQuotaNearlyUsedUpLearnMore(AIQuotaNearlyUsedUpNotification: Notification)
    begin
        if IsAdmin() then begin
            if Dialog.Confirm('AI capabilities in Business Central require AI quota, and your organization has a limited amount remaining.\\When it''s used up, AI capabilities will be unavailable until AI quota is available again.\\Would you like to open the <BC Admin Center?> to learn more about AI quota?') then
                Hyperlink('https://aka.ms');
        end
        else
            Hyperlink(AIQuotaNearlyUsedUpLearnMoreLinkLbl);
    end;

    procedure OpenPrivacyNotice(Notification: Notification)
    begin
        Page.Run(Page::"Privacy Notices");
    end;

    procedure GetAzureOpenAICategory(): Code[50]
    begin
        exit(AzureOpenAiTxt);
    end;

    procedure GetCopilotCategory(): Code[50]
    begin
        exit(CopilotCategoryLbl);
    end;

    procedure AddStatusTelemetryDimension(CopilotStatus: Enum "Copilot Status"; var CustomDimensions: Dictionary of [Text, Text])
    var
        Language: Codeunit Language;
        SavedGlobalLanguageId: Integer;
    begin
        SavedGlobalLanguageId := GlobalLanguage();
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());

        CustomDimensions.Add('Status', Format(CopilotStatus));

        GlobalLanguage(SavedGlobalLanguageId);
    end;

    procedure AddTelemetryDimensions(CopilotCapability: Enum "Copilot Capability"; AppId: Guid; var CustomDimensions: Dictionary of [Text, Text])
    var
        Language: Codeunit Language;
        SavedGlobalLanguageId: Integer;
    begin
        SavedGlobalLanguageId := GlobalLanguage();
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());

        CustomDimensions.Add('Category', GetCopilotCategory());
        CustomDimensions.Add('Capability', Format(CopilotCapability));
        CustomDimensions.Add('AppId', Format(AppId));

        GlobalLanguage(SavedGlobalLanguageId);
    end;

    procedure IsAdmin() IsAdmin: Boolean
    var
        AzureADGraphUser: Codeunit "Azure AD Graph User";
        AzureADPlan: Codeunit "Azure AD Plan";
        PlanIds: Codeunit "Plan Ids";
        UserPermissions: Codeunit "User Permissions";
    begin
        IsAdmin := AzureADGraphUser.IsUserDelegatedAdmin() or AzureADPlan.IsPlanAssignedToUser(PlanIds.GetGlobalAdminPlanId()) or AzureADPlan.IsPlanAssignedToUser(PlanIds.GetBCAdminPlanId()) or AzureADPlan.IsPlanAssignedToUser(PlanIds.GetD365AdminPlanId()) or AzureADGraphUser.IsUserDelegatedHelpdesk() or UserPermissions.IsSuper(UserSecurityId());
    end;

    [TryFunction]
    procedure CheckGeoAndEUDB(var WithinGeo: Boolean; var WithinEUDB: Boolean)
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
    begin
        WithinGeo := ALCopilotFunctions.IsWithinGeo();
        WithinEUDB := ALCopilotFunctions.IsWithinEUDB();
    end;

    procedure UpdateGuidedExperience(AllowDataMovement: Boolean)
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if AllowDataMovement then
            GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Copilot AI Capabilities")
        else
            GuidedExperience.ResetAssistedSetup(ObjectType::Page, Page::"Copilot AI Capabilities");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Privacy Notice", 'OnRegisterPrivacyNotices', '', false, false)]
    local procedure CreatePrivacyNoticeRegistrations(var TempPrivacyNotice: Record "Privacy Notice" temporary)
    begin
        TempPrivacyNotice.Init();
        TempPrivacyNotice.ID := AzureOpenAiTxt;
        TempPrivacyNotice."Integration Service Name" := AzureOpenAiTxt;
        if not TempPrivacyNotice.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetCopilotCapabilityStatus', '', false, false)]
    local procedure GetCopilotCapabilityStatus(Capability: Integer; var IsEnabled: Boolean; AppId: Guid; Silent: Boolean)
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        CopilotCapability: Enum "Copilot Capability";
    begin
        CopilotCapability := Enum::"Copilot Capability".FromInteger(Capability);
        IsEnabled := AzureOpenAI.IsEnabled(CopilotCapability, Silent, AppId);
    end;
}