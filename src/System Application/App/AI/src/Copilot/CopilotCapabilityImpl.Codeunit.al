// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System;
using System.Azure.Identity;
using System.Azure.KeyVault;
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
        CopilotSettings: Record "Copilot Settings";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Telemetry: Codeunit Telemetry;
        CopilotCategoryLbl: Label 'Copilot', Locked = true;
        AlreadyRegisteredErr: Label 'Capability has already been registered.';
        NotRegisteredErr: Label 'Copilot capability has not been registered by the module.';
        CapabilityNotRegisteredErr: Label 'Copilot capability ''%1'' has not been registered by the module.', Comment = '%1 is the name of the Copilot Capability';
        CapabilityNotEnabledErr: Label 'Copilot capability ''%1'' has not been enabled. Please contact your system administrator.', Comment = '%1 is the name of the Copilot Capability';
        TelemetrySetCapabilityLbl: Label 'Set Capability', Locked = true;
        CopilotNotEnabledErr: Label 'Copilot is not enabled. Please contact your system administrator.';
        CopilotCapabilityNotSetErr: Label 'Copilot capability has not been set.';
        CopilotDisabledForTenantErr: Label 'Copilot is not enabled for the tenant. Please contact your system administrator.';
        TelemetryIsEnabledLbl: Label 'Is Enabled', Locked = true;
        TelemetryUnableToCheckEnvironmentKVTxt: Label 'Unable to check if environment is allowed to run AOAI.', Locked = true;
        TelemetryEnvironmentNotAllowedtoRunCopilotTxt: Label 'Copilot is not allowed on this environment.', Locked = true;
        EnabledKeyTok: Label 'AOAI-Enabled', Locked = true;
        TelemetryCopilotCapabilityNotRegisteredLbl: Label 'Copilot capability not registered.', Locked = true;
        TelemetryRegisteredNewCopilotCapabilityLbl: Label 'New copilot capability registered.', Locked = true;
        TelemetryModifiedCopilotCapabilityLbl: Label 'Copilot capability modified', Locked = true;
        TelemetryUnregisteredCopilotCapabilityLbl: Label 'Copilot capability unregistered.', Locked = true;
        TelemetryActivatedCopilotCapabilityLbl: Label 'Copilot capability activated.', Locked = true;
        TelemetryDeactivatedCopilotCapabilityLbl: Label 'Copilot capability deactivated.', Locked = true;
        InvalidBillingTypeErr: Label 'Invalid billing type for Copilot capability ''%1''', Comment = '%1 is the name of the Copilot Capability';
        CopilotFeatureDeactivatedLbl: Label 'The copilot/AI capability %1, App Id %2 has been deactivated by UserSecurityId %3.', Locked = true;
        FeedbackDisabledLbl: Label 'Copilot feedback is disabled.', Locked = true;

    procedure RegisterCapability(CopilotCapability: Enum "Copilot Capability"; LearnMoreUrl: Text[2048]; CallerModuleInfo: ModuleInfo)
    begin
        RegisterCapability(CopilotCapability, Enum::"Copilot Availability"::Preview, Enum::"Copilot Billing Type"::"Not Billed", LearnMoreUrl, CallerModuleInfo);
    end;

#if not CLEAN27
    procedure RegisterCapability(CopilotCapability: Enum "Copilot Capability"; CopilotAvailability: Enum "Copilot Availability"; LearnMoreUrl: Text[2048]; CallerModuleInfo: ModuleInfo)
    begin
        RegisterCapability(CopilotCapability, CopilotAvailability, Enum::"Copilot Billing Type"::"Undefined", Enum::"Azure AI Service Type"::"Azure OpenAI", LearnMoreUrl, CallerModuleInfo);
    end;
