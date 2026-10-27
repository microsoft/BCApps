// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.AI;
using System.Text;
using System.Utilities;

codeunit 3336 "PA PDF Text Extraction"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        SystemPromptResourceTok: Label 'Prompts/PayablesAgent-PdfTextExtraction-SystemPrompt-V2.md', Locked = true;
        PdfFileDataTok: Label 'data:application/pdf;base64,%1', Comment = '%1 = base64 file content', Locked = true;
        UserPromptTxt: Label 'Extract all text from the attached PDF document.', Locked = true;
        ExtractionFailedErr: Label 'The text could not be extracted from the file.';

    procedure ExtractText(var Task: Codeunit "Payables Agent Task")
    var
        ExtractedText: Text;
    begin
        if not Task.CanExtractText() then
            Error(ExtractionFailedErr);
        ExtractedText := GenerateText(Task);
        // The entity reloads and patches only extracted text after the potentially slow model call.
        Task.SetSourceText(ExtractedText);
    end;

    local procedure GenerateText(Task: Codeunit "Payables Agent Task") ExtractedText: Text
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIDeployments: Codeunit "AOAI Deployments";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIUserMessage: Codeunit "AOAI User Message";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        PdfInStream: InStream;
        FileName: Text;
    begin
        if not Task.GetSourcePdf(TempBlob, FileName) then
            Error(ExtractionFailedErr);
        TempBlob.CreateInStream(PdfInStream);

        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT41MiniPreview());
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Payables Agent");

        AOAIChatCompletionParams.SetTemperature(0);

        AOAIChatMessages.SetPrimarySystemMessage(GetSystemPrompt());
        AOAIUserMessage.AddFilePart(StrSubstNo(PdfFileDataTok, Base64Convert.ToBase64(PdfInStream)));
        AOAIUserMessage.AddTextPart(UserPromptTxt);
        AOAIChatMessages.AddUserMessage(AOAIUserMessage);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);
        if not AOAIOperationResponse.IsSuccess() then
            Error(ExtractionFailedErr);
        if AOAIChatMessages.GetLastRole() <> Enum::"AOAI Chat Roles"::Assistant then
            Error(ExtractionFailedErr);

        ExtractedText := AOAIChatMessages.GetLastMessage();
        if ExtractedText = '' then
            Error(ExtractionFailedErr);
    end;

    local procedure GetSystemPrompt() SystemPrompt: Text
    begin
        // The base-block extraction deliberately uses only bundled instructions, without a separate security prompt.
        SystemPrompt := NavApp.GetResourceAsText(SystemPromptResourceTok, TextEncoding::UTF8);
        if SystemPrompt = '' then
            Error(ExtractionFailedErr);
    end;
}
