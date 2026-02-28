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
        FeatureNameLbl: Label 'E-Document MLLM Extraction', Locked = true;
        FileDataLbl: Label 'data:application/pdf;base64,%1', Locked = true;
        SystemPromptResourceTok: Label 'Prompts/EDocMLLMExtraction-SystemPrompt.md', Locked = true;
        UserPromptLbl: Label 'Extract invoice data into this UBL JSON structure: %1. \n\nExtract ONLY visible values. Return JSON only.', Locked = true;
        MLLMExtractionStartedMsg: Label 'MLLM extraction started.', Locked = true;
        MLLMExtractionSucceededMsg: Label 'MLLM extraction succeeded.', Locked = true;
        MLLMApiCallFailedMsg: Label 'MLLM API call failed, falling back to ADI.', Locked = true;
        MLLMEmptyResponseMsg: Label 'MLLM returned empty response, falling back to ADI.', Locked = true;
        MLLMJsonParseFailedMsg: Label 'MLLM response is not valid JSON, falling back to ADI.', Locked = true;
        MLLMSchemaValidationFailedMsg: Label 'MLLM response missing required fields (invoice_line), falling back to ADI.', Locked = true;
        ADIFallbackSucceededMsg: Label 'ADI fallback produced structured data.', Locked = true;
        ADIFallbackFailedMsg: Label 'ADI fallback returned empty result.', Locked = true;

    procedure StructureReceivedEDocument(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType
    var
        ResponseJson: JsonObject;
        CustomDimensions: Dictionary of [Text, Text];
        ResponseText: Text;
        DurationMs: Integer;
    begin
        Session.LogMessage('', MLLMExtractionStartedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', FeatureNameLbl);

        RegisterCopilotCapabilityIfNeeded();

        ResponseText := CallMLLM(EDocumentDataStorage, DurationMs);

        if not ValidateAndUnwrapResponse(ResponseText, ResponseJson, DurationMs) then
            exit(FallbackToADI(EDocumentDataStorage));

        StructuredData := ResponseText;
        FileFormat := "E-Doc. File Format"::JSON;
        ReadIntoDraftImpl := "E-Doc. Read into Draft"::MLLM;

        CustomDimensions.Add('Category', FeatureNameLbl);
        CustomDimensions.Add('DurationMs', Format(DurationMs));
        CustomDimensions.Add('LineCount', Format(GetInvoiceLineCount(ResponseJson)));
        Session.LogMessage('', MLLMExtractionSucceededMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);

        exit(this);
    end;

    local procedure CallMLLM(EDocumentDataStorage: Record "E-Doc. Data Storage"; var DurationMs: Integer): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIUserMessage: Codeunit "AOAI User Message";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIDeployments: Codeunit "AOAI Deployments";
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        FromTempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        Base64Data: Text;
        StartTime: DateTime;
    begin
        // Load schema and convert PDF to base64
        FromTempBlob := EDocumentDataStorage.GetTempBlob();
        FromTempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        Base64Data := Base64Convert.ToBase64(InStream);

        // Build AOAI call
        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT41MiniPreview());
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"E-Document MLLM Analysis");

        AOAIChatCompletionParams.SetTemperature(0);
        AOAIChatCompletionParams.SetJsonMode(true);

        AOAIChatMessages.SetPrimarySystemMessage(NavApp.GetResourceAsText(SystemPromptResourceTok, TextEncoding::UTF8));

        AOAIUserMessage.AddFilePart(StrSubstNo(FileDataLbl, Base64Data));
        AOAIUserMessage.AddTextPart(StrSubstNo(UserPromptLbl, EDocMLLMSchemaHelper.GetDefaultSchema()));
        AOAIChatMessages.AddUserMessage(AOAIUserMessage);

        StartTime := CurrentDateTime();
        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);
        DurationMs := CurrentDateTime() - StartTime;

        if not AOAIOperationResponse.IsSuccess() then begin
            Session.LogMessage('', MLLMApiCallFailedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', FeatureNameLbl, 'DurationMs', Format(DurationMs));
            exit('');
        end;

        exit(AOAIOperationResponse.GetResult());
    end;

    local procedure ValidateAndUnwrapResponse(var ResponseText: Text; var ResponseJson: JsonObject; DurationMs: Integer): Boolean
    var
        ContentToken: JsonToken;
    begin
        if ResponseText = '' then begin
            Session.LogMessage('', MLLMEmptyResponseMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', FeatureNameLbl, 'DurationMs', Format(DurationMs));
            exit(false);
        end;

        if not ResponseJson.ReadFrom(ResponseText) then begin
            Session.LogMessage('', MLLMJsonParseFailedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', FeatureNameLbl, 'DurationMs', Format(DurationMs));
            exit(false);
        end;

        // Unwrap 'content' wrapper if AOAI wrapped the response
        if ResponseJson.Get('content', ContentToken) then begin
            ResponseText := ContentToken.AsValue().AsText();
            if not ResponseJson.ReadFrom(ResponseText) then begin
                Session.LogMessage('', MLLMJsonParseFailedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', FeatureNameLbl, 'DurationMs', Format(DurationMs));
                exit(false);
            end;
        end;

        if not ValidateMLLMResponse(ResponseJson) then begin
            Session.LogMessage('', MLLMSchemaValidationFailedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', FeatureNameLbl, 'DurationMs', Format(DurationMs));
            exit(false);
        end;

        exit(true);
    end;

    local procedure FallbackToADI(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType
    var
        ADIHandler: Codeunit "E-Document ADI Handler";
        ADIResult: Interface IStructuredDataType;
    begin
        ADIResult := ADIHandler.StructureReceivedEDocument(EDocumentDataStorage);

        if ADIResult.GetContent() <> '' then
            Session.LogMessage('', ADIFallbackSucceededMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', FeatureNameLbl)
        else
            Session.LogMessage('', ADIFallbackFailedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', FeatureNameLbl);

        exit(ADIResult);
    end;

    local procedure ValidateMLLMResponse(ResponseJson: JsonObject): Boolean
    var
        LinesToken: JsonToken;
        LinesArray: JsonArray;
    begin
        if not ResponseJson.Get('invoice_line', LinesToken) then
            exit(false);
        if not LinesToken.IsArray() then
            exit(false);
        LinesArray := LinesToken.AsArray();
        exit(LinesArray.Count() >= 0);
    end;

    local procedure GetInvoiceLineCount(ResponseJson: JsonObject): Integer
    var
        LinesToken: JsonToken;
    begin
        if ResponseJson.Get('invoice_line', LinesToken) then
            if LinesToken.IsArray() then
                exit(LinesToken.AsArray().Count());
        exit(0);
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
    begin
        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"E-Document MLLM Analysis") then
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"E-Document MLLM Analysis", '');
    end;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", OnRegisterCopilotCapability, '', false, false)]
    local procedure HandleOnRegisterCopilotCapability()
    begin
        RegisterCopilotCapabilityIfNeeded();
    end;
}
