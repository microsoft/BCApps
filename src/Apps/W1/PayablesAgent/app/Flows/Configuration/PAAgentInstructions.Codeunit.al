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
    // Resource selection is version-aware; the applied fingerprint describes the exact public prompt deployed.

    var
        PASetup: Codeunit "PA Setup";
        PATelemetry: Codeunit "PA Telemetry";
        SecurityPromptTok: Label 'PayablesAgent-SecurityPromptV280', Locked = true;
        UnableToConfigureAgentInstructionsErr: Label 'Unable to configure agent instructions.';
        AgentDrivenLineMatchingTok: Label 'PAAgentDrivenLineMatching', Locked = true;
        AgentDrivenTreatmentTok: Label 'agent_driven', Locked = true;
        AgentInstructionsTok: Label 'DraftBasedPayablesAgent/Prompts/PayablesAgent-AgentInstructions.md', Locked = true;
        AgentDrivenInstructionsTok: Label 'DraftBasedPayablesAgent/Prompts/PayablesAgent-AgentInstructions-AgentDriven.md', Locked = true;
        AgentInstructionsV2Tok: Label 'Prompts/PayablesAgent-AgentInstructions-V2.md', Locked = true;

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
        ResourceName: Text;
    begin
        ResourceName := ResolveResource();
        PayablesAgentPromptText := NavApp.GetResourceAsText(ResourceName, TextEncoding::UTF8);
        if PayablesAgentPromptText = '' then
            Error(UnableToConfigureAgentInstructionsErr);
        if AzureKeyVault.GetAzureKeyVaultSecret(SecurityPromptTok, SecurityPromptSecretText) then
            CompletePromptSecretText := SecretText.SecretStrSubstNo(PayablesAgentPromptText, SecurityPromptSecretText)
        else begin
            PATelemetry.LogSecurityPromptUnavailable();
            Error(UnableToConfigureAgentInstructionsErr);
        end;
        Agent.SetInstructions(AgentUserSecurityId, CompletePromptSecretText);

        // Do not re-resolve configuration after the potentially slow secret lookup.
        ConfigHash := CopyStr(HashInstructions(ResourceName, PayablesAgentPromptText), 1, MaxStrLen(ConfigHash));
    end;

    internal procedure ResolveResource(): Text
    begin
        exit(ResolveResource(IsAgentDrivenLineMatchingEnabled()));
    end;

    // Explicit treatment input is retained for the existing resource-variant contracts.
    internal procedure ResolveResource(AgentDrivenLineMatching: Boolean): Text
    var
        Version: Codeunit "PA V1V2 Flag";
    begin
        exit(SelectResource(Version.IsV2Active(), AgentDrivenLineMatching));
    end;

    local procedure SelectResource(IsV2: Boolean; AgentDrivenLineMatching: Boolean): Text
    begin
        if IsV2 then
            exit(AgentInstructionsV2Tok);
        if AgentDrivenLineMatching then
            exit(AgentDrivenInstructionsTok);
        exit(AgentInstructionsTok);
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
        PASetup.LoadStoredOrDefaults();
        if PASetup.GetAppliedInstrConfigHash() = GetInstructionsConfigHash() then
            exit;
        PATelemetry.LogInstructionsReapplied();
        SetAgentInstructions(AgentUserSecurityId);
    end;

    [TryFunction]
    internal procedure TryEnsureAgentInstructionsMatchConfiguration(AgentUserSecurityId: Guid)
    begin
        EnsureAgentInstructionsMatchConfiguration(AgentUserSecurityId);
    end;

    internal procedure GetInstructionsConfigHash(): Text
    var
        ResourceName: Text;
    begin
        ResourceName := ResolveResource();
        exit(HashInstructions(ResourceName, NavApp.GetResourceAsText(ResourceName, TextEncoding::UTF8)));
    end;

    local procedure HashInstructions(ResourceName: Text; PromptText: Text): Text
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        Signature: TextBuilder;
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        // Includes mode/variant and resource edits, but never the AKV secret or document content.
        Signature.AppendLine(ResourceName);
        Signature.Append(PromptText);
        exit(CryptographyManagement.GenerateHash(Signature.ToText(), HashAlgorithmType::SHA256));
    end;

    #endregion
}
