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
        TelemetryRegisteredNewCopilotCapabilityLbl: Label 'New copilot capability registered.', Locked = true;
        TelemetryModifiedCopilotCapabilityLbl: Label 'Copilot capability modified', Locked = true;
        TelemetryUnregisteredCopilotCapabilityLbl: Label 'Copilot capability unregistered.', Locked = true;
        TelemetryActivatedCopilotCapabilityLbl: Label 'Copilot capability activated.', Locked = true;
        TelemetryDeactivatedCopilotCapabilityLbl: Label 'Copilot capability deactivated.', Locked = true;

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

    procedure CheckDataMovementAllowed(var AllowDataMovement: Boolean)
    var
        PrivacyNotice: Codeunit "Privacy Notice";
    begin
        case PrivacyNotice.GetPrivacyNoticeApprovalState(GetAzureOpenAICategory(), false) of
            Enum::"Privacy Notice Approval State"::Agreed:
                AllowDataMovement := true;
            Enum::"Privacy Notice Approval State"::Disagreed:
                AllowDataMovement := false;
            else
                AllowDataMovement := true;
        end;
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