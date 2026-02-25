// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Format;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using System.AI;
using System.Environment;
using System.Text;
using System.Utilities;

codeunit 6231 "E-Document MLLM Handler" implements IStructureReceivedEDocument, IStructuredFormatReader, IStructuredDataType
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        StructuredData: Text;
        FileFormat: Enum "E-Doc. File Format";
        ReadIntoDraftImpl: Enum "E-Doc. Read into Draft";
        FileDataLbl: Label 'data:application/pdf;base64,%1', Locked = true;
        SystemPromptResourceTok: Label 'Prompts/EDocMLLMExtraction-SystemPrompt.md', Locked = true;
        UserPromptLbl: Label 'Extract invoice data into this UBL JSON structure: %1. \n\nExtract ONLY visible values. Return JSON only.', Locked = true;

    procedure StructureReceivedEDocument(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType
    var
        Base64Convert: Codeunit "Base64 Convert";
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        EDocMLLMExemplarMgmt: Codeunit "E-Doc. MLLM Exemplar Mgmt";
        FromTempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        Base64Data: Text;
        SchemaText: Text;
        ZeroShotResult: Text;
        OneShotResult: Text;
        VendorName: Text[250];
        ExemplarPdfBase64: Text;
        ExemplarJson: Text;
        ExemplarFound: Boolean;
    begin
        RegisterCopilotCapabilityIfNeeded();

        SchemaText := EDocMLLMSchemaHelper.GetDefaultSchema();

        // Convert PDF to base64
        FromTempBlob := EDocumentDataStorage.GetTempBlob();
        FromTempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        Base64Data := Base64Convert.ToBase64(InStream);

        // Phase 1: Zero-shot extraction
        ZeroShotResult := CallMLLMZeroShot(Base64Data, SchemaText);

        if ZeroShotResult = '' then begin
            SetBlankDraft();
            exit(this);
        end;

        // Phase 2: Try one-shot with vendor exemplar
        VendorName := EDocMLLMExemplarMgmt.ExtractVendorNameFromJson(ZeroShotResult);
        EDocMLLMExemplarMgmt.TryGetExemplar(VendorName, ExemplarFound, ExemplarPdfBase64, ExemplarJson);

        if ExemplarFound then begin
            OneShotResult := CallMLLMOneShot(Base64Data, SchemaText, ExemplarPdfBase64, ExemplarJson);
            if OneShotResult <> '' then
                StructuredData := OneShotResult
            else
                StructuredData := ZeroShotResult;
        end else
            StructuredData := ZeroShotResult;

        FileFormat := "E-Doc. File Format"::JSON;
        ReadIntoDraftImpl := "E-Doc. Read into Draft"::MLLM;

        exit(this);
    end;

    local procedure CallMLLMZeroShot(Base64Data: Text; SchemaText: Text): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIUserMessage: Codeunit "AOAI User Message";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIDeployments: Codeunit "AOAI Deployments";
        SystemPrompt: Text;
        ResultText: Text;
        JsonResponse: JsonObject;
    begin
        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT41MiniPreview());
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"E-Document Analysis");

        AOAIChatCompletionParams.SetTemperature(0);
        AOAIChatCompletionParams.SetJsonMode(true);

        SystemPrompt := NavApp.GetResourceAsText(SystemPromptResourceTok, TextEncoding::UTF8);
        AOAIChatMessages.SetPrimarySystemMessage(SystemPrompt);

        AOAIUserMessage.AddFilePart(StrSubstNo(FileDataLbl, Base64Data));
        AOAIUserMessage.AddTextPart(StrSubstNo(UserPromptLbl, SchemaText));
        AOAIChatMessages.AddUserMessage(AOAIUserMessage);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        if not AOAIOperationResponse.IsSuccess() then
            exit('');

        ResultText := AOAIOperationResponse.GetResult();
        if ResultText = '' then
            exit('');

        if JsonResponse.ReadFrom(ResultText) then
            ResultText := JsonResponse.GetText('content', true);

        exit(ResultText);
    end;

    local procedure CallMLLMOneShot(Base64Data: Text; SchemaText: Text; ExemplarPdfBase64: Text; ExemplarJson: Text): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIExemplarMessage: Codeunit "AOAI User Message";
        AOAICurrentMessage: Codeunit "AOAI User Message";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIDeployments: Codeunit "AOAI Deployments";
        SystemPrompt: Text;
        ExtractionPrompt: Text;
        ResultText: Text;
        JsonResponse: JsonObject;
    begin
        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT41MiniPreview());
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"E-Document Analysis");

        AOAIChatCompletionParams.SetTemperature(0);
        AOAIChatCompletionParams.SetJsonMode(true);

        SystemPrompt := NavApp.GetResourceAsText(SystemPromptResourceTok, TextEncoding::UTF8);
        AOAIChatMessages.SetPrimarySystemMessage(SystemPrompt);

        ExtractionPrompt := StrSubstNo(UserPromptLbl, SchemaText);

        // User message 1: exemplar PDF + extraction prompt
        AOAIExemplarMessage.AddFilePart(StrSubstNo(FileDataLbl, ExemplarPdfBase64));
        AOAIExemplarMessage.AddTextPart(ExtractionPrompt);
        AOAIChatMessages.AddUserMessage(AOAIExemplarMessage);

        // Assistant message: corrected JSON (the exemplar answer)
        AOAIChatMessages.AddAssistantMessage(ExemplarJson);

        // User message 2: current PDF + extraction prompt
        AOAICurrentMessage.AddFilePart(StrSubstNo(FileDataLbl, Base64Data));
        AOAICurrentMessage.AddTextPart(ExtractionPrompt);
        AOAIChatMessages.AddUserMessage(AOAICurrentMessage);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        if not AOAIOperationResponse.IsSuccess() then
            exit('');

        ResultText := AOAIOperationResponse.GetResult();
        if ResultText = '' then
            exit('');

        if JsonResponse.ReadFrom(ResultText) then
            ResultText := JsonResponse.GetText('content', true);

        exit(ResultText);
    end;

    local procedure SetBlankDraft()
    begin
        FileFormat := "E-Doc. File Format"::Unspecified;
        ReadIntoDraftImpl := "E-Doc. Read into Draft"::"Blank Draft";
    end;

    procedure GetFileFormat(): Enum "E-Doc. File Format"
    begin
        exit(this.FileFormat);
    end;

    procedure GetContent(): Text
    begin
        exit(this.StructuredData);
    end;

    procedure GetReadIntoDraftImpl(): Enum "E-Doc. Read into Draft"
    begin
        exit(this.ReadIntoDraftImpl);
    end;

    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        TempEDocPurchaseHeader: Record "E-Document Purchase Header" temporary;
        TempEDocPurchaseLine: Record "E-Document Purchase Line" temporary;
        EDocPurchaseDraftWriter: Codeunit "E-Doc. Purchase Draft Writer";
    begin
        ReadIntoBuffer(EDocument, TempBlob, TempEDocPurchaseHeader, TempEDocPurchaseLine);
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempEDocPurchaseHeader, TempEDocPurchaseLine);
        exit(Enum::"E-Doc. Process Draft"::"Purchase Document");
    end;

    local procedure ReadIntoBuffer(
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        var TempEDocPurchaseHeader: Record "E-Document Purchase Header" temporary;
        var TempEDocPurchaseLine: Record "E-Document Purchase Line" temporary)
    var
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        InStream: InStream;
        SourceJsonObject: JsonObject;
        LinesToken: JsonToken;
        LinesArray: JsonArray;
        BlobAsText: Text;
    begin
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(BlobAsText);
        SourceJsonObject.ReadFrom(BlobAsText);

        EDocMLLMSchemaHelper.MapHeaderFromJson(SourceJsonObject, TempEDocPurchaseHeader);
        TempEDocPurchaseHeader."E-Document Entry No." := EDocument."Entry No";

        if SourceJsonObject.Get('invoice_line', LinesToken) then
            if LinesToken.IsArray() then begin
                LinesArray := LinesToken.AsArray();
                EDocMLLMSchemaHelper.MapLinesFromJson(LinesArray, EDocument."Entry No", TempEDocPurchaseLine);
            end;
    end;

    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    var
        TempEDocPurchaseHeader: Record "E-Document Purchase Header" temporary;
        TempEDocPurchaseLine: Record "E-Document Purchase Line" temporary;
        EDocReadablePurchaseDoc: Page "E-Doc. Readable Purchase Doc.";
    begin
        ReadIntoBuffer(EDocument, TempBlob, TempEDocPurchaseHeader, TempEDocPurchaseLine);
        EDocReadablePurchaseDoc.SetBuffer(TempEDocPurchaseHeader, TempEDocPurchaseLine);
        EDocReadablePurchaseDoc.Run();
    end;

    local procedure RegisterCopilotCapabilityIfNeeded()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;

        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"E-Document Analysis") then
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"E-Document Analysis", '');
    end;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", OnRegisterCopilotCapability, '', false, false)]
    local procedure HandleOnRegisterCopilotCapability()
    begin
        RegisterCopilotCapabilityIfNeeded();
    end;
}
