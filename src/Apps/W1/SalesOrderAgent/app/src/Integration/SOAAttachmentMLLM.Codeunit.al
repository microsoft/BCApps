// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.SalesOrderAgent;

using System.Agents;
using System.AI;
using System.Azure.KeyVault;
using System.Text;

codeunit 4420 "SOA Attachment MLLM"
{
    Access = Internal;
    Permissions = tabledata "Agent Task File" = r, tabledata "Agent Task Message Attachment" = rM;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ExtractionSystemPromptTok: Label 'Prompts/AttachmentExtraction/soa-attachment-extraction-system.md', Locked = true;
        ExtractionSchemaTok: Label 'Prompts/AttachmentExtraction/soa-attachment-extraction-example.json', Locked = true;
        SecurityPromptTok: Label 'SalesOrderAgent-Irrelevance-SecurityPromptV28', Locked = true;
        SchemaNameTok: Label 'soa-attachment-content', Locked = true;
        FileDataTok: Label 'data:%1;base64,%2', Comment = '%1 = MIME type, %2 = base64 file content', Locked = true;
        UserMessageTok: Label 'Extract all Sales Order Agent-relevant information from the complete attached file "%1". Return JSON following this flexible example structure. Only schema is mandatory. Omit unavailable information instead of inventing it: %2', Comment = '%1 = file name, %2 = flexible JSON structure', Locked = true;
        AttachmentFileNotFoundErr: Label 'The attachment file could not be found.';
        AttachmentFileEmptyErr: Label 'The attachment file is empty.';
        AttachmentMimeTypeMissingErr: Label 'The attachment MIME type is missing.';
        ExtractionPromptNotFoundErr: Label 'The attachment extraction prompt could not be loaded.';
        ExtractionCallFailedErr: Label 'The attachment extraction AI call failed. Status: %1. Error: %2', Comment = '%1 = status code, %2 = error';
        ExtractionResponseEmptyErr: Label 'The attachment extraction AI response is empty.';
        ExtractionResponseInvalidJsonErr: Label 'The attachment extraction AI response is not valid JSON.';
        ExtractionResponseInvalidSchemaErr: Label 'The attachment extraction AI response does not contain the supported schema.';

    internal procedure EnsureCanonicalTextContent(var AgentTaskMessageAttachment: Record "Agent Task Message Attachment"; var CanonicalContent: Text; var FailureReason: Text): Boolean
    var
        ExistingContent: Text;
    begin
        Clear(CanonicalContent);
        Clear(FailureReason);
        ExistingContent := GetTextContent(AgentTaskMessageAttachment);
        if IsCanonicalContent(ExistingContent) then begin
            CanonicalContent := ExistingContent;
            exit(true);
        end;

        if not TryExtractAttachmentContent(AgentTaskMessageAttachment, CanonicalContent, FailureReason) then begin
            if FailureReason = '' then
                FailureReason := GetLastErrorText();
            exit(false);
        end;

        ReplaceTextContent(AgentTaskMessageAttachment, CanonicalContent);
        exit(true);
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure TryExtractAttachmentContent(AgentTaskMessageAttachment: Record "Agent Task Message Attachment"; var ExtractedContent: Text; var FailureReason: Text)
    var
        AgentTaskFile: Record "Agent Task File";
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIDeployments: Codeunit "AOAI Deployments";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIUserMessage: Codeunit "AOAI User Message";
        Base64Convert: Codeunit "Base64 Convert";
        FileInStream: InStream;
        FileData: Text;
        Prompt: SecretText;
        PromptTemplate: Text;
        SchemaTemplate: Text;
        SecurityPrompt: SecretText;
    begin
        if not AgentTaskFile.Get(AgentTaskMessageAttachment."Task ID", AgentTaskMessageAttachment."File ID") then
            Error(AttachmentFileNotFoundErr);

        AgentTaskFile.CalcFields(Content);
        if not AgentTaskFile.Content.HasValue() then
            Error(AttachmentFileEmptyErr);
        if AgentTaskFile."File MIME Type" = '' then
            Error(AttachmentMimeTypeMissingErr);

        AgentTaskFile.Content.CreateInStream(FileInStream);
        FileData := StrSubstNo(FileDataTok, AgentTaskFile."File MIME Type", Base64Convert.ToBase64(FileInStream));

        PromptTemplate := NavApp.GetResourceAsText(ExtractionSystemPromptTok, TextEncoding::UTF8);
        SchemaTemplate := NavApp.GetResourceAsText(ExtractionSchemaTok, TextEncoding::UTF8);
        if (PromptTemplate = '') or (SchemaTemplate = '') then
            Error(ExtractionPromptNotFoundErr);
        if not AzureKeyVault.GetAzureKeyVaultSecret(SecurityPromptTok, SecurityPrompt) then
            Error(ExtractionPromptNotFoundErr);
        Prompt := SecretText.SecretStrSubstNo(PromptTemplate, SecurityPrompt);

        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT41MiniPreview());
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Sales Order Agent");

        AOAIChatCompletionParams.SetTemperature(0);
        AOAIChatCompletionParams.SetMaxTokens(GetMaxTokens());
        AOAIChatCompletionParams.SetJsonMode(true);

        AOAIChatMessages.SetPrimarySystemMessage(Prompt);

        AOAIUserMessage.AddFilePart(FileData);
        AOAIUserMessage.AddTextPart(StrSubstNo(UserMessageTok, AgentTaskFile."File Name", SchemaTemplate));
        AOAIChatMessages.AddUserMessage(AOAIUserMessage);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);
        if not AOAIOperationResponse.IsSuccess() then
            Error(ExtractionCallFailedErr, AOAIOperationResponse.GetStatusCode(), AOAIOperationResponse.GetError());

        ExtractedContent := AOAIOperationResponse.GetResult();
        if not ValidateAndNormalizeResponse(ExtractedContent, FailureReason) then
            Error(FailureReason);
    end;

    local procedure ValidateAndNormalizeResponse(var ExtractedContent: Text; var FailureReason: Text): Boolean
    var
        ContentToken: JsonToken;
        ResponseJson: JsonObject;
    begin
        if ExtractedContent = '' then begin
            FailureReason := ExtractionResponseEmptyErr;
            exit(false);
        end;

        if not ResponseJson.ReadFrom(ExtractedContent) then begin
            FailureReason := ExtractionResponseInvalidJsonErr;
            exit(false);
        end;

        if ResponseJson.Get('content', ContentToken) and ContentToken.IsValue() and not ContentToken.AsValue().IsNull() then begin
            ExtractedContent := ContentToken.AsValue().AsText();
            Clear(ResponseJson);
            if not ResponseJson.ReadFrom(ExtractedContent) then begin
                FailureReason := ExtractionResponseInvalidJsonErr;
                exit(false);
            end;
        end;

        if not HasExpectedSchema(ResponseJson) then begin
            FailureReason := ExtractionResponseInvalidSchemaErr;
            exit(false);
        end;

        ResponseJson.WriteTo(ExtractedContent);
        exit(true);
    end;

    local procedure IsCanonicalContent(Content: Text): Boolean
    var
        IsCanonical: Boolean;
    begin
        if not TryValidateCanonicalContent(Content, IsCanonical) then
            exit(false);
        exit(IsCanonical);
    end;

    [TryFunction]
    local procedure TryValidateCanonicalContent(Content: Text; var IsCanonical: Boolean)
    var
        ResponseJson: JsonObject;
    begin
        if Content = '' then
            exit;
        if not ResponseJson.ReadFrom(Content) then
            exit;
        IsCanonical := HasExpectedSchema(ResponseJson);
    end;

    local procedure HasExpectedSchema(ResponseJson: JsonObject): Boolean
    var
        SchemaToken: JsonToken;
    begin
        if not ResponseJson.Get('schema', SchemaToken) or not SchemaToken.IsValue() or SchemaToken.AsValue().IsNull() then
            exit(false);
        exit(SchemaToken.AsValue().AsText() = SchemaNameTok);
    end;

    local procedure GetTextContent(var AgentTaskMessageAttachment: Record "Agent Task Message Attachment"): Text
    var
        ContentInStream: InStream;
        Content: Text;
    begin
        AgentTaskMessageAttachment.CalcFields("Text Content");
        if not AgentTaskMessageAttachment."Text Content".HasValue() then
            exit('');
        AgentTaskMessageAttachment."Text Content".CreateInStream(ContentInStream, TextEncoding::UTF8);
        ContentInStream.Read(Content);
        exit(Content);
    end;

    local procedure ReplaceTextContent(var AgentTaskMessageAttachment: Record "Agent Task Message Attachment"; ExtractedContent: Text)
    var
        ContentOutStream: OutStream;
    begin
        Clear(AgentTaskMessageAttachment."Text Content");
        AgentTaskMessageAttachment."Text Content".CreateOutStream(ContentOutStream, TextEncoding::UTF8);
        ContentOutStream.WriteText(ExtractedContent);
        AgentTaskMessageAttachment.Modify(true);
    end;

    local procedure GetMaxTokens(): Integer
    begin
        exit(32768); // Maximum output tokens supported by GPT-4.1 mini.
    end;
}
