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
        AlreadyRegisteredErr: Label 'Capability has already been registered.';
        NotRegisteredErr: Label 'Copilot capability has not been registered by the module.';
        ReviewPrivacyNoticeLbl: Label 'Review the privacy notice';
        PrivacyNoticeDisagreedNotificationMessageLbl: Label 'To enable Copilot, please review and accept the privacy notice.';
        CapabilitiesNotAvailableOnPremNotificationMessageLbl: Label 'Copilot capabilities published by Microsoft are not available on-premises. You can extend Copilot with custom capabilities and use them on-premises for development purposes only.';
        CapabilityNotRegisteredErr: Label 'Copilot capability ''%1'' has not been registered by the module.', Comment = '%1 is the name of the Copilot Capability';
        CapabilityNotEnabledErr: Label 'Copilot capability ''%1'' has not been enabled. Please contact your system administrator.', Comment = '%1 is the name of the Copilot Capability';
        TelemetrySetCapabilityLbl: Label 'Set Capability', Locked = true;
        TelemetryCopilotCapabilityNotRegisteredLbl: Label 'Copilot capability not registered.', Locked = true;
        TelemetryRegisteredNewCopilotCapabilityLbl: Label 'New copilot capability registered.', Locked = true;
        TelemetryModifiedCopilotCapabilityLbl: Label 'Copilot capability modified', Locked = true;
        TelemetryUnregisteredCopilotCapabilityLbl: Label 'Copilot capability unregistered.', Locked = true;
        TelemetryActivatedCopilotCapabilityLbl: Label 'Copilot capability activated.', Locked = true;
        TelemetryDeactivatedCopilotCapabilityLbl: Label 'Copilot capability deactivated.', Locked = true;
        NotificationPrivacyNoticeDisagreedLbl: Label 'bd91b436-29ba-4823-824c-fc926c9842c2', Locked = true;
        NotificationCapabilitiesNotAvailableOnPremLbl: Label 'ada1592d-9728-485c-897e-8d18e8dd7dee', Locked = true;


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

    procedure SetCopilotCapability(Capability: Enum "Copilot Capability"; CallerModuleInfo: ModuleInfo; AzureAIServiceName: Text)
    var
        CopilotSettings: Record "Copilot Settings";
        CopilotTelemetry: Codeunit "Copilot Telemetry";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Language: Codeunit Language;
        SavedGlobalLanguageId: Integer;
        CustomDimensions: Dictionary of [Text, Text];
        ErrorMessage: Text;
    begin
        if not IsCapabilityRegistered(Capability, CallerModuleInfo.Id()) then begin
            SavedGlobalLanguageId := GlobalLanguage();
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            CustomDimensions.Add('Capability', Format(Capability));
            CustomDimensions.Add('AppId', Format(CallerModuleInfo.Id()));
            GlobalLanguage(SavedGlobalLanguageId);

            FeatureTelemetry.LogError('0000LFN', AzureAIServiceName, TelemetrySetCapabilityLbl, TelemetryCopilotCapabilityNotRegisteredLbl, '', Enum::"AL Telemetry Scope"::All, CustomDimensions);
            ErrorMessage := StrSubstNo(CapabilityNotRegisteredErr, Capability);
            Error(ErrorMessage);
        end;

        CopilotSettings.ReadIsolation(IsolationLevel::ReadCommitted);
        CopilotSettings.SetLoadFields(Status);
        CopilotSettings.Get(Capability, CallerModuleInfo.Id());
        if CopilotSettings.Status = Enum::"Copilot Status"::Inactive then begin
            ErrorMessage := StrSubstNo(CapabilityNotEnabledErr, Capability);
            Error(ErrorMessage);
        end;
        CopilotTelemetry.SetCopilotCapability(Capability, CallerModuleInfo.Id());
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

    procedure OpenPrivacyNotice(Notification: Notification)
    begin
        Page.Run(Page::"Privacy Notices");
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