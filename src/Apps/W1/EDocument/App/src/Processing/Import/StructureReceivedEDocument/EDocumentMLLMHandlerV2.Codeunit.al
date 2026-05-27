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
using System.Azure.KeyVault;
using System.Text;
using System.Utilities;

codeunit 6318 "E-Document MLLM Handler V2" implements IStructureReceivedEDocument, IStructuredFormatReader, IStructuredDataType
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        StructuredData: Text;
        FileFormat: Enum "E-Doc. File Format";
        FileDataLbl: Label 'data:application/pdf;base64,%1', Locked = true;
        SystemPromptV2ResourceTok: Label 'Prompts/EDocMLLMExtractionV2-SystemPrompt.md', Locked = true;
        UserPromptLbl: Label 'Extract invoice data into this UBL JSON structure: %1. \n\nExtract ONLY visible values. Return JSON only. %2', Locked = true;
        SecurityPromptAKVKeyTok: Label 'EDocMLLMExtraction-SecurityPromptV281', Locked = true;
        MaxToolCallsTok: Integer;
        BudgetExhaustedErr: Label 'The document could not be verified after %1 tool calls. The extraction was inconsistent.', Comment = '%1 = tool call count';
        DocumentNotProcessedErr: Label 'The document could not be processed.';
        InappropriateContentErr: Label 'The document could not be processed because it contains inappropriate content.';

    procedure StructureReceivedEDocument(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType
    var
        ResponseJson: JsonObject;
        ResponseText: Text;
    begin
        MaxToolCallsTok := 200;

        RegisterCopilotCapabilityIfNeeded();

        ResponseText := CallMLLMV2(EDocumentDataStorage);

        if IsInappropriateContentResponse(ResponseText) then
            Error(InappropriateContentErr);

        if not ValidateAndUnwrapResponse(ResponseText, ResponseJson) then
            exit(FallbackToADI(EDocumentDataStorage));

        StructuredData := ResponseText;
        FileFormat := "E-Doc. File Format"::JSON;
        exit(this);
    end;

    local procedure CallMLLMV2(EDocumentDataStorage: Record "E-Doc. Data Storage"): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIUserMessage: Codeunit "AOAI User Message";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIDeployments: Codeunit "AOAI Deployments";
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        VerifyLineMathTool: Codeunit "E-Doc. MLLM VL Math Tool";
        VerifyTotalsTool: Codeunit "E-Doc. MLLM VL Totals Tool";
        VerifyVATTool: Codeunit "E-Doc. MLLM VL VAT Tool";
        VerifyDatesTool: Codeunit "E-Doc. MLLM VL Dates Tool";
        VerifyRequiredTool: Codeunit "E-Doc. MLLM VL Required Tool";
        VerifyRangesTool: Codeunit "E-Doc. MLLM VL Ranges Tool";
        FromTempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        Base64Data: Text;
        ToolCallCount: Integer;
    begin
        // Load PDF as base64
        FromTempBlob := EDocumentDataStorage.GetTempBlob();
        FromTempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        Base64Data := Base64Convert.ToBase64(InStream);

        // Configure AOAI
        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT41MiniPreview());
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"E-Document MLLM Analysis");
        AOAIChatCompletionParams.SetTemperature(0);
        // Do NOT set JSON mode — tool-calling and JSON mode cannot be combined.
        // The system prompt instructs the model to output UBL JSON as its final response.

        // System prompt
        AOAIChatMessages.SetPrimarySystemMessage(NavApp.GetResourceAsText(SystemPromptV2ResourceTok, TextEncoding::UTF8));

        // Register 6 verification tools
        AOAIChatMessages.AddTool(VerifyLineMathTool);
        AOAIChatMessages.AddTool(VerifyTotalsTool);
        AOAIChatMessages.AddTool(VerifyVATTool);
        AOAIChatMessages.AddTool(VerifyDatesTool);
        AOAIChatMessages.AddTool(VerifyRequiredTool);
        AOAIChatMessages.AddTool(VerifyRangesTool);
        AOAIChatMessages.SetToolChoice('auto');

        // User message: PDF + UBL schema + security clause
        AOAIUserMessage.AddFilePart(StrSubstNo(FileDataLbl, Base64Data));
        AOAIUserMessage.AddTextPart(GetUserPromptText(EDocMLLMSchemaHelper.GetDefaultSchema()));
        AOAIChatMessages.AddUserMessage(AOAIUserMessage);

        // Agentic dispatch loop
        repeat
            AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

            if not AOAIOperationResponse.IsSuccess() then
                exit('');

            if AOAIOperationResponse.IsFunctionCall() then begin
                ToolCallCount += AOAIOperationResponse.GetFunctionResponses().Count();
                if ToolCallCount > MaxToolCallsTok then
                    Error(BudgetExhaustedErr, ToolCallCount);
                // Tool results are already appended to AOAIChatMessages by GenerateChatCompletion
                // internally (ProcessChatCompletionResponse calls AppendFunctionResponsesToChatMessages
                // for "Invoke Tools Only" preference). We just loop to get the next model response.
            end;
        until not AOAIOperationResponse.IsFunctionCall();

        exit(AOAIOperationResponse.GetResult());
    end;

    [NonDebuggable]
    local procedure GetUserPromptText(Schema: Text): Text
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        SecurityClause: SecretText;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(SecurityPromptAKVKeyTok, SecurityClause) then
            Error(DocumentNotProcessedErr);
        exit(SecretText.SecretStrSubstNo(UserPromptLbl, Schema, SecurityClause).Unwrap());
    end;

    local procedure IsInappropriateContentResponse(ResponseText: Text): Boolean
    var
        ResponseJson: JsonObject;
        ContentToken: JsonToken;
        ErrorToken: JsonToken;
        InnerText: Text;
    begin
        if ResponseText = '' then
            exit(false);
        if not ResponseJson.ReadFrom(ResponseText) then
            exit(false);
        if ResponseJson.Get('content', ContentToken) and ContentToken.IsValue() then begin
            InnerText := ContentToken.AsValue().AsText();
            Clear(ResponseJson);
            if not ResponseJson.ReadFrom(InnerText) then
                exit(false);
        end;
        exit(ResponseJson.Get('error', ErrorToken));
    end;

    local procedure ValidateAndUnwrapResponse(var ResponseText: Text; var ResponseJson: JsonObject): Boolean
    var
        ContentToken: JsonToken;
    begin
        if ResponseText = '' then
            exit(false);
        if not ResponseJson.ReadFrom(ResponseText) then
            exit(false);
        if ResponseJson.Get('content', ContentToken) then begin
            ResponseText := ContentToken.AsValue().AsText();
            if not ResponseJson.ReadFrom(ResponseText) then
                exit(false);
        end;
        exit(ValidateMLLMResponse(ResponseJson));
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
        if not ResponseJson.Get('accounting_supplier_party', SupplierToken) then exit(false);
        if not SupplierToken.IsObject() then exit(false);
        SupplierObj := SupplierToken.AsObject();
        if not SupplierObj.Get('party', PartyToken) then exit(false);
        if not PartyToken.IsObject() then exit(false);
        PartyObj := PartyToken.AsObject();
        if not PartyObj.Get('party_name', NameToken) then exit(false);
        if not NameToken.IsObject() then exit(false);
        NameObj := NameToken.AsObject();
        if not NameObj.Get('name', NameToken) then exit(false);
        VendorName := NameToken.AsValue().AsText();
        if VendorName = '' then exit(false);
        if not PartyObj.Get('postal_address', AddressToken) then exit(false);
        if not AddressToken.IsObject() then exit(false);
        exit(true);
    end;

    local procedure FallbackToADI(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType
    var
        ADIHandler: Codeunit "E-Document ADI Handler";
    begin
        exit(ADIHandler.StructureReceivedEDocument(EDocumentDataStorage));
    end;


    procedure RegisterCopilotCapabilityIfNeeded()
    var
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"E-Document MLLM Analysis") then
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"E-Document MLLM Analysis", '');
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

#pragma warning disable AA0139
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
#pragma warning restore AA0139
}
