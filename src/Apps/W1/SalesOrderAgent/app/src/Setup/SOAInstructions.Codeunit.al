// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.SalesOrderAgent;

using System.Agents;
using System.AI.BusinessSkills;
using System.Azure.KeyVault;
using System.Globalization;
using System.Telemetry;

codeunit 4598 "SOA Instructions"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Creates or refreshes tenant-wide packaged skills owned by SOA, identified by their resource paths.
    /// Each Markdown resource supplies its title in the first heading and its description in the opening paragraph.
    /// </summary>
    internal procedure UpdateBusinessSkills()
    var
        SkillResources: List of [Text];
        ResourceName: Text;
        SkillResourcesPatternTok: Label 'Prompts/Skills/*.md', Locked = true;
        MissingBusinessSkillsErr: Label 'The Sales Order Agent app does not contain any business skill resources.';
    begin
        SkillResources := NavApp.ListResources(SkillResourcesPatternTok);
        if SkillResources.Count() = 0 then
            Error(MissingBusinessSkillsErr);
        foreach ResourceName in SkillResources do
            UpdateBusinessSkill(ResourceName);
    end;

    [NonDebuggable]
    local procedure UpdateBusinessSkill(ResourceName: Text)
    var
        BusinessSkill: Record "Business Skill";
        BusinessSkillManagement: Codeunit "Business Skill";
        BusinessSkillBuilder: Codeunit "Business Skill Builder";
        SkillCode: Code[100];
        SkillTitle: Text[250];
        SkillDescription: Text[2048];
        SkillContent: SecretText;
        NormalizedSkillContent: SecretText;
        StoredSkillContent: SecretText;
        NextVersion: Text;
        InitialVersionTok: Label 'v1.0', Locked = true;
    begin
        ReadBusinessSkillMetadata(ResourceName, SkillTitle, SkillDescription);
        SkillContent := NavApp.GetResourceAsText(ResourceName, TextEncoding::UTF8);
        ReadResourcePrompt(ResourceName, NormalizedSkillContent);
        SkillCode := CopyStr(ResourceName, 1, MaxStrLen(SkillCode));

        if FindOwnedBusinessSkill(SkillCode, BusinessSkill) then begin
            // Compare normalized content, but store the original resource so trailing line breaks are not normalized twice.
            StoredSkillContent := BusinessSkillManagement.GetContent(BusinessSkill);
            if StoredSkillContent.Unwrap() <> NormalizedSkillContent.Unwrap() then begin
                NextVersion := IncStr(BusinessSkill.Version);
                if (NextVersion = '') or (StrLen(NextVersion) > MaxStrLen(BusinessSkill.Version)) then
                    NextVersion := InitialVersionTok;
                BusinessSkillManagement.SetNewContentAndUpdateVersion(SkillCode, SkillContent, CopyStr(NextVersion, 1, MaxStrLen(BusinessSkill.Version)));
            end;
            BusinessSkillManagement.UpdateMetadata(SkillCode, SkillTitle, SkillDescription);
            if BusinessSkill.Status <> BusinessSkill.Status::Active then
                BusinessSkillManagement.Activate(BusinessSkill.ID);
        end else begin
            BusinessSkillBuilder.Initialize(SkillCode, SkillTitle, SkillContent);
            BusinessSkillBuilder.SetContentLocked(false);
            BusinessSkillBuilder.SetContentVersion(InitialVersionTok);
            BusinessSkillBuilder.SetDescription(SkillDescription);
            BusinessSkillBuilder.SetActive(true);
            BusinessSkillBuilder.Create();
        end;
    end;

    local procedure FindOwnedBusinessSkill(SkillCode: Code[100]; var BusinessSkill: Record "Business Skill"): Boolean
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        BusinessSkill.LockTable();
        BusinessSkill.SetRange("Owning App ID", CurrentModuleInfo.Id);
        BusinessSkill.SetRange("Skill ID", SkillCode);
        BusinessSkill.SetRange(Manual, false);
        exit(BusinessSkill.FindFirst());
    end;

    local procedure ReadBusinessSkillMetadata(ResourceName: Text; var SkillTitle: Text[250]; var SkillDescription: Text[2048])
    var
        Input: InStream;
        Line: Text;
        DescriptionText: Text;
        InvalidSkillResourceErr: Label 'The business skill resource %1 must start with a title and a description paragraph.', Comment = '%1 = Resource file name.';
        SkillMetadataTooLongErr: Label 'The title or description in business skill resource %1 is too long.', Comment = '%1 = Resource file name.';
    begin
        NavApp.GetResource(ResourceName, Input, TextEncoding::UTF8);
        Input.ReadText(Line);
        if not Line.StartsWith('# ') then
            Error(InvalidSkillResourceErr, ResourceName);

        Line := CopyStr(Line, 3).Trim();
        if Line = '' then
            Error(InvalidSkillResourceErr, ResourceName);
        if StrLen(Line) > MaxStrLen(SkillTitle) then
            Error(SkillMetadataTooLongErr, ResourceName);
        SkillTitle := CopyStr(Line, 1, MaxStrLen(SkillTitle));

        while not Input.EOS() do begin
            Input.ReadText(Line);
            Line := Line.Trim();
            if Line = '' then begin
                if DescriptionText <> '' then
                    break;
            end else begin
                if DescriptionText <> '' then
                    DescriptionText += ' ';
                DescriptionText += Line;
            end;
        end;

        if DescriptionText = '' then
            Error(InvalidSkillResourceErr, ResourceName);
        if StrLen(DescriptionText) > MaxStrLen(SkillDescription) then
            Error(SkillMetadataTooLongErr, ResourceName);
        SkillDescription := CopyStr(DescriptionText, 1, MaxStrLen(SkillDescription));
    end;

    [NonDebuggable]
    internal procedure GetSOAInstructions(UseBusinessIQ: Boolean): SecretText
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        SignaturePlaceholderSecretText: SecretText;
        SecurityPromptSecretText: SecretText;
        SecurityPromptPlaceholderText: Text;
        SecurityPromptReplacementText: Text;
        SignaturePlaceholderText: Text;
        InstructionsText: Text;
        SOAInstructionsPromptTok: Label 'Prompts/SalesOrderAgent-AgentInstructions.json', Locked = true;
        SOAStandardInstructionsPromptTok: Label 'Prompts/SalesOrderAgent-StandardInstructions.json', Locked = true;
        SignaturePlaceholderTok: Label '%1', Locked = true;
        SecurityPromptReplacementTok: Label '%2', Locked = true;
        SOAInstructionsSecurityPromptTok: Label 'SalesOrderAgent-AgentInstructions-SecurityPromptV28', Locked = true;
        SOAInstructionsSecurityPromptPlaceholderTok: Label '{{$SAFETYCLAUSE}}', Locked = true;
        FailedToRetrieveKVAgentInstructionsSecurityPromptTxt: Label 'Failed to retrieve Sales Order Agent instructions security prompt from Azure Key Vault.', Locked = true;
        UnableToConfigureAgentInstructionsErr: Label 'Unable to configure Sales Order Agent instructions.';
    begin
        if UseBusinessIQ then
            InstructionsText := NavApp.GetResourceAsText(SOAInstructionsPromptTok, TextEncoding::UTF8)
        else
            InstructionsText := NavApp.GetResourceAsText(SOAStandardInstructionsPromptTok, TextEncoding::UTF8);
        if not AzureKeyVault.GetAzureKeyVaultSecret(SOAInstructionsSecurityPromptTok, SecurityPromptSecretText) then begin
            Session.LogMessage('0000U4D', FailedToRetrieveKVAgentInstructionsSecurityPromptTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SOASetup.GetFeatureName());
            Error(UnableToConfigureAgentInstructionsErr);
        end;

        SecurityPromptPlaceholderText := SOAInstructionsSecurityPromptPlaceholderTok;
        SecurityPromptReplacementText := SecurityPromptReplacementTok;
        InstructionsText := InstructionsText.Replace(SecurityPromptPlaceholderText, SecurityPromptReplacementText);
        SignaturePlaceholderText := SignaturePlaceholderTok;
        SignaturePlaceholderSecretText := SignaturePlaceholderText;
        exit(SecretText.SecretStrSubstNo(InstructionsText, SignaturePlaceholderSecretText, SecurityPromptSecretText));
    end;

    internal procedure GetBroaderItemSearchPrompt(): SecretText
    var
        BroaderItemSearchPromptTok: Label 'Prompts/ItemSearch/item-entity-attribute-extraction-tool.json', Locked = true;
    begin
        exit(NavApp.GetResourceAsText(BroaderItemSearchPromptTok, TextEncoding::UTF8));
    end;

    internal procedure GetBroaderItemSearchSystemPrompt(): SecretText
    var
        BroaderItemSearchSystemPrompt: SecretText;
        BroaderItemSearchSystemPromptTok: Label 'Prompts/ItemSearch/item-entity-attribute-extraction-task.md', Locked = true;
    begin
        BroaderItemSearchSystemPrompt := NavApp.GetResourceAsText(BroaderItemSearchSystemPromptTok, TextEncoding::UTF8);
        AddCultureToBroaderItemSearchSystemPrompt(BroaderItemSearchSystemPrompt);
        exit(BroaderItemSearchSystemPrompt);
    end;

    [NonDebuggable]
    local procedure AddCultureToBroaderItemSearchSystemPrompt(var Prompt: SecretText)
    var
        AgentSession: Codeunit "Agent Session";
        Language: Codeunit "Language";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        InstructionsText: Text;
        CultureName: Text;
        LanguageCode: Code[10];
        FormatRegion: Text[80];
        LanguageID: Integer;
        BroaderItemSearchTaskPromptNameTok: Label 'item-entity-attribute-extraction-task.md', Locked = true;
    begin
        InstructionsText := Prompt.Unwrap();
        SOASetup.GetCommunicationLanguageCodeAndFormat(AgentSession.GetCurrentSessionAgentTaskId(), LanguageCode, FormatRegion);
        if LanguageCode <> '' then begin
            LanguageID := Language.GetLanguageId(LanguageCode);
            CultureName := Language.GetCultureName(LanguageID);
            if not TryFormatInstructionsText(InstructionsText, CultureName) then
                FeatureTelemetry.LogError('0000PN7', SOASetup.GetFeatureName(), BroaderItemSearchTaskPromptNameTok, FailedToFormatInstructionsTextErr);
            Prompt := InstructionsText;
        end;
    end;

    internal procedure GetOutputMessageSignatureUpdateTool(): SecretText
    var
        SignatureUpdateToolTok: Label 'Prompts/MailTemplate/signature-update-tool.json', Locked = true;
    begin
        exit(NavApp.GetResourceAsText(SignatureUpdateToolTok, TextEncoding::UTF8));
    end;

    internal procedure GetOutputMessageSignatureUpdateSystemPrompt(): SecretText
    var
        SignatureUpdateInstructionsTok: Label 'Prompts/MailTemplate/signature-update-instructions.md', Locked = true;
    begin
        exit(NavApp.GetResourceAsText(SignatureUpdateInstructionsTok, TextEncoding::UTF8));
    end;

    internal procedure GetMailTemplateCheckTool(): SecretText
    var
        MailTemplateCheckToolTok: Label 'Prompts/MailTemplate/mail-template-check-tool.json', Locked = true;
    begin
        exit(NavApp.GetResourceAsText(MailTemplateCheckToolTok, TextEncoding::UTF8));
    end;

    [NonDebuggable]
    internal procedure GetMailTemplateCheckSystemPrompt(): SecretText
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        SafetyPromptSecretText: SecretText;
        HarmfulContentSecretText: SecretText;
        MailTemplateCheckPromptTemplate: Text;
        MailTemplateCheckInstructionsTok: Label 'Prompts/MailTemplate/mail-template-check-instructions.md', Locked = true;
        MailTemplateCheckSafetyPromptTok: Label 'SalesOrderAgent-MailTemplateCheck-SafetyPromptV28', Locked = true;
        MailTemplateCheckHarmfulContentPromptTok: Label 'SalesOrderAgent-MailTemplateCheck-HarmfulContentPromptV28', Locked = true;
        FailedToRetrieveKVSafetyPromptTxt: Label 'Failed to retrieve Mail Template Check safety prompt from Azure Key Vault.', Locked = true;
        FailedToRetrieveKVHarmfulContentPromptTxt: Label 'Failed to retrieve Mail Template Check harmful content prompt from Azure Key Vault.', Locked = true;
        UnableToConfigureMailTemplateCheckPromptErr: Label 'Unable to configure mail template check instructions.';
    begin
        MailTemplateCheckPromptTemplate := NavApp.GetResourceAsText(MailTemplateCheckInstructionsTok, TextEncoding::UTF8);

        if not AzureKeyVault.GetAzureKeyVaultSecret(MailTemplateCheckHarmfulContentPromptTok, HarmfulContentSecretText) then begin
            Session.LogMessage('0000U4B', FailedToRetrieveKVHarmfulContentPromptTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SOASetup.GetFeatureName());
            Error(UnableToConfigureMailTemplateCheckPromptErr);
        end;

        if not AzureKeyVault.GetAzureKeyVaultSecret(MailTemplateCheckSafetyPromptTok, SafetyPromptSecretText) then begin
            Session.LogMessage('0000U4C', FailedToRetrieveKVSafetyPromptTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SOASetup.GetFeatureName());
            Error(UnableToConfigureMailTemplateCheckPromptErr);
        end;

        exit(SecretText.SecretStrSubstNo(MailTemplateCheckPromptTemplate, HarmfulContentSecretText, SafetyPromptSecretText));
    end;

    internal procedure GetItemSelectorSystemPrompt(var Prompt: SecretText): Boolean
    var
        ItemSelectorTaskPromptTok: Label 'Prompts/ItemSearch/itemselector-task.md', Locked = true;
    begin
        exit(ReadResourcePrompt(ItemSelectorTaskPromptTok, Prompt));
    end;

    internal procedure GetItemSelectorPrompt(): SecretText
    var
        Prompt: SecretText;
        ItemSelectorToolPromptTok: Label 'Prompts/ItemSearch/itemselector-tool.json', Locked = true;
    begin
        if not ReadResourcePrompt(ItemSelectorToolPromptTok, Prompt) then
            Error(ConstructingPromptFailedErr);

        exit(Prompt);
    end;

    local procedure ReadResourcePrompt(ResourceName: Text; var Prompt: SecretText): Boolean
    var
        InStream: InStream;
        TextBuilder: TextBuilder;
        TextLine: Text;
    begin
        NavApp.GetResource(ResourceName, InStream, TextEncoding::UTF8);

        InStream.ReadText(TextLine);
        TextBuilder.Append(TextLine);
        while not InStream.EOS() do begin
            InStream.ReadText(TextLine);
            TextBuilder.AppendLine('');
            TextBuilder.Append(TextLine);
        end;

        Prompt := TextBuilder.ToText();
        exit(true);
    end;

    [TryFunction]
    local procedure TryFormatInstructionsText(var InstructionsText: Text; CultureName: Text)
    begin
        InstructionsText := StrSubstNo(InstructionsText, CultureName);
    end;

    var
        SOASetup: Codeunit "SOA Setup";
        ConstructingPromptFailedErr: label 'There was an error with sending the call to Copilot. Log a Business Central support request about this.', Comment = 'Copilot is a Microsoft service name and must not be translated';
        FailedToFormatInstructionsTextErr: label 'Failed to format broader item search instructions text with culture name.', Locked = true;
}
