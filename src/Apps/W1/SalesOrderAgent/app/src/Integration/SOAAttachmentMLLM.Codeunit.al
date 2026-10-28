// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.SalesOrderAgent;

using System.Agents;
using System.AI;
using System.Azure.KeyVault;
using System.Text;

codeunit 4421 "SOA Attachment MLLM"
{
    Access = Internal;
    Permissions = tabledata "Agent Task File" = r, tabledata "Agent Task Message Attachment" = rM;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ExtractionSystemPromptTok: Label 'Prompts/AttachmentExtraction/soa-attachment-extraction-system.md', Locked = true;
        ExtractionUserPromptTok: Label 'Prompts/AttachmentExtraction/soa-attachment-extraction-user.md', Locked = true;
        ExtractionSchemaTok: Label 'Prompts/AttachmentExtraction/soa-attachment-extraction-example.json', Locked = true;
        SecurityPromptTok: Label 'SalesOrderAgent-Irrelevance-SecurityPromptV28', Locked = true;
        SchemaNameTok: Label 'soa-attachment-content', Locked = true;
        SchemaPlaceholderTok: Label '%1', Locked = true;
        ProvenanceTok: Label 'soa_source_file_id', Locked = true;
        FileDataTok: Label 'data:%1;base64,%2', Comment = '%1 = MIME type, %2 = base64 file content', Locked = true;
        AttachmentFileNotFoundErr: Label 'The attachment file could not be found.', Locked = true;
        AttachmentFileEmptyErr: Label 'The attachment file is empty.', Locked = true;
        AttachmentMimeTypeMissingErr: Label 'The attachment MIME type is missing.', Locked = true;
        ExtractionPromptNotFoundErr: Label 'The attachment extraction prompt could not be loaded.', Locked = true;
        ExtractionSecurityPromptNotFoundErr: Label 'The attachment extraction security prompt could not be retrieved from Azure Key Vault.', Locked = true;
        ExtractionCallFailedErr: Label 'The attachment extraction AI call failed. Status: %1', Comment = '%1 = status code', Locked = true;
        ExtractionUnexpectedErr: Label 'The attachment extraction failed with an unexpected error.', Locked = true;
        ExtractionResponseEmptyErr: Label 'The attachment extraction AI response is empty.', Locked = true;
        ExtractionResponseInvalidJsonErr: Label 'The attachment extraction AI response is not valid JSON.', Locked = true;
        ExtractionResponseInvalidSchemaErr: Label 'The attachment extraction AI response does not contain the supported schema.', Locked = true;

    internal procedure EnsureCanonicalTextContent(var AgentTaskMessageAttachment: Record "Agent Task Message Attachment"; var CanonicalContent: Text; var FailureReason: Text): Boolean
    var
        ExistingContent: Text;
    begin
        Clear(CanonicalContent);
        Clear(FailureReason);
        ExistingContent := GetTextContent(AgentTaskMessageAttachment);

        // The extraction model rejects image attachments, so the call is skipped for them and the
        // text content stored with the attachment is used as-is. Relevance is still evaluated on that content.
        // This is a temporary measure until the extraction model can handle image attachments.
        if IsImageAttachment(AgentTaskMessageAttachment) then begin
            CanonicalContent := ExistingContent;
            exit(true);
        end;

        // Only content this codeunit produced for this exact attachment record is trusted. The system ID is assigned
        // by the platform after the attachment is stored, so a crafted attachment cannot embed a matching marker
        // in advance to skip the guarded extraction.
        if IsCanonicalContent(ExistingContent, AgentTaskMessageAttachment.SystemId) then begin
            CanonicalContent := ExistingContent;
            exit(true);
        end;

        if not TryExtractAttachmentContent(AgentTaskMessageAttachment, CanonicalContent, FailureReason) then begin
            // Never propagate raw runtime error text. It can contain attachment or record data, and the reason is written to telemetry.
            if FailureReason = '' then
                FailureReason := ExtractionUnexpectedErr;
            exit(false);
        end;

        StampProvenance(CanonicalContent, AgentTaskMessageAttachment.SystemId);
        ReplaceTextContent(AgentTaskMessageAttachment, CanonicalContent);
        exit(true);
    end;

    local procedure IsImageAttachment(var AgentTaskMessageAttachment: Record "Agent Task Message Attachment"): Boolean
    var
        AgentTaskFile: Record "Agent Task File";
        SOASetup: Codeunit "SOA Setup";
    begin
        if not AgentTaskFile.Get(AgentTaskMessageAttachment."Task ID", AgentTaskMessageAttachment."File ID") then
            exit(false);

        exit(SOASetup.IsImageAttachmentContentType(AgentTaskFile."File MIME Type"));
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
        Prompt: SecretText;
        SecurityPrompt: SecretText;
        FileData: Text;
        PromptTemplate: Text;
        SchemaTemplate: Text;
        UserPromptTemplate: Text;
    begin
        // Set FailureReason before each Error so the caught failure keeps a specific, sanitized reason for telemetry.
        if not AgentTaskFile.Get(AgentTaskMessageAttachment."Task ID", AgentTaskMessageAttachment."File ID") then begin
            FailureReason := AttachmentFileNotFoundErr;
            Error(AttachmentFileNotFoundErr);
        end;

        AgentTaskFile.CalcFields(Content);
        if not AgentTaskFile.Content.HasValue() then begin
            FailureReason := AttachmentFileEmptyErr;
            Error(AttachmentFileEmptyErr);
        end;
        if AgentTaskFile."File MIME Type" = '' then begin
            FailureReason := AttachmentMimeTypeMissingErr;
            Error(AttachmentMimeTypeMissingErr);
        end;

        AgentTaskFile.Content.CreateInStream(FileInStream);
        FileData := StrSubstNo(FileDataTok, AgentTaskFile."File MIME Type", Base64Convert.ToBase64(FileInStream));

        PromptTemplate := NavApp.GetResourceAsText(ExtractionSystemPromptTok, TextEncoding::UTF8);
        UserPromptTemplate := NavApp.GetResourceAsText(ExtractionUserPromptTok, TextEncoding::UTF8);
        SchemaTemplate := NavApp.GetResourceAsText(ExtractionSchemaTok, TextEncoding::UTF8);
        if (PromptTemplate = '') or (UserPromptTemplate = '') or (SchemaTemplate = '') then begin
            FailureReason := ExtractionPromptNotFoundErr;
            Error(ExtractionPromptNotFoundErr);
        end;
        if not AzureKeyVault.GetAzureKeyVaultSecret(SecurityPromptTok, SecurityPrompt) then begin
            FailureReason := ExtractionSecurityPromptNotFoundErr;
            Error(ExtractionSecurityPromptNotFoundErr);
        end;
        Prompt := SecretText.SecretStrSubstNo(PromptTemplate, SecurityPrompt);

        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT55ChatPreview());
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Sales Order Agent");

        AOAIChatCompletionParams.SetTemperature(0);
        AOAIChatCompletionParams.SetMaxTokens(GetMaxTokens());
        AOAIChatCompletionParams.SetJsonMode(true);

        AOAIChatMessages.SetPrimarySystemMessage(Prompt);

        AOAIUserMessage.AddFilePart(FileData);
        // The attachment file name is sender-controlled, so it is never placed in the prompt.
        // The template comes from a resource, so the schema is substituted with Replace rather than StrSubstNo.
        AOAIUserMessage.AddTextPart(UserPromptTemplate.Replace(SchemaPlaceholderTok, SchemaTemplate));
        AOAIChatMessages.AddUserMessage(AOAIUserMessage);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);
        if not AOAIOperationResponse.IsSuccess() then begin
            FailureReason := StrSubstNo(ExtractionCallFailedErr, AOAIOperationResponse.GetStatusCode());
            Error(ExtractionCallFailedErr, AOAIOperationResponse.GetStatusCode());
        end;

        ExtractedContent := AOAIOperationResponse.GetResult();
        ValidateAndNormalizeResponse(ExtractedContent, FailureReason);
    end;

    local procedure ValidateAndNormalizeResponse(var ExtractedContent: Text; var FailureReason: Text)
    var
        ContentToken: JsonToken;
        ResponseJson: JsonObject;
    begin
        if ExtractedContent = '' then begin
            FailureReason := ExtractionResponseEmptyErr;
            Error(ExtractionResponseEmptyErr);
        end;

        if not ResponseJson.ReadFrom(ExtractedContent) then begin
            FailureReason := ExtractionResponseInvalidJsonErr;
            Error(ExtractionResponseInvalidJsonErr);
        end;

        if ResponseJson.Get('content', ContentToken) and ContentToken.IsValue() and not ContentToken.AsValue().IsNull() then begin
            ExtractedContent := ContentToken.AsValue().AsText();
            Clear(ResponseJson);
            if not ResponseJson.ReadFrom(ExtractedContent) then begin
                FailureReason := ExtractionResponseInvalidJsonErr;
                Error(ExtractionResponseInvalidJsonErr);
            end;
        end;

        if not HasExpectedSchema(ResponseJson) then begin
            FailureReason := ExtractionResponseInvalidSchemaErr;
            Error(ExtractionResponseInvalidSchemaErr);
        end;

        ResponseJson.WriteTo(ExtractedContent);
    end;

    local procedure IsCanonicalContent(Content: Text; AttachmentSystemId: Guid): Boolean
    var
        IsCanonical: Boolean;
    begin
        if not TryValidateCanonicalContent(Content, AttachmentSystemId, IsCanonical) then
            exit(false);
        exit(IsCanonical);
    end;

    [TryFunction]
    local procedure TryValidateCanonicalContent(Content: Text; AttachmentSystemId: Guid; var IsCanonical: Boolean)
    var
        ResponseJson: JsonObject;
    begin
        if Content = '' then
            exit;
        if not ResponseJson.ReadFrom(Content) then
            exit;
        if not HasExpectedSchema(ResponseJson) then
            exit;
        IsCanonical := HasMatchingProvenance(ResponseJson, AttachmentSystemId);
    end;

    local procedure HasMatchingProvenance(ResponseJson: JsonObject; AttachmentSystemId: Guid): Boolean
    var
        ProvenanceToken: JsonToken;
    begin
        if not ResponseJson.Get(ProvenanceTok, ProvenanceToken) or not ProvenanceToken.IsValue() or ProvenanceToken.AsValue().IsNull() then
            exit(false);
        exit(ProvenanceToken.AsValue().AsText() = Format(AttachmentSystemId));
    end;

    // Binds the extraction to the attachment record it came from so stored content cannot be impersonated by attachment text.
    local procedure StampProvenance(var Content: Text; AttachmentSystemId: Guid)
    var
        ResponseJson: JsonObject;
    begin
        if not ResponseJson.ReadFrom(Content) then
            exit;
        if ResponseJson.Contains(ProvenanceTok) then
            ResponseJson.Remove(ProvenanceTok);
        ResponseJson.Add(ProvenanceTok, Format(AttachmentSystemId));
        ResponseJson.WriteTo(Content);
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
        exit(50000); // Well within the output token limit of GPT-5.5.
    end;
}
