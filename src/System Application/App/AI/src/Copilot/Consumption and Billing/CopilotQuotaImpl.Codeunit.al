// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System;

codeunit 7786 "Copilot Quota Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        InvalidUsageTypeErr: Label 'The value "%1" is not a valid Copilot Quota Usage Type.', Comment = '%1=a value such as "AI response" or "5"';
        CapabilityNotRegisteredTelemetryMsg: Label 'Capability "%1" is not registered in the system but is logging usage.', Locked = true;
        LoggingUsageTelemetryMsg: Label 'Capability "%1" is logging %2 usage of type %3, excluded from billing: %4.', Locked = true;

    trigger OnRun()
    var
        Results: Dictionary of [Text, Text];
    begin
        GetQuotaResults(Results);
        Page.SetBackgroundTaskResult(Results);
    end;

    procedure GetQuotaResults(var Results: Dictionary of [Text, Text])
    var
        Quota: Record "AI Consumption Quota" temporary;
        CopilotQuota: Codeunit "Copilot Quota";
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        ALCopilotQuotaDetails: Dotnet ALCopilotQuotaDetails;
    begin
        Clear(Results);
        if CopilotQuota.IsNewMonetizationEnabled() then begin
            CopilotQuota.GetAIConsumptionQuota(Quota);
            Results.Add('CanConsume', Format(Quota."Can Consume"));
            Results.Add('HasSetupBilling', Format(Quota."Billing Enabled"));
            if (Quota."AI Credit Limit" > 0) and (Quota."Consumed AI Credits" >= 0) then
                Results.Add('QuotaUsedPercentage', Format(100 * Quota."Consumed AI Credits" / Quota."AI Credit Limit"));
            exit;
        end;

        ALCopilotQuotaDetails := ALCopilotFunctions.GetCopilotQuotaDetails();

        if IsNull(ALCopilotQuotaDetails) then
            exit;

        Results.Add('CanConsume', Format(ALCopilotQuotaDetails.CanConsume()));
        Results.Add('HasSetupBilling', Format(ALCopilotQuotaDetails.HasSetupBilling()));
        Results.Add('QuotaUsedPercentage', Format(ALCopilotQuotaDetails.QuotaUsedPercentage()));

    end;

    procedure CanConsume(): Boolean
    var
        Quota: Record "AI Consumption Quota" temporary;
        CopilotQuota: Codeunit "Copilot Quota";
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        ALCopilotQuotaDetails: Dotnet ALCopilotQuotaDetails;
        UnableToRetrieveQuotaDetailsLbl: Label 'Unable to retrieve quota details for tenant', locked = true;
        IsTenantAllowedToConsumeQuotaLbl: Label 'Is tenant allowed to consume quota: %1', locked = true, Comment = '%1 = true/false';
    begin
        if CopilotQuota.IsNewMonetizationEnabled() then begin
            CopilotQuota.GetAIConsumptionQuota(Quota);
            exit(Quota."Can Consume");
        end;

        ALCopilotQuotaDetails := ALCopilotFunctions.GetCopilotQuotaDetails();

        if IsNull(ALCopilotQuotaDetails) then begin
            Session.LogMessage('0000P7N', UnableToRetrieveQuotaDetailsLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'category', CopilotCapabilityImpl.GetCopilotCategory());
            exit(false);
        end;

        Session.LogMessage('0000P7O', StrSubstNo(IsTenantAllowedToConsumeQuotaLbl, Format(ALCopilotQuotaDetails.CanConsume())), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'category', CopilotCapabilityImpl.GetCopilotCategory());

        exit(ALCopilotQuotaDetails.CanConsume());
    end;

    procedure LogQuotaUsage(CopilotCapability: Enum "Copilot Capability"; Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; CallerModuleInfo: ModuleInfo)
    var
        CopilotQuota: Codeunit "Copilot Quota";
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AlCopilotCapability: DotNet ALCopilotCapability;
        AlCopilotUsageType: DotNet ALCopilotUsageType;
    begin
        if not CopilotCapabilityImpl.IsCapabilityRegistered(CopilotCapability, CallerModuleInfo) then
            Session.LogMessage('0000OSL', StrSubstNo(CapabilityNotRegisteredTelemetryMsg, CopilotCapability), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetCopilotCategory());

        Session.LogMessage('0000OSM', StrSubstNo(LoggingUsageTelemetryMsg, CopilotCapability, Usage, CopilotQuotaUsageType, false), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetCopilotCategory());

        // Measured V2 usage belongs to its producer, not this legacy action-count adapter.
        if CopilotQuota.IsNewMonetizationEnabled() then
            exit;

        ALCopilotCapability := ALCopilotCapability.ALCopilotCapability(
            CallerModuleInfo.Publisher(), CallerModuleInfo.Id(), Format(CallerModuleInfo.AppVersion()), CopilotCapabilityImpl.CapabilityToEnumName(CopilotCapability));

        UsageTypeToDotnetUsageType(CopilotQuotaUsageType, AlCopilotUsageType);

        ALCopilotFunctions.LogCopilotQuotaUsage(AlCopilotCapability, Usage, AlCopilotUsageType);
    end;

    procedure LogAgentUserAIConsumption(CopilotCapability: Enum "Copilot Capability"; Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; CallerModuleInfo: ModuleInfo; AgentTaskID: BigInteger; ActionsCharged: Text[1024]; Description: Text; UniqueID: Text[1024]; ExcludeFromBilling: Boolean)
    var
        CopilotQuota: Codeunit "Copilot Quota";
        AlCopilotCapability: DotNet ALCopilotCapability;
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AlCopilotUsageType: DotNet ALCopilotUsageType;
    begin
        if not CopilotCapabilityImpl.IsCapabilityRegistered(CopilotCapability, CallerModuleInfo) then
            Session.LogMessage('0000QIY', StrSubstNo(CapabilityNotRegisteredTelemetryMsg, CopilotCapability), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetCopilotCategory());

        Session.LogMessage('0000QIZ', StrSubstNo(LoggingUsageTelemetryMsg, CopilotCapability, Usage, CopilotQuotaUsageType, ExcludeFromBilling), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetCopilotCategory());

        if CopilotQuota.IsNewMonetizationEnabled() then
            exit;

        ALCopilotCapability := ALCopilotCapability.ALCopilotCapability(
                 CallerModuleInfo.Publisher(), CallerModuleInfo.Id(), Format(CallerModuleInfo.AppVersion()), CopilotCapabilityImpl.CapabilityToEnumName(CopilotCapability));

        UsageTypeToDotnetUsageType(CopilotQuotaUsageType, AlCopilotUsageType);

        ALCopilotFunctions.LogAgentUserAIConsumptionAsync(
            ALCopilotCapability,
            AgentTaskID,
            ActionsCharged,
            Description,
            AlCopilotUsageType,
            Usage,
            UniqueID,
            ExcludeFromBilling
        );
    end;

    procedure IsAgentUserAIConsumptionLogged(UniqueID: Text[1024]): Boolean
    var
        CopilotQuota: Codeunit "Copilot Quota";
        ALCopilotFunctions: DotNet ALCopilotFunctions;
    begin
        if CopilotQuota.IsNewMonetizationEnabled() then
            exit(false);

        exit(ALCopilotFunctions.IsAgentUserAIConsumptionLogged(UniqueID));
    end;

    procedure GetAIConsumptionQuota(PrincipalId: Guid; var Quota: Record "AI Consumption Quota" temporary)
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        Result: DotNet ALAIConsumptionQuotaResult;
        Handled: Boolean;
    begin
        VerifyNewMonetizationEnabled();
        Quota.Init();
        OnBeforeGetAIConsumptionQuota(PrincipalId, Quota, Handled);
        if Handled then
            exit;

        if IsNullGuid(PrincipalId) then
            Result := ALCopilotFunctions.GetAIConsumptionQuota()
        else
            Result := ALCopilotFunctions.GetAIConsumptionQuota(PrincipalId);

        Quota.Init();
        Quota."Can Consume" := Result.CanConsume;
        Quota."Billing Enabled" := Result.IsBillingEnabled;
        Quota."Credit Source" := CopyStr(Format(Result.CurrentCreditSource), 1, MaxStrLen(Quota."Credit Source"));
        Quota."AI Credit Limit" := Result.AICreditLimit;
        Quota."Consumed AI Credits" := Result.ConsumedAICredits;
        Quota."Next Reset" := Result.NextReset;
    end;

    procedure RecordAIConsumption(ConsumptionId: Guid; SessionId: Guid; InteractionId: Guid; CorrelationId: Guid; ResourceName: Text[256]; AppId: Guid; UsagePayload: Text; PrincipalId: Guid; PrincipalDisplayName: Text[256]; AgentTaskId: BigInteger; Metadata: Text[512]; Description: Text; IsFeatureTrial: Boolean)
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
    begin
        VerifyNewMonetizationEnabled();
        ALCopilotFunctions.RecordAIConsumption(ConsumptionId, SessionId, InteractionId, CorrelationId, ResourceName, AppId, UsagePayload, PrincipalId, PrincipalDisplayName, AgentTaskId, Metadata, Description, IsFeatureTrial);
    end;

    local procedure VerifyNewMonetizationEnabled()
    var
        CopilotQuota: Codeunit "Copilot Quota";
        NewMonetizationDisabledErr: Label 'The new AI monetization integration is not enabled.';
    begin
        if not CopilotQuota.IsNewMonetizationEnabled() then
            Error(NewMonetizationDisabledErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAIConsumptionQuota(PrincipalId: Guid; var Quota: Record "AI Consumption Quota" temporary; var Handled: Boolean)
    begin
    end;

    local procedure UsageTypeToDotnetUsageType(CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; var AlCopilotUsageType: DotNet AlCopilotUsageType)
    begin
        case CopilotQuotaUsageType of
            CopilotQuotaUsageType::"Generative AI Answer":
                AlCopilotUsageType := AlCopilotUsageType::GenAIAnswer;
            CopilotQuotaUsageType::"Autonomous Action":
                AlCopilotUsageType := AlCopilotUsageType::AutonomousAction;
            else
                Error(InvalidUsageTypeErr, CopilotQuotaUsageType);
        end;
    end;
}