#endif

    procedure RegisterCapability(CopilotCapability: Enum "Copilot Capability"; CopilotAvailability: Enum "Copilot Availability"; CopilotBillingType: Enum "Copilot Billing Type"; LearnMoreUrl: Text[2048]; CallerModuleInfo: ModuleInfo)
    var
        ErrorMessage: Text;
    begin
        // Validate Billing Type
        if CopilotBillingType = Enum::"Copilot Billing Type"::Undefined then begin
            ErrorMessage := StrSubstNo(InvalidBillingTypeErr, CopilotCapability);
            Error(ErrorMessage);
        end;

        RegisterCapability(CopilotCapability, CopilotAvailability, CopilotBillingType, Enum::"Azure AI Service Type"::"Azure OpenAI", LearnMoreUrl, CallerModuleInfo);
    end;

    procedure RegisterCapability(CopilotCapability: Enum "Copilot Capability"; CopilotAvailability: Enum "Copilot Availability"; CopilotBillingType: Enum "Copilot Billing Type"; AzureAIServiceType: Enum "Azure AI Service Type"; LearnMoreUrl: Text[2048]; CallerModuleInfo: ModuleInfo)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if IsCapabilityRegistered(CopilotCapability, CallerModuleInfo) then
            Error(AlreadyRegisteredErr);

        Clear(CopilotSettings);
        CopilotSettings.Init();
        CopilotSettings.Capability := CopilotCapability;
        CopilotSettings."App Id" := CallerModuleInfo.Id();
        CopilotSettings.Publisher := CopyStr(CallerModuleInfo.Publisher, 1, MaxStrLen(CopilotSettings.Publisher));
        CopilotSettings.Availability := CopilotAvailability;
        CopilotSettings."Learn More Url" := LearnMoreUrl;
        CopilotSettings."Service Type" := AzureAIServiceType;
        CopilotSettings."Billing Type" := CopilotBillingType;
        if CopilotSettings.Availability = Enum::"Copilot Availability"::"Early Preview" then
            CopilotSettings.Status := Enum::"Copilot Status"::Inactive
        else
            CopilotSettings.Status := Enum::"Copilot Status"::Active;

        CopilotSettings.Insert();
        Commit();

        AddTelemetryDimensions(CopilotCapability, CallerModuleInfo.Id(), CustomDimensions);
        AddStatusAndBillingTypeTelemetryDimension(CopilotSettings.Status, CopilotSettings."Billing Type", CustomDimensions);
        Telemetry.LogMessage('0000LDV', TelemetryRegisteredNewCopilotCapabilityLbl, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, Enum::"AL Telemetry Scope"::All, CustomDimensions);
    end;

    procedure SetCopilotCapability(Capability: Enum "Copilot Capability"; CallerModuleInfo: ModuleInfo; AIServiceType: Enum "Azure AI Service Type")
    var
        CopilotTelemetry: Codeunit "Copilot Telemetry";
        Language: Codeunit Language;
        IAIServicename: Interface "AI Service Name";
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

            IAIServicename := AIServiceType;
            FeatureTelemetry.LogError('0000LFN', IAIServicename.GetServiceName(), TelemetrySetCapabilityLbl, TelemetryCopilotCapabilityNotRegisteredLbl, '', Enum::"AL Telemetry Scope"::All, CustomDimensions);
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

#if not CLEAN27
    procedure ModifyCapability(CopilotCapability: Enum "Copilot Capability"; CopilotAvailability: Enum "Copilot Availability"; LearnMoreUrl: Text[2048]; CallerModuleInfo: ModuleInfo)
    begin
        ModifyCapability(CopilotCapability, CopilotAvailability, Enum::"Copilot Billing Type"::"Undefined", LearnMoreUrl, CallerModuleInfo);
    end;
