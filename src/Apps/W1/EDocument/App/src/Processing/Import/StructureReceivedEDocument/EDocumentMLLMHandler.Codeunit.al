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

codeunit 6202 "E-Document MLLM Handler" implements IStructureReceivedEDocument, IStructuredFormatReader, IStructuredDataType
{
    Access = Internal;

    var
        StructuredData: Text;
        FileFormat: Enum "E-Doc. File Format";
        ReadIntoDraftImpl: Enum "E-Doc. Read into Draft";
        FileDataLbl: Label 'data:application/pdf;base64,%1', Locked = true;
        SystemPromptResourceTok: Label 'Prompts/EDocMLLMExtraction-SystemPrompt.md', Locked = true;
        UserPromptLbl: Label 'Extract the invoice data per this JSON schema:\n%1', Locked = true;

    procedure StructureReceivedEDocument(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType
    var
        EDocMLLMExtractionSchema: Record "E-Doc. MLLM Extraction Schema";
        EDocument: Record "E-Document";
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
        SchemaText: Text;
        SystemPrompt: Text;
    begin
        RegisterCopilotCapabilityIfNeeded();

        // Load schema for the E-Document's service code, or fall back to default
        SchemaText := EDocMLLMSchemaHelper.GetDefaultSchema();
        EDocument.SetRange("Unstructured Data Entry No.", EDocumentDataStorage."Entry No.");
        if EDocument.FindFirst() then
            if EDocMLLMExtractionSchema.Get(EDocument.Service) then begin
                EDocMLLMExtractionSchema.CalcFields(Schema);
                if EDocMLLMExtractionSchema.Schema.HasValue() then begin
                    SchemaText := EDocMLLMExtractionSchema.GetSchemaText();
                    if SchemaText = '' then
                        SchemaText := EDocMLLMSchemaHelper.GetDefaultSchema();
                end;
            end;

        // Convert PDF to base64
        FromTempBlob := EDocumentDataStorage.GetTempBlob();
        FromTempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        Base64Data := Base64Convert.ToBase64(InStream);

        // Build AOAI call
        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT41MiniPreview());
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"E-Document MLLM Extraction");

        AOAIChatCompletionParams.SetMaxTokens(16000);
        AOAIChatCompletionParams.SetTemperature(0);
        AOAIChatCompletionParams.SetJsonMode(true);

        SystemPrompt := NavApp.GetResourceAsText(SystemPromptResourceTok, TextEncoding::UTF8);
        AOAIChatMessages.SetPrimarySystemMessage(SystemPrompt);

        AOAIUserMessage.AddFilePart(StrSubstNo(FileDataLbl, Base64Data));
        AOAIUserMessage.AddTextPart(StrSubstNo(UserPromptLbl, SchemaText));
        AOAIChatMessages.AddUserMessage(AOAIUserMessage);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        if AOAIOperationResponse.IsSuccess() then begin
            StructuredData := AOAIOperationResponse.GetResult();
            if StructuredData <> '' then begin
                FileFormat := "E-Doc. File Format"::JSON;
                ReadIntoDraftImpl := "E-Doc. Read into Draft"::MLLM;
            end else begin
                FileFormat := "E-Doc. File Format"::Unspecified;
                ReadIntoDraftImpl := "E-Doc. Read into Draft"::"Blank Draft";
            end;
        end else begin
            FileFormat := "E-Doc. File Format"::Unspecified;
            ReadIntoDraftImpl := "E-Doc. Read into Draft"::"Blank Draft";
        end;

        exit(this);
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
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        // Clean up old data
        EDocumentPurchaseHeader.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocumentPurchaseHeader.DeleteAll();
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocumentPurchaseLine.DeleteAll();

        ReadIntoBuffer(EDocument, TempBlob, TempEDocPurchaseHeader, TempEDocPurchaseLine);
        EDocumentPurchaseHeader := TempEDocPurchaseHeader;
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader.Insert();
        OnInsertedEDocumentPurchaseHeader(EDocument, EDocumentPurchaseHeader);

        if TempEDocPurchaseLine.FindSet() then begin
            repeat
                EDocumentPurchaseLine := TempEDocPurchaseLine;
                EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
                EDocumentPurchaseLine."Line No." := EDocumentPurchaseLine.GetNextLineNo(EDocument."Entry No");
                EDocumentPurchaseLine.Insert();
            until TempEDocPurchaseLine.Next() = 0;

            OnInsertedEDocumentPurchaseLines(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine);
        end;

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

        if SourceJsonObject.Get('invoiceLines', LinesToken) then
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

        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"E-Document MLLM Extraction") then
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"E-Document MLLM Extraction", '');
    end;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", OnRegisterCopilotCapability, '', false, false)]
    local procedure HandleOnRegisterCopilotCapability()
    begin
        RegisterCopilotCapabilityIfNeeded();
    end;

    [InternalEvent(false, false)]
    local procedure OnInsertedEDocumentPurchaseHeader(EDocument: Record "E-Document"; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnInsertedEDocumentPurchaseLines(EDocument: Record "E-Document"; EDocumentPurchaseHeader: Record "E-Document Purchase Header"; EDocumentPurchaseLine: Record "E-Document Purchase Line")
    begin
    end;
}
