// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;
using System.Azure.KeyVault;
using System.Config;
using System.Security.Encryption;

codeunit 3349 "PA Agent Instructions"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    #region Agent instructions
    // The prompt resource still needs version-aware selection: today the v1 prompts are always used.

    internal procedure SetAgentInstructions(AgentUserSecurityId: Guid)
    begin
        if IsNullGuid(AgentUserSecurityId) then
            exit;

        PASetup.SaveAppliedInstrConfigHash(ApplyAgentInstructions(AgentUserSecurityId));
    end;

    internal procedure ApplyAgentInstructions(AgentUserSecurityId: Guid) ConfigHash: Text[64]
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        Agent: Codeunit Agent;
        SecurityPromptSecretText, CompletePromptSecretText : SecretText;
        PayablesAgentPromptText: Text;
        AgentDriven: Boolean;
    begin
        AgentDriven := IsAgentDrivenLineMatchingEnabled();
        if AgentDriven then
            PayablesAgentPromptText := NavApp.GetResourceAsText(PayablesAgentAgentDrivenPromptTok, TextEncoding::UTF8)
        else
            PayablesAgentPromptText := NavApp.GetResourceAsText(PayablesAgentPromptTok, TextEncoding::UTF8);
        if AzureKeyVault.GetAzureKeyVaultSecret(SecurityPromptTok, SecurityPromptSecretText) then
            CompletePromptSecretText := SecretText.SecretStrSubstNo(PayablesAgentPromptText, SecurityPromptSecretText)
        else begin
            Session.LogMessage('0000QPX', 'Failed to retrieve security prompt', Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', PATelemetry.FeatureName());
            Error(UnableToConfigureAgentInstructionsErr);
        end;
        Agent.SetInstructions(AgentUserSecurityId, CompletePromptSecretText);

        ConfigHash := CopyStr(GetInstructionsConfigHash(), 1, MaxStrLen(ConfigHash));
    end;

    internal procedure IsAgentDrivenLineMatchingEnabled(): Boolean
    var
        FeatureConfiguration: Codeunit "Feature Configuration";
    begin
        exit(FeatureConfiguration.GetConfiguration(AgentDrivenLineMatchingTok) = AgentDrivenTreatmentTok);
    end;

    internal procedure EnsureAgentInstructionsMatchConfiguration(AgentUserSecurityId: Guid)
    begin
        if IsNullGuid(AgentUserSecurityId) then
            exit;
        PASetup.GetSetup();
        if PASetup.GetAppliedInstrConfigHash() = GetInstructionsConfigHash() then
            exit;
        Session.LogMessage('0000SEK', 'Payables Agent instructions reapplied due to experiment configuration drift.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PATelemetry.FeatureName());
        SetAgentInstructions(AgentUserSecurityId);
    end;

    [TryFunction]
    internal procedure TryEnsureAgentInstructionsMatchConfiguration(AgentUserSecurityId: Guid)
    begin
        EnsureAgentInstructionsMatchConfiguration(AgentUserSecurityId);
    end;

    internal procedure GetInstructionsConfigHash(): Text
    var
        FeatureConfiguration: Codeunit "Feature Configuration";
        CryptographyManagement: Codeunit "Cryptography Management";
        ConfigKey: Text;
        Signature: TextBuilder;
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        foreach ConfigKey in GetInstructionsExperimentKeys() do begin
            Signature.Append(ConfigKey);
            Signature.Append('=');
            Signature.Append(FeatureConfiguration.GetConfiguration(ConfigKey));
            Signature.Append(';');
        end;
        exit(CryptographyManagement.GenerateHash(Signature.ToText(), HashAlgorithmType::SHA256));
    end;

    local procedure GetInstructionsExperimentKeys() Keys: List of [Text]
    begin
        // Tenant-level experiment keys whose ECS configuration changes the agent's instructions.
        // Add future prompt-affecting experiment keys here.
        Keys.Add(AgentDrivenLineMatchingTok);
    end;

    #endregion

    var
        PASetup: Codeunit "PA Setup";
        PATelemetry: Codeunit "PA Telemetry";
        PayablesAgentPromptTok: Label '_DraftBasedPayablesAgent/Prompts/PayablesAgent-AgentInstructions.md', Locked = true;
        PayablesAgentAgentDrivenPromptTok: Label '_DraftBasedPayablesAgent/Prompts/PayablesAgent-AgentInstructions-AgentDriven.md', Locked = true;
        SecurityPromptTok: Label 'PayablesAgent-SecurityPromptV280', Locked = true;
        UnableToConfigureAgentInstructionsErr: Label 'Unable to configure agent instructions.';
        AgentDrivenLineMatchingTok: Label 'PAAgentDrivenLineMatching', Locked = true;
        AgentDrivenTreatmentTok: Label 'agent_driven', Locked = true;
}
