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
using System.Telemetry;
using System.Text;
using System.Utilities;

codeunit 6231 "E-Document MLLM Handler" implements IStructureReceivedEDocument, IStructuredFormatReader, IStructuredDataType
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Telemetry: Codeunit Telemetry;
        StructuredData: Text;
        FileFormat: Enum "E-Doc. File Format";
        FeatureNameLbl: Label 'E-Document MLLM Extraction', Locked = true;
        FileDataLbl: Label 'data:application/pdf;base64,%1', Locked = true;
        SystemPromptResourceTok: Label 'Prompts/EDocMLLMExtraction-SystemPrompt.md', Locked = true;
        UserPromptLbl: Label 'Extract invoice data into this UBL JSON structure: %1. \n\nExtract ONLY visible values. Return JSON only.', Locked = true;
        MLLMExtractionStartedMsg: Label 'MLLM extraction started.', Locked = true;
        MLLMExtractionSucceededMsg: Label 'MLLM extraction succeeded.', Locked = true;
        MLLMApiCallSucceededMsg: Label 'MLLM API call succeeded.', Locked = true;
        MLLMApiCallFailedMsg: Label 'MLLM API call failed, falling back to ADI.', Locked = true;
        MLLMEmptyResponseMsg: Label 'MLLM returned empty response, falling back to ADI.', Locked = true;
        MLLMJsonParseFailedMsg: Label 'MLLM response is not valid JSON, falling back to ADI.', Locked = true;
        MLLMSchemaValidationFailedMsg: Label 'MLLM response missing required vendor fields (name or address), falling back to ADI.', Locked = true;
        ADIFallbackSucceededMsg: Label 'ADI fallback produced structured data.', Locked = true;
        ADIFallbackFailedMsg: Label 'ADI fallback returned empty result.', Locked = true;

    procedure StructureReceivedEDocument(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType
    var
        ResponseJson: JsonObject;
        CustomDimensions: Dictionary of [Text, Text];
        ResponseText: Text;
    begin
        Telemetry.LogMessage('0000SGQ', MLLMExtractionStartedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, GetCustomDimensions());

        RegisterCopilotCapabilityIfNeeded();

        ResponseText := CallMLLM(EDocumentDataStorage);

        if not ValidateAndUnwrapResponse(ResponseText, ResponseJson) then
            exit(FallbackToADI(EDocumentDataStorage));

        StructuredData := ResponseText;
        FileFormat := "E-Doc. File Format"::JSON;

        CustomDimensions := GetCustomDimensions();
        CustomDimensions.Add('LineCount', Format(GetInvoiceLineCount(ResponseJson)));
        Telemetry.LogMessage('0000SGR', MLLMExtractionSucceededMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);

        exit(this);
    end;

    local procedure CallMLLM(EDocumentDataStorage: Record "E-Doc. Data Storage"): Text
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
        CustomDimensions: Dictionary of [Text, Text];
        InStream: InStream;
        Base64Data: Text;
        StartTime: DateTime;
        DurationMs: Integer;
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

        CustomDimensions := GetCustomDimensions();
        CustomDimensions.Add('DurationMs', Format(DurationMs));

        if not AOAIOperationResponse.IsSuccess() then begin
            Telemetry.LogMessage('0000SGS', MLLMApiCallFailedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
            exit('');
        end;

        Telemetry.LogMessage('0000SGT', MLLMApiCallSucceededMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
        exit(AOAIOperationResponse.GetResult());
    end;

    local procedure ValidateAndUnwrapResponse(var ResponseText: Text; var ResponseJson: JsonObject): Boolean
    var
        ContentToken: JsonToken;
    begin
        if ResponseText = '' then begin
            Telemetry.LogMessage('0000SGU', MLLMEmptyResponseMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, GetCustomDimensions());
            exit(false);
        end;

        if not ResponseJson.ReadFrom(ResponseText) then begin
            Telemetry.LogMessage('0000SGV', MLLMJsonParseFailedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, GetCustomDimensions());
            exit(false);
        end;

        // Unwrap 'content' wrapper if AOAI wrapped the response
        if ResponseJson.Get('content', ContentToken) then begin
            ResponseText := ContentToken.AsValue().AsText();
            if not ResponseJson.ReadFrom(ResponseText) then begin
                Telemetry.LogMessage('0000SGW', MLLMJsonParseFailedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, GetCustomDimensions());
                exit(false);
            end;
        end;

        if not ValidateMLLMResponse(ResponseJson) then begin
            Telemetry.LogMessage('0000SGX', MLLMSchemaValidationFailedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, GetCustomDimensions());
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
            Telemetry.LogMessage('0000SGY', ADIFallbackSucceededMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, GetCustomDimensions())
        else
            Telemetry.LogMessage('0000SGZ', ADIFallbackFailedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, GetCustomDimensions());

        exit(ADIResult);
    end;

    local procedure ValidateMLLMResponse(ResponseJson: JsonObject): Boolean
    var
        SupplierToken: JsonToken;
        PartyToken: JsonToken;
        NameToken: JsonToken;
        AddressToken: JsonToken;
        SupplierObj: JsonObject;
        PartyObj: JsonObject;
        NameObj: JsonObject;
        VendorName: Text;
    begin
        if not ResponseJson.Get('accounting_supplier_party', SupplierToken) then
            exit(false);
        if not SupplierToken.IsObject() then
            exit(false);
        SupplierObj := SupplierToken.AsObject();

        if not SupplierObj.Get('party', PartyToken) then
            exit(false);
        if not PartyToken.IsObject() then
            exit(false);
        PartyObj := PartyToken.AsObject();

        if not PartyObj.Get('party_name', NameToken) then
            exit(false);
        if not NameToken.IsObject() then
            exit(false);
        NameObj := NameToken.AsObject();

        if not NameObj.Get('name', NameToken) then
            exit(false);
        VendorName := NameToken.AsValue().AsText();
        if VendorName = '' then
            exit(false);

        if not PartyObj.Get('postal_address', AddressToken) then
            exit(false);
        if not AddressToken.IsObject() then
            exit(false);

        exit(true);
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
        exit("E-Doc. Read into Draft"::MLLM);
    end;

    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        TempEDocPurchaseHeader: Record "E-Document Purchase Header" temporary;
        TempEDocPurchaseLine: Record "E-Document Purchase Line" temporary;
        EDocPurchaseDraftUtility: Codeunit "E-Doc. Purchase Draft Utility";
    begin
        ReadIntoBuffer(EDocument, TempBlob, TempEDocPurchaseHeader, TempEDocPurchaseLine);
        EDocPurchaseDraftUtility.PersistDraft(EDocument, TempEDocPurchaseHeader, TempEDocPurchaseLine);
        exit(Enum::"E-Doc. Process Draft"::"Purchase Invoice");
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

    local procedure GetCustomDimensions(): Dictionary of [Text, Text]
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Add('Category', FeatureNameLbl);
        exit(CustomDimensions);
    end;

    procedure RegisterCopilotCapabilityIfNeeded()
    var
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"E-Document MLLM Analysis") then
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"E-Document MLLM Analysis", '');
    end;
}