#endif

    procedure ModifyCapability(CopilotCapability: Enum "Copilot Capability"; CopilotAvailability: Enum "Copilot Availability"; CopilotBillingType: Enum "Copilot Billing Type"; LearnMoreUrl: Text[2048]; CallerModuleInfo: ModuleInfo)
    var
        CustomDimensions: Dictionary of [Text, Text];
        ErrorMessage: Text;
    begin
        if not IsCapabilityRegistered(CopilotCapability, CallerModuleInfo) then
            Error(NotRegisteredErr);

        CopilotSettings.ReadIsolation(IsolationLevel::ReadCommitted);
        CopilotSettings.Get(CopilotCapability, CallerModuleInfo.Id());

        if CopilotSettings.Availability <> CopilotAvailability then
            CopilotSettings.Status := Enum::"Copilot Status"::Active;

        CopilotSettings.Availability := CopilotAvailability;
        CopilotSettings."Learn More Url" := LearnMoreUrl;

        // Validate Billing Type, Undefined billing type is not allowed
        if (CopilotSettings."Billing Type" <> Enum::"Copilot Billing Type"::Undefined) and
            (CopilotBillingType = Enum::"Copilot Billing Type"::Undefined) then begin
            ErrorMessage := StrSubstNo(InvalidBillingTypeErr, CopilotCapability);
            Error(ErrorMessage);
        end;

        CopilotSettings."Billing Type" := CopilotBillingType;
        CopilotSettings.Modify(true);
        Commit();

        AddTelemetryDimensions(CopilotCapability, CallerModuleInfo.Id(), CustomDimensions);
        AddStatusAndBillingTypeTelemetryDimension(CopilotSettings.Status, CopilotSettings."Billing Type", CustomDimensions);
        Telemetry.LogMessage('0000LDW', TelemetryModifiedCopilotCapabilityLbl, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, Enum::"AL Telemetry Scope"::All, CustomDimensions);
    end;

    procedure UnregisterCapability(CopilotCapability: Enum "Copilot Capability"; var CallerModuleInfo: ModuleInfo)
    var
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
    begin
        CopilotSettings.ReadIsolation(IsolationLevel::ReadCommitted);
        CopilotSettings.SetRange("Capability", CopilotCapability);
        CopilotSettings.SetRange("App Id", AppId);
        exit(not CopilotSettings.IsEmpty());
    end;

    procedure IsCapabilityActive(CallerModuleInfo: ModuleInfo): Boolean
    begin
        exit(IsCapabilityActive(CopilotSettings.Capability, CallerModuleInfo.Id()));
    end;

    procedure IsCapabilityActive(CopilotCapability: Enum "Copilot Capability"; CallerModuleInfo: ModuleInfo): Boolean
    begin
        exit(IsCapabilityActive(CopilotCapability, CallerModuleInfo.Id()));
    end;

    procedure IsCapabilityActive(CopilotCapability: Enum "Copilot Capability"; AppId: Guid): Boolean
    var
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

    procedure GetCapabilityName(): Text
    begin
        CheckCapabilitySet();

        exit(CapabilityToEnumName(CopilotSettings.Capability));
    end;

    procedure CapabilityToEnumName(CopilotCapability: Enum "Copilot Capability"): Text
    var
        CapabilityIndex: Integer;
        CapabilityName: Text;
    begin
        CapabilityIndex := CopilotCapability.Ordinals.IndexOf(CopilotCapability.AsInteger());
        CapabilityName := CopilotCapability.Names.Get(CapabilityIndex);

        if CapabilityName.Trim() = '' then
            exit(Format(CopilotCapability, 0, 9));

        exit(CapabilityName);
    end;

    procedure CheckCapabilitySet()
    begin
        if CopilotSettings.Capability.AsInteger() = 0 then
            Error(CopilotCapabilityNotSetErr);
    end;

    procedure CheckCapabilityServiceType(ServiceType: Enum "Azure AI Service Type")
    begin
        if CopilotSettings."Service Type" <> ServiceType then
            Error(CopilotCapabilityNotSetErr);
    end;

    procedure CheckEnabled(CallerModuleInfo: ModuleInfo)
    begin
        if not IsCapabilityEnabled(CopilotSettings.Capability, true, CallerModuleInfo) then
            Error(CopilotNotEnabledErr);
    end;

    procedure IsCapabilityEnabled(Capability: Enum "Copilot Capability"; CallerModuleInfo: ModuleInfo): Boolean
    begin
        exit(IsCapabilityEnabled(Capability, false, CallerModuleInfo));
    end;

    procedure IsCapabilityEnabled(Capability: Enum "Copilot Capability"; Silent: Boolean; CallerModuleInfo: ModuleInfo): Boolean
    var
        CopilotNotAvailable: Page "Copilot Not Available";
    begin
        if not IsTenantAllowedToUseAOAI() then begin
            if not Silent then
                Error(CopilotDisabledForTenantErr); // Copilot capabilities cannot be run on this environment.

            exit(false);
        end;

        if not IsCapabilityActive(Capability, CallerModuleInfo.Id()) then begin
            if not Silent then begin
                CopilotNotAvailable.SetCopilotCapability(Capability);
                CopilotNotAvailable.Run();
            end;

            exit(false);
        end;

        exit(CheckPrivacyNoticeState(Silent, Capability));
    end;

    [NonDebuggable]
    local procedure IsTenantAllowedToUseAOAI(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
        AzureOpenAIImpl: Codeunit "Azure OpenAI Impl";
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureAdTenant: Codeunit "Azure AD Tenant";
        ModuleInfo: ModuleInfo;
        BlockList, TelemtryTok : Text;
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit(true);

        NavApp.GetCurrentModuleInfo(ModuleInfo);
        if ModuleInfo.Publisher <> 'Microsoft' then
            exit(true);

        TelemtryTok := AzureOpenAIImpl.GetAzureOpenAICategory();
        if (not AzureKeyVault.GetAzureKeyVaultSecret(EnabledKeyTok, BlockList)) or (BlockList.Trim() = '') then begin
            FeatureTelemetry.LogError('0000KYC', TelemtryTok, TelemetryIsEnabledLbl, TelemetryUnableToCheckEnvironmentKVTxt);
            exit(false);
        end;

        if BlockList.Contains(AzureAdTenant.GetAadTenantId()) then begin
            FeatureTelemetry.LogError('0000LFP', TelemtryTok, TelemetryIsEnabledLbl, TelemetryEnvironmentNotAllowedtoRunCopilotTxt);
            exit(false);
        end;

        exit(true);
    end;

    local procedure CheckPrivacyNoticeState(Silent: Boolean; Capability: Enum "Copilot Capability"): Boolean
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        AzureOpenAIImpl: Codeunit "Azure OpenAI Impl";
        CopilotNotAvailable: Page "Copilot Not Available";
        PrivacyNoticeApprovalState: Enum "Privacy Notice Approval State";
    begin
        PrivacyNoticeApprovalState := PrivacyNotice.GetPrivacyNoticeApprovalState(AzureOpenAIImpl.GetAzureOpenAICategory(), false);
        case PrivacyNoticeApprovalState of
            Enum::"Privacy Notice Approval State"::Agreed:
                exit(true);
            Enum::"Privacy Notice Approval State"::Disagreed:
                begin
                    if not Silent then begin
                        CopilotNotAvailable.SetCopilotCapability(Capability);
                        CopilotNotAvailable.Run();
                    end;

                    exit(false);
                end;
            else
                exit(true);
        end;
    end;

    procedure AddTelemetryCustomDimensions(var CustomDimensions: Dictionary of [Text, Text]; CallerModuleInfo: ModuleInfo)
    var
        Language: Codeunit Language;
        SavedGlobalLanguageId: Integer;
    begin
        SavedGlobalLanguageId := GlobalLanguage();
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());

        CustomDimensions.Add('Capability', Format(CopilotSettings.Capability));
        CustomDimensions.Add('AppId', Format(CopilotSettings."App Id"));
        CustomDimensions.Add('Publisher', CallerModuleInfo.Publisher);
        CustomDimensions.Add('UserLanguage', Format(GlobalLanguage()));
        CustomDimensions.Add('BillingType', Format(CopilotSettings."Billing Type"));

        GlobalLanguage(SavedGlobalLanguageId);
    end;

    procedure SendActivateTelemetry(CopilotCapability: Enum "Copilot Capability"; AppId: Guid)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        AddTelemetryDimensions(CopilotCapability, AppId, CustomDimensions);
        Telemetry.LogMessage('0000LDY', TelemetryActivatedCopilotCapabilityLbl, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, Enum::"AL Telemetry Scope"::All, CustomDimensions);
    end;

    procedure SendDeactivateTelemetry(CopilotCapability: Enum "Copilot Capability"; AppId: Guid; Reason: Option; FeedbackEnabled: Boolean)
    var
        Language: Codeunit Language;
        SavedGlobalLanguageId: Integer;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        AddTelemetryDimensions(CopilotCapability, AppId, CustomDimensions);

        SavedGlobalLanguageId := GlobalLanguage();
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());

        if FeedbackEnabled then
            CustomDimensions.Add('Reason', Format(Reason))
        else
            CustomDimensions.Add('Reason', FeedbackDisabledLbl);

        Telemetry.LogMessage('0000LDZ', TelemetryDeactivatedCopilotCapabilityLbl, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, Enum::"AL Telemetry Scope"::All, CustomDimensions);

        GlobalLanguage(SavedGlobalLanguageId);
    end;

    procedure GetCopilotCategory(): Code[50]
    begin
        exit(CopilotCategoryLbl);
    end;

    procedure AddStatusAndBillingTypeTelemetryDimension(CopilotStatus: Enum "Copilot Status"; CopilotBillingType: Enum "Copilot Billing Type"; var CustomDimensions: Dictionary of [Text, Text])
    var
        Language: Codeunit Language;
        SavedGlobalLanguageId: Integer;
    begin
        SavedGlobalLanguageId := GlobalLanguage();
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());

        CustomDimensions.Add('Status', Format(CopilotStatus));
        CustomDimensions.Add('BillingType', Format(CopilotBillingType));

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

    procedure IsAdmin(): Boolean
    var
        AzureADGraphUser: Codeunit "Azure AD Graph User";
        AzureADPlan: Codeunit "Azure AD Plan";
        PlanIds: Codeunit "Plan Ids";
        UserPermissions: Codeunit "User Permissions";
    begin
        exit(AzureADGraphUser.IsUserDelegatedAdmin() or AzureADPlan.IsPlanAssignedToUser(PlanIds.GetGlobalAdminPlanId()) or AzureADPlan.IsPlanAssignedToUser(PlanIds.GetBCAdminPlanId()) or AzureADPlan.IsPlanAssignedToUser(PlanIds.GetD365AdminPlanId()) or AzureADGraphUser.IsUserDelegatedHelpdesk() or UserPermissions.IsSuper(UserSecurityId()));
    end;

    [TryFunction]
    procedure CheckGeoAndEUDB(var WithinGeo: Boolean; var WithinEUDB: Boolean)
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
    begin
        WithinGeo := ALCopilotFunctions.IsWithinGeo();
        WithinEUDB := ALCopilotFunctions.IsWithinEUDB();
    end;

    procedure GetDataMovementAllowed(var AllowDataMovement: Boolean)
    var
        AzureOpenAIImpl: Codeunit "Azure OpenAI Impl";
        PrivacyNotice: Codeunit "Privacy Notice";
    begin
        case PrivacyNotice.GetPrivacyNoticeApprovalState(AzureOpenAIImpl.GetAzureOpenAICategory(), false) of
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

    procedure DeactivateCapability(var CopilotSettingsLocal: Record "Copilot Settings")
    var
        CopilotNotifications: Codeunit "Copilot Notifications";
        CopilotDeactivate: Page "Copilot Deactivate Capability";
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        FeedbackEnabled: Boolean;
    begin
        FeedbackEnabled := ALCopilotFunctions.IsCopilotFeedbackEnabled();

        if FeedbackEnabled then begin
            CopilotDeactivate.SetCaption(Format(CopilotSettingsLocal.Capability));
            if CopilotDeactivate.RunModal() <> Action::OK then
                exit;
        end;

        CopilotSettingsLocal.Status := CopilotSettingsLocal.Status::Inactive;
        CopilotSettingsLocal.Modify(true);

        CopilotNotifications.ShowCapabilityChange();
        SendDeactivateTelemetry(CopilotSettingsLocal.Capability, CopilotSettingsLocal."App Id", CopilotDeactivate.GetReason(), FeedbackEnabled);
        Session.LogAuditMessage(StrSubstNo(CopilotFeatureDeactivatedLbl, CopilotSettingsLocal.Capability, CopilotSettingsLocal."App Id", UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", GetCopilotCapabilityStatus, '', false, false)]
    local procedure GetCopilotCapabilityStatus(Capability: Integer; var IsEnabled: Boolean; AppId: Guid; Silent: Boolean)
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        CopilotCapability: Enum "Copilot Capability";
    begin
        CopilotCapability := Enum::"Copilot Capability".FromInteger(Capability);
        IsEnabled := AzureOpenAI.IsEnabled(CopilotCapability, Silent, AppId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", GetCopilotCapabilityInfo, '', false, false)]
    local procedure GetCopilotCapabilityInfo(Capability: Integer; AppId: Guid; var CapabilityInfo: JsonObject)
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        CopilotCapability: Enum "Copilot Capability";
        LearnMoreUrlLbl: Label 'learnMoreUrl', Locked = true;
        IsEnabledLbl: Label 'isEnabled', Locked = true;
        IsPreviewLbl: Label 'isPreview', Locked = true;
    begin
        CopilotCapability := Enum::"Copilot Capability".FromInteger(Capability);
        CapabilityInfo.Add(IsEnabledLbl, AzureOpenAI.IsEnabled(CopilotCapability, true, AppId));

        CopilotSettings.ReadIsolation(IsolationLevel::ReadCommitted);
        if not CopilotSettings.Get(CopilotCapability, AppId) then
            exit;
        CapabilityInfo.Add(LearnMoreUrlLbl, CopilotSettings."Learn More Url");
        CapabilityInfo.Add(IsPreviewLbl, CopilotSettings.Availability <> Enum::"Copilot Availability"::"Generally Available");
    end;

    procedure IsPublisherMicrosoft(CallerModuleInfo: ModuleInfo): Boolean
    var
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        exit(CallerModuleInfo.Publisher() = ModuleInfo.Publisher());
    end;

    procedure GetCopilotBillingType(): Enum "Copilot Billing Type"
    begin
        CheckCapabilitySet();
        exit(CopilotSettings."Billing Type");
    end;

    procedure IsProductionEnvironment(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.IsProduction());
    end;
}